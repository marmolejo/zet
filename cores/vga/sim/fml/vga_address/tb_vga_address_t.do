quit -sim

if {[file exists work]} {
  vdel -lib work -all
}
vlib work
vmap work work

echo "Compiling verilog modules..."

vlog -work work -nocovercells ./tb_vga_address.v
vlog -work work -nocovercells ../../../rtl/vga_planar.v
vlog -work work -nocovercells ../../../rtl/vga_text_mode.v
vlog -work work -nocovercells ../../../rtl/vga_linear.v
vlog -work work -nocovercells ../../../rtl/vga_char_rom.v
vlog -work work -nocovercells ../../../rtl/fml/vga_text_mode_fml.v

vsim work.tb_vga_address work.vga_char_rom work.vga_text_mode_fml work.vga_linear work.vga_planar work.vga_text_mode

add wave -label clk           -hex           {sim:/tb_vga_address/clk_50 } 
add wave -label rst           -hex           {sim:/tb_vga_address/rst } 
add wave -label h_count       -dec -unsigned {sim:/tb_vga_address/h_count } 
add wave -label v_count       -dec -unsigned {sim:/tb_vga_address/v_count }
add wave -label horiz_sync_i  -hex           {sim:/tb_vga_address/horiz_sync_i }
add wave -label video_on_h_i  -hex           {sim:/tb_vga_address/video_on_h_i }
add wave -label csr_dat_i     -hex -unsigned {sim:/tb_vga_address/csr_dat_i }
add wave -label fml_dat_i     -hex -unsigned {sim:/tb_vga_address/fml_dat_i } 


add wave -divider "CSR Inputs and Outputs"
 
add wave -label csr_tm_adr_o  -dec -unsigned {sim:/tb_vga_address/csr_tm_adr_o } 
add wave -label csr_tm_stb_o  -hex           {sim:/tb_vga_address/csr_tm_stb_o } 
add wave -label attr_tm       -hex           {sim:/tb_vga_address/attr_tm } 
add wave -label video_on_h_tm -hex           {sim:/tb_vga_address/video_on_h_tm }
add wave -label horiz_sync_tm -hex           {sim:/tb_vga_address/horiz_sync_tm }

add wave -divider "FML Inputs and Outputs"
 
add wave -label fml_csr_tm_adr_o  -dec -unsigned {sim:/tb_vga_address/fml_csr_tm_adr_o } 
add wave -label fml_csr_tm_stb_o  -hex           {sim:/tb_vga_address/fml_csr_tm_stb_o } 
add wave -label fml_attr_tm       -hex           {sim:/tb_vga_address/fml_attr_tm } 
add wave -label fml_video_on_h_tm -hex           {sim:/tb_vga_address/fml_video_on_h_tm } 
add wave -label fml_horiz_sync_tm -hex           {sim:/tb_vga_address/fml_horiz_sync_tm }

add wave -divider "FML Text Mode Registers"

add wave -label clk -hex -unsigned {sim:/tb_vga_address/text_mode_fml/clk }
add wave -label pipe -hex -unsigned {sim:/tb_vga_address/text_mode_fml/pipe }
add wave -label fml_dat_i -hex -unsigned {sim:/tb_vga_address/text_mode_fml/fml_dat_i }
add wave -label fml1_dat -hex -unsigned {sim:/tb_vga_address/text_mode_fml/fml1_dat }

add wave -label attr_data_out -hex -unsigned {sim:/tb_vga_address/text_mode_fml/attr_data_out }
add wave -label char_addr_in -hex -unsigned {sim:/tb_vga_address/text_mode_fml/char_addr_in }

add wave -label load_shift -hex -unsigned {sim:/tb_vga_address/text_mode_fml/load_shift }
add wave -label vga_shift -hex -unsigned {sim:/tb_vga_address/text_mode_fml/vga_shift }

add wave -divider "Text Mode Registers"

add wave -label pipe -hex -unsigned {sim:/tb_vga_address/text_mode/pipe }
add wave -label csr_dat_i -hex -unsigned {sim:/tb_vga_address/text_mode/csr_dat_i }

add wave -label attr_data_out -hex -unsigned {sim:/tb_vga_address/text_mode/attr_data_out }
add wave -label char_addr_in -hex -unsigned {sim:/tb_vga_address/text_mode/char_addr_in }

add wave -label load_shift -hex -unsigned {sim:/tb_vga_address/text_mode/load_shift }
add wave -label vga_shift -hex -unsigned {sim:/tb_vga_address/text_mode/vga_shift }





run 500us