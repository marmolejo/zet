/*
 *  Wishbone master interface module for Zet
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module zet_wb_master (
    // common signals
    input clk,
    input rst,

    // UMI slave interface - fetch
    input      [19:0] umif_adr_i,
    output reg [15:0] umif_dat_o,
    input             umif_stb_i,
    input             umif_by_i,
    output reg        umif_ack_o,

    // UMI slave interface - exec
    input      [19:0] umie_adr_i,
    output reg [15:0] umie_dat_o,
    input      [15:0] umie_dat_i,
    input             umie_we_i,
    input             umie_by_i,
    input             umie_stb_i,
    output reg        umie_ack_o,
    input             umie_tga_i,

    // Wishbone master interface
    input      [15:0] wb_dat_i,
    output reg [15:0] wb_dat_o,
    output reg [19:1] wb_adr_o,
    output reg        wb_we_o,
    output reg        wb_tga_o,
    output reg [ 1:0] wb_sel_o,
    output reg        wb_stb_o,
    output reg        wb_cyc_o,
    input             wb_ack_i
  );

  // Register and nets
  wire [15:0] blw;   // low byte (sign extended)
  wire [15:0] bhw;   // high byte (sign extended)

  reg  [ 2:0] cs;    // current state
  reg  [ 2:0] ns;    // next state

  // Declare the symbolic names for states
  localparam [2:0]
    IDLE = 3'd0,
    BY1E = 3'd1,
    BY2E = 3'd2,
    ACKE = 3'd3,
    BY1F = 3'd4,
    BY2F = 3'd5,
    ACKF = 3'd6;

  // Continuous assignments
  assign blw = { {8{wb_dat_i[ 7]}}, wb_dat_i[ 7:0] };
  assign bhw = { {8{wb_dat_i[15]}}, wb_dat_i[15:8] };

  // Behaviour
  always @(posedge clk) cs <= rst ? IDLE : ns;

  // umie_ack_o
  always @(posedge clk)
    umie_ack_o <= rst ? 1'b0
      : (((cs==BY1E && (umie_by_i || !umie_by_i && !umie_adr_i[0]))
      || cs==BY2E) & wb_ack_i);

  // umif_ack_o
  always @(posedge clk)
    umif_ack_o <= rst ? 1'b0
      : (((cs==BY1F && (umif_by_i || !umif_by_i && !umif_adr_i[0]))
      || cs==BY2F) & wb_ack_i);

  // wb_adr_o
  always @(posedge clk)
    if (rst)
      wb_adr_o <= 19'h0;
    else
      case (ns)
        BY1E: wb_adr_o <= umie_adr_i[19:1];
        BY2E: wb_adr_o <= umie_adr_i[19:1] + 19'd1;
        BY1F: wb_adr_o <= umif_adr_i[19:1];
        BY2F: wb_adr_o <= umif_adr_i[19:1] + 19'd1;
        default: wb_adr_o <= 19'h0;
      endcase

  // wb_we_o
  always @(posedge clk)
    wb_we_o <= rst ? 1'b0 : (ns==BY1E || ns==BY2E) & umie_we_i;

  // wb_tga_o
  always @(posedge clk)
    wb_tga_o <= rst ? 1'b0 : (ns==BY1E || ns==BY2E) & umie_tga_i;

  // wb_stb_o
  always @(posedge clk)
    wb_stb_o <= rst ? 1'b0 : (ns==BY1E || ns==BY2E || ns==BY1F || ns==BY2F);

  // wb_cyc_o
  always @(posedge clk)
    wb_cyc_o <= rst ? 1'b0 : (ns==BY1E || ns==BY2E || ns==BY1F || ns==BY2F);

  // wb_sel_o
  always @(posedge clk)
    if (rst)
      wb_sel_o <= 2'b00;
    else
      case (ns)
        BY1E: wb_sel_o <= umie_adr_i[0] ? 2'b10
                        : (umif_by_i ? 2'b01 : 2'b11);
        BY2E: wb_sel_o <= 2'b01;
        default: wb_sel_o <= 2'b11;
      endcase

  // wb_dat_o
  always @(posedge clk)
    wb_dat_o <= rst ? 16'h0
      : (ns==BY1E || ns==BY2E) ? 
        (umie_adr_i[0] ? 
          { umie_dat_i[7:0], umie_dat_i[15:8] } : umie_dat_i)
          : wb_dat_o;

  // umif_dat_o
  always @(posedge clk)
    umif_dat_o <= rst ? 16'h0
      : (cs==BY1F && wb_ack_i) ? (umif_adr_i[0] ? bhw
         : (umif_by_i ? blw : wb_dat_i))
      : (cs==BY2F && wb_ack_i) ? {wb_dat_i[7:0], umif_dat_o[7:0]}
      : umif_dat_o;

  // umie_dat_o
  always @(posedge clk)
    umie_dat_o <= rst ? 16'h0
      : (cs==BY1E && wb_ack_i) ? (umie_adr_i[0] ? bhw
         : (umie_by_i ? blw : wb_dat_i))
      : (cs==BY2E && wb_ack_i) ? {wb_dat_i[7:0], umie_dat_o[7:0]}
      : umie_dat_o;

  // State machine
  always @(*)
    case (cs)
      default:  // IDLE
        if (umie_stb_i) ns = BY1E;
        else if (umif_stb_i) ns = BY1F;
        else ns = IDLE;
      BY1E:     // First byte or word of exec
        if (wb_ack_i)
          begin
            if (umie_adr_i[0] && !umie_by_i) ns = BY2E;
            else
              begin
                if (umif_stb_i && !umif_ack_o) ns = BY1F;
                else ns = ACKE;
              end
          end
        else ns = BY1E;
      BY2E:     // Second byte of exec
        if (wb_ack_i)
          if (umif_stb_i) ns = BY1F;
          else ns = ACKE;
        else ns = BY2E;
      ACKE:     // Ack to exec
        if (umif_stb_i) ns = BY1F;
        else ns = IDLE;
      BY1F:     // First byte or word of fetch
        if (wb_ack_i)
          begin 
            if (umif_adr_i[0] && !umif_by_i) ns = BY2F;
            else
              begin
                if (umie_stb_i && !umie_ack_o) ns = BY1E;
                else ns = ACKF;
              end
          end
        else ns = BY1F;
      BY2F:    // Second byte of fetch
        if (wb_ack_i)
          if (umie_stb_i) ns = BY1E;
          else ns = ACKF;
        else ns = BY2F;
      ACKF:    // Ack to fetch
        if (umie_stb_i) ns = BY1E;
        else ns = IDLE;
    endcase

endmodule
