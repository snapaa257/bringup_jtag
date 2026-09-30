// GenSmalAndProductiveWithOfficialRiscvDebug
// jtag_idcode_tb
// Hand-clock the TAP, read IDCODE
// FSM/shift advance on posedge tck
// TDO updates on negedge tck
// TAP resets via TMI = 1

`timescale 1ns/1ps

module jtag_idcode_tb;
  localparam TCK_PERIOD = 40;
  localparam [31:0] EXPECTED = 32'h10002fff;
 
 // JTAG signals
  reg jtag_tck = 0, jtag_tms = 1, jtag_tdi = 0;
  wire jtag_do;

 // Core signals
  reg clk = 0, reset = 1, debugReset = 1;
  wire ndmreset, stoptime;

 // Wishbone bus + irq, tie up since to going to be used here currently
  wire iBusWishbone_CYC, iBusWishbone_STB, iBusWishbone_WE;
  wire [29:0] iBusWishbone_ADR;
  wire [31:0] iBusWishbone_DAT_MOSI;
  wire [3:0] iBusWishbone_SEL;
  wire [2:0] iBusWishbone_CTI;
  wire [1:0] iBusWishbone_BTE;

  wire dBusWishbone_CYC, dBusWishbone_STB, dBusWishbone_WE;
  wire [29:0] dBusWishbone_ADR;
  wire [31:0] dBusWishbone_DAT_MOSI;
  wire [3:0] dBusWishbone_SEL;
  wire [2:0] dBusWishbone_CTI;
  wire [1:0] dBusWishbone_BTE;

  VexRiscv dut (
    .timerInterrupt(1'b0), .externalInterrupt(1'b0), .softwareInterrupt(1'b0),

     // JTAG
    .jtag_tms(jtag_tms), 
    .jtag_tdi(jtag_tdi), 
    .jtag_tdo(jtag_tdo), 
    .jtag_tck(jtag_tck),

    .ndmreset(ndmreset),

     // Ibus
    .iBusWishbone_CYC(iBusWishbone_CYC), .iBusWishbone_STB(iBusWishbone_STB), .iBusWishbone_ACK(1'b0), .iBusWishbone_WE(iBusWishbone_WE), .iBusWishbone_ADR(iBusWishbone_ADR),
    .iBusWishbone_DAT_MISO(32'b0), .iBusWishbone_DAT_MOSI(iBusWishbone_DAT_MOSI), .iBusWishbone_SEL(iBusWishbone_SEL), .iBusWishbone_ERR(1'b0), .iBusWishbone_CTI(iBusWishbone_CTI), .iBusWishbone_BTE(iBusWishbone_BTE),
 
    // dBus
    .dBusWishbone_CYC(dBusWishbone_CYC), .dBusWishbone_STB(dBusWishbone_STB), .dBusWishbone_ACK(1'b0), .dBusWishbone_WE(dBusWishbone_WE), .dBusWishbone_ADR(dBusWishbone_ADR),
    .dBusWishbone_DAT_MISO(32'b0), .dBusWishbone_DAT_MOSI(dBusWishbone_DAT_MOSI), .dBusWishbone_SEL(dBusWishbone_SEL), .dBusWishbone_ERR(1'b0), .dBusWishbone_CTI(dBusWishbone_CTI), .dBusWishbone_BTE(dBusWishbone_BTE), 
  
    .reset(reset), .stoptime(stoptime), .clk(clk), .debugReset(debugReset)
  );

  always #5 clk = ~clk;

  // tck_drive
  // drive tms/tdi on posedges
  // advances on FSM and shifter
  // negedge updates tdo
  task tck_drive;
     input tms_i;
     input tdi_i;
     begin
       jtag_tms = tms_i;
       jtag_tdi = tdi_i;

       #(TCK_PERIOD/2) jtag_tck = 1;
       #(TCK_PERIOD/2) jtag_tck = 0;
     end
  endtask

  integer index;
  reg [31:0] idcode;

  initial begin 
    // release resets
    #23 reset = 1'b0; debugReset = 1'b0;
    #40;

    // force Test-Logic-Reset (TMS=1 x5), TLR loads IR=IDCODE auto
    for (index = 0; index < 6; index = index + 1)
      tck_drive(1, 0);

    // TLR to Run-test/Idle
    tck_drive(0, 0);

    // Idle to Select-DR
    tck_drive(1, 0);

    // Select-DR to Capture DR
    tck_drive(0, 0);

    // Capture DR to shift DR
    tck_drive(0, 0);

    // Updates tdo, drive to prevent core from halting 
    for (index = 0; index < 32; index = index + 1) begin
      tck_drive(0, 0);
      idcode[index] = jtag_tdo;
    end

    #10;
    $display("");
    $display("IDCODE got = 0x%08h", idcode);
    $display("expected    = 0x%08h", EXPECTED);
    if (idcode === EXPECTED)
      $display("PASS: TAP alive, IDCODE matches. DTM is breathing. :)");
    else
      $display("FAIL: mismatch, wrong edge/sequence).");
    $display("");
    $finish;
  end

  initial begin
    $dumpfile("jtag_idcode_tb.vcd");
    $dumpvars(0, jtag_idcode_tb);
    #200000 $display("TIMEOUT"); 
    $finish;
  end
endmodule
