// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc.
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altrea Development
//   Kits made by Terasic.  Other use of this code, including the selling
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL or Verilog source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use
//   or functionality of this code.
//
// --------------------------------------------------------------------
//
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------

//`define I2C_VIDEO

module speaker_i2c_av_config (  //      Host Side
                                                clk_i,
                                                rst_i,
                                                //      I2C Side
                                                i2c_sclk,
                                                i2c_sdat        );
//      Host Side
input           clk_i;
input           rst_i;
//      I2C Side
output          i2c_sclk;
inout           i2c_sdat;
//      Internal Registers/Wires
reg     [15:0]  mI2C_CLK_DIV;
reg     [23:0]  mI2C_DATA;
reg                     mI2C_CTRL_CLK;
reg                     mI2C_GO;
wire            mI2C_END;
wire            mI2C_ACK;
reg     [15:0]  LUT_DATA;
reg     [5:0]   LUT_INDEX;
reg     [3:0]   mSetup_ST;

//      Clock Setting
parameter       CLK_Freq        =       25000000;       //      25      MHz
parameter       I2C_Freq        =       20000;          //      20      KHz
//      LUT Data Number
`ifdef I2C_VIDEO
parameter       LUT_SIZE        =       50;
`else
parameter       LUT_SIZE        =       10;
`endif
//      Audio Data Index
parameter       SET_LIN_L       =       0;
parameter       SET_LIN_R       =       1;
parameter       SET_HEAD_L      =       2;
parameter       SET_HEAD_R      =       3;
parameter       A_PATH_CTRL     =       4;
parameter       D_PATH_CTRL     =       5;
parameter       POWER_ON        =       6;
parameter       SET_FORMAT      =       7;
parameter       SAMPLE_CTRL     =       8;
parameter       SET_ACTIVE      =       9;
`ifdef I2C_VIDEO
//      Video Data Index
parameter       SET_VIDEO       =       10;
`endif

/////////////////////   I2C Control Clock       ////////////////////////
always@(posedge clk_i)
begin
        if(rst_i)
        begin
                mI2C_CTRL_CLK   <=      0;
                mI2C_CLK_DIV    <=      0;
        end
        else
        begin
                if( mI2C_CLK_DIV        < (CLK_Freq/I2C_Freq) )
                mI2C_CLK_DIV    <=      mI2C_CLK_DIV+16'h1;
                else
                begin
                        mI2C_CLK_DIV    <=      0;
                        mI2C_CTRL_CLK   <=      ~mI2C_CTRL_CLK;
                end
        end
end
////////////////////////////////////////////////////////////////////
speaker_i2c_controller  i2c_controller (       .CLOCK(mI2C_CTRL_CLK),          //      Controller Work Clock
                                                .I2C_SCLK(i2c_sclk),            //      I2C CLOCK
                                                .I2C_SDAT(i2c_sdat),            //      I2C DATA
                                                .I2C_DATA(mI2C_DATA),           //      DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
                                                .GO(mI2C_GO),                           //      GO transfor
                                                .END(mI2C_END),                         //      END transfor 
                                                .ACK(mI2C_ACK),                         //      ACK
                                                .RESET(rst_i),
                                                .W_R (1'b0)
                                                );
////////////////////////////////////////////////////////////////////
//////////////////////  Config Control  ////////////////////////////
always@(posedge mI2C_CTRL_CLK)
begin
        if(rst_i)
        begin
                LUT_INDEX       <=      0;
                mSetup_ST       <=      0;
                mI2C_GO         <=      0;
        end
        else
        begin
                if(LUT_INDEX<LUT_SIZE)
                begin
                        case(mSetup_ST)
                        0:      begin
`ifdef I2C_VIDEO
                                        if(LUT_INDEX>=SET_VIDEO)
                                        mI2C_DATA       <=      {8'h40,LUT_DATA};
                                        else
`endif
                                        mI2C_DATA       <=      {8'h34,LUT_DATA};
                                        mI2C_GO         <=      1;
                                        mSetup_ST       <=      1;
                                end
                        1:      begin
                                        if(mI2C_END)
                                        begin
                                                if(!mI2C_ACK)
                                                mSetup_ST       <=      2;
                                                else
                                                mSetup_ST       <=      0;                                                      
                                                mI2C_GO         <=      0;
                                        end
                                end
                        2:      begin
                                        LUT_INDEX       <=      LUT_INDEX+6'h1;
                                        mSetup_ST       <=      0;
                                end
                        endcase
                end
        end
end
////////////////////////////////////////////////////////////////////
/////////////////////   Config Data LUT   //////////////////////////    
always
begin
        case(LUT_INDEX)
        //      Audio Config Data
        SET_LIN_L       :       LUT_DATA        <=      16'h001A;
        SET_LIN_R       :       LUT_DATA        <=      16'h021A;
        SET_HEAD_L      :       LUT_DATA        <=      16'h047B;
        SET_HEAD_R      :       LUT_DATA        <=      16'h067B;
        A_PATH_CTRL     :       LUT_DATA        <=      16'h08F8;
        D_PATH_CTRL     :       LUT_DATA        <=      16'h0A06;
        POWER_ON        :       LUT_DATA        <=      16'h0C00;
        SET_FORMAT      :       LUT_DATA        <=      16'h0E42;
        SAMPLE_CTRL     :       LUT_DATA        <=      16'h107C;
        SET_ACTIVE      :       LUT_DATA        <=      16'h1201;
`ifdef I2C_VIDEO
        //      Video Config Data
        SET_VIDEO+0     :       LUT_DATA        <=      16'h1500;
        SET_VIDEO+1     :       LUT_DATA        <=      16'h1741;
        SET_VIDEO+2     :       LUT_DATA        <=      16'h3a16;
        SET_VIDEO+3     :       LUT_DATA        <=      16'h5004;
        SET_VIDEO+4     :       LUT_DATA        <=      16'hc305;
        SET_VIDEO+5     :       LUT_DATA        <=      16'hc480;
        SET_VIDEO+6     :       LUT_DATA        <=      16'h0e80;
        SET_VIDEO+7     :       LUT_DATA        <=      16'h5020;
        SET_VIDEO+8     :       LUT_DATA        <=      16'h5218;
        SET_VIDEO+9     :       LUT_DATA        <=      16'h58ed;
        SET_VIDEO+10:   LUT_DATA        <=      16'h77c5;
        SET_VIDEO+11:   LUT_DATA        <=      16'h7c93;
        SET_VIDEO+12:   LUT_DATA        <=      16'h7d00;
        SET_VIDEO+13:   LUT_DATA        <=      16'hd048;
        SET_VIDEO+14:   LUT_DATA        <=      16'hd5a0;
        SET_VIDEO+15:   LUT_DATA        <=      16'hd7ea;
        SET_VIDEO+16:   LUT_DATA        <=      16'he43e;
        SET_VIDEO+17:   LUT_DATA        <=      16'hea0f;
        SET_VIDEO+18:   LUT_DATA        <=      16'h3112;
        SET_VIDEO+19:   LUT_DATA        <=      16'h3281;
        SET_VIDEO+20:   LUT_DATA        <=      16'h3384;
        SET_VIDEO+21:   LUT_DATA        <=      16'h37A0;
        SET_VIDEO+22:   LUT_DATA        <=      16'he580;
        SET_VIDEO+23:   LUT_DATA        <=      16'he603;
        SET_VIDEO+24:   LUT_DATA        <=      16'he785;
        SET_VIDEO+25:   LUT_DATA        <=      16'h5000;
        SET_VIDEO+26:   LUT_DATA        <=      16'h5100;
        SET_VIDEO+27:   LUT_DATA        <=      16'h0050;
        SET_VIDEO+28:   LUT_DATA        <=      16'h1000;
        SET_VIDEO+29:   LUT_DATA        <=      16'h0402;
        SET_VIDEO+30:   LUT_DATA        <=      16'h0b00;
        SET_VIDEO+31:   LUT_DATA        <=      16'h0a20;
        SET_VIDEO+32:   LUT_DATA        <=      16'h1100;
        SET_VIDEO+33:   LUT_DATA        <=      16'h2b00;
        SET_VIDEO+34:   LUT_DATA        <=      16'h2c8c;
        SET_VIDEO+35:   LUT_DATA        <=      16'h2df2;
        SET_VIDEO+36:   LUT_DATA        <=      16'h2eee;
        SET_VIDEO+37:   LUT_DATA        <=      16'h2ff4;
        SET_VIDEO+38:   LUT_DATA        <=      16'h30d2;
        SET_VIDEO+39:   LUT_DATA        <=      16'h0e05;
`endif
        default:        LUT_DATA        <=      16'h0000;
        endcase
end
////////////////////////////////////////////////////////////////////
endmodule