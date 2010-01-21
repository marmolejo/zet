/*
 * Wishbone to FML 8x16 bridge
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 * adapted to FML 8x16 by Zeus Gomez Marmolejo <zeus@aluzina.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module fmlbrg #(
    parameter fml_depth      = 23,
    parameter cache_depth    = 9   // 512 byte cache
  )
  (
    input sys_clk,
    input sys_rst,

    input  [fml_depth-1:1] wb_adr_i,
    input           [15:0] wb_dat_i,
    output          [15:0] wb_dat_o,
    input           [ 1:0] wb_sel_i,
    input                  wb_cyc_i,
    input                  wb_stb_i,
    input                  wb_tga_i,
    input                  wb_we_i,
    output reg             wb_ack_o,

    output reg [fml_depth-1:0] fml_adr,
    output reg                 fml_stb,
    output reg                 fml_we,
    input                      fml_ack,
    output              [ 1:0] fml_sel,
    output              [15:0] fml_do,
    input               [15:0] fml_di
  );

/*
 * Line length is the burst length, that is 8*16 bits, or 16 bytes
 * Address split up :
 *
 * |             TAG            |         INDEX          |   OFFSET   |
 * |fml_depth-1      cache_depth|cache_depth-1          4|3          0|
 *
 */

wire [3:1] offset = wb_adr_i[3:1];
wire [cache_depth-1-4:0] index = wb_adr_i[cache_depth-1:4];
wire [fml_depth-cache_depth-1:0] tag = wb_adr_i[fml_depth-1:cache_depth];

/*
 * TAG MEMORY
 *
 * Addressed by index (length cache_depth-5)
 * Contains valid bit + dirty bit + tag
 */

wire [cache_depth-1-4:0] tagmem_a;
reg tagmem_we;
wire [fml_depth-cache_depth-1+2:0] tagmem_di;
reg [fml_depth-cache_depth-1+2:0] tagmem_do;

reg [fml_depth-cache_depth-1+2:0] tags[0:(1 << (cache_depth-4))-1];

always @(posedge sys_clk) begin
  if(tagmem_we) begin
    tags[tagmem_a] <= tagmem_di;
    tagmem_do <= tagmem_di;
  end else
    tagmem_do <= tags[tagmem_a];
end

// synthesis translate_off
integer i;
initial begin
  for(i=0;i<(1 << (cache_depth-4));i=i+1)
    tags[i] = 0;
end
// synthesis translate_on

reg index_load;
reg [cache_depth-1-4:0] index_r;
always @(posedge sys_clk) begin
  if(index_load)
    index_r <= index;
end

assign tagmem_a = index;

reg di_valid;
reg di_dirty;
assign tagmem_di = {di_valid, di_dirty, tag};

wire do_valid;
wire do_dirty;
wire [fml_depth-cache_depth-1:0] do_tag;
wire cache_hit;

assign do_valid = tagmem_do[fml_depth-cache_depth-1+2];
assign do_dirty = tagmem_do[fml_depth-cache_depth-1+1];
assign do_tag = tagmem_do[fml_depth-cache_depth-1:0];

always @(posedge sys_clk)
  fml_adr <= {do_tag, index, offset, 1'b0};

/*
 * DATA MEMORY
 *
 * Addressed by index+offset in 16-bit words (length cache_depth-1)
 * 16-bit memory with 8-bit write granularity
 */

wire [cache_depth-1-1:0] datamem_a;
wire [ 1:0] datamem_we;
reg  [15:0] datamem_di;
wire [15:0] datamem_do;

fmlbrg_datamem #(
  .depth(cache_depth-1)
) datamem (
  .sys_clk(sys_clk),
  
  .a(datamem_a),
  .we(datamem_we),
  .di(datamem_di),
  .do(datamem_do)
);

reg [2:0] bcounter;
reg [2:0] bcounter_next;
always @(posedge sys_clk) begin
  if(sys_rst)
    bcounter <= 3'd0;
  else begin
    bcounter <= bcounter_next;
  end
end

reg bcounter_load;
reg bcounter_en;
always @(*) begin
  if(bcounter_load)
    bcounter_next <= offset;
  else if(bcounter_en)
    bcounter_next <= bcounter + 3'd1;
  else
    bcounter_next <= bcounter;
end

assign datamem_a = { index_load ? index : index_r, bcounter_next };

reg datamem_we_wb;
reg datamem_we_fml;

assign datamem_we = ({2{datamem_we_fml}} & 2'b11)
  |({2{datamem_we_wb}} & wb_sel_i);

always @(*) begin
  datamem_di = fml_di;
  if(datamem_we_wb) begin
    if(wb_sel_i[0])
      datamem_di[7:0] = wb_dat_i[7:0];
    if(wb_sel_i[1])
      datamem_di[15:8] = wb_dat_i[15:8];
  end
end

assign wb_dat_o = datamem_do;
assign fml_do = datamem_do;
assign fml_sel = 2'b11;

/* FSM */

reg [fml_depth-cache_depth-1:0] tag_r;
always @(posedge sys_clk)
  tag_r = tag;
assign cache_hit = do_valid & (do_tag == tag_r);

reg [4:0] state;
reg [4:0] next_state;

parameter IDLE      = 5'd0;
parameter TEST_HIT  = 5'd1;
parameter WRITE_HIT = 5'd2;

parameter EVICT  = 5'd3;
parameter EVICT2 = 5'd4;
parameter EVICT3 = 5'd5;
parameter EVICT4 = 5'd6;
parameter EVICT5 = 5'd7;
parameter EVICT6 = 5'd8;
parameter EVICT7 = 5'd9;
parameter EVICT8 = 5'd10;

parameter REFILL      = 5'd11;
parameter REFILL_WAIT = 5'd12;
parameter REFILL1     = 5'd13;
parameter REFILL2     = 5'd14;
parameter REFILL3     = 5'd15;
parameter REFILL4     = 5'd16;
parameter REFILL5     = 5'd17;
parameter REFILL6     = 5'd18;
parameter REFILL7     = 5'd19;
parameter REFILL8     = 5'd20;

parameter TEST_INVALIDATE = 5'd21;
parameter INVALIDATE      = 5'd22;

always @(posedge sys_clk) begin
  if(sys_rst)
    state = IDLE;
  else begin
    //$display("state: %d -> %d", state, next_state);
    state = next_state;
  end
end

always @(*) begin
  tagmem_we = 1'b0;
  di_valid = 1'b0;
  di_dirty = 1'b0;
  
  bcounter_load = 1'b0;
  bcounter_en = 1'b0;
  
  index_load = 1'b1;
  
  datamem_we_wb = 1'b0;
  datamem_we_fml = 1'b0;
  
  wb_ack_o = 1'b0;
  
  fml_stb = 1'b0;
  fml_we = 1'b0;
  
  next_state = state;
  
  case(state)
    IDLE: begin
      bcounter_load = 1'b1;
      if(wb_cyc_i & wb_stb_i) begin
        if(wb_tga_i)
          next_state = TEST_INVALIDATE;
        else
          next_state = TEST_HIT;
      end
    end
    TEST_HIT: begin
      if(cache_hit) begin
        if(wb_we_i) begin
          next_state = WRITE_HIT;
        end else begin
          wb_ack_o = 1'b1;
          next_state = IDLE;
        end
      end else begin
        if(do_dirty)
          next_state = EVICT;
        else
          next_state = REFILL;
      end
    end
    WRITE_HIT: begin
      di_valid = 1'b1;
      di_dirty = 1'b1;
      tagmem_we = 1'b1;
      datamem_we_wb = 1'b1;
      wb_ack_o = 1'b1;
      next_state = IDLE;
    end
  
    /*
     * Burst counter has already been loaded.
     * Yes, we evict lines in different order depending
     * on the critical word position of the cache miss
     * inside the line, but who cares :)
     */
    EVICT: begin
      fml_stb = 1'b1;
      fml_we = 1'b1;
      if(fml_ack) begin
        bcounter_en = 1'b1;
        next_state = EVICT2;
      end
    end
    EVICT2: begin
      bcounter_en = 1'b1;
      next_state = EVICT3;
    end
    EVICT3: begin
      bcounter_en = 1'b1;
      next_state = EVICT4;
    end
    EVICT4: begin
      bcounter_en = 1'b1;
      next_state = EVICT5;
    end
    EVICT5: begin
      bcounter_en = 1'b1;
      next_state = EVICT6;
    end
    EVICT6: begin
      bcounter_en = 1'b1;
      next_state = EVICT7;
    end
    EVICT7: begin
      bcounter_en = 1'b1;
      next_state = EVICT8;
    end
    EVICT8: begin
      bcounter_en = 1'b1;
      if(wb_tga_i)
        next_state = INVALIDATE;
      else
        next_state = REFILL;
    end
  
    REFILL: begin
      /* Write the tag first. This will also set the FML address. */
      di_valid = 1'b1;
      if(wb_we_i)
        di_dirty = 1'b1;
      else
        di_dirty = 1'b0;
      tagmem_we = 1'b1;
      next_state = REFILL_WAIT;
    end
    REFILL_WAIT: next_state = REFILL1; /* one cycle latency for the FML address */
    REFILL1: begin
      bcounter_load = 1'b1;
      fml_stb = 1'b1;
      /* Asserting both
       * datamem_we_fml and
       * datamem_we_wb, WB has priority
       */
      datamem_we_fml = 1'b1;
      if(wb_we_i)
        datamem_we_wb = 1'b1;
      if(fml_ack)
        next_state = REFILL2;
    end
    REFILL2: begin
      /*
       * For reads, the critical word has just been written to the datamem
       * so by acking the cycle now we get the correct result (because the
       * datamem is a write-first SRAM).
       * For writes, we could have acked the cycle before but it's simpler this way.
       * Otherwise, we have the case of a master releasing WE just after ACK,
       * and we must add a reg to tell whether we have a read or a write in REFILL2...
       */
      wb_ack_o = 1'b1;
      /* Now we must use our copy of index, as the WISHBONE
       * address may change.
       */
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = REFILL3;
    end
    REFILL3: begin
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = REFILL4;
    end
    REFILL4: begin
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = REFILL5;
    end
    REFILL5: begin
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = REFILL6;
    end
    REFILL6: begin
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = REFILL7;
    end
    REFILL7: begin
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = REFILL8;
    end
    REFILL8: begin
      index_load = 1'b0;
      datamem_we_fml = 1'b1;
      bcounter_en = 1'b1;
      next_state = IDLE;
    end
  
    TEST_INVALIDATE: begin
      if(do_dirty)
        next_state = EVICT;
      else
        next_state = INVALIDATE;
    end
    INVALIDATE: begin
      di_valid = 1'b0;
      di_dirty = 1'b0;
      tagmem_we = 1'b1;
      wb_ack_o = 1'b1;
      next_state = IDLE;
    end
  endcase
end

endmodule
