SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Force G++ for Verilator in this environment
CXX = g++
LINK = g++

SRC_DIR = $(PWD)/../../src
VERILOG_SOURCES = $(SRC_DIR)/operators_top.v \
                  $(SRC_DIR)/tkeo.v \
                  $(SRC_DIR)/ed.v \
                  $(SRC_DIR)/aso.v \
                  $(SRC_DIR)/ado.v

# Enable FST tracing for Verilator
EXTRA_ARGS += --trace --trace-fst --trace-structs -Wno-CMPCONST

TOPLEVEL = operators_top
MODULE = test_operators

include $(shell cocotb-config --makefiles)/Makefile.sim

clean_extra:
	rm -rf *.csv *.html __pycache__ results.xml