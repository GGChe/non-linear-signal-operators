# ============================================================
# Cocotb configuration
# ============================================================

export CXX = g++
export CC = gcc
export COCOTB_WAVES        = 1
export COCOTB_WAVE_FORMAT = fst

SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(PWD)/src/operators_top.v \
                  $(PWD)/src/tkeo.v \
                  $(PWD)/src/ed.v \
                  $(PWD)/src/aso.v \
                  $(PWD)/src/ado.v
TOPLEVEL = operators_top
MODULE = test_operators

# Enable FST tracing for Verilator
EXTRA_ARGS += --trace --trace-fst --trace-structs

export PYTHONPATH := $(PWD)/tb/cocotb:$(PYTHONPATH)
export PLUSARGS += +trace

.PHONY: help test-cocotb test-verilog view-cocotb view-verilog clean librelane view-openroad

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

librelane: ## Run LibreLane ASIC synthesis flow
	librelane --flow classic librelane/config.json

test-cocotb: ## Run Cocotb testbench
	cd tb/cocotb && poetry run $(MAKE) SIM=$(SIM)

test-verilog: ## Run Verilog testbench (Icarus Verilog)
	iverilog -g2005-sv -o sim_rtl.out $(VERILOG_SOURCES) $(PWD)/tb/verilog/tb_operators.v
	vvp sim_rtl.out

view-cocotb: ## View Cocotb waveforms
	xdg-open tb/cocotb/report_lfp_real.html &
	gtkwave tb/cocotb/dump.fst

view-verilog: ## View Verilog testbench waveforms
	gtkwave tb/verilog/wave.gtkw

view-openroad: ## View synthesized design in OpenROAD
	@LATEST_RUN=$$(ls -td librelane/runs/RUN_* 2>/dev/null | head -n 1); \
	if [ -z "$$LATEST_RUN" ]; then \
		echo "Error: No LibreLane run found in librelane/runs/"; \
		exit 1; \
	fi; \
	ODB_FILE="$$LATEST_RUN/final/odb/operators_top.odb"; \
	if [ ! -f "$$ODB_FILE" ]; then \
		echo "Error: ODB file not found: $$ODB_FILE"; \
		exit 1; \
	fi; \
	echo "Opening $$ODB_FILE in OpenROAD..."; \
	env ODB_FILE="$$ODB_FILE" openroad -gui librelane/view_openroad.tcl

clean:: ## Clean up build artifacts
	rm -rf sim_build __pycache__ .pytest_cache
	rm -f results.xml *.csv *.html *.vcd *.fst *.wlf transcript sim_rtl.out
	cd tb/cocotb && rm -rf sim_build __pycache__ results.xml *.csv *.html *.fst
	rm -rf librelane/runs/*
