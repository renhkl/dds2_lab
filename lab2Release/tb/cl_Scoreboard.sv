//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================

// =========================================
// cl_Scoreboard class
// =========================================
class cl_Scoreboard #(parameter int WIDTH = 8);
  local rand logic [WIDTH-1:0] q[$];
  // function new(); endfunction  // what happens when new function is not explicity defined?

  task ta_queuePush(input logic [WIDTH-1:0] data);
    q.push_back(data);
  endtask

  task ta_popAndCheck(
    input  logic [WIDTH-1:0] actual,
    output int               errorCount
  );
    logic [WIDTH-1:0] expected;
    errorCount = 0;
    if (q.size() == 0) begin
      $display("[%0t] ERROR: Read with empty scoreboard!", $time);
      errorCount++;
      $error;
      return;
    end
    expected = q.pop_front();
    if (actual !== expected) begin
      $display("[%0t] MISMATCH: expected=0x%0h actual=0x%0h", $time, expected, actual);
      errorCount++;
      $error;
    end
  endtask

  task ta_scoreboardReset();
    q.delete();
  endtask
endclass


