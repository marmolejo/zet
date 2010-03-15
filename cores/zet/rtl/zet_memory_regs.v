/*
 *  Decoder for x86 memory access registers
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

module zet_memory_regs (
    input [2:0] rm,
    input [1:0] mod,
    input [2:0] sovr_pr,

    output reg [3:0] base,
    output reg [3:0] index,
    output     [1:0] seg
  );

  // Register declaration
  reg [1:0] s;

  // Continuous assignments
  assign seg = sovr_pr[2] ? sovr_pr[1:0] : s;

  // Behaviour
  always @(rm or mod)
    case (rm)
      3'b000: begin base <= 4'b0011; index <= 4'b0110; s <= 2'b11; end
      3'b001: begin base <= 4'b0011; index <= 4'b0111; s <= 2'b11; end
      3'b010: begin base <= 4'b0101; index <= 4'b0110; s <= 2'b10; end
      3'b011: begin base <= 4'b0101; index <= 4'b0111; s <= 2'b10; end
      3'b100: begin base <= 4'b1100; index <= 4'b0110; s <= 2'b11; end
      3'b101: begin base <= 4'b1100; index <= 4'b0111; s <= 2'b11; end
      3'b110: begin base <= mod ? 4'b0101 : 4'b1100; index <= 4'b1100;
                    s <= mod ? 2'b10 : 2'b11; end
      3'b111: begin base <= 4'b0011; index <= 4'b1100; s <= 2'b11; end
    endcase
endmodule
