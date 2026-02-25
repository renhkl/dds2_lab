//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================

// =========================================
// cl_FifoWriter : tasks take DUT signals as args
// =========================================
class cl_FifoWriter #(parameter int WIDTH = 8); //extends cl_TbUtils; //extends cl_TbUtils(ta_flushFifo);
  local virtual if_TbEvents.writer eif;
  local virtual if_Fifo vif;
  local cl_Scoreboard #(WIDTH) sb;
  local cl_TbUtils    #(WIDTH) utils;

  function new(

    cl_Scoreboard #(WIDTH)      sb,
    virtual if_TbEvents.writer  eif,
    cl_TbUtils   #(WIDTH)       utils, 
    virtual if_Fifo vif
  );
    this.sb    = sb;
    this.eif   = eif;
    this.utils = utils;
    this.vif = vif;
  endfunction

  // Single word write
  task ta_writeWord(
    ref logic               clk,
    input  bit               full,
    output bit               wr_en,
    output logic [WIDTH-1:0] wr_data,
    input  logic [WIDTH-1:0] data
  );
    $display ("Time %t, %m", $realtime);
    @(posedge vif.clk);
    $display("ta_writeWord: clk: %d full: %d wr_en: %d wr_data: %d data: %d", vif.clk, vif.full, wr_en, wr_data, data);
    $display ("%t, clock edge", $realtime);
    if (!vif.full) begin
      vif.wr_en   = 1'b1;
      vif.wr_data = data;
      //$display("ta_writeWord: %t %t", wr_data, data);
      $display("ta_writeWord: clk: %d full: %d wr_en: %d wr_data: %d data: %d", vif.clk, vif.full, vif.wr_en, vif.wr_data, data);
      sb.ta_queuePush(data);
    end 
    else begin
      vif.wr_en   = 1'b0;
      vif.wr_data = '0;
    end
    @(posedge vif.clk);
    vif.wr_en   = 1'b0;
    vif.wr_data = '0;
    $display("ta_writeWord finished");
  endtask

  // Burst write
  task ta_writeBurst(
    input  int               n,
    input  int               seed,
    ref logic                clk,
    input  bit               full,
    output bit               wr_en,
    //output logic [WIDTH-1:0] data, //nothigi
    output logic [WIDTH-1:0] wr_data
  );
    $display("ta_writeburst_started");
    for (int i = 0; i < n; i++) begin
      logic [WIDTH-1:0] data = (seed + i) & {WIDTH{1'b1}};
      //$display("ta_writeBurst: %t %t", wr_data, data);
      $display("ta_writeBurst: n: %d seed: %d clk: %d vif.full: %d wr_en: %d", n, seed, vif.clk, vif.full, wr_en);
      ta_writeWord(vif.clk, vif.full, vif.wr_en, vif.wr_data, data);
      $display("ta_writeBurst finished");
    end
  endtask

  // Transmit one packet
  task ta_xmitOnePacket(
    ref    int               currentPacketTxNum,
    input  int               numWordsInPacket,
    ref logic                clk,
    input  bit               full,
    input  bit               flush,
    output bit               wr_en,
    output logic [WIDTH-1:0] wr_data
  );
    logic [WIDTH-1:0] data = $urandom_range(0, 'h80);
    $display ("\n\n**** %t : TX starting new packet %0d", $realtime, currentPacketTxNum);
    for (int i = 0; i < numWordsInPacket; i++) begin
      data = (data + i) & {WIDTH{1'b1}};
      if (vif.full) begin
        wait (!vif.full);
      end
      @(negedge vif.clk);
      vif.wr_en = 1'b1;
      if (i == 0) begin
        vif.wr_data = currentPacketTxNum[WIDTH-1:0];
        sb.ta_queuePush(currentPacketTxNum[WIDTH-1:0]);
      end else begin
        vif.wr_data = data;
        sb.ta_queuePush(data);
      end
    end
    @(negedge vif.clk);
    vif.wr_en  = 1'b0;
    vif.wr_data = '0;
    $display ("%t : TX packet sent %0d", $realtime, currentPacketTxNum);
  endtask

  // Background TX model. Call once; it will run forever and react to eif.tx.
  task run(
    ref    int               currentPacketTxNum,
    ref    int               errorCnt,
    ref    int               packetAck[$],
    input  int               numWordsInPacket,
    input  realtime          packetTimeoutVal,
    ref logic                clk,
    input  bit               flush,
    input  bit               full,
    input  bit               empty,
    output bit               wr_en,
    output logic [WIDTH-1:0] wr_data
  );
    forever begin
      @(eif.tx);
      // Two independent behaviors that used to be separate always blocks
      fork
        begin : tx_proc_A
          // sendPacket + waitForflushWhileTx
          fork
            begin : sendPacket
              ta_xmitOnePacket(currentPacketTxNum, numWordsInPacket, vif.clk, vif.full, vif.flush, wr_en, wr_data);
            end : sendPacket
            begin : waitForflushWhileTx
              $display ("%t : TX packet sending", $realtime);
              wait (vif.flush);
              $display ("**** %t : TX packet %0d flushed waiting for TX to complete.", $realtime, currentPacketTxNum);
              vif.wr_en = 1'b0;
            end : waitForflushWhileTx
          join_any
          disable fork;
          wait (!vif.flush);
          currentPacketTxNum++;
        end : tx_proc_A

        begin : tx_proc_B
          automatic int thisPacketIndex = currentPacketTxNum;
          // timeout / ack / flush-wait trio
          fork
            begin : transmitPacketAndWaitForTimeout
              #(packetTimeoutVal);
              $display ("%t : TX timeout detected %0d", $realtime, thisPacketIndex);
              errorCnt++;
              $error;
              //ta_flushFifo(errorCnt);
            end : transmitPacketAndWaitForTimeout

            begin : waitForAckInTx
              wait ( (packetAck.size() >= 1) && (packetAck[0] === thisPacketIndex) );
              #1 packetAck.pop_front();
              $display ("%t : TX ack received %0d", $realtime, thisPacketIndex);
            end : waitForAckInTx

            begin : waitForflushWhileRx
              wait (vif.flush);
              wait (!vif.flush);
            end : waitForflushWhileRx
          join_any
          disable fork;
        end : tx_proc_B
      join_none
    end
  endtask
endclass

