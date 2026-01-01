# Clock definition
create_clock -name clk -period 20.0 [get_ports clk]

# Input delays (relative to clk)
set_input_delay  2.0 -clock clk [get_ports rst]
set_input_delay  2.0 -clock clk [get_ports data_in*]

# Output delays (relative to clk)
set_output_delay 2.0 -clock clk [get_ports tkeo_out*]
set_output_delay 2.0 -clock clk [get_ports ed_out*]
set_output_delay 2.0 -clock clk [get_ports aso_out*]
set_output_delay 2.0 -clock clk [get_ports ado_out*]

# False paths
set_false_path -from [get_ports rst]
