/*
 *  Fetch FSM helper for next state
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

module zet_next_or_not (
    input [1:0] prefix,
    input [7:1] opcode,
    input cx_zero,
    input zf,
    input ext_int,
    output next_in_opco,
    output next_in_exec
  );

  // Net declarations
  wire exit_z, cmp_sca, exit_rep, valid_ops;

  // Assignments
  assign cmp_sca = opcode[2] & opcode[1];
  assign exit_z = prefix[0] ? /* repz */ (cmp_sca ? ~zf : 1'b0 )
                            : /* repnz */ (cmp_sca ? zf : 1'b0 );
  assign exit_rep = cx_zero | exit_z;
  assign valid_ops = (opcode[7:1]==7'b1010_010   // movs
                   || opcode[7:1]==7'b1010_011   // cmps
                   || opcode[7:1]==7'b1010_101   // stos
                   || opcode[7:1]==7'b1010_110   // lods
                   || opcode[7:1]==7'b1010_111); // scas
  assign next_in_exec = prefix[1] && valid_ops && !exit_rep && !ext_int;
  assign next_in_opco = prefix[1] && valid_ops && cx_zero;
endmodule
