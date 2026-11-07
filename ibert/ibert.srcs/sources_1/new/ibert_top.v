// ibert_top.v - top level for IBERT 7 Series GTH (ibert_7series_gth_0)
//
// Sweeps all 20 GTH channels (quads 114-118) at 10.3125 Gb/s with a
// 156.25 MHz MGTREFCLK0 per quad, to find which pins the QSFP lane and
// reference clock really use.
//
// System clock: the board has a 25 MHz oscillator on AH9, but IBERT needs
// 50-820 MHz, so an MMCM multiplies 25 -> 100 MHz
// (VCO = 25 x 40 = 1000 MHz, /10 = 100 MHz). 100 MHz is what the IBERT IP
// was configured with (C_SYSCLK_FREQUENCY = 100).
//
// Index mapping: bit i of txp/txn/rxp/rxn = quad (114 + i/4), channel (i%4).
//                bit q of refclk0_p/n      = MGTREFCLK0 of quad (114 + q).

`timescale 1ns / 1ps

module ibert_top (
  input  wire        clk25in,       // 25 MHz board oscillator (AH9, LVCMOS18)
  output wire        fan,           // fan driver (AL33): held high, same as OrderBook

  input  wire [4:0]  refclk0_p,     // MGTREFCLK0P_114..118
  input  wire [4:0]  refclk0_n,     // MGTREFCLK0N_114..118

  output wire [19:0] txp,
  output wire [19:0] txn,
  input  wire [19:0] rxp,
  input  wire [19:0] rxn
);

  // ---------------------------------------------------------------------
  // Fan: OrderBook's fan_pwm runs at G_DUTY_PCT = 100, G_ACTIVE_HIGH = true,
  // i.e. the pin is constantly high. Keep the fan at full speed here too.
  // ---------------------------------------------------------------------
  assign fan = 1'b1;

  // ---------------------------------------------------------------------
  // 25 MHz -> 100 MHz system clock for IBERT
  // ---------------------------------------------------------------------
  wire clk25_ibuf;
  wire mmcm_fb;
  wire sysclk_100_unbuf;
  wire sysclk_100;
  wire mmcm_locked;

  IBUF u_clk25_ibuf (
    .I (clk25in),
    .O (clk25_ibuf)
  );

  MMCME2_BASE #(
    .BANDWIDTH        ("OPTIMIZED"),
    .CLKIN1_PERIOD    (40.000),     // 25 MHz
    .DIVCLK_DIVIDE    (1),
    .CLKFBOUT_MULT_F  (40.000),     // VCO = 1000 MHz
    .CLKFBOUT_PHASE   (0.000),
    .CLKOUT0_DIVIDE_F (10.000),     // 100 MHz
    .CLKOUT0_DUTY_CYCLE (0.5),
    .CLKOUT0_PHASE    (0.000),
    .STARTUP_WAIT     ("FALSE")
  ) u_sysclk_mmcm (
    .CLKIN1   (clk25_ibuf),
    .CLKFBIN  (mmcm_fb),
    .CLKFBOUT (mmcm_fb),
    .CLKFBOUTB(),
    .CLKOUT0  (sysclk_100_unbuf),
    .CLKOUT0B (),
    .CLKOUT1  (), .CLKOUT1B (),
    .CLKOUT2  (), .CLKOUT2B (),
    .CLKOUT3  (), .CLKOUT3B (),
    .CLKOUT4  (),
    .CLKOUT5  (),
    .CLKOUT6  (),
    .LOCKED   (mmcm_locked),
    .PWRDWN   (1'b0),
    .RST      (1'b0)
  );

  BUFG u_sysclk_bufg (
    .I (sysclk_100_unbuf),
    .O (sysclk_100)
  );

  // ---------------------------------------------------------------------
  // GT reference clock buffers (one per quad, MGTREFCLK0)
  // ---------------------------------------------------------------------
  wire [4:0] gtrefclk0;

  genvar q;
  generate
    for (q = 0; q < 5; q = q + 1) begin : g_refclk
      IBUFDS_GTE2 u_refclk_buf (
        .I     (refclk0_p[q]),
        .IB    (refclk0_n[q]),
        .CEB   (1'b0),
        .O     (gtrefclk0[q]),
        .ODIV2 ()
      );
    end
  endgenerate

  // ---------------------------------------------------------------------
  // IBERT core
  // ---------------------------------------------------------------------
  ibert_7series_gth_0 u_ibert_core (
    .TXN_O       (txn),
    .TXP_O       (txp),
    .RXOUTCLK_O  (),
    .RXN_I       (rxn),
    .RXP_I       (rxp),
    .GTREFCLK0_I (gtrefclk0),
    .GTREFCLK1_I (5'b00000),
    .SYSCLK_I    (sysclk_100)
  );

endmodule
