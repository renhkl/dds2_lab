//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================


// =========================================
// cl_FifoReader : tasks take DUT/event signals as args
// =========================================
class cl_FifoReader #(parameter int WIDTH = 8) extends cl_TbUtils; 
  local virtual if_TbEvents.reader  eif;


  function new(
    cl_Scoreboard #(WIDTH) sb,
    virtual if_TbEvents.reader  eif,
    virtual if_Fifo vif
  );
    super.new(vif, sb);
    this.eif = eif;
  endfunction

  // Single word read
  task ta_readWord(
    input  bit               empty,
    output bit               rd_en,
    input  logic [WIDTH-1:0] rd_data,
    output int               errors_added
  );
    errors_added = 0;
    @(posedge vif.clk);
    if (!vif.empty) begin
      vif.rd_en = 1'b1;
    end else begin
      vif.rd_en = 1'b0;
    end
    @(posedge vif.clk);
    if (vif.rd_en && !vif.empty) begin
      int localErrCount;
      sb.ta_popAndCheck(vif.rd_data, localErrCount);
      errors_added += localErrCount;
    end
    vif.rd_en = 1'b0;
  endtask

  // Burst read
  task ta_readBurst(
    input  int               n,
    input  bit               empty,
    output bit               rd_en,
    input  logic [WIDTH-1:0] rd_data,
    output int               errors_added
  );
    errors_added = 0;
    for (int i = 0; i < n; i++) begin
      int localErrCount; 
      ta_readWord(vif.empty, vif.rd_en, vif.rd_data, localErrCount); 
      errors_added += localErrCount;
    end
  endtask

  // Receive one packet
  task ta_receiveOnePacket(
    input  int               numWordsInPacket,
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
      if (vif.empty) wait (!vif.empty);
      @(negedge vif.clk); vif.rd_en = 1'b1;
      @(posedge vif.clk) data = vif.rd_data;
      sb.ta_popAndCheck(data, localErrCount); errors_added += localErrCount;
      if (i == 0) rxPacketId = data;
    end
    @(negedge vif.clk); vif.rd_en = 1'b0;
  endtask

  // Background RX model. Call once; it will run forever and react to posedge of eif.rxTrig.
  task run(
    ref    int               currentPacketRxNum,
    ref    int               rxPacketId,
    ref    int               errorCnt,
    ref    int               packetAck[$],
    input  int               numWordsInPacket,
    input  int               numCyclesToProcessPacket,
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
          $display ("%t : RX packet processing %0d with ID %0d", $realtime, currentPacketRxNum, rxPacketId);
          ta_receiveOnePacket(numWordsInPacket, vif.empty, vif.rd_en, vif.rd_data, vif.flush, id, localErrors);
          rxPacketId = id;
          errorCnt  += localErrors;
          repeat (numCyclesToProcessPacket) @(posedge vif.clk);
          $display ("%t : RX packet processed %0d with ID %0d", $realtime, currentPacketRxNum, rxPacketId);
          packetAck.push_back(rxPacketId);
          #1;
          currentPacketRxNum++;
        end : receivePacket

        begin : waitForflush
          wait (vif.flush);
          $display ("**** %t : RX packet %0d (ID=%0d) flushed.", $realtime, currentPacketRxNum, rxPacketId);
          @(negedge vif.clk) vif.rd_en = 1'b0;
          wait (!vif.flush);
        end : waitForflush
      join_any
      disable fork;
      eif.rxDone = 1;
      wait (eif.rxTrig === 0);
      #1ns; eif.rxDone = 0;
    end
  endtask
endclass

