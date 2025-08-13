module cv32e40p_clock_gate (
  input  logic clk_i,
  input  logic en_i,
  input  logic scan_cg_en_i,
  output logic clk_o
);

  assign clk_o = clk_i;

endmodule
