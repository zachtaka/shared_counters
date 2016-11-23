module subcounter (clk,sub_command_in,data_out); //load_data_in  #add_load
parameter granularity=4;

input wire clk;
input wire [1:0] sub_command_in;
//input wire [granularity-1:0] load_data_in; #add_load
output reg [granularity-1:0] data_out;
reg [granularity-1:0] data_out_incremented;
enum { idle, reset, increment, load } command;


//command decode
// 00-> reset
// 01-> increment
// 10-> idle
// 11-> load
always @(sub_command_in) begin
	if (sub_command_in==2'b00) begin
		command = reset;
	end else if (sub_command_in==2'b01) begin
		command = increment;
	end else if  (sub_command_in==2'b10) begin
		command = idle;
	// end else if(sub_command_in==2'b11) begin
	// 	command = load;    #add_load
	end

end

always @(*) begin
	data_out_incremented = data_out + 1;
end

always @(posedge clk) begin
	if (command==reset) begin
		data_out<={granularity{1'b0}};
	end else if (command==increment ) begin
		data_out<=data_out_incremented;
	end else  if (command==idle )begin
		data_out<=data_out;
	end /*else if (command==load ) begin  #add_load
		data_out<=load_data_in;
	end*/
end



// changed 



endmodule