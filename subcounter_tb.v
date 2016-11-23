`include "subcounter.v"
module subcounter_tb();


parameter granularity=4;
reg clk; 
reg [1:0]sub_command_in;
wire [granularity-1:0] data_out;


parameter ClkCycle = 10;
reg [20:0]ClkCycleCounter;
integer file;

//command decode
// 00-> reset
initial begin
	file = $fopen("C:/Users/haris/Desktop/HDL_Books/verilog_projects/shared_counters/results.txt", "w") ;
	$fwrite (file, "Clock_Cycle\tCommand\tdata_out \n");
	clk=0;
	ClkCycleCounter=0;
	sub_command_in = 2'b00;
	#(ClkCycle*10)
	sub_command_in = 2'b01;
	#(ClkCycle*10)
	sub_command_in = 2'b10;


end

always @(posedge clk) begin
	ClkCycleCounter<=ClkCycleCounter+1'b1;
	$fwrite(file,"%d\t%b\t%b\n",ClkCycleCounter,sub_command_in,data_out);
end



always begin
	#(ClkCycle/2) clk = !clk; 
end

subcounter #(.granularity(4))uut(
				.clk(clk),
				.sub_command_in(sub_command_in),
				.data_out(data_out)
				);




endmodule