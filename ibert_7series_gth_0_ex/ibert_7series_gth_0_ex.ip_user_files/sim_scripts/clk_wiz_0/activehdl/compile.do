transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+D:/AMDDesignTools/2026.1/Vivado/data/rsb/busdef" "+incdir+../../../../ibert_7series_gth_0_ex.gen/sources_1/ip/clk_wiz_0" -l xpm -l xil_defaultlib \
"D:/AMDDesignTools/2026.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/AMDDesignTools/2026.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"D:/AMDDesignTools/2026.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -93  \
"../../../../ibert_7series_gth_0_ex.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_sim_netlist.vhdl" \

vlog -work xil_defaultlib \
"glbl.v"

