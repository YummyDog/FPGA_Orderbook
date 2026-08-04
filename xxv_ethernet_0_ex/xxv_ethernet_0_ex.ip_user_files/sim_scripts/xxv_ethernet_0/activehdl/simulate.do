transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+xxv_ethernet_0  -L xil_defaultlib -L xilinx_vip -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.xxv_ethernet_0 xil_defaultlib.glbl

do {xxv_ethernet_0.udo}

run 1000ns

endsim

quit -force
