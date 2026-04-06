//////////////////////////////////////////////////
// Title:   assertions_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

/* The assertions_hdlc module is a test module containing the concurrent
   assertions. It is used by binding the signals of assertions_hdlc to the
   corresponding signals in the test_hdlc testbench. This is already done in
   bind_hdlc.sv 

   For this exercise you will write concurrent assertions for the Rx module:
   - Verify that Rx_FlagDetect is asserted two cycles after a flag is received
   - Verify that Rx_AbortSignal is asserted after receiving an abort flag
*/

module assertions_hdlc (
  output int   ErrCntAssertions,
  input  logic Clk,
  input  logic Rst,
  input  logic Rx,
  input  logic Rx_FlagDetect,
  input  logic Rx_ValidFrame,
  input  logic Rx_AbortDetect,
  input  logic Rx_AbortSignal,
  input  logic Rx_Overflow,
  input  logic Rx_WrBuff
);

  initial begin
    ErrCntAssertions  =  0;
  end

  /*******************************************
   *  Verify correct Rx_FlagDetect behavior  *
   *******************************************/

  sequence Rx_flag;
    // INSERT CODE HERE
    !Rx ##1 Rx[*6] ##1 !Rx; //0111 1110
  endsequence

  // Check if flag sequence is detected
  property RX_FlagDetect;
    @(posedge Clk) Rx_flag |-> ##2 Rx_FlagDetect;
  endproperty

  RX_FlagDetect_Assert : assert property (RX_FlagDetect) begin
    $display("PASS: Flag detect");
  end else begin 
    $error("Flag sequence did not generate FlagDetect"); 
    ErrCntAssertions++; 
  end

  /********************************************
   *  Verify correct Rx_AbortSignal behavior  *
   ********************************************/

  //If abort is detected during valid frame. then abort signal should go high

    sequence Abort_Flag;
    Rx[*7] ##1 !Rx && Rx_ValidFrame; //1111 1110
  endsequence


  property RX_AbortSignal;
    // INSERT CODE HERE
    @(posedge Clk) Rx_ValidFrame && Rx_AbortDetect |=> Rx_AbortSignal; 
    //@(posedge Clk) Rx_ValidFrame throughout Abort_Flag |=> Rx_AbortSignal;   
    //@(posedge Clk) Abort_Flag ##1 Rx_ValidFramSe && Rx_AbortDetect |=> Rx_AbortSignal; 
  endproperty

  RX_AbortSignal_Assert : assert property (RX_AbortSignal) begin
    $display("PASS: Abort signal");
  end else begin 
    $error("AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end

/********************************************
   *  Verify correct Rx_Abort_Pattern behavior  *
   ********************************************/

    /********************************************
   *  Verify correct Tx_Abort_Pattern behavior  *
   ********************************************/

//need to change the error messsage and property

  sequence Rx_Abort_Flag;
    Rx[*7] ##1 !Rx; //1111 1110
  endsequence

//  sequence TX_Abort_Flag
//    !Tx |=> Tx[*7]; //0111 1111
//  endsequence

/*

  property TX_Abort_Pattern;
    @(posedge Clk) Rx_ValidFrame && Rx_AbortDetect |=> Rx_AbortSignal; 
  endproperty

  RX_AbortSignal_Assert : assert property (TX_Abort_Pattern) begin
    $display("PASS: TX Abort pattern");
  end else begin 
    $error("AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end

  
  property RX_Abort_Pattern;
    @(posedge Clk) Rx_ValidFrame && Rx_AbortDetect |=> Rx_AbortSignal; 
  endproperty

  RX_AbortSignal_Assert : assert property (RX_Abort_Pattern) begin
    $display("PASS: RX Abort pattern");
  end else begin 
    $error("AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end
*/

 /********************************************
   *  Verify correct Rx_Abort_Pattern behavior  *
   ********************************************/

  property RX_Abort_Pattern_AbortSignal; //valid frame for the duration
    @(posedge Clk) Rx_Abort_Flag |=> Rx_AbortSignal; 
  endproperty

  RX_Abort_Pattern_AbortSignal_Assert : assert property (RX_Abort_Pattern_AbortSignal) begin
    $display("PASS: RX_AbortSignal asserted after abort pattern");
  end else begin 
    $error("AbortSignal did not go high after abort pattern during validframe"); 
    ErrCntAssertions++; 
  end

    /********************************************
   *  Verify correct Tx_Abort_Pattern behavior  *
   ********************************************/


/*
  property TX_Aborted_Trans;
    @(posedge Clk) Tx_AbortFrame |=> Tx_AbortedTrans; 
  endproperty

  TX_AbortedTrans_Assert : assert property (TX_Aborted_Trans) begin
    $display("PASS: TX AbortedTrans asserted");
  end else begin 
    $error("AbortedTrans did not go high after AbortFrame"); 
    ErrCntAssertions++; 
  end*/


  /*  sequence Rx_Idle_Pattern;
    Rx[*8]; //1111 1110
  endsequence

     sequence Tx_Idle_Pattern;
    Tx[*8]; //1111 1110
  endsequence*/

endmodule
