//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-29
//====================================================================

// =========================================
// Testbench utilities (flush, etc.)
// =========================================
class cl_TbUtils #(parameter int WIDTH = 8);
  local virtual if_Fifo #(WIDTH) vif; // full interface handle (not a modport)
  local cl_Scoreboard #(WIDTH) sb;

  function new(virtual if_Fifo #(WIDTH) vif, cl_Scoreboard #(WIDTH) sb);
    this.vif = vif;
    this.sb  = sb;
  endfunction

  // Perform a flush and validate FIFO empty and scoreboard reset
  task ta_flushFifo(ref int errorCnt);
    @(negedge vif.clk);
    vif.flush <= 1'b1;
    @(negedge vif.clk);
    vif.flush <= 1'b0;
    sb.ta_scoreboardReset();
    @(negedge vif.clk);
    if (!vif.empty) begin
      $display("[%0t] ERROR: empty should be 1 after flush", $time);
      errorCnt++;
      $fatal(1);
    end
    if (vif.full) begin
      $display("[%0t] ERROR: full should be 0 after flush", $time);
      errorCnt++;
      $fatal(1);
    end
  endtask
endclass

