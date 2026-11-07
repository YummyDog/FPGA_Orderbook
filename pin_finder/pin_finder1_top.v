// pin_finder1_top.v - ONE 10G PCS/PMA core, for testing a channel in a
// quad that borrows another quad's reference clock (e.g. channel in quad
// 115 or 117, clock from MGTREFCLK1_116 = V6/V5).
//
// Same core settings, clocks, idles and VIO as pin_finder_top.v, but only
// one channel. The VIO probes are still 5 bits wide; only BIT 0 is used:
//   sync2_1[0] (probe_in0)  qplllock   - borrowed refclk reaches this quad's QPLL
//   sync2_2[5] (probe_in1)  resetdone
//   sync2[10]  (probe_in2)  blocklock now
//   blocklock_seen[0]       blocklock seen since last clear
//   vio_reset / vio_clear   as before

`timescale 1ns / 1ps

module pin_finder1_top (
  input  wire clk25in,      // 25 MHz oscillator, AH9
  output wire fan,          // AL33, held high like OrderBook's fan_pwm (100 %)

  input  wire refclk_p,
  input  wire refclk_n,

  output wire txp,
  output wire txn,
  input  wire rxp,
  input  wire rxn
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

  // ---- reset: ~1.3 ms after MMCM lock, plus VIO reset ----
  wire       vio_reset, vio_clear;
  reg [17:0] por_cnt   = 18'd0;
  reg        rst_cores = 1'b1;

  always @(posedge sysclk) begin
    if (!mmcm_locked)
      por_cnt <= 18'd0;
    else if (!por_cnt[17])
      por_cnt <= por_cnt + 18'd1;
    rst_cores <= !por_cnt[17] || vio_reset;
  end

  // ---- the core ----
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

  // ---- status into sysclk domain (bit 0 of each probe) ----
  (* ASYNC_REG = "TRUE" *) reg [14:0] sync1 = 15'd0;
  (* ASYNC_REG = "TRUE" *) reg [14:0] sync2 = 15'd0;
  reg [4:0] blocklock_seen = 5'd0;

  always @(posedge sysclk) begin
    sync1 <= {4'd0, core_status[0], 4'd0, resetdone, 4'd0, qplllock};
    sync2 <= sync1;
    if (vio_clear)
      blocklock_seen <= 5'd0;
    else
      blocklock_seen <= blocklock_seen | sync2[14:10];
  end

  vio_pf u_vio (
    .clk        (sysclk),
    .probe_in0  (sync2[4:0]),
    .probe_in1  (sync2[9:5]),
    .probe_in2  (sync2[14:10]),
    .probe_in3  (blocklock_seen),
    .probe_in4  (mmcm_locked),
    .probe_out0 (vio_reset),
    .probe_out1 (vio_clear)
  );

endmodule
