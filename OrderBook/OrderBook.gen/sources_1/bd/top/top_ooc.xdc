################################################################################

# This XDC is used only for OOC mode of synthesis, implementation
# This constraints file contains default clock frequencies to be used during
# out-of-context flows such as OOC Synthesis and Hierarchical Designs.
# This constraints file is not used in normal top-down synthesis (default flow
# of Vivado)
################################################################################
create_clock -name clk25in -period 40 [get_ports clk25in]
create_clock -name gt_refclk_clk_p -period 6.400 [get_ports gt_refclk_clk_p]

################################################################################