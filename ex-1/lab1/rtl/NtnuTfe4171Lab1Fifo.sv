


module NtnuTfe4171Lab1Fifo #(
    parameter WIDTH = 8,          // Data width in bits
    parameter DEPTH = 32          // FIFO depth in bytes
)(
    input  wire              clk,
    input  wire              arst,
    input  wire              wr_en,
    input  wire [WIDTH-1:0]  wr_data,
    input  wire              rd_en,
    input  wire              flush,      // Flush FIFO (writer control)
    output reg  [WIDTH-1:0]  rd_data,
    output wire              full,
    output wire              empty
);

    // Calculate address width
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // Full/Empty logic
    assign empty = (wr_ptr == rd_ptr);
    assign full  = ((wr_ptr - rd_ptr) == DEPTH);

    integer i;

    // Write pointer logic
    always_ff @(posedge clk or posedge arst) begin
      if (arst)
        wr_ptr <= 0;
      else if (flush)
        wr_ptr <= 0;
      else if (wr_en && !full) begin
        wr_ptr <= wr_ptr + 1;
      end
    end

    // write mem logic
    always_ff @(posedge clk) begin
//      if (arst) begin
//        for (i = 0; i < (WIDTH-1)*(DEPTH-1); i = i + 1) begin
//          mem[i] <= 8'b0;
//        end
//      end
      if (wr_en && !full && !flush) //begin
        mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;

    end

    // Read pointer logic
    always_ff @(posedge clk or posedge arst) begin
      if (arst)
        rd_ptr <= 0;
      else if (flush)
        rd_ptr <= 0;
      else if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end

		// read out data logic
    always @* begin
      if (rd_en && !empty && !flush)
        rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
      else
        rd_data <= 8'h00;
    end

endmodule
