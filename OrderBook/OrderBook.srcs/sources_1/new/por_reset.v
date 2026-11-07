// por_reset.v - power-on reset for the 10G PCS/PMA cores.
//
// Holds rst_out high for 2^(BITS-1) cycles of clk after configuration
// (BITS = 17 at 25 MHz -> ~2.6 ms), then releases it. force_rst (e.g. from a
// VIO) re-asserts it for as long as it is high.
//
// This mirrors the working pin_finder build, which released the core's reset
// ~1.3 ms after configuration instead of tying it to 0.

`timescale 1ns / 1ps

module por_reset #(
  parameter integer BITS = 17
) (
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
  (* X_INTERFACE_PARAMETER = "FREQ_HZ 25000000" *)
  input  wire clk,

  input  wire force_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_out RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  output reg  rst_out = 1'b1
);

  reg [BITS-1:0] cnt = {BITS{1'b0}};

  always @(posedge clk) begin
    if (!cnt[BITS-1])
      cnt <= cnt + 1'b1;
    rst_out <= ~cnt[BITS-1] | force_rst;
  end

endmodule
