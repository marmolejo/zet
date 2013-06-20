quit -sim

echo "Compiling verilog modules..."

vlog -work work -nocovercells ./tb_vga_lcd_fml.v
vlog -work work -nocovercells ../../../rtl/fml/vga_lcd_fml.v

vlog -work work -nocovercells ../../../rtl/fml/vga_crtc_fml.v
vlog -work work -nocovercells ../../../rtl/fml/vga_fifo.v

vlog -work work -nocovercells ../../../rtl/fml/vga_pal_dac_fml.v
vlog -work work -nocovercells ../../../rtl/fml/vga_palette_regs_fml.v
vlog -work work -nocovercells ../../../rtl/fml/vga_dac_regs_fml.v

vlog -work work -nocovercells ../../../rtl/fml/vga_sequencer_fml.v

vlog -work work -nocovercells ../../../rtl/fml/vga_text_mode_fml.v
vlog -work work -nocovercells ../../../rtl/vga_char_rom.v

vlog -work work -nocovercells ../../../rtl/fml/vga_planar_fml.v

vlog -work work -nocovercells ../../../rtl/fml/vga_linear_fml.v

vsim work.tb_vga_lcd_fml work.vga_lcd_fml work.vga_crtc_fml work.vga_fifo work.vga_pal_dac_fml work.vga_palette_regs_fml work.vga_dac_regs_fml work.vga_sequencer_fml work.vga_text_mode_fml work.vga_char_rom work.vga_planar_fml work.vga_linear_fml

add wave -divider "Top Level Test Bench I/O"
add wave -label clk           -hex           {sim:/tb_vga_lcd_fml/clk_100 } 
add wave -label rst           -hex           {sim:/tb_vga_lcd_fml/rst }
add wave -label fml_stb       -hex -unsigned {sim:/tb_vga_lcd_fml/fml_stb }
add wave -label fml_adr       -dec -unsigned {sim:/tb_vga_lcd_fml/fml_adr }
add wave -label fml_di        -hex -unsigned {sim:/tb_vga_lcd_fml/fml_di }
add wave -label fml_do        -hex -unsigned {sim:/tb_vga_lcd_fml/fml_do }
add wave -label dcb_stb       -hex -unsigned {sim:/tb_vga_lcd_fml/dcb_stb }
add wave -label dcb_adr       -dec -unsigned {sim:/tb_vga_lcd_fml/dcb_adr }
add wave -label dcb_dat       -hex -unsigned {sim:/tb_vga_lcd_fml/dcb_dat }
add wave -label dcb_hit       -hex -unsigned {sim:/tb_vga_lcd_fml/dcb_hit }

add wave -divider "VGA LCD FML"

add wave -label horiz_total       -dec -unsigned     {sim:/tb_vga_lcd_fml/dut/crtc/horiz_total }
add wave -label hor_scan_end       -dec -unsigned     {sim:/tb_vga_lcd_fml/dut/crtc/hor_scan_end }
add wave -label h_count       -dec -unsigned     {sim:/tb_vga_lcd_fml/dut/h_count } 
add wave -label horiz_sync_i  -hex -unsigned     {sim:/tb_vga_lcd_fml/dut/horiz_sync_i } 

add wave -label v_count       -dec -unsigned     {sim:/tb_vga_lcd_fml/dut/v_count } 
add wave -label vert_sync_crtc_o  -hex -unsigned {sim:/tb_vga_lcd_fml/dut/vert_sync_crtc_o } 

add wave -label video_on_h_i  -hex           {sim:/tb_vga_lcd_fml/dut/video_on_h_i } 
add wave -label video_on_v    -hex           {sim:/tb_vga_lcd_fml/dut/video_on_v } 

add wave -divider "FML Text Mode Registers"

add wave -label pipe -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/pipe }
add wave -label fml_dat_i -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml_dat_i }
add wave -label fml0_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml0_dat }
add wave -label fml1_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml1_dat }
add wave -label fml2_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml2_dat }
add wave -label fml3_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml3_dat }
add wave -label fml4_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml4_dat }
add wave -label fml5_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml5_dat }
add wave -label fml6_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml6_dat }
add wave -label fml7_dat -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/fml7_dat }

add wave -label attr_data_out -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/attr_data_out }
add wave -label char_addr_in -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/char_addr_in }

add wave -label load_shift -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/load_shift }
add wave -label vga_shift -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/text_mode/vga_shift }

add wave -divider "FML Linear Mode Registers"

add wave -label pipe -hex -unsigned {sim:/tb_vga_lcd_fml/dut/sequencer/linear/pipe }
add wave -label fml_dat_i -hex {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml_dat_i }
add wave -label fml1_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml1_dat }
add wave -label fml2_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml2_dat }
add wave -label fml3_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml3_dat }
add wave -label fml4_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml4_dat }
add wave -label fml5_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml5_dat }
add wave -label fml6_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml6_dat }
add wave -label fml7_dat -hex  {sim:/tb_vga_lcd_fml/dut/sequencer/linear/fml7_dat }

add wave -label color -hex {sim:/tb_vga_lcd_fml/dut/sequencer/linear/color }

run 500us