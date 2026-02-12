//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================

// =========================================
// FIFO Interface for testbench classes
// =========================================
interface if_Fifo #(parameter int WIDTH = 8);
  // DUT pins
  logic                    clk;
  logic                    arst;        // Active-high async reset
  logic                    wr_en;
  logic [WIDTH-1:0]        wr_data;
  logic                    rd_en;
  logic [WIDTH-1:0]        rd_data;
  logic                    full;
  logic                    empty;
  logic                    flush;

  // Modports for users
  modport writer (
    input  clk, full, flush,
    output wr_en, wr_data
  );

  modport reader (
    input  clk, empty, flush, rd_data,
    output rd_en
  );

  // Modport for DUT connection
  modport dut (
    input  clk, arst, wr_en, wr_data, rd_en, flush,
    output rd_data, full, empty
  );
endinterface
