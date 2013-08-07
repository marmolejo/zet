quit -sim

if {[file exists work]} {
  vdel -lib work -all
}
vlib work
vmap work work

echo "Compiling verilog modules..."

vlog -work work -nocovercells ./tb_vga_linear_fml.v
vlog -work work -nocovercells ../../../rtl/vga_linear.v
vlog -work work -nocovercells ../../../rtl/fml/vga_linear_fml.v

vsim work.tb_vga_linear_fml work.vga_linear_fml work.vga_linear

add wave -label clk           -hex           {sim:/tb_vga_linear_fml/clk_50 } 
add wave -label rst           -hex           {sim:/tb_vga_linear_fml/rst } 
add wave -label h_count       -dec -unsigned {sim:/tb_vga_linear_fml/h_count } 
add wave -label v_count       -dec -unsigned {sim:/tb_vga_linear_fml/v_count }
add wave -label horiz_sync_i  -hex           {sim:/tb_vga_linear_fml/horiz_sync_i }
add wave -label video_on_h_i  -hex           {sim:/tb_vga_linear_fml/video_on_h_i }
add wave -label csr_dat_i     -hex           {sim:/tb_vga_linear_fml/csr_dat_i }
add wave -label fml_dat_i     -hex           {sim:/tb_vga_linear_fml/fml_dat_i } 


add wave -divider "CSR Inputs and Outputs"
 
add wave -label csr_gm_adr_o  -dec -unsigned {sim:/tb_vga_linear_fml/csr_gm_adr_o } 
add wave -label csr_gm_stb_o  -hex           {sim:/tb_vga_linear_fml/csr_gm_stb_o } 
add wave -label color         -hex           {sim:/tb_vga_linear_fml/color } 
add wave -label video_on_h_gm -hex           {sim:/tb_vga_linear_fml/video_on_h_gm }
add wave -label horiz_sync_gm -hex           {sim:/tb_vga_linear_fml/horiz_sync_gm }

add wave -divider "FML Inputs and Outputs"
 
add wave -label fml_gm_adr_o      -dec -unsigned {sim:/tb_vga_linear_fml/fml_gm_adr_o } 
add wave -label fml_gm_stb_o      -hex           {sim:/tb_vga_linear_fml/fml_gm_stb_o } 
add wave -label fml_color         -hex           {sim:/tb_vga_linear_fml/fml_color } 
add wave -label fml_video_on_h_gm -hex           {sim:/tb_vga_linear_fml/fml_video_on_h_gm } 
add wave -label fml_horiz_sync_gm -hex           {sim:/tb_vga_linear_fml/fml_horiz_sync_gm }

add wave -divider "FML Linear Mode Registers"

add wave -label pipe      -hex -unsigned {sim:/tb_vga_linear_fml/linear_fml/pipe }
add wave -label fml_dat_i -hex {sim:/tb_vga_linear_fml/linear_fml/fml_dat_i }
add wave -label fml1_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml1_dat }
add wave -label fml2_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml2_dat }
add wave -label fml3_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml3_dat }
add wave -label fml4_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml4_dat }
add wave -label fml5_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml5_dat }
add wave -label fml6_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml6_dat }
add wave -label fml7_dat  -hex {sim:/tb_vga_linear_fml/linear_fml/fml7_dat }

add wave -divider "Linear Mode Registers"

add wave -label pipe -hex -unsigned {sim:/tb_vga_linear_fml/linear/pipe }
add wave -label csr_dat_i -hex      {sim:/tb_vga_linear_fml/linear/csr_dat_i }
add wave -label plane_addr -hex     {sim:/tb_vga_linear_fml/linear/plane_addr }
add wave -label word_offset -hex    {sim:/tb_vga_linear_fml/linear/word_offset }

run 500us