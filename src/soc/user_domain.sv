// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

module user_domain import user_pkg::*; import croc_pkg::*; import spi_pkg::*; #(
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

  output logic spi_cs_no_o,
  output logic spi_sclk_o,
  output logic spi_mosi_o,
  input  logic spi_miso_i,

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
    .NumMgrPorts        ( NumUserSbr      ),
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

    spi_obi_req_t spi_obi_req;
    spi_obi_rsp_t spi_obi_rsp;
    logic [OBI_ID_WIDTH-1:0] spi_aid;

    assign spi_aid = {{(OBI_ID_WIDTH-SbrObiCfg.IdWidth){1'b0}}, all_user_obi_req[UserSpi].a.aid};

    assign spi_obi_req.req          = all_user_obi_req[UserSpi].req;
    assign spi_obi_req.a.addr       = all_user_obi_req[UserSpi].a.addr;
    assign spi_obi_req.a.we         = all_user_obi_req[UserSpi].a.we;
    assign spi_obi_req.a.be         = all_user_obi_req[UserSpi].a.be;
    assign spi_obi_req.a.wdata      = all_user_obi_req[UserSpi].a.wdata;
    assign spi_obi_req.a.aid        = spi_aid;
    assign spi_obi_req.a.a_optional = all_user_obi_req[UserSpi].a.a_optional;

    assign all_user_obi_rsp[UserSpi].gnt          = spi_obi_rsp.gnt;
    assign all_user_obi_rsp[UserSpi].rvalid       = spi_obi_rsp.rvalid;
    assign all_user_obi_rsp[UserSpi].r.rdata      = spi_obi_rsp.r.rdata;
    assign all_user_obi_rsp[UserSpi].r.rid        = spi_obi_rsp.r.rid[SbrObiCfg.IdWidth-1:0];
    assign all_user_obi_rsp[UserSpi].r.err        = spi_obi_rsp.r.err;
    assign all_user_obi_rsp[UserSpi].r.r_optional = spi_obi_rsp.r.r_optional;

    spi i_spi (
      .clk_i      ( clk_i      ),
      .rst_ni     ( rst_ni     ),
      .obi_req_i  ( spi_obi_req ),
      .obi_rsp_o  ( spi_obi_rsp ),
      .spi_cs_no  ( spi_cs_no_o ),
      .spi_sclk_o ( spi_sclk_o ),
      .spi_mosi_o ( spi_mosi_o ),
      .spi_miso_i ( spi_miso_i )
    );


endmodule
