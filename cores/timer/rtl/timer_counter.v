/*
 *  Single channel counter of 8254 timer simplified for Zet SoC
 *  Copyright (c) 2010  YS <ys05@mail.ru>
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

/*
 *  This module uses:
 *   - Modes (binary) 2 and 3 only
 *  Assumptions:
 *   1. clkt is asynchronous simple wire (1.193182 MHz by default)
 *   2. gate is synchronous (comes from Wishbone controlled register)
 *   3. clkrw read/write clock (derived from Wishbone clock) is running
 *      always and it has much higher frequency than clkt
 */

module timer_counter(
  input [1:0] cntnum,       // Counter Number constant 0/1/2
  input [5:0] cw0,          // Initial Control Word constant
  input [15:0] cr0,         // Initial Constant Register constant
  input clkrw,              // Read/Write System Clock
  input rst,                // Reset
  input wrc,                // Write Command 1 clock pulse
  input wrd,                // Write Data 1 clock pulse
  input rdd,                // Read Data full cycle strobe
  input [7:0] data_i,       // Input Data
  output reg [7:0] data_o,  // Output Data
  input clkt,               // Timer Clock (asynchronous to clkrw)
  input gate,               // Timer Gate (synchronous to clkrw)
  output out                // Timer Out (synchronous to clkrw)
  );

  localparam
          DATL = 2'd0,
          DATH = 2'd1,
          STAT = 2'd2;

  reg [15:0] rCounter;      // Timer Counter
  reg [15:0] rConstant;     // Constant Register
  reg [5:0] rControl;       // Control Word Register
  reg [15:0] rLatchD;       // Output Data Latch
  reg [7:0] rLatchS;        // Output State Latch
  reg bOut;                     
  reg bFn;

  reg clcd, clcs;           // Latch Data and Latch State command pulses

  reg fWroteLow;
  reg fWroteHigh;

  reg fCount;
  reg bCurrentClk;
  reg bFilterClk1;
  reg bFilterClk2;

  reg fLatchData;
  reg fLatchStat;

  reg rdd1;
  reg [1:0] outmux;
  reg fToggleHigh;

  wire fReadEnd;

  wire [2:0] rbc_cnt_mask = data_i[3:1];

  wire fMode3 = (rControl[2:1] == 2'b11);

  wire fRWLow = rControl[4];
  wire fRWHigh = rControl[5];

  assign out = bOut;

  // Write to Control Word Register
  always @(posedge clkrw)
  begin
    if (rst)
    begin
      rControl <= cw0;
      clcd <= 1'b0;
      clcs <= 1'b0;
    end
    else
    begin
      if (wrc && data_i[7:6] == cntnum)
      begin
        if (data_i[5:4] == 2'b00) 
          clcd <= 1'b1;            // CLC
        else
          rControl <= data_i[5:0]; // WRC
      end
      else if (wrc && data_i[7:6] == 2'b11 && rbc_cnt_mask[cntnum])
      begin
        clcd <= ~data_i[5];        // RBC
        clcs <= ~data_i[4];
      end

      if (clcd)
        clcd <= 1'b0;  // 1 clock pulse clcd

      if (clcs)
        clcs <= 1'b0;  // 1 clock pulse clcs
    end
  end

  // Write to Constant Register
  always @(posedge clkrw)
  begin
    if (rst)
    begin
      rConstant <= cr0;
      fWroteLow <= 1'b0;
      fWroteHigh <= 1'b0;
    end
    else
    begin
      if (fWroteHigh || wrc)
      begin
        fWroteLow <= 1'b0;
        fWroteHigh <= 1'b0;
      end
      if (wrd) // need 1 clock pulse wrd!!!
      begin
        if (!fWroteLow)
        begin
          if (fRWLow)
            rConstant[7:0] <= data_i[7:0];
          fWroteLow <= 1'b1;
          if (!fRWHigh)
          begin
            rConstant[15:8] <= 8'b00000000;
            fWroteHigh <= 1'b1;
          end
        end
        if (!fWroteHigh && (fWroteLow || !fRWLow))
        begin
          if (fRWHigh)
            rConstant[15:8] <= data_i[7:0];
          fWroteHigh <= 1'b1;
          if (!fRWLow)
          begin
            rConstant[7:0] <= 8'b00000000;
            fWroteLow <= 1'b1;
          end
        end
      end // if (wrd)
    end
  end

  // Synchronizing Count Clock with Wishbone Clock
  always @(posedge clkrw)
  begin
    if (rst)
    begin
      fCount <= 1'b0;
      bCurrentClk <= 1'b0;
      bFilterClk1 <= 1'b0;
      bFilterClk2 <= 1'b0;
    end
    else
    begin
      bFilterClk1 <= clkt;
      bFilterClk2 <= bFilterClk1;
      if ((bFilterClk1 == bFilterClk2) && (bCurrentClk != bFilterClk2))
      begin
        bCurrentClk <= bFilterClk2;
        if (bCurrentClk == 1'b1) // falling edge of clkt
          fCount <= 1'b1;
      end
      if (fCount)
        fCount <= 1'b0; // 1 clock pulse fCount
    end
  end  

  // Timer Counter in mode 2 or mode 3
  always @(posedge clkrw)
  begin
    if (rst)
    begin
      bOut <= 1'b1;
      rCounter <= cr0 & ((cw0[2:1] == 2'b11) ? 16'hFFFE : 16'hFFFF); // (mode==3) ? :
      bFn <= 1'b0;
    end
    else
    begin
      if (fWroteHigh)
      begin
        rCounter <= rConstant & ((fMode3) ? 16'hFFFE : 16'hFFFF);
        bOut <= 1'b1;
      end
      else if (fCount && gate) // tclk_i && gate_i
      begin
        if ((fMode3) ? (bOut == 1'b0 && rCounter == 16'h0002) : (bOut == 1'b0))
        begin
          rCounter <= rConstant & ((fMode3) ? 16'hFFFE : 16'hFFFF);
          bOut <= 1'b1;
        end
        else if (fMode3 && bOut == 1'b1 && rCounter == ((rConstant[0]) ? 16'h0000 : 16'h0002))
        begin
          rCounter <= rConstant & 16'hFFFE;
          bOut <= 1'b0;
        end
        else if (!fMode3 && rCounter == 16'h0002)
          bOut <= 1'b0;
        else
          rCounter <= rCounter - ((fMode3) ? 16'h0002 : 16'h0001);
      end
    end
  end

  // Output Latch Control
  always @(posedge clkrw)
  begin
    if (rst)
    begin
      fLatchData <= 1'b0;
      fLatchStat <= 1'b0;
      rLatchD <= 16'b0;
      rLatchS <= 8'b0;
    end
    else
    begin
      if (!fLatchData)
        rLatchD <= rCounter;
      if (!fLatchStat)
        rLatchS <= {bOut, bFn, rControl};
      if (clcd)
        fLatchData <= 1'b1;
      if (clcs)
        fLatchStat <= 1'b1;
      if (fReadEnd)
      begin
        if (fLatchStat)
          fLatchStat <= 1'b0;
        else if (fLatchData)
          fLatchData <= 1'b0;
      end
    end
  end

  // Output Mux
  always @(outmux or rLatchS or rLatchD)
  begin
    case (outmux)
      STAT: data_o = rLatchS;
      DATH: data_o = rLatchD[15:8];
      DATL: data_o = rLatchD[7:0];
    endcase
  end

  assign fReadEnd = !rdd && rdd1; // 1 clock pulse after read

  // Read Data/State
  always @(posedge clkrw)
  begin
    if (rst)
    begin
      rdd1 <= 1'b0;
      outmux <= DATL;
      fToggleHigh <= 1'b0;
    end
    else
    begin
      // Helper for fReadEnd
      rdd1 <= rdd;

      // Output Mux Control
      if (fLatchStat)
        outmux <= STAT;
      else if ((fRWHigh && !fRWLow) || (fRWHigh && fToggleHigh))
        outmux <= DATH;
      else
        outmux <= DATL;

      if (wrc)
        fToggleHigh <= 1'b0;
      else if (fReadEnd && !fLatchStat)
        fToggleHigh <= !fToggleHigh;
    end
  end

endmodule
