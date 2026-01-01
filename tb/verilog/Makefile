SIM  = iverilog
TOP  = tb_operators
SRC_DIR = ../../src

# Include all 4 operator files + top-level testbench
SRCS = \
  $(SRC_DIR)/tkeo.v \
  $(SRC_DIR)/ed.v \
  $(SRC_DIR)/aso.v \
  $(SRC_DIR)/ado.v \
  tb_operators.v

all: compile run

compile:
	$(SIM) -g2012 -o sim.out -s $(TOP) $(SRCS)

run:
	vvp sim.out

wave:
	gtkwave operators_wave.vcd

clean:
	rm -f sim.out operators_wave.vcd
	rm -f *.csv *.html

.PHONY: all compile run wave clean