//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================


// =========================================
// cl_FifoReader : tasks take DUT/event signals as args
// =========================================
class cl_FifoReader #(parameter int WIDTH = 8);
  local virtual if_TbEvents.reader  eif;
  local cl_Scoreboard #(WIDTH) sb;

  function new(
    cl_Scoreboard #(WIDTH) sb,
    virtual if_TbEvents.reader  eif
  );
    this.sb = sb;
    this.eif = eif;
  endfunction

  // Single word read
  task ta_readWord(
    input  bit               clk,
    input  bit               empty,
    output bit               rd_en,
    input  logic [WIDTH-1:0] rd_data,
    output int               errors_added
  );
    errors_added = 0;
    @(posedge clk);
    if (!empty) begin
      rd_en = 1'b1;
    end else begin
      rd_en = 1'b0;
    end
    @(posedge clk);
    if (rd_en && !empty) begin
      int localErrCount;
      sb.ta_popAndCheck(rd_data, localErrCount);
      errors_added += localErrCount;
    end
    rd_en = 1'b0;
  endtask

  // Burst read
  task ta_readBurst(
    input  int               n,
    input  bit               clk,
    input  bit               empty,
    output bit               rd_en,
    input  logic [WIDTH-1:0] rd_data,
    output int               errors_added
  );
    errors_added = 0;
    for (int i = 0; i < n; i++) begin
      int localErrCount; ta_readWord(clk, empty, rd_en, rd_data, localErrCount); errors_added += localErrCount;
    end
  endtask

  // Receive one packet
  task ta_receiveOnePacket(
    input  int               numWordsInPacket,
    input  bit               clk,
    input  bit               empty,
    output bit               rd_en,
    input  logic [WIDTH-1:0] rd_data,
    input  bit               flush,
    output int               rxPacketId,
    output int               errors_added
  );
    logic [WIDTH-1:0] data;
    errors_added = 0;
    for (int i=0; i<numWordsInPacket; i++) begin
      int localErrCount;
      if (empty) wait (!empty);
      @(negedge clk); rd_en = 1'b1;
      @(posedge clk) data = rd_data;
      sb.ta_popAndCheck(data, localErrCount); errors_added += localErrCount;
      if (i == 0) rxPacketId = data;
    end
    @(negedge clk); rd_en = 1'b0;
  endtask

  // Background RX model. Call once; it will run forever and react to posedge of eif.rxTrig.
  task run(
    ref    int               currentPacketRxNum,
    ref    int               rxPacketId,
    ref    int               errorCnt,
    ref    int               packetAck[$],
    input  int               numWordsInPacket,
    input  int               numCyclesToProcessPacket,
    input  bit               clk,
    input  bit               flush,
    output bit               rd_en,
    input  logic [WIDTH-1:0] rd_data,
    input  bit               empty
  );
    forever begin
      @(posedge eif.rxTrig);
      fork
        begin : receivePacket
          int localErrors, id;
          ta_receiveOnePacket(numWordsInPacket, clk, empty, rd_en, rd_data, flush, id, localErrors);
          rxPacketId = id;
          errorCnt  += localErrors;
          repeat (numCyclesToProcessPacket) @(posedge clk);
          $display ("%t : RX packet processed %0d with ID %0d", $realtime, currentPacketRxNum, rxPacketId);
          packetAck.push_back(rxPacketId);
          #1;
          currentPacketRxNum++;
        end : receivePacket

        begin : waitForFlush
          wait (flush);
          $display ("**** %t : RX packet %0d (ID=%0d) flushed.", $realtime, currentPacketRxNum, rxPacketId);
          @(negedge clk) rd_en = 1'b0;
          wait (!flush);
        end : waitForFlush
      join_any
      disable fork;
      eif.rxDone = 1;
      wait (eif.rxTrig === 0);
      #1ns; eif.rxDone = 0;
    end
  endtask
endclass

