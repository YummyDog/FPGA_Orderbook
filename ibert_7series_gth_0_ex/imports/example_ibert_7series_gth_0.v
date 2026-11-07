// file: ibert_7series_gth_0.v
//////////////////////////////////////////////////////////////////////////////
// Module example_ibert_7series_gth_0
//////////////////////////////////////////////////////////////////////////////


`define C_NUM_QUADS 5
`define C_REFCLKS_USED 5
module example_ibert_7series_gth_0
(
  // GT top level ports
  output [(4*`C_NUM_QUADS)-1:0]		TXN_O,
  output [(4*`C_NUM_QUADS)-1:0]		TXP_O,
  input  [(4*`C_NUM_QUADS)-1:0]    	RXN_I,
  input  [(4*`C_NUM_QUADS)-1:0]   	RXP_I,
  input                           	SYSCLKP_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK0P_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK0N_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK1P_I,
  input  [`C_REFCLKS_USED-1:0]        	GTREFCLK1N_I
);

  //
  // Ibert refclk internal signals
  //
  wire   [`C_NUM_QUADS-1:0]        	gtrefclk0_i;
  wire   [`C_NUM_QUADS-1:0]        	gtrefclk1_i;
  wire   [`C_REFCLKS_USED-1:0]        	refclk0_i;
  wire   [`C_REFCLKS_USED-1:0]        	refclk1_i;
  wire                            	sysclk_i;

  //
  // Refclk IBUFDS instantiations
  //

    IBUFDS_GTE2 u_buf_q16_clk0
      (
        .O            (refclk0_i[0]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK0P_I[0]),
        .IB           (GTREFCLK0N_I[0])
      );

    IBUFDS_GTE2 u_buf_q16_clk1
      (
        .O            (refclk1_i[0]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK1P_I[0]),
        .IB           (GTREFCLK1N_I[0])
      );
    IBUFDS_GTE2 u_buf_q17_clk0
      (
        .O            (refclk0_i[1]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK0P_I[1]),
        .IB           (GTREFCLK0N_I[1])
      );

    IBUFDS_GTE2 u_buf_q17_clk1
      (
        .O            (refclk1_i[1]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK1P_I[1]),
        .IB           (GTREFCLK1N_I[1])
      );
    IBUFDS_GTE2 u_buf_q18_clk0
      (
        .O            (refclk0_i[2]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK0P_I[2]),
        .IB           (GTREFCLK0N_I[2])
      );

    IBUFDS_GTE2 u_buf_q18_clk1
      (
        .O            (refclk1_i[2]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK1P_I[2]),
        .IB           (GTREFCLK1N_I[2])
      );
    IBUFDS_GTE2 u_buf_q19_clk0
      (
        .O            (refclk0_i[3]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK0P_I[3]),
        .IB           (GTREFCLK0N_I[3])
      );

    IBUFDS_GTE2 u_buf_q19_clk1
      (
        .O            (refclk1_i[3]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK1P_I[3]),
        .IB           (GTREFCLK1N_I[3])
      );
    IBUFDS_GTE2 u_buf_q20_clk0
      (
        .O            (refclk0_i[4]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK0P_I[4]),
        .IB           (GTREFCLK0N_I[4])
      );

    IBUFDS_GTE2 u_buf_q20_clk1
      (
        .O            (refclk1_i[4]),
        .ODIV2        (),
        .CEB          (1'b0),
        .I            (GTREFCLK1P_I[4]),
        .IB           (GTREFCLK1N_I[4])
      );

  //
  // Refclk connection from each IBUFDS to respective quads depending on the source selected in gui
  //
  assign gtrefclk0_i[0] = refclk0_i[0];
  assign gtrefclk1_i[0] = refclk1_i[0];
  assign gtrefclk0_i[1] = refclk0_i[1];
  assign gtrefclk1_i[1] = refclk1_i[1];
  assign gtrefclk0_i[2] = refclk0_i[2];
  assign gtrefclk1_i[2] = refclk1_i[2];
  assign gtrefclk0_i[3] = refclk0_i[3];
  assign gtrefclk1_i[3] = refclk1_i[3];
  assign gtrefclk0_i[4] = refclk0_i[4];
  assign gtrefclk1_i[4] = refclk1_i[4];



  //
  // Sysclock connection
  //
  assign sysclk_i = SYSCLKP_I;


  //
  // IBERT core instantiation
  //
  ibert_7series_gth_0 u_ibert_core
    (
      .TXN_O(TXN_O),
      .TXP_O(TXP_O),
      .RXN_I(RXN_I),
      .RXP_I(RXP_I),
      .SYSCLK_I(sysclk_i),
      .GTREFCLK0_I(gtrefclk0_i),
      .GTREFCLK1_I(gtrefclk1_i)
    );

endmodule
