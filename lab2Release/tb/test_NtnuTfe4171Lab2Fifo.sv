//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================
// Top-level testbench module integrating classes

module test_NtnuTfe4171Lab2Fifo;

  localparam WIDTH = 8;
  localparam DEPTH = 32;

  // Interfaces
  if_Fifo    #(WIDTH) tb_if();
  if_TbEvents         ev_if();

  // DUT
  NtnuTfe4171Lab1Fifo #(
    .WIDTH (WIDTH),
    .DEPTH (DEPTH)
  ) u_NtnuTfe4171Lab1Fifo (
    .clk     (tb_if.clk),
    .arst    (tb_if.arst),
    .wr_en   (tb_if.wr_en),
    .wr_data (tb_if.wr_data),
    .rd_en   (tb_if.rd_en),
    .flush   (tb_if.flush),
    .rd_data (tb_if.rd_data),
    .full    (tb_if.full),
    .empty   (tb_if.empty)
  );


  cl_Scoreboard #(WIDTH) sb     = new();
  cl_TbUtils    #(WIDTH) utils  = new(tb_if, sb);
  cl_FifoWriter #(WIDTH) writer = new(sb, ev_if, utils);
  cl_FifoReader #(WIDTH) reader = new(sb, ev_if);
  
  
  int errorCnt = 0;


  // Reset
  bit resetComplete;
  task doReset;
  begin
    tb_if.arst    <= 1'b1;
    tb_if.wr_en   <= 1'b0;
    tb_if.rd_en   <= 1'b0;
    tb_if.flush   <= 1'b0;
    tb_if.wr_data <= '0;
    sb.ta_scoreboardReset();
    repeat (3) @(posedge tb_if.clk);
    tb_if.arst <= 1'b0;
    repeat (2) @(posedge tb_if.clk);
    if (!tb_if.empty) begin
      $display("[%0t] ERROR: empty should be 1 after reset", $time);
      errorCnt++;
      $fatal(1);
    end
    if (tb_if.full) begin
      $display("[%0t] ERROR: full should be 0 after reset", $time);
      errorCnt++;
      $fatal(1);
    end
  end
  endtask

  // Clock 16 MHz
  realtime clock_period = (1s/16e6);
  initial begin tb_if.clk = 0; forever #(clock_period/2.0) tb_if.clk = !tb_if.clk; end
  initial begin
    #1ms;
    $fatal (1, "WATCHDOG TIMER : simulation seems stuck");
  end

  // Main stimulus
  localparam NUM_PACKETS_TO_TRANSMIT = 1;
  int packetAck[$];
  int currentPacketTxNum = 0;
  int currentPacketRxNum = 0;
  int rxPacketId;
  const int      numWordsInPacket         = 27;
  const int      numCyclesToProcessPacket = 50;
  const realtime packetTimeoutVal         = 5.1us;

  initial begin
    tb_if.arst    = 0;
    tb_if.wr_en   = 0;
    tb_if.rd_en   = 0;
    tb_if.flush   = 0;
    tb_if.wr_data = 0;
    resetComplete = 0;
    errorCnt      = 0;

    #10; doReset(); resetComplete = 1;
  end

  // Launch background writer/reader models (event-driven)
  initial begin
    wait (resetComplete);
    fork
      writer.run(currentPacketTxNum, errorCnt, packetAck,
                 numWordsInPacket, packetTimeoutVal,
                 tb_if.clk, tb_if.flush, tb_if.full, tb_if.empty, tb_if.wr_en, tb_if.wr_data);
      reader.run(currentPacketRxNum, rxPacketId, errorCnt, packetAck,
                 numWordsInPacket, numCyclesToProcessPacket,
                 tb_if.clk, tb_if.flush, tb_if.rd_en, tb_if.rd_data, tb_if.empty);
    join_none
  end

  // Tests (unchanged behavior, but use utils.ta_flushFifo instead of task)
  initial begin
    int localErrCnt1, localErrCnt2, localErrCnt3;
    wait (resetComplete);
    #10;

    // 1) burst write partial packet (e.g. 16 bytes) then read back
    writer.ta_writeBurst(16, 8'h10, tb_if.clk, tb_if.full, tb_if.wr_en, tb_if.wr_data);
    reader.ta_readBurst(16, tb_if.clk, tb_if.empty, tb_if.rd_en, tb_if.rd_data, localErrCnt1);
    errorCnt += localErrCnt1;
    #1; if (!tb_if.empty) begin $display("[%0t] ERROR: (1) FIFO should be empty after equal write/read", $time); errorCnt++; $error; end
        else                    $display("[%0t] SUCCESS: (1) FIFO data pushed and emptied after equal write/read\n", $time);

    // removing test-vector 2 to simplify Lab2 - can bring back for increased testing.
/*
    // 2) Write near-full, then flush
    writer.ta_writeBurst(DEPTH - 2, 8'h20, clk, full, wr_en, wr_data);
    if (empty) begin $display("[%0t] ERROR: (2) FIFO should not be empty after writes", $time); errorCnt++; $error; end
    else $display("[%0t] SUCCESS: (2) FIFO data pushed and empty de-asserted\n", $time);
    utils.ta_flushFifo(errorCnt);
*/

    // Attempt to read after flush
    reader.ta_readBurst(4, tb_if.clk, tb_if.empty, tb_if.rd_en, tb_if.rd_data, localErrCnt2);
    errorCnt += localErrCnt2;

    // removing test-vector 3 to simplify Lab2 - can bring back for increased testing.
/*
    // 3) Fill to full, then drain and compare
    writer.ta_writeBurst(DEPTH, 8'h40, clk, full, wr_en, wr_data);
    @(posedge clk);
    if (!full) $display("[%0t] WARNING: (3a) full is not asserted after DEPTH writes (check pointer/flag logic)", $time);
    else        $display("[%0t] SUCCESS: (3a) FIFO filled and full asserted\n", $time);
    reader.ta_readBurst(DEPTH, clk, empty, rd_en, tb_if.rd_data, localErrCnt3);
    errorCnt += localErrCnt3;
    #1; if (!empty) begin $display("[%0t] ERROR: (3b) FIFO should be empty after draining", $time); errorCnt++; $error; end
        else              $display("[%0t] SUCCESS: (3b) FIFO emptied after filling and empty asserted\n", $time);
    utils.ta_flushFifo(errorCnt);
*/

    // 4) Interleaved traffic: keep existing TX/RX orchestrators
    //    read/write (same-cycle ops) to exercise FIFO data integrity
    //    Write 27 bytes while reading in parallel after some delay
    fork
      begin : writerThread
        for (int ii = 0; ii < NUM_PACKETS_TO_TRANSMIT; ii++) begin
          wait (ii === currentPacketTxNum); #1;
          $display ("%t : transmitting packet number %0d", $realtime, ii);
          -> ev_if.tx;
        end
      end
      begin : readerThread
        forever begin
          wait ( (tb_if.empty === 0) && (tb_if.flush == 0) ); #1;
          ev_if.rxTrig = 1; #1;
          wait (ev_if.rxDone == 1); ev_if.rxTrig = 0; wait (ev_if.rxDone == 0); #1ns;
        end
      end
    join_any

    #(NUM_PACKETS_TO_TRANSMIT * packetTimeoutVal); #1;
    if (currentPacketRxNum != currentPacketTxNum) begin
      $display("[%0t] ERROR: (4) Packets transmitted (%0d) not equal to packets received (%0d)", $time, currentPacketTxNum, currentPacketRxNum);
      errorCnt++; $error;
    end else $display("[%0t] (4) All transmitted packets (%0d) are received", $time, currentPacketTxNum);

    if (!tb_if.empty) begin
      $display("[%0t] ERROR: (4) FIFO should be empty after draining", $time);
      errorCnt++; $error;
    end else $display("[%0t] SUCCESS: (4) FIFO emptied and empty asserted\n", $time);

    if (errorCnt == 0) $display("[%0t] TEST PASSED: All data matched and flags behaved correctly.\n", $time);
    else $display("[%0t] TEST FAILED: %0d errors detected.\n", $time, errorCnt);

    // Finish
    #1us;
    $finish;
  end

endmodule

