// pin_finder_top.v
//
// Finds which GTH channel / reference clock the QSFP is wired to.
//
// One 10G PCS/PMA core (tg_pcs_pma, "shared logic in core", same settings
// as OrderBook's ten_gig_eth_pcs_pma_0) in EACH of the 5 GTH quads 114-118.
// Every core uses its own quad's MGTREFCLK0 (or MGTREFCLK1) and one channel
// of that quad. Which channel (0-3) and which refclk are chosen per build
// by pin_finder_build.tcl (variables CH and REF).
//
// Index q = 0..4  <->  quad 114..118.
//
// Every core transmits 10GBASE-R idles. A VIO (clocked from the 25 MHz
// board oscillator via an MMCM, so it works even if no refclk is alive)
// shows, per quad:
//   probe_in0  qplllock        - this quad's refclk pin has a working 156.25 MHz clock
//   probe_in1  resetdone       - the transceiver came out of reset
//   probe_in2  blocklock       - PCS block lock NOW: this channel is receiving
//                                the ConnectX-5's 10GBASE-R signal
//   probe_in3  blocklock_seen  - block lock seen at any time since last clear
//   probe_in4  mmcm_locked     - system clock OK
// VIO outputs:
//   probe_out0 reset all cores (write 1 then 0)
//   probe_out1 clear blocklock_seen (write 1 then 0)

`timescale 1ns / 1ps

module pin_finder_top (
  input  wire       clk25in,      // 25 MHz oscillator, AH9
  output wire       fan,          // AL33, held high like OrderBook's fan_pwm (100 %)

  input  wire [4:0] refclk_p,     // one refclk pin pair per quad 114..118
  input  wire [4:0] refclk_n,

  output wire [4:0] txp,          // one channel per quad 114..118
  output wire [4:0] txn,
  input  wire [4:0] rxp,
  input  wire [4:0] rxn
);

  assign fan = 1'b1;

  // -------------------------------------------------------------------
  // 25 MHz -> 100 MHz free-running clock (VIO clock and core DRP clock)
  // -------------------------------------------------------------------
  wire clk25_ibuf, mmcm_fb, sysclk_unbuf, sysclk, mmcm_locked;

  IBUF u_clk25_ibuf (.I(clk25in), .O(clk25_ibuf));

  MMCME2_BASE #(
    .BANDWIDTH          ("OPTIMIZED"),
    .CLKIN1_PERIOD      (40.000),   // 25 MHz
    .DIVCLK_DIVIDE      (1),
    .CLKFBOUT_MULT_F    (40.000),   // VCO 1000 MHz
    .CLKOUT0_DIVIDE_F   (10.000),   // 100 MHz
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

  // -------------------------------------------------------------------
  // Reset: ~1.3 ms power-on reset after the MMCM locks, plus VIO reset
  // -------------------------------------------------------------------
  wire       vio_reset, vio_clear;
  reg [17:0] por_cnt    = 18'd0;
  reg        rst_cores  = 1'b1;

  always @(posedge sysclk) begin
    if (!mmcm_locked)
      por_cnt <= 18'd0;
    else if (!por_cnt[17])
      por_cnt <= por_cnt + 18'd1;
    rst_cores <= !por_cnt[17] || vio_reset;
  end

  // -------------------------------------------------------------------
  // One 10G PCS/PMA core per quad
  // -------------------------------------------------------------------
  wire [4:0] qplllock, resetdone, blocklock;

  genvar q;
  generate
    for (q = 0; q < 5; q = q + 1) begin : g_quad
      wire [7:0]  core_status;
      wire        drp_req;
      wire        drp_den, drp_dwe, drp_drdy;
      wire [15:0] drp_daddr, drp_di, drp_drpdo;

      tg_pcs_pma u_pcs (
        .refclk_p               (refclk_p[q]),
        .refclk_n               (refclk_n[q]),
        .reset                  (rst_cores),
        .resetdone_out          (resetdone[q]),
        .coreclk_out            (),
        .rxrecclk_out           (),
        .dclk                   (sysclk),
        .txp                    (txp[q]),
        .txn                    (txn[q]),
        .rxp                    (rxp[q]),
        .rxn                    (rxn[q]),
        .sim_speedup_control    (1'b0),
        .txusrclk_out           (),
        .txusrclk2_out          (),
        .areset_datapathclk_out (),
        .gttxreset_out          (),
        .gtrxreset_out          (),
        .txuserrdy_out          (),
        .reset_counter_done_out (),
        .qplllock_out           (qplllock[q]),
        .qplloutclk_out         (),
        .qplloutrefclk_out      (),
        // transmit 10GBASE-R idles
        .xgmii_txd              (64'h0707070707070707),
        .xgmii_txc              (8'hFF),
        .xgmii_rxd              (),
        .xgmii_rxc              (),
        // MDIO unused (register defaults), same as OrderBook
        .mdc                    (1'b0),
        .mdio_in                (1'b0),
        .mdio_out               (),
        .mdio_tri               (),
        .prtad                  (5'd0),
        .core_status            (core_status),
        .signal_detect          (1'b1),
        .tx_fault               (1'b0),
        // DRP looped back to itself, same as OrderBook
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

      assign blocklock[q] = core_status[0];   // PCS block lock
    end
  endgenerate

  // -------------------------------------------------------------------
  // Bring status into the sysclk domain, keep a sticky block-lock flag
  // -------------------------------------------------------------------
  (* ASYNC_REG = "TRUE" *) reg [14:0] sync1 = 15'd0;
  (* ASYNC_REG = "TRUE" *) reg [14:0] sync2 = 15'd0;
  reg [4:0] blocklock_seen = 5'd0;

  always @(posedge sysclk) begin
    sync1 <= {blocklock, resetdone, qplllock};
    sync2 <= sync1;
    if (vio_clear)
      blocklock_seen <= 5'd0;
    else
      blocklock_seen <= blocklock_seen | sync2[14:10];
  end

  vio_pf u_vio (
    .clk        (sysclk),
    .probe_in0  (sync2[4:0]),     // qplllock  [q] = quad 114+q
    .probe_in1  (sync2[9:5]),     // resetdone
    .probe_in2  (sync2[14:10]),   // blocklock now
    .probe_in3  (blocklock_seen), // blocklock seen since clear
    .probe_in4  (mmcm_locked),
    .probe_out0 (vio_reset),
    .probe_out1 (vio_clear)
  );

endmodule
