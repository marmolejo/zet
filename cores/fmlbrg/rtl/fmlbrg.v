/*
 * Wishbone to FML 8x16 bridge
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010 Sebastien Bourdeauducq
 * adjusted to FML 8x16 by Zeus Gomez Marmolejo <zeus@aluzina.org>
 * updated to include Direct Cache Bus by Charley Picker <charleypicker@yahoo.com>
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
	parameter fml_depth = 23,
	parameter cache_depth = 9 // 512 byte cache	
) (
	input sys_clk,
	input sys_rst,
	
	input [fml_depth-1:1] wb_adr_i,
	input           [2:0] wb_cti_i,
	input          [15:0] wb_dat_i,
	output         [15:0] wb_dat_o,
	input           [1:0] wb_sel_i,
	input                 wb_cyc_i,
	input                 wb_stb_i,
	input                 wb_tga_i,
	input                 wb_we_i,
	output reg            wb_ack_o,
	
	output reg [fml_depth-1:0] fml_adr,
	output reg                 fml_stb,
	output reg                 fml_we,
	input                      fml_ack,
	output               [1:0] fml_sel,
	output              [15:0] fml_do,
	input               [15:0] fml_di,

	/* Direct Cache Bus */
	input                 dcb_stb,
	input [fml_depth-1:1] dcb_adr,
	output         [15:0] dcb_dat,
	output                dcb_hit
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

wire [3:1] dcb_offset = dcb_adr[3:1];
wire [cache_depth-1-4:0] dcb_index = dcb_adr[cache_depth-1:4];
wire [fml_depth-cache_depth-1:0] dcb_tag = dcb_adr[fml_depth-1:cache_depth];

wire coincidence = index == dcb_index;

/*
 * TAG MEMORY
 *
 * Addressed by index (length cache_depth-5)
 * Contains valid bit + dirty bit + tag
 */

wire [cache_depth-1-4:0] tagmem_a;
reg tagmem_we;
wire [fml_depth-cache_depth-1+2:0] tagmem_di;
wire [fml_depth-cache_depth-1+2:0] tagmem_do;

wire [cache_depth-1-4:0] tagmem_a2;
wire [fml_depth-cache_depth-1+2:0] tagmem_do2;

fmlbrg_tagmem #(
	.depth(cache_depth-4),
	.width(fml_depth-cache_depth+2)
) tagmem (
	.sys_clk(sys_clk),

	.a(tagmem_a),
	.we(tagmem_we),
	.di(tagmem_di),
	.dout(tagmem_do),

	.a2(tagmem_a2),
	.do2(tagmem_do2)
);

reg index_load;
reg [cache_depth-1-4:0] index_r;
always @(posedge sys_clk) begin
  if(index_load)
    index_r <= index;
end

assign tagmem_a = index;

assign tagmem_a2 = dcb_index;

reg di_valid;
reg di_dirty;
assign tagmem_di = {di_valid, di_dirty, tag};

wire do_valid;
wire do_dirty;
wire [fml_depth-cache_depth-1:0] do_tag;
wire cache_hit;

wire do2_valid;
wire [fml_depth-cache_depth-1:0] do2_tag;

assign do_valid = tagmem_do[fml_depth-cache_depth-1+2];
assign do_dirty = tagmem_do[fml_depth-cache_depth-1+1];
assign do_tag = tagmem_do[fml_depth-cache_depth-1:0];

assign do2_valid = tagmem_do2[fml_depth-cache_depth-1+2];
assign do2_tag = tagmem_do2[fml_depth-cache_depth-1:0];

always @(posedge sys_clk)
	fml_adr <= {do_tag, index, offset, 1'b0};

/*
 * DATA MEMORY
 *
 * Addressed by index+offset in 16-bit words (length cache_depth-1)
 * 16-bit memory with 8-bit write granularity
 */

wire [cache_depth-1-1:0] datamem_a;
reg [1:0] datamem_we;
reg [15:0] datamem_di;
wire [15:0] datamem_do;

wire [cache_depth-1-1:0] datamem_a2;
wire [15:0] datamem_do2;

fmlbrg_datamem #(
	.depth(cache_depth-1)
) datamem (
	.sys_clk(sys_clk),
	
	.a(datamem_a),
	.we(datamem_we),
	.di(datamem_di),
	.dout(datamem_do),

	.a2(datamem_a2),
	.do2(datamem_do2)
);

reg [2:0] bcounter;
reg [2:0] bcounter_next;
always @(posedge sys_clk) begin
	if(sys_rst)
		bcounter <= 3'd0;
	else
		bcounter <= bcounter_next;
end

reg [1:0] bcounter_sel;

localparam BCOUNTER_RESET	= 2'd0;
localparam BCOUNTER_KEEP	= 2'd1;
localparam BCOUNTER_LOAD	= 2'd2;
localparam BCOUNTER_INC		= 2'd3;

always @(*) begin
	case(bcounter_sel)
		BCOUNTER_RESET: bcounter_next <= 3'd0;
		BCOUNTER_KEEP: bcounter_next <= bcounter;
		BCOUNTER_LOAD: bcounter_next <= offset;
		BCOUNTER_INC: bcounter_next <= bcounter + 3'd1;
		default: bcounter_next <= 3'bxxx;
	endcase
end

assign datamem_a = { index_load ? index : index_r, bcounter_next };

assign datamem_a2 = {dcb_index, dcb_offset};

reg datamem_we_wb;
reg datamem_we_fml;

always @(*) begin
	if(datamem_we_fml)
		datamem_we = 2'b11;
	else if(datamem_we_wb)
		   datamem_we = {wb_sel_i};
		 else datamem_we = 2'b00;
end

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
assign dcb_dat = datamem_do2;

/* FSM */

reg [fml_depth-cache_depth-1:0] tag_r;
always @(posedge sys_clk)
	tag_r = tag;
assign cache_hit = do_valid & (do_tag == tag_r);

reg [4:0] state;
reg [4:0] next_state;

  localparam [4:0]
    IDLE     = 5'd0,
    TEST_HIT = 5'd1,

    WB_BURST = 5'd2,

    EVICT  = 5'd3,
    EVICT2 = 5'd4,
    EVICT3 = 5'd5,
    EVICT4 = 5'd6,
    EVICT5 = 5'd7,
    EVICT6 = 5'd8,
    EVICT7 = 5'd9,
    EVICT8 = 5'd10,

    REFILL      = 5'd11,
    REFILL_WAIT = 5'd12,
    REFILL1     = 5'd13,
    REFILL2     = 5'd14,
    REFILL3     = 5'd15,
    REFILL4     = 5'd16,
    REFILL5     = 5'd17,
    REFILL6     = 5'd18,
    REFILL7     = 5'd19,
    REFILL8     = 5'd20,

    TEST_INVALIDATE = 5'd21,
    INVALIDATE      = 5'd22;

always @(posedge sys_clk) begin
	if(sys_rst)
		state <= IDLE;
	else begin
		//$display("state: %d -> %d", state, next_state);
		state <= next_state;
	end
end

always @(*) begin
	tagmem_we = 1'b0;
	di_valid = 1'b0;
	di_dirty = 1'b0;
	
	bcounter_sel = BCOUNTER_KEEP;
	
	index_load = 1'b1;
		
	datamem_we_wb = 1'b0;
	datamem_we_fml = 1'b0;
	
	wb_ack_o = 1'b0;
	
	fml_stb = 1'b0;
	fml_we = 1'b0;
	
	next_state = state;
	
	case(state)
		IDLE: begin
			bcounter_sel = BCOUNTER_LOAD;
			if(wb_cyc_i & wb_stb_i) begin
				if(wb_tga_i)
					next_state = TEST_INVALIDATE;
				else
					next_state = TEST_HIT;
			end
		end
		TEST_HIT: begin
			if(cache_hit) begin
				wb_ack_o = 1'b1;
				if(wb_we_i) begin
					di_valid = 1'b1;
					di_dirty = 1'b1;
					tagmem_we = 1'b1;
					datamem_we_wb = 1'b1;
				end
				if(wb_cti_i == 3'b010)
					next_state = WB_BURST;
				else
					next_state = IDLE;
			end else begin
				if(do_dirty)
					next_state = EVICT;
				else
					next_state = REFILL;
			end
		end
		
		WB_BURST: begin
			bcounter_sel = BCOUNTER_INC;
			if(wb_we_i)
				datamem_we_wb = 1'b1;
			wb_ack_o = 1'b1;
			if(wb_cti_i != 3'b010)
				next_state = IDLE;
		end
		
        /*
         * Burst counter has already been loaded.
         * Yes, we evict lines in different order depending
         * on the critical word position of the cache miss
         * inside the line, but who cares :)
         */		
		EVICT: begin
		  $display("Evict");
			fml_stb = 1'b1;
			fml_we = 1'b1;
			if(fml_ack) begin
				bcounter_sel = BCOUNTER_INC;
				next_state = EVICT2;
			end
		end
		EVICT2: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT3;
		end
		EVICT3: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT4;
		end
		EVICT4: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT5;
		end
		EVICT5: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT6;
		end
		EVICT6: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT7;
		end
		EVICT7: begin
			bcounter_sel = BCOUNTER_INC;
			next_state = EVICT8;
		end
		EVICT8: begin
			bcounter_sel = BCOUNTER_INC;
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
			if(~(dcb_stb & coincidence)) begin
				tagmem_we = 1'b1;
				next_state = REFILL_WAIT;
			end
		end
		REFILL_WAIT: next_state = REFILL1; /* one cycle latency for the FML address */
		REFILL1: begin
			bcounter_sel = BCOUNTER_LOAD;
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
		    bcounter_sel = BCOUNTER_INC;
		    next_state = REFILL3;
		end
		REFILL3: begin
		  index_load = 1'b0;
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL4;
		end
		REFILL4: begin
		  index_load = 1'b0;
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL5;
		end
		REFILL5: begin
		  index_load = 1'b0;
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL6;
		end
		REFILL6: begin
		  index_load = 1'b0;
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL7;
		end
		REFILL7: begin
		$display("Refill 7");
		  index_load = 1'b0;
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
			next_state = REFILL8;
		end
		REFILL8: begin
		  index_load = 1'b0;
			datamem_we_fml = 1'b1;
			bcounter_sel = BCOUNTER_INC;
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

/* Do not hit on a line being refilled */
reg dcb_can_hit;

always @(posedge sys_clk) begin
	dcb_can_hit <= 1'b0;
	if(dcb_stb) begin
		if((state != REFILL_WAIT)
		|| (state != REFILL2)
		|| (state != REFILL3)
		|| (state != REFILL4)
		|| (state != REFILL5)
		|| (state != REFILL6)
		|| (state != REFILL7)
		|| (state != REFILL8))
			dcb_can_hit <= 1'b1;
		if(~coincidence)
			dcb_can_hit <= 1'b1;
	end
end

reg [fml_depth-cache_depth-1:0] dcb_tag_r;
always @(posedge sys_clk)
	dcb_tag_r = dcb_tag;

assign dcb_hit = dcb_can_hit & do2_valid & (do2_tag == dcb_tag_r);

endmodule
