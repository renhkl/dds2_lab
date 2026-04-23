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
  input  logic RxEN,
  input  logic Tx,
  input  logic TxEN,

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
    !Rx ##1 Rx[*6] ##1 !Rx; //0111 1110
  endsequence

  // Check if flag sequence is detected
  property RX_FlagDetect;
    @(posedge Clk) Rx_flag |-> ##2 Rx_FlagDetect;
  endproperty

  RX_FlagDetect_Assert : assert property (RX_FlagDetect) begin
    $display("PASS: RX Flag detect");
  end else begin 
    $error("FAIL: RX flag sequence did not generate FlagDetect"); 
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
    @(posedge Clk) Rx_ValidFrame && Rx_AbortDetect |=> Rx_AbortSignal; 
    //@(posedge Clk) Rx_ValidFrame throughout Abort_Flag |=> Rx_AbortSignal;   
    //@(posedge Clk) Abort_Flag ##1 Rx_ValidFramSe && Rx_AbortDetect |=> Rx_AbortSignal; 
  endproperty

  RX_AbortSignal_Assert : assert property (RX_AbortSignal) begin
    $display("PASS: Rx_AbortSignal asserted");
  end else begin 
    $error("FAIL: Rx_AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end


/********************************************
   * Part B - Assertion 5    *
   ********************************************/

   //Tx_ValidFrame throughout Tx_Flag; 

  sequence Tx_Flag;
    !Tx ##1 Tx[*6] ##1 !Tx; //0111_1110
  endsequence

  property Tx_Flag_Pattern_Start;
    @(posedge Clk) $rose(Tx_ValidFrame) |-> ##2 Tx_Flag; 
  endproperty

  property Tx_Flag_Pattern_End;
    @(posedge Clk) disable iff(!Rst) $fell(Tx_ValidFrame) && !Tx_AbortedTrans |=> Tx_Flag; 
  endproperty

  Tx_Flag_Pattern_Start_Assert : assert property (Tx_Flag_Pattern_Start) begin
    $display("PASS: TX Flag pattern");
  end else begin 
    $error("FAIL TX flag not detected (start)"); 
    ErrCntAssertions++; 
  end

    Tx_Flag_Pattern_End_Assert : assert property (Tx_Flag_Pattern_End) begin
    $display("PASS: TX Flag pattern");
  end else begin 
    $error("FAIL: TX flag not detected (end)"); 
    ErrCntAssertions++; 
  end


/********************************************
   *Part B - Assertion 8  *
   ********************************************/

  sequence Tx_Abort_Flag;
    !Tx ##1 Tx[*7]; //0111 1111
  endsequence

  property Tx_Abort_Pattern; 
    @(posedge Clk) $rose(Tx_AbortFrame) |=> ##3 Tx_Abort_Flag; 
  endproperty


  Tx_Abort_Pattern_Assert : assert property (Tx_Abort_Pattern) begin
    $display("PASS: TX abort pattern");
  end else begin 
    $error("FAIL: TX abort pattern didn't happen on abort"); 
    ErrCntAssertions++; 
  end



  /********************************************
   *Part B - Assertion 6  * Kanskje scrap
   ********************************************/
  /*
  sequence FiveOnesTx;
    Tx[*5] ##1 !Tx;
  endsequence

  property TX_ZeroInsertion;
    @(posedge Clk) Tx_ValidFrame
    ##8 FiveOnesTx 
    ##8 !Tx_ValidFrame//&& !Tx_AbortFrame 
    |-> !Tx; 
  endproperty

  Hvis 5 enere er sett, og TX ikke er idle eller aborted eller på flag i frame så burde den være aktiv?
  Burde kanskje se på TxEN for å finne ut om man er i starten av et flag, og kanskje sjekke om 6 enere
  kanskje følges av en end-of-frame tag i Tx. 

  Hittil bare sjekk for zeroinsertion, abort, og idle. 
  */


 /********************************************
   * Part B - Assertion 10   *
  ********************************************/

  sequence Rx_Abort_Flag;
   !Rx  ##1 Rx[*7] ; //0111 1111, this is abort on the receive side
  endsequence

  property Rx_Abort_Pattern_AbortSignal; 
    @(posedge Clk) Rx_ValidFrame throughout Rx_Abort_Flag |-> ##3 Rx_AbortSignal; 
  endproperty


  Rx_Abort_Pattern_AbortSignal_Assert : assert property (Rx_Abort_Pattern_AbortSignal) begin
    $display("PASS: Rx_AbortSignal asserted after abort pattern");
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
    $display("PASS: Tx_AbortedTrans asserted");
  end else begin 
    $error("FAIL: Tx_AbortedTrans did not go high after Tx_AbortFrame"); 
    ErrCntAssertions++; 
  end


  /********************************************
   *  Part B - Assertion 7   *
   ********************************************/

  sequence Rx_Idle_Pattern;
    Rx[*8]; //1111 1111
  endsequence

  sequence Tx_Idle_Pattern;
    Tx[*8]; //1111 1111
  endsequence

  property Tx_Idle_Pattern_Disruptions;
    @(posedge Clk) !Tx_ValidFrame and 
    TxEN |=> 
    Tx;
  endproperty

  Idle_Pattern_Assert : assert property (Tx_Idle_Pattern_Disruptions) begin
      //$display("PASS: IDLE IS GOOD asserted");
      ;
    end else begin 
      $error("FAIL: Idle pattern was broken");
      ErrCntAssertions++; 
  end

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


  /********************************************
   *  Part B - Assertion 17   *
   ********************************************/

   //Tx_RdBuff ##8 !Tx_RdBuff |=> Tx_Done;

  property Tx_Done_Reading_Transmit;
    @(posedge Clk) disable iff (!Rst) $fell(Tx_RdBuff) ##[0:1] Tx_Done |=> !Tx_DataAvail;
  endproperty


  Tx_Done_Reading_Transmit_Assert : assert property (Tx_Done_Reading_Transmit) begin
    $display("PASS: Tx_Done asserted after reading buffer for transmit");
  end else begin 
    $error("FAIL: Tx_Done NOT asserted after reading buffer for transmit"); 
    ErrCntAssertions++; 
  end
  

  /********************************************
   *  Part B - Assertion 18   *
   ********************************************/

   //$fell(Tx_WrBuff) ##1 $stable(Tx_WrBuff). it gets asserted before wrbuff is finished
   //@(posedge Clk)  Tx_Full |-> ##6 Tx_DataAvail && (Tx_FrameSize == 126); //this is spammy and prints several times

  property Tx_Full_126;
    @(posedge Clk) disable iff(!Rst) $fell(Tx_Full) |-> Tx_DataAvail && (Tx_FrameSize == 126);
  endproperty

  Tx_Full_126_Assert : assert property (Tx_Full_126) begin
    $display("PASS: Tx_Full asserted after writing 126 bytes");
  end else begin 
    $error("FAIL: Tx_Full NOT asserted after writing 126 bytes"); 
    ErrCntAssertions++; 
  end

endmodule
