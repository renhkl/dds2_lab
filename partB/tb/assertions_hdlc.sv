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
  output int   ErrCntAssertions, //concurrent errors
  input  logic Clk,
  input  logic Rst,
  input  logic Rx,
  input  logic Tx,

  input logic       Rx_ValidFrame,
  input logic       Rx_WrBuff,
  input logic       Rx_EoF,
  input logic       Rx_AbortSignal,
  input logic       Rx_StartZeroDetect,
  input logic       Rx_FrameError,
  input logic       Rx_StartFCS,
  input logic       Rx_StopFCS,
  input  logic [7:0] Rx_Data,
  input logic       Rx_NewByte,
  input logic       Rx_FlagDetect,
  input logic       Rx_AbortDetect,
  input logic       RxD,
  input logic       Rx_FCSerr,
  input logic       Rx_Ready,
  input logic [7:0] Rx_FrameSize,
  input logic       Rx_Overflow,
  input logic [7:0] Rx_DataBuffOut,
  input logic       Rx_FCSen,
  input logic       Rx_RdBuff,
  input logic       Rx_Drop,
  input logic       ZeroDetect,

  //Tx
  input logic Tx_ValidFrame,
  input logic Tx_AbortedTrans,
  input logic Tx_WriteFCS,
  input logic Tx_InitZero,
  input logic Tx_StartFCS,
  input logic Tx_RdBuff,
  input logic Tx_NewByte,
  input logic Tx_FCSDone,
  input logic [7:0] Tx_Data,
  input logic Tx_Done,
  input logic Tx_Full,
  input logic Tx_DataAvail,
  input logic [7:0] Tx_FrameSize,
  input logic [127:0][7:0] Tx_DataArray,
  input logic [7:0] Tx_DataOutBuff,
  input logic Tx_WrBuff,
  input logic Tx_Enable,
  input logic [7:0] Tx_DataInBuff,
  input logic Tx_AbortFrame



);

  initial begin
    ErrCntAssertions  =  0;
  end

  /*******************************************
   * Part A - Verify correct Rx_FlagDetect behavior  *
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
   *  Part A - Verify correct Rx_AbortSignal behavior  *
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
   * Part B - Assertion 5    *
   ********************************************/

   //Tx_ValidFrame throughout Tx_Flag; 

  sequence Tx_Flag;
    !Tx ##1 Tx[*6] ##1 !Tx; //0111_1110
  endsequence

  property TX_Flag_Pattern_Start;
    @(posedge Clk) $rose(Tx_ValidFrame) |-> ##2 Tx_Flag; 
  endproperty

  property TX_Flag_Pattern_End;
    @(posedge Clk) $fell(Tx_ValidFrame) |=> Tx_Flag; 
  endproperty

  TX_Flag_Pattern_Start_Assert : assert property (TX_Flag_Pattern_Start) begin
    $display("PASS: TX Flag pattern");
  end else begin 
    $error("Tx flag not detected"); 
    ErrCntAssertions++; 
  end

    TX_Flag_Pattern_End_Assert : assert property (TX_Flag_Pattern_End) begin
    $display("PASS: TX Flag pattern");
  end else begin 
    $error("Tx flag not detected"); 
    ErrCntAssertions++; 
  end


/********************************************
   *Part B - Assertion 8  *
   ********************************************/

//need to change the error messsage and property

  sequence Tx_Abort_Flag;
    Tx[*7]  ##1 !Tx; //1111 1110
  endsequence

  property TX_Abort_Pattern; 
    @(posedge Clk) $rose(Tx_AbortedTrans) |=> Tx_Abort_Flag; 
  endproperty


  TX_Abort_Pattern_Assert : assert property (TX_Abort_Pattern) begin
    $display("PASS: Tx abort pattern");
  end else begin 
    $error("FAIL: Tx abort pattern didn't happen on abort"); 
    ErrCntAssertions++; 
  end



  /********************************************
   *Part B - Assertion 6  *
   ********************************************/
  /*
  sequence ZeroInsertionBitTx;
    Tx[*5];
  endsequence


  property TX_ZeroInsertion;
    @(posedge Clk) TX_ZeroInsertion && !TxEN && !Tx_AbortFrame |=> !Tx; 
  endproperty

  Hvis 5 enere er sett, og TX ikke er idle eller aborted eller på flag i frame så burde den være aktiv?
  Burde kanskje se på TxEN for å finne ut om man er i starten av et flag, og kanskje sjekke om 6 enere
  kanskje følges av en end-of-frame tag i Tx. 

  Hittil bare sjekk for zeroinsertion, abort, og idle. 


  */
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
   * Part B - Assertion 10   *
   ********************************************/

  sequence Rx_Abort_Flag;
   !Rx  ##1 Rx[*7] ; //0111 1111, this is abort on the receive side
  endsequence

  property RX_Abort_Pattern_AbortSignal; 
    @(posedge Clk) Rx_ValidFrame throughout Rx_Abort_Flag |-> ##3 Rx_AbortSignal; 
  endproperty


  RX_Abort_Pattern_AbortSignal_Assert : assert property (RX_Abort_Pattern_AbortSignal) begin
    $display("PASS: RX_AbortSignal asserted after abort pattern");
  end else begin 
    $error("FAIL: Rx_AbortSignal did not go high after abort pattern during Rx_ValidFrame"); 
    ErrCntAssertions++; 
  end
  

    /********************************************
   *  Part B - Assertion 9   *
   ********************************************/



  property TX_AbortedTrans;
    @(posedge Clk) Tx_AbortFrame |-> ##2 Tx_AbortedTrans; 
  endproperty

  TX_AbortedTrans_Assert : assert property (TX_AbortedTrans) begin
    $display("PASS: TX_AbortedTrans asserted");
  end else begin 
    $error("Tx_AbortedTrans did not go high after Tx_AbortFrame"); 
    ErrCntAssertions++; 
  end

//trenger denne å passe på at den ikke er idle også kanskje?

    /********************************************
   *  Part B - Assertion 7   *
   ********************************************/
  sequence Rx_Idle_Pattern;
    Rx[*8]; //1111 1111
  endsequence

  sequence Tx_Idle_Pattern;
    Tx[*8]; //1111 1111
  endsequence


      /********************************************
   *  Part B - Assertion 12   *
   ********************************************/

  property RX_EoF;
    @(posedge Clk) Rx_FlagDetect ##4 $fell(Rx_ValidFrame) |=> Rx_EoF; 
  endproperty

  RX_EoF_Assert : assert property (RX_EoF) begin
    $display("PASS: Rx_EoF asserted");
  end else begin 
    $error("FAIL: Rx_EoF not asserted after receiving a whole frame"); 
    ErrCntAssertions++; 
  end

endmodule
