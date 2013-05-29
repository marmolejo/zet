quit -sim

echo "Compiling verilog modules..."

vlog -work work -nocovercells Z:/Documents/sirchuckalot/zet/cores/vga/sim/test_vga_address.v
vlog -work work -nocovercells Z:/Documents/sirchuckalot/zet/cores/vga/rtl/vga_planar.v
vlog -work work -nocovercells Z:/Documents/sirchuckalot/zet/cores/vga/rtl/vga_text_mode.v
vlog -work work -nocovercells Z:/Documents/sirchuckalot/zet/cores/vga/rtl/vga_linear.v
vlog -work work -nocovercells Z:/Documents/sirchuckalot/zet/cores/vga/rtl/vga_char_rom.v
vlog -work work -nocovercells Z:/Documents/sirchuckalot/zet/cores/vga/rtl/vga_fml_text_mode.v

vsim work.test_vga_address work.vga_char_rom work.vga_fml_text_mode work.vga_linear work.vga_planar work.vga_text_mode

add wave -label clk           -hex           {sim:/test_vga_address/clk_50 } 
add wave -label rst           -hex           {sim:/test_vga_address/rst } 
add wave -label h_count       -dec -unsigned {sim:/test_vga_address/h_count } 
add wave -label v_count       -dec -unsigned {sim:/test_vga_address/v_count }
add wave -label horiz_sync_i  -hex           {sim:/test_vga_address/horiz_sync_i }
add wave -label video_on_h_i  -hex           {sim:/test_vga_address/video_on_h_i }
add wave -label csr_dat_i     -hex -unsigned {sim:/test_vga_address/csr_dat_i }
add wave -label fml_dat_i     -hex -unsigned {sim:/test_vga_address/fml_dat_i } 


add wave -divider "CSR Inputs and Outputs"
 
add wave -label csr_tm_adr_o  -dec -unsigned {sim:/test_vga_address/csr_tm_adr_o } 
add wave -label csr_tm_stb_o  -hex           {sim:/test_vga_address/csr_tm_stb_o } 
add wave -label attr_tm       -hex           {sim:/test_vga_address/attr_tm } 
add wave -label video_on_h_tm -hex           {sim:/test_vga_address/video_on_h_tm }
add wave -label horiz_sync_tm -hex           {sim:/test_vga_address/horiz_sync_tm }

add wave -divider "FML Inputs and Outputs"
 
add wave -label fml_csr_tm_adr_o  -dec -unsigned {sim:/test_vga_address/fml_csr_tm_adr_o } 
add wave -label fml_csr_tm_stb_o  -hex           {sim:/test_vga_address/fml_csr_tm_stb_o } 
add wave -label fml_attr_tm       -hex           {sim:/test_vga_address/fml_attr_tm } 
add wave -label fml_video_on_h_tm -hex           {sim:/test_vga_address/fml_video_on_h_tm } 
add wave -label fml_horiz_sync_tm -hex           {sim:/test_vga_address/fml_horiz_sync_tm }

add wave -divider "FML Text Mode Registers"

add wave -label clk -hex -unsigned {sim:/test_vga_address/fml_text_mode/clk }
add wave -label pipe -hex -unsigned {sim:/test_vga_address/fml_text_mode/pipe }
add wave -label fml_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml_dat_i }
add wave -label fml0_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml0_dat_i }
add wave -label fml1_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml1_dat_i }
add wave -label fml2_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml2_dat_i }
add wave -label fml3_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml3_dat_i }
add wave -label fml4_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml4_dat_i }
add wave -label fml5_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml5_dat_i }
add wave -label fml6_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml6_dat_i }
add wave -label fml7_dat_i -hex -unsigned {sim:/test_vga_address/fml_text_mode/fml7_dat_i }

add wave -label attr_data_out -hex -unsigned {sim:/test_vga_address/fml_text_mode/attr_data_out }
add wave -label char_addr_in -hex -unsigned {sim:/test_vga_address/fml_text_mode/char_addr_in }

add wave -label load_shift -hex -unsigned {sim:/test_vga_address/fml_text_mode/load_shift }
add wave -label vga_shift -hex -unsigned {sim:/test_vga_address/fml_text_mode/vga_shift }

add wave -divider "Text Mode Registers"

add wave -label pipe -hex -unsigned {sim:/test_vga_address/text_mode/pipe }
add wave -label csr_dat_i -hex -unsigned {sim:/test_vga_address/text_mode/csr_dat_i }

add wave -label attr_data_out -hex -unsigned {sim:/test_vga_address/text_mode/attr_data_out }
add wave -label char_addr_in -hex -unsigned {sim:/test_vga_address/text_mode/char_addr_in }

add wave -label load_shift -hex -unsigned {sim:/test_vga_address/text_mode/load_shift }
add wave -label vga_shift -hex -unsigned {sim:/test_vga_address/text_mode/vga_shift }





run 500us