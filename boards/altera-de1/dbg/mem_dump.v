module mem_dump (
    input       clk,
    input       rst,
    input [9:0] sw_,

    // Wishbone master interface for the VDU
    output reg [15:0] vdu_dat_o,
    output reg [11:1] vdu_adr_o,
    output            vdu_we_o,
    output            vdu_stb_o,
    output     [ 1:0] vdu_sel_o,
    output            vdu_tga_o,
    input             vdu_ack_i,

    // Master CSR interface for the SRAM
    output [17:1] csr_adr_o,
    output [ 1:0] csr_sel_o,
    output        csr_we_o,
    input  [15:0] csr_dat_i
  );

  // Registers and nets
  reg [ 5:0] st;
  reg [ 2:0] sp;
  reg [ 3:0] nibb;
  reg [15:0] col;
  reg        op;
  reg [ 7:0] low_adr;
  wire       spg;

  // Continuous assignments
  assign vdu_we_o  = op;
  assign vdu_stb_o = op;
  assign vdu_sel_o = 2'b11;
  assign vdu_tga_o = 1'b0;
  assign csr_we_o  = 1'b0;
  assign csr_sel_o = 2'b11;
  assign spg       = sp>3'b0;
  assign csr_adr_o = { sw_[9:1], low_adr[7:0] };

  // Behaviour
  always @(posedge clk)
    if (rst)
      begin
        sp   <= 2'h3;
        nibb <= 4'h0;
        col  <= 16'd80;
        st   <= 6'h5;
        op   <= 1'b0;
      end
    else
      case (st)
        6'd5: // memory dump
              if (!vdu_ack_i) begin
                vdu_dat_o <= { 8'h05, spg ? 8'h20 : itoa(nibb) };
                vdu_adr_o <= col;
                st <= 6'h6;
                op <= 1'b1;
                sp <= spg ? (sp - 3'b1) : 3'd4;
                col <= col + 16'd1;
                nibb <= spg ? nibb : (nibb + 4'h2);
              end
        6'd6: if (vdu_ack_i) begin
                st <= (col==16'd160) ? 6'h7 : 6'h5;
                op <= 1'b0;
              end
        6'd7: begin
                low_adr <= 8'h0;
                st <= 6'h8;
              end
        6'd8: if (!vdu_ack_i) begin
                vdu_dat_o <= { 8'h5, itoa(csr_adr_o[7:4]) };
                vdu_adr_o <= col;
                st <= 6'd9;
                op <= 1'b1;
              end
        6'd9: if (vdu_ack_i) begin
                st <= 6'd10;
                op <= 1'b0;
                col <= col + 16'd1;
              end
        6'd10: st <= 6'd11;
        6'd11: st <= 6'd12;
        6'd12: if (!vdu_ack_i) begin
                vdu_dat_o <= { 8'h7, itoa(csr_dat_i[15:12]) };
                vdu_adr_o <= col;
                st <= 6'd13;
                op <= 1'b1;
              end
        6'd13: if (vdu_ack_i) begin
                st <= 6'd14;
                op <= 1'b0;
                col <= col + 16'd1;
              end
        6'd14: if (!vdu_ack_i) begin
                vdu_dat_o <= { 8'h7, itoa(csr_dat_i[11:8]) };
                vdu_adr_o <= col;
                st <= 6'd15;
                op <= 1'b1;
              end
        6'd15: if (vdu_ack_i) begin
                st <= 6'd16;
                op <= 1'b0;
                col <= col + 16'd1;
              end
        6'd16: if (!vdu_ack_i) begin
                vdu_dat_o <= { 8'h7, itoa(csr_dat_i[7:4]) };
                vdu_adr_o <= col;
                st <= 6'd17;
                op <= 1'b1;
              end
        6'd17: if (vdu_ack_i) begin
                st <= 6'd18;
                op <= 1'b0;
                col <= col + 16'd1;
              end
        6'd18: if (!vdu_ack_i) begin
                vdu_dat_o <= { 8'h7, itoa(csr_dat_i[3:0]) };
                vdu_adr_o <= col;
                st <= 6'd19;
                op <= 1'b1;
              end
        6'd19: if (vdu_ack_i) begin
                st <= (csr_adr_o[4:1]==4'hf) ? 6'd22 : 6'd20;
                op <= 1'b0;
                col <= col + 16'd1;
                low_adr <= low_adr + 8'h1;
              end
        6'd20: if (!vdu_ack_i) begin
                vdu_dat_o <= 16'h0720;
                vdu_adr_o <= col;
                st <= 6'd21;
                op <= 1'b1;
              end
        6'd21: if (vdu_ack_i) begin
                st <= 6'd10;
                op <= 1'b0;
                col <= col + 16'd1;
              end
        6'd22: st <= (low_adr==8'h0) ? 6'd23 : 6'd8;
        6'd23: begin
        sp   <= 2'h3;
        nibb <= 4'h0;
        col  <= 16'd80;
        st   <= 6'h5;
        op   <= 1'b0;
               end
        default: st <= 6'h23;
      endcase

  function [7:0] itoa;
    input [3:0] i;
    begin
      if (i < 8'd10) itoa = i + 8'h30;
      else itoa = i + 8'h57;
    end
  endfunction
endmodule
