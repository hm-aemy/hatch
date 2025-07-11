module hatch(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg [7:0] data_out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 8'h00;
    end else begin
      data_out <= data_in + 1; // Simple increment operation for demonstration
    end
  end

endmodule