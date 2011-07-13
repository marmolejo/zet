module reset (
    input        clk, // clk - input frequency
	input        lock,
    input  [7:0] sw,
    output reg   rst  // reset out
  );


`ifndef SIMULATION

  reg  [16:0] rst_debounce;	
  initial     rst_debounce <= 17'h1FFFF;
  
  initial     rst <= 1'b1;
  
  wire        rst_lck;
  assign      rst_lck    = !sw[0] & lock;
  
  always @(posedge clk) begin
    if(~rst_lck) /* reset is active low */
      rst_debounce <= 17'h1FFFF;
    else if(rst_debounce != 17'd0)
      rst_debounce <= rst_debounce - 17'd1;
    rst <= rst_debounce != 17'd0;
  end
`else
  wire rst;
  assign rst = !rst_lck;
`endif

endmodule
