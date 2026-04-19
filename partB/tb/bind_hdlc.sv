//////////////////////////////////////////////////
// Title:   bind_hdlc
// Author:  Karianne Krokan Kragseth
// Date:    20.10.2017
//////////////////////////////////////////////////

module bind_hdlc ();

  bind test_hdlc assertions_hdlc u_assertion_bind(
    .ErrCntAssertions (uin_hdlc.ErrCntAssertions),
    .Clk              (uin_hdlc.Clk),
    .Rst              (uin_hdlc.Rst),
    .Rx               (uin_hdlc.Rx),


.Rx_ValidFrame    (uin_hdlc.Rx_ValidFrame),
.Rx_WrBuff (uni)
    .Rx_FlagDetect    (uin_hdlc.Rx_FlagDetect),
    
    .Rx_AbortDetect   (uin_hdlc.Rx_AbortDetect),
    .Rx_AbortSignal   (uin_hdlc.Rx_AbortSignal),
    .Rx_Overflow      (uin_hdlc.Rx_Overflow),
    .Rx_WrBuff        (uin_hdlc.Rx_WrBuff)
      (uin_hdlc.Rx_ValidFrame)      = u_dut.Rx_ValidFrame;
   uin_hdlc.Rx_WrBuff          = u_dut.Rx_WrBuff;
   uin_hdlc.Rx_EoF             = u_dut.Rx_EoF;
  assign uin_hdlc.Rx_AbortSignal     = u_dut.Rx_AbortSignal;
  assign uin_hdlc.Rx_StartZeroDetect = u_dut.Rx_StartZeroDetect;
  assign uin_hdlc.Rx_FrameError      = u_dut.Rx_FrameError;
  assign uin_hdlc.Rx_StartFCS        = u_dut.Rx_StartFCS;
  assign uin_hdlc.Rx_StopFCS         = u_dut.Rx_StopFCS;
  assign uin_hdlc.Rx_Data            = u_dut.Rx_Data;
  assign uin_hdlc.Rx_NewByte         = u_dut.Rx_NewByte;
  assign uin_hdlc.Rx_FlagDetect      = u_dut.Rx_FlagDetect;
  assign uin_hdlc.Rx_AbortDetect     = u_dut.Rx_AbortDetect;
  assign uin_hdlc.RxD                = u_dut.RxD;
  assign uin_hdlc.Rx_FCSerr          = u_dut.Rx_FCSerr;
  //assign uin_hdlc.Rx_Ready           = u_dut.Rx_Ready; //missing
  assign uin_hdlc.Rx_FrameSize       = u_dut.Rx_FrameSize;
  assign uin_hdlc.Rx_Overflow        = u_dut.Rx_Overflow;
  assign uin_hdlc.Rx_DataBuffOut     = u_dut.Rx_DataBuffOut;
  assign uin_hdlc.Rx_FCSen           = u_dut.Rx_FCSen;
  assign uin_hdlc.Rx_RdBuff          = u_dut.Rx_RdBuff;
  assign uin_hdlc.Rx_Drop            = u_dut.Rx_Drop;
  assign uin_hdlc.ZeroDetect         = u_dut.u_RxChannel.ZeroDetect;

  //Tx
  assign uin_hdlc.Tx_ValidFrame      = u_dut.Tx_ValidFrame;
  assign uin_hdlc.Tx_AbortedTrans    = u_dut.Tx_AbortedTrans;
  assign uin_hdlc.Tx_WriteFCS        = u_dut.Tx_WriteFCS;
  assign uin_hdlc.Tx_InitZero        = u_dut.Tx_InitZero;
  assign uin_hdlc.Tx_StartFCS        = u_dut.Tx_StartFCS;
  assign uin_hdlc.Tx_RdBuff          = u_dut.Tx_RdBuff;
  assign uin_hdlc.Tx_NewByte         = u_dut.Tx_NewByte;
  assign uin_hdlc.Tx_FCSDone         = u_dut.Tx_FCSDone;
  assign uin_hdlc.Tx_Data            = u_dut.Tx_Data;
  assign uin_hdlc.Tx_Done            = u_dut.Tx_Done;
  assign uin_hdlc.Tx_Full            = u_dut.Tx_Full;
  assign uin_hdlc.Tx_DataAvail       = u_dut.Tx_DataAvail;
  assign uin_hdlc.Tx_FrameSize       = u_dut.Tx_FrameSize;
  assign uin_hdlc.Tx_DataArray       = u_dut.Tx_DataArray;
  assign uin_hdlc.Tx_DataOutBuff     = u_dut.Tx_DataOutBuff;
  assign uin_hdlc.Tx_WrBuff          = u_dut.Tx_WrBuff;
  assign uin_hdlc.Tx_Enable          = u_dut.Tx_Enable;
  assign uin_hdlc.Tx_DataInBuff      = u_dut.Tx_DataInBuff;
  assign uin_hdlc.Tx_AbortFrame      = u_dut.Tx_AbortFrame;

  );

endmodule
