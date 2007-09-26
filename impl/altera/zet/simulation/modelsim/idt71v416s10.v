/****************************************************************************
 *   Copyright 1991,1992,1993,1998,1999 Integrated Device Technology Corp.
 *   All right reserved.
 *
 *   This program is proprietary and confidential information of
 *   IDT Corp. and may be used and disclosed only as authorized 
 *   in a license agreement controlling such use and disclosure.
 *
 *   IDT reserves the right to make any changes to
 *   the product herein to improve function or design.
 *   IDT does not assume any liability arising out of
 *   the application or use of the product herein.
 *
 *   WARNING: The unlicensed shipping, mailing, or carring of this
 *   technical data outside the United States, or the unlicensed
 *   disclosure, by whatever means, through visits abroad, or the
 *   unlicensed disclosure to foreign national in the United States,
 *   may violate the United States criminal law.
 *
 *   File Name                 : idt71v416s10.v
 *   Function                  : 256Kx16-bit Asynchronous Static RAM
 *   Simulation Tool/Version   : Verilog-XL 2.5
 *
 ***************************************************************************/

/*******************************************************************************
 * Module Name: idt71v416s10
 * Description: 256Kx16 10ns Asynchronous Static RAM
 * Revision                  : rev00
 * Date                      : 06/08/99
 * Notes                     : This model is believed to be functionally
 *                             accurate.  Please direct any inquiries to
 *                             IDT SRAM Applications at: sramhelp@idt.com
 *
 *******************************************************************************/
`timescale 1ns/10ps

module idt71v416s10(data, addr, we_, oe_, cs_, ble_, bhe_);
inout [15:0] data;
input [17:0] addr;
input we_, oe_, cs_, bhe_, ble_;

//Read Cycle Parameters
parameter Taa  = 10; // address access time
parameter Tacs = 10; // cs_     access time
parameter Tclz =  4; // cs_ to output low Z time
parameter Tchz =  5; // cs_ to output high Z time
parameter Toe  =  5; // oe_ to output  time
parameter Tohz =  5; // oe_ to output Z time
parameter Toh  =  4; // data hold from adr change time
parameter Tbe  =  5; // we_ to output valid time        

//Write Cycle Parameters
parameter Taw  =  8; // adr valid to end of write time
parameter Tcw  =  8; // cs_ to end of write time
parameter Tbw  =  8; // ble_/bhe_ to end of write time
parameter Tas  =  0; // address set up time
parameter Twp  =  8; // write pulse width min
parameter Tdw  =  5; // data valid to end of writ time
parameter Tow  =  3; // data act from end of writ time
parameter Twhz =  6; // we_ to output in high Z time


reg [7:0] mem1[0:262143];
reg [7:0] mem2[0:262143];

time adr_chng,da_chng,we_fall,we_rise,cs_fall,cs_rise;
time oe_fall,oe_rise,ble_fall,ble_rise,bhe_fall,bhe_rise;

wire [15:0] data_in;
reg  [15:0] data_out;
reg  [15:0] temp1,temp2,temp3;
reg outen, out_en, in_en;


initial
  begin
       in_en = 1'b1;
    if (cs_)
       out_en = 1'b0;
  end

// input/output control logic
//---------------------------
assign data   = out_en ? data_out : 'hzzzz;
assign data_in = in_en ? data : 'hzzzz;

// read access
//------------
always @(addr)
      if (cs_==0 & we_==1) begin           //read
       fork
        if(~ble_)
         #Taa data_out[7:0] = mem1[addr];
        else #Taa data_out[7:0] = 'hzz;
        if(~bhe_)
         #Taa data_out[15:8] = mem2[addr];
        else #Taa data_out[15:8] = 'hzz;
       join
      end
always @(addr)
  begin
     adr_chng = $time;

              outen  = 1'b0;
         #Toh out_en = outen;

//---------------------------------------------
      if (cs_==0 & we_==1)                 //read
        begin
           if (oe_==0)
             begin
              outen = 1'b1;
              out_en = 1'b1;
             end
        end
//---------------------------------------------
     if (cs_==0 & we_==0)                 //write
       begin
         if (oe_==0)
           begin
                outen = 1'b0;
                out_en = 1'b0;
                temp1 = data_in;
                 fork
                  if(~ble_) 
                    #Tdw mem1[addr] = temp1[7:0];
                  if(~bhe_)
                    #Tdw mem2[addr] = temp1[15:8];
                 join
           end
         else
           begin
                outen = 1'b0;
                out_en = 1'b0;
                temp1 = data_in;
                 fork
                  if(~ble_) 
                    #(Tdw-Toh) mem1[addr] = temp1[7:0];
                  if(~bhe_)
                    #(Tdw-Toh) mem2[addr] = temp1[15:8];
                 join
           end

         if(~ble_)
           data_out[7:0] = mem1[addr];
         else data_out[7:0] = 'hzz;
         if(~bhe_)
           data_out[15:8] = mem2[addr];
         else data_out[15:8] = 'hzz;
       end
  end

always @(negedge cs_)
  begin
     cs_fall = $time;

     if (cs_fall - adr_chng < Tas)
         $display($time, "  Adr setup time is not enough Tas");

      if (we_==1 & oe_==0)
               outen  = 1'b1;
         #Tclz out_en = outen;

      if (we_==1) begin
        fork
         if(~ble_)
           #(Tacs-Tclz) data_out[7:0] = mem1[addr];
         else #(Tacs-Tclz) data_out[7:0] = 'hzz;
         if(~bhe_)
           #(Tacs-Tclz) data_out[15:8] = mem2[addr];
         else #(Tacs-Tclz) data_out[15:8] = 'hzz;
        join
      end

      if (we_==0)
       begin
               outen = 1'b0;
               out_en = 1'b0;
               temp2 = data_in;
              fork
               if(~ble_) 
                 #Tdw mem1[addr] = temp2[7:0];
               if(~bhe_) 
                 #Tdw mem2[addr] = temp2[15:8];
              join
       end
  end

always @(posedge cs_)
  begin
     cs_rise = $time;

   if (we_==0)
    begin
     if (cs_rise - adr_chng < Taw)
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  Adr valid to end of write is not enough Taw");
       end

     if (cs_rise - cs_fall < Tcw)
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  cs_ to end of write is not enough Tcw");
       end

     if (cs_rise - da_chng < Tdw)
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  Data setup is not enough_1");
       end
    end

               outen  = 1'b0;
         #Tchz out_en = outen;
 
  end

always @(negedge oe_)
  begin
     oe_fall = $time;
      
       if(~ble_)
         data_out[7:0] = mem1[addr];
       else data_out[7:0] = 'hzz;
       if(~bhe_)
         data_out[15:8] = mem2[addr];
       else data_out[15:8] = 'hzz;

      if (we_==1 & cs_==0)
              outen  = 1'b1;
         #Toe out_en = outen;
  end

always @(posedge oe_)
  begin
     oe_rise = $time;

               outen  = 1'b0;
         #Tohz out_en = outen;
  end

// write to ram
//-------------
always @(negedge we_)
  begin
     we_fall = $time;

     if (we_fall - adr_chng < Tas)
         $display($time, "  Address set-up to WE low is not enough");

     if (cs_==0 & oe_==0)
       begin
               outen  = 1'b0;
         #Twhz out_en = outen;
                  temp3 = data_in;
        fork
         if(~ble_) 
           #Tdw mem1[addr] = temp3[7:0];
         if(~bhe_) 
           #Tdw mem2[addr] = temp3[15:8];
        join

         if(~ble_)
              data_out[7:0] = mem1[addr];
         else data_out[7:0] = 'hzz;
         if(~bhe_)
              data_out[15:8] = mem2[addr];
         else data_out[15:8] = 'hzz;
       end

     if (cs_==0 & oe_==1)
       begin
               outen = 1'b0;
               out_en = 1'b0;
                  temp3 = data_in;
        fork
         if(~ble_) 
           #Tdw mem1[addr] = temp3[7:0];
         if(~bhe_) 
           #Tdw mem2[addr] = temp3[15:8];
        join

         if(~ble_)
              data_out[7:0] = mem1[addr];
         else data_out[7:0] = 'hzz;
         if(~bhe_)
              data_out[15:8] = mem2[addr];
         else data_out[15:8] = 'hzz;
       end
  end

always @(posedge we_)
  begin
     we_rise = $time;

   if (cs_==0)
    begin
     if (we_rise - da_chng < Tdw)
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  Data setup is not enough_2");
       end
     if (we_rise - adr_chng < Taw)
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  Addr setup is not enough");
       end
    end
   if (cs_==0 & oe_==0)
    begin
     if (we_rise - we_fall < (Twhz+Tdw) )
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  WE pulse width needs to be Twhz+Tdw");
       end

               outen  = 1'b1;
         #Tow  out_en = outen;
    end
   if (cs_==0 & oe_==1)
    begin
     if (we_rise - we_fall < Twp)
       begin
         if(~ble_) 
           mem1[addr] = 8'hxx;
         if(~bhe_) 
           mem2[addr] = 8'hxx;
         $display($time, "  WE pulse width needs to be Twp");
       end
    end
  end

always @(negedge ble_)
  begin
     ble_fall = $time;

     if (ble_fall - adr_chng < Tas)
         $display($time, "  Address set-up to BLE low is not enough");

     if (we_==0 & cs_==0)
       begin
               outen  = 1'b0;
               out_en = outen;
               temp3 = data_in;

         #Tdw mem1[addr] = temp3[7:0];

         if(~ble_)
              data_out[7:0] = mem1[addr];
         else data_out[7:0] = 'hzz;
         if(~bhe_)
              data_out[15:8] = mem2[addr];
         else data_out[15:8] = 'hzz;
       end
  end

always @(negedge bhe_)
  begin
     bhe_fall = $time;

     if (bhe_fall - adr_chng < Tas)
         $display($time, "  Address set-up to BHE low is not enough");

     if (we_==0 & cs_==0)
       begin
               outen  = 1'b0;
               out_en = outen;
               temp3 = data_in;

         #Tdw mem2[addr] = temp3[15:8];

         if(~ble_)
              data_out[7:0] = mem1[addr];
         else data_out[7:0] = 'hzz;
         if(~bhe_)
              data_out[15:8] = mem2[addr];
         else data_out[15:8] = 'hzz;
       end
  end

always @(posedge ble_)
  begin
     ble_rise = $time;

   if (we_==0 & cs_==0)
    begin

     if (ble_rise - ble_fall < Tbw)
       begin
           mem1[addr] = 8'hxx;
         $display($time, "  ble_ to end of write is not enough Tbw");
       end

    end
  end

always @(posedge bhe_)
  begin
     bhe_rise = $time;

   if (we_==0 & cs_==0)
    begin

     if (bhe_rise - bhe_fall < Tbw)
       begin
           mem2[addr] = 8'hxx;
         $display($time, "  bhe_ to end of write is not enough Tbw");
       end

    end
  end

always @ (data)
  begin
     da_chng = $time;

     if (we_==0 & cs_==0)
       begin
        fork
         if(~ble_) 
           #Tdw mem1[addr] = data_in[7:0];
         if(~bhe_) 
           #Tdw mem2[addr] = data_in[15:8];
        join

         if(~ble_)
              data_out[7:0] = mem1[addr];
         else data_out[7:0] = 'hzz;
         if(~bhe_)
              data_out[15:8] = mem2[addr];
         else data_out[15:8] = 'hzz;
       end
  end

endmodule
