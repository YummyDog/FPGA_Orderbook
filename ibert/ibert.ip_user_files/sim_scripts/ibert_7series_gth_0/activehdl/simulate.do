transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+ibert_7series_gth_0  -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.ibert_7series_gth_0 xil_defaultlib.glbl

do {ibert_7series_gth_0.udo}

run 1000ns

endsim

quit -force
