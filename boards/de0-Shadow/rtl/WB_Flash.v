// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module:      WB_Flash.v
// Description: Wishbone Flash RAM core.
// --------------------------------------------------------------------
// --------------------------------------------------------------------
module WB_Flash(
    input            	wb_clk_i,		// Wishbone slave interface
    input            	wb_rst_i,
    input  		[15:0] 	wb_dat_i,
    output 		[15:0] 	wb_dat_o,
    input            	wb_we_i,
    input       [ 1:0]	wb_adr_i,		// Wishbone address lines
    input      	[ 1:0] 	wb_sel_i,
    input            	wb_stb_i,
    input            	wb_cyc_i,
    output reg       	wb_ack_o,

    output     [21:0] flash_addr_,		// Pad signals
    input      [15:0] flash_data_,
    output            flash_we_n_,
    output            flash_oe_n_,
    output            flash_ce_n_,
    output            flash_rst_n_ 
  );

  assign flash_rst_n_ = 1'b1;
  assign flash_we_n_  = 1'b1;
  assign flash_oe_n_  = !op;
  assign flash_ce_n_  = !op;
  assign flash_addr_  = address;
  assign wb_dat_o     = flash_data_;
  wire   op           = wb_stb_i & wb_cyc_i;
  wire 	 wr_command   = op       & wb_we_i;     	// Wishbone write access Singal
 
  always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
    if(wb_rst_i) wb_ack_o <= 1'b0;
    else         wb_ack_o <= op & ~wb_ack_o; // one clock delay on acknowledge output
  end

 // --------------------------------------------------------------------
 // Register addresses and defaults
 // --------------------------------------------------------------------
 `define FLASH_ALO   2'h1    // Write only - Lower 16 bits of address lines
 `define FLASH_AHI   2'h2    // Write only - Upper  6 bits of address lines
  reg  [21:0] address;
  always @(posedge wb_clk_i or posedge wb_rst_i) begin		// Synchrounous
	if(wb_rst_i) begin
        address <= 22'h000000;      // Interupt Enable default
    end
    else if(wr_command) begin                   // If a write was requested
        case(wb_adr_i)                          // Determine which register was writen to
            `FLASH_ALO: address[15: 0] <= wb_dat_i;
            `FLASH_AHI: address[21:16] <= wb_dat_i[5:0];    
            default:    ;      	                		// Default
        endcase                                 		// End of case
    end
end  // Synchrounous always

// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------
// End of WB Module
// --------------------------------------------------------------------

