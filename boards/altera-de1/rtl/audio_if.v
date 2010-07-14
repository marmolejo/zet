/*
 *  DE1/DE2 Audio Interface (WM8731 audio chip):
 *   - aud_xck should be generated and sent to audio chip externally
 *   - Setup in I2C_AV_Config.v:
 *     SET_FORMAT:  16'h0E42 (Slave / I2S / 16 bit)
 *     -  aud_xck        = 11.2896 MHz
 *        MCLK = aud_xck = 11.2896 MHz
 *     SAMPLE_CTRL: 16'h1020 (fs=44.1kHz / MCLK=256fs)
 *     -  aud_xck        = 5.6448 MHz
 *        MCLK = aud_xck = 5.6448 MHz
 *     SAMPLE_CTRL: 16'h103C (fs=44.1kHz / MCLK=128fs)
 *     -  aud_xck          = 11.2896 MHz
 *        MCLK = aud_xck/2 =  5.6448 MHz
 *     SAMPLE_CTRL: 16'h107C (fs=44.1kHz / MCLK=128fs)
 *   - clk_i should be much faster than aud_bclk_i
 *   - suppose in slave mode aud_daclrck_i == aud_adclrck_i, otherwise
 *     aud_adclrck_i may need separate processing and ready_o should 
 *     be splitted into readydac_o and readyadc_o
 *   - ADC part is not tested
 *
 *  Copyright (c) 2010  YS
 *  Copyright (c) 2009  Zeus Gomez Marmolejo <zeus@opencores.org>
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

module audio_if 
  (
    // Main system interface
    input                     clk_i, 
    input                     rst_i, 
    input      signed [15:0]  datal_i,
    input      signed [15:0]  datar_i,
    output reg signed [15:0]  datal_o,
    output reg signed [15:0]  datar_o,

    output reg                ready_o,
//    output reg                readydac_o, // not used
//    output reg                readyadc_o, // not used

    // Audio interface
    input                     aud_bclk_i,
    input                     aud_daclrck_i,
    output reg                aud_dacdat_o,
    input                     aud_adclrck_i, // not used
    input                     aud_adcdat_i
  );

  reg fBCLK_HL;
//  reg fBCLK_LH;
  reg bCurrentClk;
  reg bFilterClk1;
  reg bFilterClk2;

  reg bDACLRCK_old;
  reg bDACLRCK;

  reg [15:0] rDAC;
  reg [15:0] rADC;

  reg fADCReady;

  // Synchronizing BCLK with clk_i
  always @(posedge clk_i or posedge rst_i)
  begin
    if (rst_i)
    begin
      fBCLK_HL <= 1'b0;
//      fBCLK_LH <= 1'b0;
      bCurrentClk <= 1'b0;
      bFilterClk1 <= 1'b0;
      bFilterClk2 <= 1'b0;
    end
    else
    begin
      bFilterClk1 <= aud_bclk_i;
      bFilterClk2 <= bFilterClk1;
      if ((bFilterClk1 == bFilterClk2) && (bCurrentClk != bFilterClk2))
      begin
        bCurrentClk <= bFilterClk2;
        if (bCurrentClk == 1'b1)
          fBCLK_HL <= 1'b1;  // falling edge of aud_bclk_i
//        else
//          fBCLK_LH <= 1'b1;  // rising edge of aud_bclk_i
      end
      if (fBCLK_HL)
        fBCLK_HL <= 1'b0; // 1 clock pulse fBCLK_HL
//      if (fBCLK_LH)
//        fBCLK_LH <= 1'b0; // 1 clock pulse fBCLK_LH
    end
  end  

  // Filtering aud_daclrck_i
  always @(posedge clk_i)
    bDACLRCK <= aud_daclrck_i;

  // Processsing BCLK
  always @(posedge clk_i)
  begin
    if (fBCLK_HL)
    begin
      bDACLRCK_old <= bDACLRCK;
      if (bDACLRCK != bDACLRCK_old)
      begin
        // DAC write
        rDAC <= (bDACLRCK) ? datar_i : datal_i;
        aud_dacdat_o <= 1'b0;
        // ADC read
        if (bDACLRCK)
          datal_o <= rADC;
        else
          datar_o <= rADC;
        rADC <= 16'h0001;
        fADCReady <= 1'b0;
        // ready pulse
        ready_o <= ~bDACLRCK;
      end
      else
      begin
        //DAC shift
        { aud_dacdat_o, rDAC } <= { rDAC, 1'b0 };
        // ADC shift
        if (!fADCReady)
          { fADCReady, rADC} <= { rADC, aud_adcdat_i };
      end
    end
    else if (ready_o)
      ready_o <= 1'b0; // 1 clock ready_o pulse
  end

endmodule