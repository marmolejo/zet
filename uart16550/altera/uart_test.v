`include "../verilog/uart_defines.v"

module uart_test(clk_, stxo_, led_);
  // Module IO ports
  input clk_;
  output stxo_;
  output reg [7:0] led_;

  // Net declarations
  wire clk, boot;
  reg   [4:0]   wb_adr_i;
  reg   [31:0]  wb_dat_i;
  wire  [31:0]  wb_dat_o;
  reg   [3:0]   wb_sel_i;
  wire  wb_ack_o;
  reg   wb_rst_i, wb_we_i, wb_stb_i, wb_cyc_i;

  // Module instantiations
  uart_top uart_snd(clk, 
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, 
    wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i, /* int_o */,
    stxo_,, 
    /* rts_o */, 1'b1, /* dtr_o */, 1'b1, 1'b1, 1'b1);
  altpll0 pll0(clk_, clk, boot);

  always @(posedge clk)
    if (~boot)
      begin 
        led_     <= 8'd1;
        wb_rst_i <= 1'b1;
        wb_adr_i <= 5'bxxxxx;
        wb_dat_i <= 32'hxxxx_xxxx;
        wb_cyc_i <= 1'b0;
        wb_stb_i <= 1'b0;
        wb_sel_i <= 4'hx;
        wb_we_i  <= 1'hx;
      end
    else
      case (led_)
        8'd01: begin wb_rst_i <= 1'b0; led_ <= 8'd02; end

        // wbm.wb_wr1(`UART_REG_LC, 4'b1000, {8'b10011011, 24'b0});
        8'd02: begin
                 wb_adr_i <= `UART_REG_LC;
                 wb_dat_i <= {8'b10011011, 24'b0};
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b1000;
                 led_ <= 8'd03;
               end
        8'd03: if (wb_ack_o)
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_ <= 8'd04;
                 end
        
        // set dl to divide by 3
        // wbm.wb_wr1(`UART_REG_DL1,4'b0001, 32'd2);
        8'd04: begin
                 wb_adr_i <= `UART_REG_DL1;
                 wb_dat_i <= 32'd3;
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b0001;
                 led_ <= 8'd05;
               end
        8'd05: if (wb_ack_o)
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_     <= 8'd06;
                 end

        // restore normal registers
        // wbm.wb_wr1(`UART_REG_LC, 4'b1000, {8'b00011011, 24'b0});
        8'd06: begin
                 wb_adr_i <= `UART_REG_LC;
                 wb_dat_i <= {8'b00011011, 24'b0};
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b1000;
                 led_     <= 8'd07;
               end
        8'd07: if (wb_ack_o) 
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_     <= 8'd08;
               end

        // wb_wr1(5'd0, 4'b1, 32'b10000001);
        8'd08: begin
                 wb_adr_i <= 5'd0;
                 wb_dat_i <= 32'h5a;
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b1;
                 led_     <= 8'd09;
               end
        8'd09: if (wb_ack_o)
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_     <= 8'd10;
                 end

        // wb_wr1(5'd0, 4'b1, 32'b01000010);
        8'd10: begin
                 wb_adr_i <= 5'd0;
                 wb_dat_i <= 32'h65;
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b1;
                 led_     <= 8'd11;
               end
        8'd11: if (wb_ack_o) 
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_     <= 8'd12;
                 end

        8'd12: begin
                 wb_adr_i <= 5'd0;
                 wb_dat_i <= 32'h75;
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b1;
                 led_     <= 8'd13;
               end
        8'd13: if (wb_ack_o) 
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_     <= 8'd14;
                 end
        8'd14: begin
                 wb_adr_i <= 5'd0;
                 wb_dat_i <= 32'h73;
                 wb_cyc_i <= 1'b1;
                 wb_stb_i <= 1'b1;
                 wb_we_i  <= 1'b1;
                 wb_sel_i <= 4'b1;
                 led_     <= 8'd15;
               end
        8'd15: if (wb_ack_o) 
                 begin
                   wb_cyc_i <= 1'b0;
                   wb_stb_i <= 1'b0;
                   wb_adr_i <= 5'bxxxxx;
                   wb_dat_i <= 32'hxxxx_xxxx;
                   wb_we_i  <= 1'hx;
                   wb_sel_i <= 4'hx;
                   led_     <= 8'd16;
                 end
      endcase

endmodule