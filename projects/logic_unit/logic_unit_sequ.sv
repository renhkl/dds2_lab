// -------------------------------------------------
// Copyright(c) LUBIS EDA GmbH, All rights reserved
// Contact: contact@lubis-eda.com
// -------------------------------------------------

`default_nettype none

module logic_unit_sequ #(
    parameter    WIDTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] req_vec,
    input  logic             valid,

    output logic             out,
    output logic             done,
    output logic [WIDTH-1:0] counter_dbg, //!!
    output logic 	     busy_dbg //!!
);

    //////////////////////
    // Internal Signals //
    //////////////////////
    logic [WIDTH-1:0] req_vec_reg;
    logic [WIDTH-1:0] counter;
    logic             or_result_reg;
    logic             out_reg;
    logic             busy;
    logic             done_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            out_reg       <= 1'b0;
            done_reg      <= 1'b1; //this becomes output signal done
            busy          <= 1'b0;
            req_vec_reg   <= WIDTH'(0);
            counter       <= WIDTH'(0);
            or_result_reg <= (WIDTH-1)'(0);
        end else begin //if not reset
            if (valid && done_reg) begin
                busy          <= 1'b1;
                req_vec_reg   <= req_vec;
                or_result_reg <= (WIDTH-1)'(0);
                done_reg      <= 1'b0; //done should not be set high here
	        counter       <= WIDTH'(0); //reset counter on new computation
		out_reg       <= 1'b0; //out reg doesn't have a value yet
            end else begin
		busy          <= 1'b0; //not busy

		//same as for above case
                req_vec_reg   <= req_vec;
                or_result_reg <= (WIDTH-1)'(0);
                done_reg      <= 1'b0; //done should not be set high here
	        counter       <= WIDTH'(0); //reset counter on new computation
		out_reg       <= 1'b0; //out reg doesn't have a value yet

end 

            if (busy) begin
                if (counter < (WIDTH-1)) begin
                    or_result_reg <= or_result_reg || req_vec_reg[counter];
		    out_reg <= or_result_reg || req_vec_reg[counter];	//make temp out value available
                    counter <= counter + WIDTH'(1);
		    done_reg <= 1'b0;
		    busy <= 1'b1; //stays the same
		    req_vec_reg   <= req_vec; //stays the same
                end else if (counter == (WIDTH-1)) begin
                    out_reg <= req_vec_reg[(WIDTH-1)] && or_result_reg;
                    done_reg <= 1'b1;
		    counter <= WIDTH'(0);  //reset counter when finished computation
		    busy <= 1'b0; //moved
                    req_vec_reg   <= req_vec_reg; //stays the same
                    or_result_reg <= (WIDTH-1)'(0); //can be reset after computation

                //end
                //if (counter == (WIDTH-1)) begin
                //busy <= 1'b0;
                end else begin
                    out_reg  <= 1'b0;
                    done_reg <= 1'b0;
		    busy <= 1'b0; //cannot be busy if counter is bigger than WIDTH-1
		    counter <= WIDTH'(0); //counter should be reset
		    or_result_reg <= (WIDTH-1)'(0); //then the or result would't be
                    req_vec_reg   <= req_vec_reg; //stays the same
                end //end of busy
            end else begin //not busy
                out_reg <= 1'b0;

		//just set everything to zero as don't know what should be done with the values
               done_reg <= 1'b0;
		    busy <= 1'b0; //cannot be busy if counter is bigger than WIDTH-1
		    counter <= WIDTH'(0); //counter should be reset
		    or_result_reg <= (WIDTH-1)'(0); //then the or result would't be
                    req_vec_reg   <= req_vec_reg; //stays the same

	    end
        end //end of not rst
    end //end of always_ff

    assign out = out_reg;
    assign done = done_reg;

    //getting access to internal signals
    assign counter_dbg = counter; //!! 
    assign busy_dbg = busy; //!!

endmodule

/*
`default_nettype none


module logic_unit_sequ #(
    parameter    WIDTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [WIDTH-1:0] req_vec,
    input  logic             valid,
    output logic             out,
    output logic             done,
output logic  [WIDTH-1:0] counter_dbg,
output logic busy_dbg
);

    //////////////////////
    // Internal Signals //
    //////////////////////
    logic [WIDTH-1:0] req_vec_reg;
    logic [WIDTH-1:0] counter;
    logic             or_result_reg;
    logic             out_reg;
    logic             busy;
    logic             done_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            out_reg       <= 1'b0;
            done_reg      <= 1'b1; //this becomes output signal done
            busy          <= 1'b0;
            req_vec_reg   <= WIDTH'(0);
            counter       <= WIDTH'(0);
            or_result_reg <= 1'b0; //(WIDTH-1)'(0);
        end else begin //if not reset
            if (valid && done_reg) begin
                busy     <= 1'b1;
                req_vec_reg   <= WIDTH'(req_vec); //legge til widht
                or_result_reg <= 1'b0; //remove width-1'0
                done_reg      <= 1'b0; //done should not be set high here
		counter       <= WIDTH'(0); //reset counter on new computation
            end

            if (busy) begin
		//for (int i = 0; i < WIDTH; i++) begin //for loop
                if (counter < (WIDTH-1)) begin
                    or_result_reg <= or_result_reg || req_vec_reg[counter];
		    out_reg <= or_result_reg || req_vec_reg[counter]; //make temp value available
                    counter <= counter + WIDTH'(1);
                    
                end else if (counter == (WIDTH-1)) begin
                    out_reg <= req_vec_reg[(WIDTH-1)] && or_result_reg;
                    done_reg <= 1'b1;
                    busy <= 1'b0; //moved
                end
                //if (counter == (WIDTH-1)) begin
                    //busy <= 1'b0; //deleted
                //end else begin //nothing will come here
                  //  out_reg  <= 1'b0;
                   // done_reg <= 1'b0; 
                end //end of busy
		//end //for loop
            //end else begin //not busy
              //  out_reg <= 1'b0; //deleted
	//	done_reg <= 1'b0; //moved
	//	    end
        end //end of not rst


    end //end of always_ff
    
    assign out = out_reg;
    assign done = done_reg;

	//getting access to internal signals
	assign counter_dbg = counter;
	assign busy_dbg = busy;


endmodule
*/
