# view_openroad.tcl
# TCL script to load the OpenROAD database for visualization

if { [info exists ::env(ODB_FILE)] } {
    set odb_file $::env(ODB_FILE)
    puts "Loading OpenROAD database: $odb_file"
    read_db $odb_file
} else {
    puts "Error: ODB_FILE environment variable not set."
    exit 1
}
