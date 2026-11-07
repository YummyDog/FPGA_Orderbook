PIN FINDER - find the GTH channel and refclk wired to the QSFP
================================================================

One 10G PCS/PMA core in each GTH quad 114-118 (5 at once), all sending
10GBASE-R idles. A VIO shows which quad's refclk works and which channel
receives the ConnectX-5's signal.

BUILD (Vivado Tcl Console, no project open):
  set CH 0; set REF 0; source C:/Users/lskje/Desktop/FPGA_Orderbook/pin_finder/pin_finder_build.tcl
  -> pin_finder_ch0_ref0.bit / .ltx in this folder

  CH  = channel 0..3 tested in every quad
  REF = 0 (MGTREFCLK0) or 1 (MGTREFCLK1)

TEST:
  1. Hardware Manager: program pin_finder_chX_refY.bit with probes file pin_finder_chX_refY.ltx
  2. ConnectX:  mlxlink -d mt4119_pciconf0 -p 1 --test_mode DS   (make sure PRBS is off)
                mlxlink -d mt4119_pciconf0 -p 1 -a TG
  3. VIO (hw_vio_1), bit q = quad 114+q:
       probe_in0 qplllock        1 = that quad's refclk pin has 156.25 MHz
       probe_in1 resetdone       1 = transceiver out of reset
       probe_in2 blocklock       1 = this channel receives the ConnectX lane
       probe_in3 blocklock_seen  sticky version of probe_in2
       probe_in4 mmcm_locked     should be 1
     probe_out0 = 1 then 0 : reset all cores
     probe_out1 = 1 then 0 : clear blocklock_seen
  4. mlxlink -d mt4119_pciconf0 -p 1   -> Active / LinkUp means TX is right too

ORDER: CH0/REF0, CH3/REF0, CH1/REF0, CH2/REF0, then the same with REF1 if no
quad shows qplllock=1.

RESULT -> orderbook.xdc: copy the 6 lines for the winning quad from
pins_chX_refY.xdc (rename refclk_p[q]->gt_refclk_clk_p, refclk_n[q]->gt_refclk_clk_n,
rxp[q]->sfp_rxp, rxn[q]->sfp_rxn, txp[q]->sfp_txp, txn[q]->sfp_txn).
If REF=1 won, also set the OrderBook PCS/PMA IP reference clock to clk1.

Note: the 10G PCS/PMA core is an evaluation build - test soon after programming.
