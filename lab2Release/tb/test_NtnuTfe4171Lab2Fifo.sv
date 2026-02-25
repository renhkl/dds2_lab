//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================
// Top-level testbench module integrating classes

/*
class tb_top;
// virtual interface declaration
virtual If_Dut if_Fifo;
// point virtual interface to actual interface in constructor
function new (virtual If_Dut vif);
this.if_Fifo = vif;
endfunction
endclass

frame tb_top;
initial tb_top = new (tb_dut_interface_inst);
*/


module test_NtnuTfe4171Lab2Fifo;

  localparam WIDTH = 8;
  localparam DEPTH = 32;

  // Interfaces
  if_Fifo    #(WIDTH) tb_if();
  if_TbEvents         ev_if();

/*
  virtual if_Fifo tb_if;
  // point virtual interface to actual interface in constructor
  function new (virtual if_Fifo vif);
  this.tb_if = vif;
  endfunction

  if_Fifo tb_if;
  initial tb_if = new (tb_dut_interface_inst);
  */
virtual if_Fifo vif;

  // DUT
  NtnuTfe4171Lab1Fifo #(
    .WIDTH (WIDTH),
    .DEPTH (DEPTH)
  ) u_NtnuTfe4172Lab1Fifo (
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
  cl_FifoWriter #(WIDTH) writer = new(sb, ev_if.writer, utils, tb_if.writer);
  cl_FifoReader #(WIDTH) reader = new(sb, ev_if.reader, tb_if.reader);
  
  
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


  //CONCURRENT ASSERTIONS

property empty_after_flush_property;
  @(posedge tb_if.clk) (tb_if.flush |=> tb_if.empty);
endproperty

 empty_after_flush_assert: assert property(empty_after_flush_property) $display("YES1");
        else begin
          $display("[%0t] ERROR1: empty should be 1 after flush", $time);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end

property not_full_after_flush_property; 
  @(posedge tb_if.clk) (tb_if.flush |=> !tb_if.full);
endproperty

not_full_after_flush_assert: assert property(not_full_after_flush_property) $display("YES2");
        else begin
          $display("[%0t] ERROR2: full should be 0 after flush", $time);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end


property not_empty_after_write_property;
  @(posedge tb_if.clk) disable iff (tb_if.arst) (tb_if.wr_en |=> !tb_if.empty);
endproperty

 not_empty_after_write_assert: assert property(not_empty_after_write_property) $display("YES3");
        else begin
          $display("[%0t] ERROR3: empty should be deasserted after wr_en", $time);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end

//cannot read empty fifo empty -> !rd_en
//full -> !wr_en

property cannot_read_empty_fifo_property;
  @(posedge tb_if.clk) (tb_if.full |-> !tb_if.wr_en);
endproperty

 cannot_read_empty_fifo_assert: assert property(cannot_read_empty_fifo_property) $display("YES4");
        else begin
          $display("[%0t] ERROR4: en empty FIFO cannot be read", $time);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end

/*
property write_data_is_zero_if_write_enable_is_deasserted_property;
  @(posedge tb_if.clk) (!tb_if.wr_en |-> !tb_if.wr_data || tb_if.wr_data == 8'bx);
endproperty

 write_data_is_zero_if_write_enable_is_deasserted_assert: assert property(write_data_is_zero_if_write_enable_is_deasserted_property) $display("YES4");
        else begin
          $display("[%0t] ERROR4: wr_data should be zero if wr_en is deasserted %d %d", $time, tb_if.wr_en, tb_if.wr_data);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end


property delay_between_each_read_enable_property; 
  @(posedge tb_if.clk) (tb_if.rd_en |=> !tb_if.rd_en);
endproperty

 delay_between_each_read_enable_assert: assert property(delay_between_each_read_enable_property)  $display("YES4");
        else begin
          $display("[%0t] ERROR4: there's no delay between each rd_en during reader operation", $time);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end


property write_enable_asserted_then_read_enable_deasserted_property; 
  @(posedge tb_if.clk) disable iff (tb_if.arst) (tb_if.wr_en |-> !tb_if.rd_en);
endproperty

 write_enable_asserted_then_read_enable_deasserted_assert:  assert property(write_enable_asserted_then_read_enable_deasserted_property)  $display("YES5");
        else begin
          $display("[%0t] ERROR5: if wr_en is asserted, rd_en cannot be asserted in the same clock cycle %d %d", $time, tb_if.wr_en, tb_if.rd_en);
          errorCnt = errorCnt + 1;
          //$fatal(1);
        end
*/


//COVER STATEMENTS

property empty_after_flush_antecedent_property;
  @(posedge tb_if.clk) (tb_if.flush);
endproperty


property not_full_after_flush_antecedent_property; 
  @(posedge tb_if.clk) (tb_if.flush);
endproperty

property not_empty_after_write_antecedent_property;
  @(posedge tb_if.clk) (tb_if.rd_en);
endproperty

cover property(empty_after_flush_antecedent_property) $display("empty_after_flush_property happens");
cover property(not_full_after_flush_antecedent_property) $display("not_full_after_flush_property happens");
cover property(not_empty_after_write_antecedent_property) $display("not_empty_after_write_property happens");


//COVER GROUPS

covergroup cg @(posedge tb_if.clk);
        c1: coverpoint tb_if.wr_data { 
          bins zeros = {'0};
          bins ones = {'1};
          bins non_zeros = {[8'h01:8'hfe]}; //??
        }

        c2: coverpoint tb_if.wr_en;

        wr_en_X_wr_data: cross c1, c2; //??

endgroup: cg

//instantiate and create covergroup
cg cg_inst = new();

  // Clock 16 MHz
  realtime clock_period = (1s/16e6);
  initial begin 
    tb_if.clk = 0; 
    forever 
      #(clock_period/2.0) 
      tb_if.clk = !tb_if.clk; 
    end
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
                 tb_if.flush, tb_if.rd_en, tb_if.rd_data, tb_if.empty);
    join_none
  end

  // Tests (unchanged behavior, but use utils.ta_flushFifo instead of task)
  initial begin
    int localErrCnt1, localErrCnt2, localErrCnt3;
    wait (resetComplete);
    #10;

    // 1) burst write partial packet (e.g. 16 bytes) then read back
    writer.ta_writeBurst(16, 8'h10, tb_if.clk, tb_if.full, tb_if.wr_en, tb_if.wr_data);
    reader.ta_readBurst(16, tb_if.empty, tb_if.rd_en, tb_if.rd_data, localErrCnt1);
    errorCnt += localErrCnt1;
    #1; if (!tb_if.empty) begin $display("[%0t] ERROR: (1) FIFO should be empty after equal write/read", $time); errorCnt++; $error; end
        else                    $display("[%0t] SUCCESS: (1) FIFO data pushed and emptied after equal write/read\n", $time);

    // removing test-vector 2 to simplify Lab2 - can bring back for increased testing.

    // 2) Write near-full, then flush
    writer.ta_writeBurst(DEPTH - 2, 8'h20, tb_if.clk, tb_if.full, tb_if.wr_en, tb_if.wr_data);
    if (tb_if.empty) begin $display("[%0t] ERROR: (2) FIFO should not be empty after writes", $time); errorCnt++; $error; end
    else $display("[%0t] SUCCESS: (2) FIFO data pushed and empty de-asserted\n", $time);
    utils.ta_flushFifo(errorCnt);


    // Attempt to read after flush
    reader.ta_readBurst(4, tb_if.empty, tb_if.rd_en, tb_if.rd_data, localErrCnt2);
    errorCnt += localErrCnt2;

    // removing test-vector 3 to simplify Lab2 - can bring back for increased testing.
/*
    // 3) Fill to full, then drain and compare
    writer.ta_writeBurst(DEPTH, 8'h40, tb_if.clk, tb_if.full, tb_if.wr_en, tb_if.wr_data);
    @(posedge tb_if.clk);
    if (!tb_if.full) begin
      $display("[%0t] WARNING: (3a) full is not asserted after DEPTH writes (check pointer/flag logic)", $time); end
    else        $display("[%0t] SUCCESS: (3a) FIFO filled and full asserted\n", $time);
    reader.ta_readBurst(DEPTH, tb_if.clk, tb_if.empty, tb_if.rd_en, tb_if.rd_data, localErrCnt3);
    errorCnt += localErrCnt3;
    #1; 
    if (!tb_if.empty) begin 
      $display("[%0t] ERROR: (3b) FIFO should be empty after draining", $time); errorCnt++; $error; end
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
          wait ((tb_if.empty === 0) && (tb_if.flush == 0) ); #1;
          //-> ev_if.rxTrig;

          ev_if.rxTrig = 1; #1;
          wait (ev_if.rxDone == 1); 
          ev_if.rxTrig = 0; 
          wait (ev_if.rxDone == 0); 
          #1ns;
        end
      end
    join_any

    #(NUM_PACKETS_TO_TRANSMIT * packetTimeoutVal); #1; 
    #10;
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

