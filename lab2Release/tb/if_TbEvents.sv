//====================================================================
//        Copyright (c) 2025
// Created : omqa at 2025-12-01
//====================================================================


// =========================================
// Events/handshake interface
// =========================================
interface if_TbEvents;
  event tx;          // trigger a TX packet send
  logic rxTrig;      // trigger a RX packet receive (pulse/high level)
  logic rxDone;      // handshake back from reader (pulse/high level)

  modport writer (input tx);
  modport reader (input rxTrig, output rxDone);
endinterface


