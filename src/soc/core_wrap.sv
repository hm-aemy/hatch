// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

module core_wrap import croc_pkg::*; #() (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic ref_clk_i,
  input  logic test_enable_i,

  input logic [15:0] irqs_i,
  input logic timer0_irq_i,

  input  logic [31:0] boot_addr_i,

  // Instruction memory interface
  output logic        instr_req_o,
  input  logic        instr_gnt_i,
  input  logic        instr_rvalid_i,
  output logic [31:0] instr_addr_o,
  input  logic [31:0] instr_rdata_i,
  input  logic        instr_err_i,

  // Data memory interface
  output logic        data_req_o,
  input  logic        data_gnt_i,
  input  logic        data_rvalid_i,
  output logic        data_we_o,
  output logic [3:0]  data_be_o,
  output logic [31:0] data_addr_o,
  output logic [31:0] data_wdata_o,
  input  logic [31:0] data_rdata_i,
  input  logic        data_err_i,

  // Debug Interface
  input  logic        debug_req_i,

  // CPU Control Signals
  input  logic        fetch_enable_i,

  output logic        core_busy_o
);

  // lowest 8 bits are ignored internally
  logic[31:0] boot_addr;
  assign boot_addr = boot_addr_i & 32'hFFFFFF00; 

  logic core_sleep;
  assign core_busy_o = ~core_sleep;

  logic irq_external, irq_software;
  assign irq_external = 0;
  assign irq_software = 0;

  cv32e40p_top #(
    .COREV_PULP       (0),
    .COREV_CLUSTER    (0),
    .FPU              (0),
    .FPU_ADDMUL_LAT   (0),
    .FPU_OTHERS_LAT   (0),
    .ZFINX            (0),
    .NUM_MHPMCOUNTERS (1)
  ) i_cv32e40p (
    .clk_i,
    .rst_ni,

    .pulp_clock_en_i (0),
    .scan_cg_en_i    (test_enable_i),

    .boot_addr_i     (boot_addr),
    .hart_id_i       (HartId),

    .mtvec_addr_i    (boot_addr),
    .dm_halt_addr_i  (32'h800),
    .dm_exception_addr_i (32'h808),
    
    // Instruction Memory Interface:
    .instr_req_o,
    .instr_gnt_i,
    .instr_rdata_i,
    .instr_rvalid_i,
    .instr_addr_o,

    // Data memory interface:
    .data_req_o, 
    .data_gnt_i,
    .data_rvalid_i,
    .data_we_o,
    .data_be_o,
    .data_addr_o,
    .data_wdata_o,
    .data_rdata_i,

    .irq_i    ({irq_fast_i, 4'b0, irq_external, 3'b0, timer0_irq_i, 3'b0, irq_software, 3'b0}),
    .irq_ack_o(),
    .irq_id_o (),

    .debug_req_i,
    .debug_havereset_o (),
    .debug_running_o   (),
    .debug_halted_o    (),

    .fetch_enable_i,
    .core_sleep_o (core_sleep)
  );

endmodule
