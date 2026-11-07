// qsfp_test_top.v - bring up the board's QSFP module and send 10GBASE-R
// idles on QSFP lane 1, using the pin-out from the reference design
// (rugmac.xdc):
//
//   GTHE2_CHANNEL_X1Y24 (quad 116 ch0): TX -> QSFP fibre/lane 1
//   GTHE2_CHANNEL_X1Y26 (quad 116 ch2): RX <- QSFP fibre/lane 1  (not used here)
//   refclk  MGTREFCLK1_116 = V6/V5, 156.25 MHz
//   QSFP_RESET  AH13  (output)     SFP_OR_OPT  AC12  (output)
//   QSFP_PRES   AL23  (input)      SF_FLT_LOS  AK23  (input)
//
// One 10G PCS/PMA core (tg_pcs_pma, same settings as OrderBook, clk1) on
// X1Y24 transmits idles, so the ConnectX-5 (forced to 10G) can come up.
//
// VIO (vio_qsfp), clocked from the 25 MHz oscillator via an MMCM:
//   inputs : s_qplllock, s_resetdone, s_blocklock, s_qsfp_pres,
//            s_flt_los, mmcm_locked
//   outputs: vio_reset (reset the 10G core), qsfp_reset_o, sfp_or_opt_o
// Both QSFP control outputs start at 0; set them from the VIO dashboard.

`timescale 1ns / 1ps

module qsfp_test_top (
  input  wire clk25in,      // 25 MHz oscillator, AH9
  output wire fan,          // AL33, held high like OrderBook's fan_pwm (100 %)

  input  wire refclk_p,     // V6  MGTREFCLK1P_116
  input  wire refclk_n,     // V5  MGTREFCLK1N_116

  output wire txp,          // MGTHTXP0_116 (X1Y24) -> QSFP lane 1
  output wire txn,
  input  wire rxp,          // MGTHRXP0_116 (X1Y24) <- QSFP lane 3 (unused)
  input  wire rxn,

  output wire QSFP_RESET,   // AH13
  output wire SFP_OR_OPT,   // AC12
  input  wire QSFP_PRES,    // AL23
  input  wire SF_FLT_LOS    // AK23
);

  assign fan = 1'b1;

  // ---- 25 MHz -> 100 MHz free-running clock ----
  wire clk25_ibuf, mmcm_fb, sysclk_unbuf, sysclk, mmcm_locked;

  IBUF u_clk25_ibuf (.I(clk25in), .O(clk25_ibuf));

  MMCME2_BASE #(
    .BANDWIDTH          ("OPTIMIZED"),
    .CLKIN1_PERIOD      (40.000),
    .DIVCLK_DIVIDE      (1),
    .CLKFBOUT_MULT_F    (40.000),
    .CLKOUT0_DIVIDE_F   (10.000),
    .CLKOUT0_DUTY_CYCLE (0.5),
    .STARTUP_WAIT       ("FALSE")
  ) u_mmcm (
    .CLKIN1(clk25_ibuf), .CLKFBIN(mmcm_fb), .CLKFBOUT(mmcm_fb), .CLKFBOUTB(),
    .CLKOUT0(sysclk_unbuf), .CLKOUT0B(),
    .CLKOUT1(), .CLKOUT1B(), .CLKOUT2(), .CLKOUT2B(),
    .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
    .LOCKED(mmcm_locked), .PWRDWN(1'b0), .RST(1'b0)
  );

  BUFG u_sysclk_bufg (.I(sysclk_unbuf), .O(sysclk));

  // ---- VIO-driven QSFP control pins (registered, start at 0) ----
  wire vio_reset, qsfp_reset_o, sfp_or_opt_o;
  reg  qsfp_reset_q = 1'b0;
  reg  sfp_or_opt_q = 1'b0;

  always @(posedge sysclk) begin
    qsfp_reset_q <= qsfp_reset_o;
    sfp_or_opt_q <= sfp_or_opt_o;
  end

  assign QSFP_RESET = qsfp_reset_q;
  assign SFP_OR_OPT = sfp_or_opt_q;

  // ---- reset for the 10G core: ~1.3 ms after MMCM lock, plus VIO ----
  reg [17:0] por_cnt   = 18'd0;
  reg        rst_cores = 1'b1;

  always @(posedge sysclk) begin
    if (!mmcm_locked)
      por_cnt <= 18'd0;
    else if (!por_cnt[17])
      por_cnt <= por_cnt + 18'd1;
    rst_cores <= !por_cnt[17] || vio_reset;
  end

  // ---- 10G PCS/PMA on X1Y24: transmits idles on QSFP lane 1 ----
  wire        qplllock, resetdone;
  wire [7:0]  core_status;
  wire        drp_req, drp_den, drp_dwe, drp_drdy;
  wire [15:0] drp_daddr, drp_di, drp_drpdo;

  tg_pcs_pma u_pcs (
    .refclk_p               (refclk_p),
    .refclk_n               (refclk_n),
    .reset                  (rst_cores),
    .resetdone_out          (resetdone),
    .coreclk_out            (),
    .rxrecclk_out           (),
    .dclk                   (sysclk),
    .txp                    (txp),
    .txn                    (txn),
    .rxp                    (rxp),
    .rxn                    (rxn),
    .sim_speedup_control    (1'b0),
    .txusrclk_out           (),
    .txusrclk2_out          (),
    .areset_datapathclk_out (),
    .gttxreset_out          (),
    .gtrxreset_out          (),
    .txuserrdy_out          (),
    .reset_counter_done_out (),
    .qplllock_out           (qplllock),
    .qplloutclk_out         (),
    .qplloutrefclk_out      (),
    .xgmii_txd              (64'h0707070707070707),   // idles
    .xgmii_txc              (8'hFF),
    .xgmii_rxd              (),
    .xgmii_rxc              (),
    .mdc                    (1'b0),
    .mdio_in                (1'b0),
    .mdio_out               (),
    .mdio_tri               (),
    .prtad                  (5'd0),
    .core_status            (core_status),
    .signal_detect          (1'b1),
    .tx_fault               (1'b0),
    .drp_req                (drp_req),
    .drp_gnt                (drp_req),
    .drp_den_o              (drp_den),
    .drp_dwe_o              (drp_dwe),
    .drp_daddr_o            (drp_daddr),
    .drp_di_o               (drp_di),
    .drp_drdy_o             (drp_drdy),
    .drp_drpdo_o            (drp_drpdo),
    .drp_den_i              (drp_den),
    .drp_dwe_i              (drp_dwe),
    .drp_daddr_i            (drp_daddr),
    .drp_di_i               (drp_di),
    .drp_drdy_i             (drp_drdy),
    .drp_drpdo_i            (drp_drpdo),
    .tx_disable             (),
    .pma_pmd_type           (3'b000)
  );

  // ---- status into sysclk domain ----
  (* ASYNC_REG = "TRUE" *) reg [4:0] sync1 = 5'd0;
  (* ASYNC_REG = "TRUE" *) reg [4:0] sync2 = 5'd0;

  always @(posedge sysclk) begin
    sync1 <= {SF_FLT_LOS, QSFP_PRES, core_status[0], resetdone, qplllock};
    sync2 <= sync1;
  end

  wire s_qplllock  = sync2[0];
  wire s_resetdone = sync2[1];
  wire s_blocklock = sync2[2];
  wire s_qsfp_pres = sync2[3];
  wire s_flt_los   = sync2[4];

  vio_qsfp u_vio (
    .clk        (sysclk),
    .probe_in0  (s_qplllock),
    .probe_in1  (s_resetdone),
    .probe_in2  (s_blocklock),
    .probe_in3  (s_qsfp_pres),
    .probe_in4  (s_flt_los),
    .probe_in5  (mmcm_locked),
    .probe_out0 (vio_reset),
    .probe_out1 (qsfp_reset_o),
    .probe_out2 (sfp_or_opt_o)
  );

endmodule
