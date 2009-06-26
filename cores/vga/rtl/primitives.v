// Quartus II Verilog Template
// One-bit wide, N-bit long shift register

module basic_shift_register 
#(parameter N=64)
(
	input clk, enable,
	input sr_in,
	output sr_out
);

	// Declare the shift register
	reg [N-1:0] sr;

	// Shift everything over, load the incoming bit
	always @ (posedge clk)
	begin
		if (enable == 1'b1)
		begin
			sr[N-1:1] <= sr[N-2:0];
			sr[0] <= sr_in;
		end
	end

	// Catch the outgoing bit
	assign sr_out = sr[N-1];

endmodule
