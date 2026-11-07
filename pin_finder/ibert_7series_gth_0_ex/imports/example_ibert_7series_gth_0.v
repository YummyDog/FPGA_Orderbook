// file: ibert_7series_gth_0.v
//////////////////////////////////////////////////////////////////////////////
// Module example_ibert_7series_gth_0
//////////////////////////////////////////////////////////////////////////////


`define C_NUM_QUADS 3
`define C_REFCLKS_USED 1
module example_ibert_7series_gth_0
(
  // GT top level ports
  output [(4*`C_NUM_QUADS)-1:0]		TXN_O,
  output [(4*`C_NUM_QUADS)-1:0]		TXP_O,
  input  [(4*`C_NUM_QUADS)-1:0]    	RXN_I,
  input  [(4*`C_NUM_QUADS)-1:0]   	RXP_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK0P_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK0N_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK1P_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK1N_I,
  // ---- added: board clock, fan, QSFP control (pins from rugmac.xdc) ----
  input                                 clk25in,      // AH9, 25 MHz
  output                                fan,          // AL33, held high
  output                                QSFP_RESET,   // AH13
  output                                SFP_OR_OPT    // AC12
);

  //
  // Ibert refclk internal signals
  //
  wire   [`C_NUM_QUADS-1:0]        	gtrefclk0_i;
  wire   [`C_NUM_QUADS-1:0]        	gtrefclk1_i;
  wire   [`C_REFCLKS_USED-1:0]        	refclk0_i;
  wire   [`C_REFCLKS_USED-1:0]        	refclk1_i;

  //
  // Refclk IBUFDS instantiations
  //

    IBUFDS_GTE2 u_buf_q18_clk0
      (
        .O            (refclk0_i[0]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK0P_I[0]),
        .IB           (GTREFCLK0N_I[0])
      );

    IBUFDS_GTE2 u_buf_q18_clk1
      (
        .O            (refclk1_i[0]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK1P_I[0]),
        .IB           (GTREFCLK1N_I[0])
      );

  //
  // Refclk connection from each IBUFDS to respective quads depending on the source selected in gui
  //
  assign gtrefclk0_i[0] = 1'b0;
  assign gtrefclk1_i[0] = refclk1_i[0];
  assign gtrefclk0_i[1] = refclk0_i[0];
  assign gtrefclk1_i[1] = refclk1_i[0];
  assign gtrefclk0_i[2] = 1'b0;
  assign gtrefclk1_i[2] = refclk1_i[0];





  //
  // IBERT core instantiation
  //
  ibert_7series_gth_0 u_ibert_core
    (
      .TXN_O(TXN_O),
      .TXP_O(TXP_O),
      .RXN_I(RXN_I),
      .RXP_I(RXP_I),
      .GTREFCLK0_I(gtrefclk0_i),
      .GTREFCLK1_I(gtrefclk1_i)
    );

  // ---------------------------------------------------------------------
  // Added: fan + QSFP control pins.
  // QSFP_RESET / SFP_OR_OPT come from flip-flops that never change after
  // configuration, so their level is set by each FF's INIT value. The INIT
  // can be changed on the implemented design and a new bitstream written in
  // ~2 minutes without re-implementing (see qsfp_ctrl.tcl).
  // ---------------------------------------------------------------------
  assign fan = 1'b1;

  wire clk25_i, clk25;
  IBUF u_clk25_ibuf (.I(clk25in), .O(clk25_i));
  BUFG u_clk25_bufg (.I(clk25_i), .O(clk25));

  (* DONT_TOUCH = "TRUE" *) reg qsfp_reset_ff = 1'b0;
  (* DONT_TOUCH = "TRUE" *) reg sfp_or_opt_ff = 1'b0;

  always @(posedge clk25) begin
    qsfp_reset_ff <= qsfp_reset_ff;
    sfp_or_opt_ff <= sfp_or_opt_ff;
  end

  assign QSFP_RESET = qsfp_reset_ff;
  assign SFP_OR_OPT = sfp_or_opt_ff;

endmodule
