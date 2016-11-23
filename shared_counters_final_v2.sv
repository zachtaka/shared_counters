`include "subcounter.v"
module shared_counters_final_v2(clk,rst,command_in,id,data_out,new_counter_size,allocation_id,valid_allocation_id,rdata_out,valid_data_out,last); //load_data_in #add_load
input wire clk,rst;
input wire [2:0]command_in;
parameter n=10; //o arithmos twn subcounter
parameter g=4; //o arithmos bits ana subcounter
input wire [$clog2(n)-1:0]id;
output reg [g-1:0] data_out[n-1:0];
//reg [g-1:0] data_in[n-1:0]; #add_load
input integer new_counter_size;
reg [1:0] mask_sub_command_in [n-1:0];


// generate subcounters
generate
	genvar i;
	for (i = 0; i < n; i=i+1) begin
		subcounter #(.granularity(g)) subcounter_i(
						.clk(clk),
						.sub_command_in(mask_sub_command_in[i]),
						//.load_data_in(data_in[i]) #add_load
						.data_out(data_out[i])
						);
	end
endgenerate



//command decode
//command_in -> command(idle, reset, increment, new_counter)
enum { idle, reset, increment, new_counter,deallocation, load, read } command;
always @(command_in or rst) begin : command_decode
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

// subcounter_of_counter: dinei ena vector apo poious subcounter apoteleitai o counter(id)
reg [n-1:0] subcounter_of_counter;
reg [n-1:0] free;//na ginei reg
reg [n-1:0] shift_mask,local_mask,or_local_mask;
reg [n-1:0]  mask; //na ginei reg
always @(*) begin //command or id or mask or free or subcounter_of_counter
if (command==increment || command==deallocation || command==load || command==read) begin
	shift_mask = (mask >>id+1);
	local_mask= (shift_mask <<id+1);
	for (int i =n-1; i>=0;i=i-1)begin
		if (i<id) begin
			subcounter_of_counter[i]=1'b0;
		end else if (i==id) begin
			subcounter_of_counter[i]=1'b1;
		end else if (i>id) begin
			if (|local_mask==1'b1 || free[i]==1'b1) begin 		// na elenksw oti leitourgei kala me to free[i]
				subcounter_of_counter[i]=1'b0;
			end else begin
				subcounter_of_counter[i]=1'b1;
			end
			local_mask= local_mask<<1;
			//$display("local_mask[%d]=%b",i,subcounter_of_counter);
		end
	end
end
end

// Allocation
//new_counter
output reg valid_allocation_id;
output reg [$clog2(n):0] allocation_id;
reg [n-1:0] local_vector;
reg [n-1:0] candidate,mask_candidate,final_candidate;
always @(*) begin
	if (command==new_counter) begin
		for (int i=0;i<n;i=i+1)begin
			local_vector[i] = (i<new_counter_size) ? 1:0;
		end
		// $display("free=%b",free);
		// $display("size=%d",new_counter_size);
		for (int i=0;i<n;i=i+1)begin
			local_vector = (i>0) ? (local_vector<<1):local_vector;
			// $display("local_vector[%d]=%b",i,local_vector);
			// $display("free&local_vector=%b",free&local_vector);
			candidate[i] = ((free&local_vector)==local_vector) ? 1:0;
			//$display("candidate[%d]=%b",i,candidate[i]);
			
		end
		
		for (int i=0;i<n;i=i+1)begin
			if (i<new_counter_size) begin
				candidate = candidate<<i;
				candidate = candidate>>i;
			end 
		end
		//$display("candidate=%b",candidate);

		mask_candidate=candidate;
		//$display("mask_candidate=%b",mask_candidate);
		for (int i=n-1; i>=0; i=i-1)begin
			mask_candidate = mask_candidate<<1;
			// $display("candidate[%d]=%b",i,candidate[i]);
			// $display("mask_candidate[%d]=%b",i,mask_candidate);
			// $display("|mask_candidate[%d]=%b",i,|mask_candidate);
			if ((candidate[i]==1'b1) && ((|mask_candidate)==1'b0) ) begin
				final_candidate[i]=1'b1;
			end else begin
				final_candidate[i]=0;
			end
		end
		//$display("final_candidate=%b",final_candidate);

		if (|final_candidate==1'b1) begin
			for(int i=0;i<n;i=i+1)begin
				if (final_candidate[i]==1'b1) begin
					allocation_id=i;
					valid_allocation_id=1'b1;
					mask[i]=1'b1;
				end
			end
			
		end else begin
			allocation_id=0;
			valid_allocation_id=1'b0;
		end
		//$display("allocation_id=%d",allocation_id);
		//$display("valid_allocation_id=%b",valid_allocation_id);
		
		for (int i=0;i<n;i=i+1)begin
			if (valid_allocation_id==1'b1 && i>=allocation_id && i<allocation_id+new_counter_size) begin
				free[i]=0;
			end else begin
				free[i]=free[i];
			end
		end
		$display("Allocation done, size=%d", new_counter_size);
		$display("free=%b",free);
		$display("mask=%b",mask);

	end else begin
		allocation_id=0;
		valid_allocation_id=1'b0;
	end
end

// Deallocation
always @(*) begin
	if (command==deallocation) begin
		for (int i=0;i<n;i=i+1)begin
			if (subcounter_of_counter[i]==1'b1) begin
				if (i==id) begin
					mask[i]=0;
				end
				free[i]=1;
			end else begin
				mask[i]=mask[i];
				free[i]=free[i];
			end
		end
		$display("De-Allocation done, counter_id=%d", id);
		$display("mask=%b",mask);
		$display("free=%b",free);	
	end
end



// analoga me to command moirazw tis katalliles entoles stous subcounter 
// (prosoxi dn einai oi telikes entoles pou tha paroun oi subcounter, oi telikes dinontai apo to mask_sub_command_in)
reg [1:0] sub_command_in [n-1:0];
always @(*) begin
if (command==increment) begin
	for (int i=0; i<n; i=i+1)begin
		if (subcounter_of_counter[i]==1'b1) begin
			if (&data_out[i]==1'b1) begin
				sub_command_in[i]=2'b00; // id data_out[i]="1111" then reset
			end else begin
				sub_command_in[i]=2'b01; // else increment
			end
		end else begin
			sub_command_in[i]=2'b10; // is subcounter doesnt belong to counter set idle
		end
		//$display("sub_command_in[%d]=%b",i,sub_command_in[i]);
	end
end else if(command==idle) begin
	for(int i=0;i<n;i=i+1)begin
		sub_command_in[i]=2'b10; // set every subcounter idle
	end
end else if (command==reset) begin
	free={n{1'b1}};
	mask={n{1'b0}};
	for(int i=0;i<n;i=i+1)begin
		sub_command_in[i]=2'b00; // set every subcounter reset
	end
end
end


// mask_sub_command_in: metatrepw tis entoles sub_command_in stis swstes entoles pou dinontai stous subcounter
// oi entoles sub_command_in edinan tis entoles increment/reset mono koitazontas tin eksodo twn subcounter (an ola 1 tote reset alliws increment )
// me tis masked entoles elegxw mexri na dwsw to 1o increment se subcounter kai dinw entoli idle stous subcounter meta apo auton
reg [n-1:0] local_mask_sub_command_in;
always @(*) begin
	for (int i=0;i<n;i=i+1)begin
		if (sub_command_in[i]==2'b01) begin
			local_mask_sub_command_in[i]=1'b1;
		end else if (sub_command_in[i]==2'b00 || sub_command_in[i]==2'b10) begin
			local_mask_sub_command_in[i]=1'b0;
		end


		/*$display("sub_command_in[%d]=%b",i,sub_command_in[i]);
		$display("local_mask_sub_command_in[%d]=%b",i,local_mask_sub_command_in[i]);*/
	end
	for (int i=n-1; i>=0;i=i-1)begin
		local_mask_sub_command_in = local_mask_sub_command_in<<1;
		//$display("local_mask_sub_command_in[%d]=%b",i,local_mask_sub_command_in);
		if (|local_mask_sub_command_in==1'b1 || subcounter_of_counter[i]==1'b0) begin
			mask_sub_command_in[i]=2'b10; // set idle 
		end else if (|local_mask_sub_command_in==1'b0) begin
			mask_sub_command_in[i]=sub_command_in[i]; //pass increment or reset
		end
	end
end

// READ
output reg valid_data_out;
output reg [g-1:0] rdata_out;
output reg last;
reg [$clog2(n)-1:0] cycle_counter;
always @(posedge clk or posedge rst) begin
	if (rst) begin
		rdata_out<={g{0}};
		cycle_counter<=0;
		valid_data_out<=0;
	end
	else if (command==read) begin
		cycle_counter<= cycle_counter+1;
		if (subcounter_of_counter[id+cycle_counter]==1'b1) begin
			rdata_out<=data_out[id+cycle_counter];
			valid_data_out<=1'b1;
			if (id+cycle_counter+1<n) begin
				if (subcounter_of_counter[id+cycle_counter+1]==1'b0) begin
					last<=1'b1;
				end else
					last<=1'b0;
			end
			// $display("rdata_out=%b",data_out[id+cycle_counter]);
			// $display("valid_data_out=%b",1'b1);
		end else begin
			rdata_out<={g{0}};
			valid_data_out<=0;
		end
	end else begin
		rdata_out<={g{0}};
		cycle_counter<=0;
		valid_data_out<=0;
	end
end


//LOAD
//external load
/*reg [63:0] temp_load_data;
input wire [63:0] load_data_in;
input wire valid_load_data;
reg valid_temp_load_data;
reg [$clog2(n)-1:0]temp_id;
always @(posedge clk or posedge rst) begin
	if (rst) begin
		cycle_counter<= 0;
		temp_load_data<=0;
		valid_temp_load_data<=0;
		temp_id<=0;
	end
	else if ((command==load) && (valid_load_data==1'b1) begin
		cycle_counter<= cycle_counter+1;
		temp_load_data<=load_data_in;
		valid_temp_load_data<=1'b1;
		temp_id<=id;
	end else begin
		cycle_counter<= 0;
		temp_load_data<=0;
		valid_temp_load_data<=0;
		temp_id<=0;
	end
end
//internal load
always @(*) begin
	if (valid_temp_load_data=1'b1) begin
		for (int i=0;i<n;i=i+1)begin
			if (subcounter_of_counter[i]==1'b1) begin
				data_in[i]=temp_load_data[(i-temp_id)+:g]
			end
		end
	end
end*/


// changed
endmodule