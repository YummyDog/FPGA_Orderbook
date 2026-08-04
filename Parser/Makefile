# cocotb + NVC testbench for the market-data header parser pipeline
#
#   make            run the Ethernet parser tests
#   make clean

SIM           ?= nvc
TOPLEVEL_LANG ?= vhdl

RTL_DIR := $(shell pwd)/../rtl

# Compile order matters: package before entity
VHDL_SOURCES += $(RTL_DIR)/eth_parser_pkg.vhd
VHDL_SOURCES += $(RTL_DIR)/eth_parser.vhd

TOPLEVEL := eth_parser
MODULE   := test_eth_parser

# NVC global options must precede the sub-command, hence EXTRA_ARGS
EXTRA_ARGS += --std=2008

# Waveforms: make WAVES=1
ifeq ($(WAVES),1)
    SIM_ARGS += --wave=eth_parser.fst --dump-arrays
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	@rm -rf sim_build __pycache__ results.xml *.fst
