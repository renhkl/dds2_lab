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
    output logic [WIDTH-1:0] counter_dbg,
    output logic             busy_dbg,
    output logic             or_result_dbg
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
            or_result_reg <= 1'b0; //
        end else begin //if not reset
            if (valid && done_reg) begin
                busy     <= 1'b1;
                req_vec_reg   <= req_vec;
                or_result_reg <= req_vec[0]; //18 -> 17 cycles, set to req_vec[0] instead of 1'b0
                done_reg      <= 1'b0; //done should not be set high here
                counter       <= WIDTH'(1); //18 -> 17 cycles, reset counter to 1 instead of 0
                out_reg <= req_vec[0];
            
           
		end else if (busy) begin
                if (counter < (WIDTH-1)) begin
                    or_result_reg <= or_result_reg || req_vec_reg[counter];
                    out_reg <= or_result_reg; //make temp partial value available
                    counter <= counter + WIDTH'(1);
                
		end else if (counter == (WIDTH-1)) begin
                    out_reg <= req_vec_reg[(WIDTH-1)] && or_result_reg;
                    done_reg <= 1'b1;
                    busy <= 1'b0; //not busy anymore as calculation is done
                    counter <= WIDTH'(1); //reset counter to 1
                end

            end else begin
                //out_reg <= 1'b0; //possible overwrite?
                 done_reg <= 1'b0; //moved
		    end

        end //end of not reset
    end //end of always_ff

    assign out = out_reg;
    assign done = done_reg;
    assign counter_dbg = counter;
    assign busy_dbg = busy;
    assign or_result_dbg = or_result_reg;
    assign req_vec = req_vec_reg;

endmodule