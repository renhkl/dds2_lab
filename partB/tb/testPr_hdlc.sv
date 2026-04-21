//////////////////////////////////////////////////
// Title:   testPr_hdlc
// Author: 
// Date:  
//////////////////////////////////////////////////

/* testPr_hdlc contains the simulation and immediate assertion code of the
   testbench. 

   For this exercise you will write immediate assertions for the Rx module which
   should verify correct values in some of the Rx registers for:
   - Normal behavior
   - Buffer overflow 
   - Aborts

   HINT:
   - A ReadAddress() task is provided, and addresses are documentet in the 
     HDLC Module Design Description
*/

program testPr_hdlc(
  in_hdlc uin_hdlc
);
  
  int TbErrorCnt;

  /****************************************************************************
   *                                                                          *
   *                               Student code                               *
   *                                                                          *
   ****************************************************************************/

//addresses
parameter RXSC = 3'h2;
parameter TXSC_ADDRESS = 3'h0;
parameter TXBUFF_ADDRESS = 3'h1;
parameter RXSC_ADDRESS = 3'h2;
parameter RXBUFF_ADDRESS = 3'h3;
parameter RXLEN_ADDRESS = 3'h4;
int successCounter = 0;

//the values can be gotten by using this syntax uin_hdlc.Rx_Signal

  /****************************************************************************
   *                                                                          *
   *                               Abort receive                               *
   *                                                                          *
   ****************************************************************************/

  // VerifyAbortReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer is zero after abort.
  task VerifyAbortReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic [7:0] RxLen; //had to be defined here and not later


    $display("-------- ABORT RECEIVE --------");
     
    //checking rxsc values
    ReadAddress(RXSC_ADDRESS, ReadData);
    assert(!ReadData[0]) $display("SUCCESS: No Rx_Ready (%d)", ReadData[0]); else begin $display("FAIL: Rx_Ready = %d", ReadData[0]); TbErrorCnt++; end
    assert(!ReadData[2]) $display("SUCCESS: No Rx_FrameError (%d)", ReadData[2]); else begin $display("FAIL: Rx_FrameError = %d", ReadData[2]); TbErrorCnt++; end
    assert(ReadData[3]) $display("SUCCESS: Rx_AbortSignal asserted (%d)", ReadData[3]); else begin $display("FAIL: Rx_AbortSignal = %d", ReadData[3]); TbErrorCnt++; end
    assert(!ReadData[4]) $display("SUCCESS: No Rx_Overflow (%d)", ReadData[4]); else begin $display("FAIL: Rx_Overflow = %d", ReadData[4]); TbErrorCnt++; end

    //checking data buffer
    ReadAddress(RXLEN_ADDRESS, RxLen); //RxLen is not zero
    $display("Size: %d %d", Size, RxLen);

    for (int i = 0; i < Size; i++) begin
      //@(posedge uin_hdlc.Clk);
      ReadAddress(RXBUFF_ADDRESS, ReadData); //ReadData is zero, while data[i] is not
      assert(!ReadData) successCounter++; //$display("SUCCESS: Data is zero"); 
      else begin $display("FAIL: Data is not zero (%d)", ReadData); TbErrorCnt++; 
      end
    end

    if (successCounter > 0)
      $display("SUCCESS: Data is zero, number of times: %d", successCounter);
    successCounter = 0; 

  endtask

  /****************************************************************************
   *                                                                          *
   *                               Normal receive                               *
   *                                                                          *
   ****************************************************************************/

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyNormalReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic [7:0] RxLen;
    wait(uin_hdlc.Rx_Ready);


    $display("-------- NORMAL RECEIVE --------");

    //checking rxsc values
    ReadAddress(RXSC_ADDRESS, ReadData);
    assert(ReadData[0]) $display("SUCCESS: Rx_Ready asserted (%d)", ReadData[0]); else begin $display("FAIL: Rx_Ready = %d", ReadData[0]); TbErrorCnt++; end
    assert(!ReadData[2]) $display("SUCCESS: No Rx_FrameError (%d)", ReadData[2]); else begin $display("FAIL: Rx_FrameError = %d", ReadData[2]); TbErrorCnt++; end
    assert(!ReadData[3]) $display("SUCCESS: No Rx_AbortSignal (%d)", ReadData[3]); else begin $display("FAIL: Rx_AbortSignal = %d", ReadData[3]); TbErrorCnt++; end
    assert(!ReadData[4]) $display("SUCCESS: No Rx_Overflow (%d)", ReadData[4]); else begin $display("FAIL: Rx_Overflow = %d", ReadData[4]); TbErrorCnt++; end

    //checking data buffer
    ReadAddress(RXLEN_ADDRESS, RxLen);
    assert(RxLen == Size) $display("SUCCESS: RxLen is the same as input size"); else begin $display("FAIL: RxLen isn't the same length as input size"); TbErrorCnt++; end
    assert(RxLen < 127) $display("SUCCESS: RxLen is less than 127 bytes"); else begin $display("FAIL: RxLen is too long"); TbErrorCnt++; end
    assert(uin_hdlc.Rx_FrameSize == RxLen) $display("SUCCESS: Rx_FrameSize is the same as RxLen"); else begin $display("FAIL: Rx_FrameSize isn't the same length as RxLen"); TbErrorCnt++; end
    $display("Size: %d %d %d", Size, RxLen, uin_hdlc.Rx_FrameSize); 

    for (int i = 0; i < Size; i++) begin
      //@(posedge uin_hdlc.Clk);
      ReadAddress(RXBUFF_ADDRESS, ReadData);
      //comparing data in function argument and in rx buffer
      assert(data[i] == ReadData) successCounter++; //$display("SUCCESS: Data is matching"); 
      else begin $display("FAIL: %d != %d", ReadData, data[i]); TbErrorCnt++; 
      end
    end
    
    if (successCounter > 0)
      $display("SUCCESS: Data is matching, number of times:%d", successCounter);
    successCounter = 0;

  endtask


  

  /****************************************************************************
   *                                                                          *
   *                               Overflow receive                               *
   *                                                                          *
   ****************************************************************************/

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyOverflowReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic [7:0] RxLen;
    wait(uin_hdlc.Rx_Ready);


    $display("-------- OVERFLOW RECEIVE --------");
    
    //checking rxsc values
    ReadAddress(RXSC_ADDRESS, ReadData);
    assert(ReadData[0]) $display("SUCCESS: Rx_Ready asserted (%d)", ReadData[0]); else begin $display("FAIL: Rx_Ready = %d", ReadData[0]) ; TbErrorCnt++; end
    assert(!ReadData[2]) $display("SUCCESS: No Rx_FrameError (%d)", ReadData[2]); else begin $display("FAIL: Rx_FrameError = %d", ReadData[2]); TbErrorCnt++; end
    assert(!ReadData[3]) $display("SUCCESS: No Rx_AbortSignal (%d)", ReadData[3]); else begin $display("FAIL: Rx_AbortSignal = %d", ReadData[3]); TbErrorCnt++; end
    assert(ReadData[4]) $display("SUCCESS: Rx_Overflow asserted (%d)", ReadData[4]); else begin $display("FAIL: Rx_Overflow = %d", ReadData[4]); TbErrorCnt++; end

  
    //RxLen can only be 126 bytes long, while the size can be bigger. The difference will be the overflown bytes
    //overflow is borderline triggered on 126 bytes. Both normal and overflow receive works
    ReadAddress(RXLEN_ADDRESS, RxLen);
    assert(RxLen <= Size) $display("SUCCESS: RxLen is the same or less than input size"); else begin $display("FAIL: RxLen more than input size"); TbErrorCnt++; end
    assert(RxLen == 126) $display("SUCCESS: RxLen is 126 bytes"); else begin $display("FAIL: RxLen is %d bytes", RxLen); TbErrorCnt++; end
    assert(uin_hdlc.Rx_FrameSize == RxLen) $display("SUCCESS: Rx_FrameSize is the same as RxLen"); else begin $display("FAIL: Rx_FrameSize isn't the same length as RxLen"); TbErrorCnt++; end
    $display("Size: %d %d %d", Size, RxLen, uin_hdlc.Rx_FrameSize);

      //checking data buffer
    for (int i = 0; i < Size - (Size - RxLen); i++) begin
      //@(posedge uin_hdlc.Clk);
      ReadAddress(RXBUFF_ADDRESS, ReadData);
      //comparing data in function argument and in rx buffer
      assert(data[i] == ReadData) successCounter++; //$display("SUCCESS: Data is matching");  
      else begin $display("FAIL: %d != %d", ReadData, data[i]); TbErrorCnt++; 
      end
    end

    if (successCounter > 0)
      $display("SUCCESS: Data is matching, number of times: %d", successCounter);
    successCounter = 0; //reset before checking the overflown bytes

    //the overflown bytes should be zero
    for (int j = 0; j < (Size - RxLen); j++) begin
      ReadAddress(RXBUFF_ADDRESS, ReadData);
      assert(!ReadData) successCounter++; 
      else begin $display("FAIL: Data is not zero (%d)", ReadData); TbErrorCnt++; 
      end
    end

    if (successCounter > 0)
      $display("SUCCESS: Data is zero , number of times : %d", successCounter);
    successCounter = 0;
  
  endtask


  

  /****************************************************************************
   *                                                                          *
   *                               Frame error receive                               *
   *                                                                          *
   ****************************************************************************/



  task VerifyFrameErrorReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic [7:0] RxLen; //had to be defined here and not later
    

    $display("-------- FRAME ERROR RECEIVE --------");
     
    //checking rxsc values
    ReadAddress(RXSC_ADDRESS, ReadData);
    assert(!ReadData[0]) $display("SUCCESS: No Rx_Ready (%d)", ReadData[0]); else begin $display("FAIL: Rx_Ready = %d", ReadData[0]); TbErrorCnt++; end
    assert(ReadData[2]) $display("SUCCESS: Rx_FrameError asserted (%d)", ReadData[2]); else begin $display("FAIL: Rx_FrameError = %d", ReadData[2]); TbErrorCnt++; end
    assert(!ReadData[3]) $display("SUCCESS: No Rx_AbortSignal (%d)", ReadData[3]); else begin $display("FAIL: Rx_AbortSignal = %d", ReadData[3]); TbErrorCnt++; end
    assert(!ReadData[4]) $display("SUCCESS: No Rx_Overflow (%d)", ReadData[4]); else begin $display("FAIL: Rx_Overflow = %d", ReadData[4]); TbErrorCnt++; end

    //checking data buffer
    ReadAddress(RXLEN_ADDRESS, RxLen); //RxLen is not zero
    $display("Size: %d %d", Size, RxLen);

    for (int i = 0; i < Size; i++) begin
      //@(posedge uin_hdlc.Clk);
      ReadAddress(RXBUFF_ADDRESS, ReadData); //ReadData is zero, while data[i] is not
      assert(!ReadData) successCounter++; //$display("SUCCESS: Data is zero"); 
      else begin $display("FAIL: Data is not zero (%d)", ReadData); TbErrorCnt++;
      end
    end

    if (successCounter > 0)
      $display("SUCCESS: Data is zero, number of times: %d", successCounter);
    successCounter = 0; 

  endtask
  


  /****************************************************************************
   *                                                                          *
   *                               Dropped frame receive                               *
   *                                                                          *
   ****************************************************************************/

    task VerifyDroppedFrameReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic [7:0] WriteData;
    logic [7:0] RxLen; //had to be defined here and not later
   

    $display("-------- DROPPED FRAME RECEIVE --------");
     
 
    ReadAddress(RXSC_ADDRESS, ReadData);
    assert(!ReadData[0]) $display("SUCCESS: No Rx_Ready (%d)", ReadData[0]); else begin $display("FAIL: Rx_Ready = %d", ReadData[0]); TbErrorCnt++; end
    assert(!ReadData[2]) $display("SUCCESS: No Rx_FrameError (%d)", ReadData[2]); else begin $display("FAIL: Rx_FrameError = %d", ReadData[2]); TbErrorCnt++; end
    assert(ReadData[3]) $display("SUCCESS: Rx_AbortSignal asserted (%d)", ReadData[3]); else begin $display("FAIL: Rx_AbortSignal = %d", ReadData[3]); TbErrorCnt++; end
    assert(!ReadData[4]) $display("SUCCESS: No Rx_Overflow (%d)", ReadData[4]); else begin $display("FAIL: Rx_Overflow = %d", ReadData[4]); TbErrorCnt++; end
    

    //checking data buffer
    ReadAddress(RXLEN_ADDRESS, RxLen); //RxLen is not zero
    $display("Size: %d %d", Size, RxLen);

    for (int i = 0; i < Size; i++) begin
      //@(posedge uin_hdlc.Clk);
      ReadAddress(RXBUFF_ADDRESS, ReadData); //ReadData is zero, while data[i] is not
      assert(!ReadData) successCounter++; //$display("SUCCESS: Data is zero"); 
      else begin $display("FAIL: Data is not zero (%d)", ReadData); TbErrorCnt++; 
      end
    end

    if (successCounter > 0)
      $display("SUCCESS: Data is zero, number of times: %d", successCounter);
    successCounter = 0; 

  endtask
  


    /****************************************************************************
   *                                                                          *
   *                               Normal transmit                               *
   *                                                                          *
   ****************************************************************************/

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyNormalTransmit(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    //wait(uin_hdlc.Tx_Done);


    $display("-------- NORMAL TRANSMIT --------");

    //checking rxsc values
    ReadAddress(RXSC_ADDRESS, ReadData);
    assert(ReadData[0]) $display("SUCCESS: Tx_Done asserted (%d)", ReadData[0]); else begin $display("FAIL: Tx_Done = %d", ReadData[0]); TbErrorCnt++; end
    assert(!ReadData[3]) $display("SUCCESS: No Tx_AbortedTrans (%d)", ReadData[3]); else begin $display("FAIL: Tx_AbortedTrans = %d", ReadData[3]); TbErrorCnt++; end
    assert(!ReadData[4]) $display("SUCCESS: No Tx_Full (%d)", ReadData[4]); else begin $display("FAIL: Tx_Full = %d", ReadData[4]); TbErrorCnt++; end
   
   
    //checking data buffer

    for (int i = 0; i < Size; i++) begin
      //@(posedge uin_hdlc.Clk);
      ReadAddress(TXBUFF_ADDRESS, ReadData);
      //comparing data in function argument and in rx buffer
      assert(data[i] == ReadData) successCounter++; //$display("SUCCESS: Data is matching"); 
      else begin $display("FAIL: %d != %d", ReadData, data[i]); TbErrorCnt++; 
      end
    end
    
    if (successCounter > 0)
      $display("SUCCESS: Data is matching, number of times:%d", successCounter);
    successCounter = 0;

  endtask

  /****************************************************************************
   *                                                                          *
   *                             Simulation code                              *
   *                                                                          *
   ****************************************************************************/

  initial begin
    $display("*************************************************************");
    $display("%t - Starting Test Program", $time);
    $display("*************************************************************");

    Init();

    //Receive: Size, Abort, FCSerr, NonByteAligned, Overflow, Drop, SkipRead
    Receive( 10, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 40, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 45, 0, 0, 0, 0, 0, 0); //Normal
    Receive(126, 0, 0, 0, 0, 0, 0); //Normal
    Receive(122, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 25, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 47, 0, 0, 0, 0, 0, 0); //Normal


    Receive( 40, 0, 1, 0, 0, 0, 0); //FCSerr
    Receive( 40, 0, 0, 1, 0, 0, 0); //NonByteAligned
    Receive( 40, 0, 0, 0, 0, 1, 0); //Drop
    Receive( 127, 1, 0, 0, 1, 0, 0); //Overflow and abort
    Receive( 127, 0, 0, 0, 0, 0, 0); //Normal but with overflow
    

    //uin_hdlc.Rx          =   1'b1;
    //uin_hdlc.Rx        =   1'b0;
    //uin_hdlc.RxEN        =   1'b0;
    uin_hdlc.TxEN        =   1'b1;
    //WriteAddress(RXSC, 8'h00);
    
  


    Transmit(40, 0, 0); //normal not functional
    //Transmit(40, 1, 0); //Abort
    //Transmit(40, 0, 1); //Oveflow
    
    

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: %0d\t  *", TbErrorCnt + uin_hdlc.ErrCntAssertions);
    $display("*                               *");
    $display("*********************************");

  end

  task Init();
    uin_hdlc.Clk         =   1'b0;
    uin_hdlc.Rst         =   1'b0;
    uin_hdlc.Address     = 3'b000;
    uin_hdlc.WriteEnable =   1'b0;
    uin_hdlc.ReadEnable  =   1'b0;
    uin_hdlc.DataIn      =     '0;
    uin_hdlc.TxEN        =   1'b0;
    uin_hdlc.Rx          =   1'b1;
    uin_hdlc.RxEN        =   1'b1;
    //uin_hdlc.Tx          = 1'b1;

    TbErrorCnt = 0;

    #1000ns;
    uin_hdlc.Rst         =   1'b1;
  endtask




  /****************************************************************************
   *                                                                          *
   *                             Address interface                            *
   *                                                                          *
   ****************************************************************************/

  task WriteAddress(input logic [2:0] Address ,input logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address     = Address;
    uin_hdlc.WriteEnable = 1'b1;
    uin_hdlc.DataIn      = Data;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.WriteEnable = 1'b0;
  endtask

  task ReadAddress(input logic [2:0] Address ,output logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address    = Address;
    uin_hdlc.ReadEnable = 1'b1;
    #100ns;
    Data                = uin_hdlc.DataOut;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.ReadEnable = 1'b0;
  endtask

    /****************************************************************************
   *                                                                          *
   *                            Flag and abort generation                     *
   *                                                                          *
   ****************************************************************************/


  //Rx
  //Flag:  0111_1110
  //Abort: 0111_1111
  task InsertFlagOrAbort(int flag); 
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b0;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    if(flag)
      uin_hdlc.Rx = 1'b0;
    else
      uin_hdlc.Rx = 1'b1;
  endtask



  //Tx
  //Flag:  0111_1110
  //Abort: 0111_1111??
   task InsertFlagOrAbortTx(int abort);
    if (abort) 
      WriteAddress(TXSC_ADDRESS, 8'b0000_0110); //abort tx
    else
      WriteAddress(TXSC_ADDRESS, 8'b0000_0010); //enable tx 
  endtask


  /****************************************************************************
   *                                                                          *
   *                             Rx/Tx stimulus                               *
   *                                                                          *
   ****************************************************************************/


  task MakeRxStimulus(logic [127:0][7:0] Data, int Size);
    logic [4:0] PrevData;
    PrevData = '0;
    for (int i = 0; i < Size; i++) begin
      for (int j = 0; j < 8; j++) begin
        if(&PrevData) begin
          @(posedge uin_hdlc.Clk);
          uin_hdlc.Rx = 1'b0;
          PrevData = PrevData >> 1;
          PrevData[4] = 1'b0;
        end

        @(posedge uin_hdlc.Clk);
        uin_hdlc.Rx = Data[i][j];

        PrevData = PrevData >> 1;
        PrevData[4] = Data[i][j];
      end
    end
  endtask


  task MakeTxStimulus(logic [127:0][7:0] Data, int Size);

    for (int i = 0; i < Size; i++) begin
      //for (int j = 0; i < 8; j++) begin
      //writeaddress takes in one byte at a time¨
        //wait(uin_hdlc.Tx_Done);
        WriteAddress(TXBUFF_ADDRESS, Data[i]); //Data[i][j]
      //end
    end

  endtask


  /****************************************************************************
   *                                                                          *
   *                             Receive task                                 *
   *                                                                          *
   ****************************************************************************/
  

  task Receive(int Size, int Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead);
    logic [127:0][7:0] ReceiveData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;
    logic [127:0][8:0] NonByteAlignedData; //it only seems to give frame error if the array is bigger than 8 bits and not less even if that's still non byte aligned


    string msg;
    if(Abort)
      msg = "- Abort";
    else if(FCSerr)
      msg = "- FCS error";
    else if(NonByteAligned)
      msg = "- Non-byte aligned";
    else if(Overflow)
      msg = "- Overflow";
    else if(Drop)
      msg = "- Drop";
    else if(SkipRead)
      msg = "- Skip read";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Receive %s", $time, msg);
    $display("*************************************************************");
    
    if (Size > 126)
      Overflow = 1;

    if (NonByteAligned) begin
    //generate random data
    for (int i = 0; i < Size; i++) begin
      NonByteAlignedData[i] = $urandom;
    end
    NonByteAlignedData[Size]   = '0;
    NonByteAlignedData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(NonByteAligned, Size, FCSBytes);
    NonByteAlignedData[Size]   = FCSBytes[7:0];
    NonByteAlignedData[Size+1] = FCSBytes[15:8];
    end else begin
       //generate random data
    for (int i = 0; i < Size; i++) begin
      ReceiveData[i] = $urandom;
    end
    ReceiveData[Size]   = '0;
    ReceiveData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    ReceiveData[Size]   = FCSBytes[7:0];
    ReceiveData[Size+1] = FCSBytes[15:8];
    end
    
    if (FCSerr) begin
      //Calculate FCS bits;
    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    ReceiveData[Size]   = FCSBytes[15:8];
    ReceiveData[Size+1] = FCSBytes[7:0];
    end

    //Enable FCS
    if(!Overflow && !Drop) //abort, fcserr, skipread, normal will still go here, nonbytealigned
      WriteAddress(RXSC, 8'h20); //0010_0000, enable fcs
      //guess its not worth going for fcs if there's an overflow
    else if (Drop) begin
      WriteAddress(RXSC, 8'b0010_0010); //discard frame
      $display("dropped frame"); end
    else
      WriteAddress(RXSC, 8'h00); //0000_0000 

    //here the actual "sending" happens
    //Generate stimulus
    InsertFlagOrAbort(1); //flag
    
    if (NonByteAligned) 
    MakeRxStimulus(NonByteAlignedData, Size + 2);
    else
    MakeRxStimulus(ReceiveData, Size + 2);
    
    //need own overflow data array, because receiveData is only up to max valid size
    if(Overflow) begin
      OverflowData[0] = 8'h44;
      OverflowData[1] = 8'hBB;
      OverflowData[2] = 8'hCC;
      MakeRxStimulus(OverflowData, 3);
    end

    if(Abort || Drop) begin // || Drop
      InsertFlagOrAbort(0);
    end else begin
      InsertFlagOrAbort(1);
    end

    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;

    repeat(8) //idle
      @(posedge uin_hdlc.Clk);

      // Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead

    if(Abort)
      VerifyAbortReceive(ReceiveData, Size);
    else if(Overflow)
      VerifyOverflowReceive(ReceiveData, Size);
    else if(FCSerr)
      VerifyFrameErrorReceive(ReceiveData, Size); //FCS isn't frame error but causes it?
    else if(NonByteAligned)
      VerifyFrameErrorReceive(ReceiveData, Size);
    else if (Drop)
    VerifyDroppedFrameReceive(ReceiveData, Size);

    else if(!SkipRead)
      VerifyNormalReceive(ReceiveData, Size);
   


    #5000ns;
  endtask

  
  /****************************************************************************
   *                                                                          *
   *                             Transmit task                                *
   *                                                                          *
   ****************************************************************************/

  task Transmit(int Size, int Abort, int Overflow);
    logic [127:0][7:0] TransmitData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;


    //i think maybe transmit does things automatically for us, if we just set the registers right
    //fcs, abort and overflow should be done by the dut
    //will it automatically see that the size is too long?

    //begin with these three
    string msg;
    if(Abort)
      msg = "- Abort";
    else if(Overflow)
      msg = "- Overflow";
    else
      msg = "- Normal";


    $display("*************************************************************");
    $display("%t - Starting task Transmit %s", $time, msg);
    $display("*************************************************************");

    //generate random data to transmit. the tx module doesn't generate the data
    for (int i = 0; i < Size; i++) begin
      TransmitData[i] = $urandom;
    end
    //TransmitData[Size]   = '0;
    //TransmitData[Size+1] = '0;

    //calculate FCS bits;
    //GenerateFCSBytes(TransmitData, Size, FCSBytes);
    //TransmitData[Size]   = FCSBytes[7:0];
    //TransmitData[Size+1] = FCSBytes[15:8];

    //Generate stimulus



  //MakeTxStimulus(TransmitData, Size);
  //wait(uin_hdlc.Tx_Done);
    for (int j = 0; j < Size; j++) begin
      //for (int j = 0; i < 8; j++) begin
      //writeaddress takes in one byte at a time¨
        //wait(uin_hdlc.Tx_Done);
        WriteAddress(TXBUFF_ADDRESS, TransmitData[j]); //Data[i][j]
      //end
    end

      WriteAddress(TXSC_ADDRESS, 8'b0000_0010); //enable tx. dont think it matter if before or after writeaddress

    //if (Abort) 
    //  WriteAddress(TXSC_ADDRESS, 8'b0000_0110); //abort tx
    //else //normal and overflow
    
    
    //wait(uin_hdlc.Tx_Done);
   
    //InsertFlagOrAbortTx(1); //enable or abort and enable
 
    
    //if(Overflow) begin
    //  OverflowData[0] = 8'h44;
    //  OverflowData[1] = 8'hBB;
    //  OverflowData[2] = 8'hCC;
    //  MakeTxStimulus(OverflowData, 3);
    //end

    //if(Abort) begin
    //  InsertFlagOrAbortTx(0);
    //end else begin
    //  InsertFlagOrAbortTx(1);
    //end

    //@(posedge uin_hdlc.Clk);
    //uin_hdlc.Tx = 1'b1;

    //repeat(8) //idle
    //  @(posedge uin_hdlc.Clk);

    if(Abort)
      $display("tx abort"); //VerifyAbortTransmit(ReceiveData, Size);
    else if(Overflow)
      $display("tx overflow"); //VerifyOverflowTransmit(ReceiveData, Size);
    else
      //VerifyNormalTransmit(TransmitData, Size);
       $display("tx normal");


    //WriteAddress(TXSC_ADDRESS, 8'b0000_0000); //disable tx 
//make it go to idle

#10000ns;
  endtask



  /****************************************************************************
   *                                                                          *
   *                             FCS bytes                                    *
   *                                                                          *
   ****************************************************************************/

  task GenerateFCSBytes(logic [127:0][7:0] data, int size, output logic[15:0] FCSBytes);
    logic [23:0] CheckReg;
    CheckReg[15:8]  = data[1];
    CheckReg[7:0]   = data[0];
    for(int i = 2; i < size+2; i++) begin
      CheckReg[23:16] = data[i];
      for(int j = 0; j < 8; j++) begin
        if(CheckReg[0]) begin
          CheckReg[0]    = CheckReg[0] ^ 1;
          CheckReg[1]    = CheckReg[1] ^ 1;
          CheckReg[13:2] = CheckReg[13:2];
          CheckReg[14]   = CheckReg[14] ^ 1;
          CheckReg[15]   = CheckReg[15];
          CheckReg[16]   = CheckReg[16] ^1;
        end
        CheckReg = CheckReg >> 1;
      end
    end
    FCSBytes = CheckReg;
  endtask

endprogram
