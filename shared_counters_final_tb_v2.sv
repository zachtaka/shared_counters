`include "shared_counters_final_v2.sv"

module shared_counters_final_tb_v2();

parameter n=10;
parameter g=4;
parameter ClockCycle=20;
reg clk,rst;
reg [$clog2(n)-1:0] id;
reg [2:0] command_in;
reg [n-1:0] mask,free;
wire  [g-1:0] data_out[n-1:0];
integer file,file2;
reg [31:0] new_counter_size;
reg [20:0]ClkCycleCounter;
wire [$clog2(n):0] allocation_id;
wire valid_allocation_id;
wire [g-1:0] rdata_out;
wire valid_data_out;
wire last;

// Commands decoding
/*if(rst==1'b1) begin
		command = reset;
	end else if(command_in==2'b000) begin
		command = idle;
	end else if(command_in==2'b001) begin
		command = increment;
	end else if(command_in==2'b010) begin
		command = new_counter;
	end else if (command_in==2'b011) begin
		command = deallocation;
	end else if(command_in==2'b100) begin
		command = load;
	end else if(command_in==2'b101) begin
		command = read;
	end
end*/


initial begin
	file = $fopen("C:/Users/haris/Desktop/HDL_Books/verilog_projects/shared_counters/results.txt", "w") ;
	file2 = $fopen("C:/Users/haris/Desktop/HDL_Books/verilog_projects/shared_counters/read_out.txt", "w") ;
	//$fwrite (file, "Clock_Cycle \t Command \t data_out[9] \t data_out[8] \t data_out[7] \t data_out[6] \t data_out[5] \t data_out[4] \t data_out[3] \t data_out[2] \t data_out[1] \t data_out[0] \n");
	signals_initialize;
	assert_reset;
	deassert_reset;
	/*set_mask(0010001001);
	set_free(1100000000);
	increment_counter(3);
	repeat (1000)begin
		tick;
	end
	set_system_idle;
	assert_reset;
	deassert_reset;*/
	//set_free(1_111_111_111);


	//setting some counters
	new__counter(3);
	new__counter(1);
	new__counter(4);
	new__counter(2);

	//deallocate counter with id 3,4
	deallocate_counter(3);
	deallocate_counter(4);

	//increment counter with id 0
	increment_counter(0);
	#(ClockCycle*10000)

	set_system_idle;
	#(ClockCycle*3)

	//read counter
	read_counter(0);
	#(ClockCycle*5) //xreiazetai mono 3 kuklous vevaia
	deassert_read;



end


//command decode to string
enum { idle, reset, increment, new_counter,deallocation, load, read } command;
always @(*) begin
 	if(rst==1'b1) begin
		command = reset;
	end else if(command_in==3'b000) begin
		command = idle;
	end else if(command_in==3'b001) begin
		command = increment;
	end else if(command_in==3'b010) begin
		command = new_counter;
	end else if (command_in==3'b011) begin
		command = deallocation;
	end else if(command_in==3'b100) begin
		command = load;
	end else if(command_in==3'b101) begin
		command = read;
	end
 end 


always @(posedge clk) begin
	ClkCycleCounter <=ClkCycleCounter+1;
	if ((command==increment) ||(command==new_counter)) begin // for proper text alignment
		$fwrite(file,"%d\t\t%s[%d]\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t\n",ClkCycleCounter,command,id,data_out[9],data_out[8],data_out[7],data_out[6],data_out[5],data_out[4],data_out[3],data_out[2],data_out[1],data_out[0]);
	end else if (command==read && valid_data_out==1'b1) begin
		$fwrite(file2, "Cycle counter=%d  rdata_out=%b  last=%b\n",ClkCycleCounter, rdata_out,last);
	end  else if (command==deallocation) begin
		$fwrite(file,"%d\t\t%s[%d]%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t\n",ClkCycleCounter,command,id,data_out[9],data_out[8],data_out[7],data_out[6],data_out[5],data_out[4],data_out[3],data_out[2],data_out[1],data_out[0]);
	end else begin
		$fwrite(file,"%d\t\t%s\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t%b\t\t\n",ClkCycleCounter,command,data_out[9],data_out[8],data_out[7],data_out[6],data_out[5],data_out[4],data_out[3],data_out[2],data_out[1],data_out[0]);
	end
	
end





always begin
	#10 clk = ~clk;
end

shared_counters_final_v2 uut (
	.clk(clk),
	.rst(rst),
	.id(id),
	.command_in(command_in),
	// .mask(mask),
	// .free(free),
	.data_out(data_out),
	.new_counter_size(new_counter_size),
	.allocation_id(allocation_id),
	.valid_allocation_id(valid_allocation_id),
	.rdata_out(rdata_out),
	.valid_data_out(valid_data_out),
	.last(last)

	);


/////////////////////////////////////////////////////////////
//////////////   My tasks    ///////////////////////////
/////////////////////////////////////////////////////////////

task signals_initialize;
begin
	clk=1;
	ClkCycleCounter=0;
end
endtask : signals_initialize

task assert_reset;
begin
	@(posedge clk);
	rst = 1'b1;
end
endtask : assert_reset

task deassert_reset;
begin
	@(posedge clk);
	rst = 1'b0;
end
endtask : deassert_reset

task set_system_idle;
begin
	@(posedge clk);
	command_in = 3'b000;
end
endtask : set_system_idle






task tick;
	@(posedge clk);
endtask : tick

task increment_counter;
	input integer increment_id;
	begin
		id=increment_id;
		command_in=3'b001;
	end
endtask : increment_counter


task set_mask;
	input [n-1:0] value;
	begin
		mask = value;
	end
endtask : set_mask

task set_free;
	input [n-1:0] value;
	begin
		free = value;
	end
endtask : set_free


task new__counter;
	input [n:0] size;
	begin
		@(posedge clk);
		command_in=3'b010; 
		new_counter_size = size;
		@(posedge clk);
		command_in=3'b000; 
		new_counter_size = 0;
	end
endtask

task deallocate_counter;
	input [n:0] id_in;
	begin
		@(posedge clk);
		command_in=3'b011; 
		id=id_in;
		@(posedge clk);
		command_in=3'b000; 
		id=0;
	end
endtask


task read_counter;
	input [n:0] id_in;
	begin
		@(posedge clk);
		command_in=3'b101; 
		id=id_in;
	end
endtask

task deassert_read;
	begin
		@(posedge clk);
		command_in=3'b000; 
		id=0;
	end
endtask
endmodule
