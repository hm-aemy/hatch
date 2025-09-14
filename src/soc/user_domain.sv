// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

module user_domain import user_pkg::*; import croc_pkg::*; #(
  parameter int unsigned GpioCount = 16
) (
  input  logic      clk_i,
  input  logic      ref_clk_i,
  input  logic      rst_ni,
  input  logic      testmode_i,
  
  input  sbr_obi_req_t user_sbr_obi_req_i, // User Sbr (rsp_o), Croc Mgr (req_i)
  output sbr_obi_rsp_t user_sbr_obi_rsp_o,

  input  mgr_obi_req_t trace_obi_req_i,
  output mgr_obi_rsp_t trace_obi_rsp_o,

  output mgr_obi_req_t user_mgr_obi_req_o, // User Mgr (req_o), Croc Sbr (rsp_i)
  input  mgr_obi_rsp_t user_mgr_obi_rsp_i,

  input logic sram_impl,

  input  logic [      GpioCount-1:0] gpio_in_sync_i, // synchronized GPIO inputs
  output logic [NumExternalIrqs-1:0] interrupts_o // interrupts to core
);

  assign interrupts_o = '0;  


  //////////////////////
  // User Manager MUX //
  /////////////////////

  // No manager so we don't need a obi_mux module and just terminate the request properly
  assign user_mgr_obi_req_o = '0;

  // ----------------------------------------------------------------------------------------------
  // User Subordinate Buses
  // ----------------------------------------------------------------------------------------------
  logic [cf_math_pkg::idx_width(NumUserSbr)-1:0] user_idx;

  sbr_obi_req_t [NumUserSbr-1:0] all_user_obi_req;
  sbr_obi_rsp_t [NumUserSbr-1:0] all_user_obi_rsp;

  mgr_obi_req_t [1:0] all_obi_req;
  mgr_obi_rsp_t [1:0] all_obi_rsp;

  assign all_obi_req[0].req = user_sbr_obi_req_i.req; // User Sbr
  assign all_obi_req[0].a.addr = user_sbr_obi_req_i.a.addr;
  assign all_obi_req[0].a.we = user_sbr_obi_req_i.a.we;
  assign all_obi_req[0].a.be = user_sbr_obi_req_i.a.be;
  assign all_obi_req[0].a.wdata = user_sbr_obi_req_i.a.wdata;
  assign all_obi_req[0].a.aid = user_sbr_obi_req_i.a.aid[0];
  assign all_obi_req[0].a.a_optional = user_sbr_obi_req_i.a.a_optional;
  assign user_sbr_obi_rsp_o.gnt = all_obi_rsp[0].gnt;
  assign user_sbr_obi_rsp_o.rvalid = all_obi_rsp[0].rvalid;
  assign user_sbr_obi_rsp_o.r.rdata = all_obi_rsp[0].r.rdata;
  assign user_sbr_obi_rsp_o.r.rid = {2'b00, all_obi_rsp[0].r.rid};
  assign user_sbr_obi_rsp_o.r.err = all_obi_rsp[0].r.err;
  assign user_sbr_obi_rsp_o.r.r_optional = all_obi_rsp[0].r.r_optional;
  
  assign all_obi_req[1] = trace_obi_req_i;    // Trace Sbr
  assign trace_obi_rsp_o = all_obi_rsp[1];

  obi_xbar #(
    .SbrPortObiCfg      ( MgrObiCfg        ),
    .MgrPortObiCfg      ( SbrObiCfg        ),
    .sbr_port_obi_req_t ( mgr_obi_req_t    ),
    .sbr_port_a_chan_t  ( mgr_obi_a_chan_t ),
    .sbr_port_obi_rsp_t ( mgr_obi_rsp_t    ),
    .sbr_port_r_chan_t  ( mgr_obi_r_chan_t ),
    .mgr_port_obi_req_t ( sbr_obi_req_t    ),
    .mgr_port_obi_rsp_t ( sbr_obi_rsp_t    ),
    .NumSbrPorts        ( 2  ),
    .NumMgrPorts        ( 2  ),
    .NumMaxTrans        ( 2                ),
    .NumAddrRules       ( NumUserSbrRules  ),
    .addr_map_rule_t    ( addr_map_rule_t  ),
    .UseIdForRouting    ( 1'b0             ),
    .Connectivity       ( '1               )
  ) i_xbar (
    .clk_i,
    .rst_ni,
    .testmode_i,

    .sbr_ports_req_i  ( all_obi_req ), // from managers towards subordinates
    .sbr_ports_rsp_o  ( all_obi_rsp ),
    .mgr_ports_req_o  ( all_user_obi_req ), // connections to subordinates
    .mgr_ports_rsp_i  ( all_user_obi_rsp ),

    .addr_map_i       ( user_addr_map   ),
    .en_default_idx_i ( 2'b11           ),
    .default_idx_i    ( '1              )
  );


//-------------------------------------------------------------------------------------------------
// User Subordinates
//-------------------------------------------------------------------------------------------------

  // Error Subordinate
  obi_err_sbr #(
    .ObiCfg      ( SbrObiCfg     ),
    .obi_req_t   ( sbr_obi_req_t ),
    .obi_rsp_t   ( sbr_obi_rsp_t ),
    .NumMaxTrans ( 1             ),
    .RspData     ( 32'hBADCAB1E  )
  ) i_user_err (
    .clk_i,
    .rst_ni,
    .testmode_i ( testmode_i      ),
    .obi_req_i  ( all_user_obi_req[UserError] ),
    .obi_rsp_o  ( all_user_obi_rsp[UserError] )
  );

    logic bank_req, bank_we, bank_gnt, bank_single_err;
    logic [SbrObiCfg.AddrWidth-1:0] bank_byte_addr;
    logic [SramBankAddrWidth-1:0] bank_word_addr;
    logic [SbrObiCfg.DataWidth-1:0] bank_wdata, bank_rdata;
    logic [SbrObiCfg.DataWidth/8-1:0] bank_be;

    obi_sram_shim #(
      .ObiCfg    ( SbrObiCfg     ),
      .obi_req_t ( sbr_obi_req_t ),
      .obi_rsp_t ( sbr_obi_rsp_t )
    ) i_sram_shim (
      .clk_i,
      .rst_ni,

      .obi_req_i ( all_user_obi_req[UserRam] ),
      .obi_rsp_o ( all_user_obi_rsp[UserRam] ),

      .req_o   ( bank_req       ),
      .we_o    ( bank_we        ),
      .addr_o  ( bank_byte_addr ),
      .wdata_o ( bank_wdata     ),
      .be_o    ( bank_be        ),

      .gnt_i   ( bank_gnt   ),
      .rdata_i ( bank_rdata )
    );

    assign bank_word_addr = bank_byte_addr[SbrObiCfg.AddrWidth-1:2];

    tc_sram_impl #(
      .NumWords  ( 2048 ),
      .DataWidth ( 32 ),
      .NumPorts  (  1 ),
      .Latency   (  1 )
    ) i_sram (
      .clk_i,
      .rst_ni,

      .impl_i  ( sram_impl      ),
      .impl_o  ( ), // not connected

      .req_i   ( bank_req       ),
      .we_i    ( bank_we        ),
      .addr_i  ( bank_word_addr ),

      .wdata_i ( bank_wdata ),
      .be_i    ( bank_be    ),
      .rdata_o ( bank_rdata )
    );

    assign bank_gnt = 1'b1;


endmodule
