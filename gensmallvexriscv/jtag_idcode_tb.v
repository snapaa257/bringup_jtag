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

 // Core bus + irq, tie up since to going to be used here currently
  wire dBus_cmd_valid, dBus_cmd_payload_wr, dBus_cmd_payload_uncached;
  wire [31:0] dBus_cmd_payload_address, dBus_cmd_payload_data;
  wire [3:0]  dBus_cmd_payload_mask;
  wire [1:0]  dBus_cmd_payload_size;
  wire dBus_cmd_payload_last;
  wire iBus_cmd_valid; wire [31:0] iBus_cmd_payload_address; wire [2:0] iBus_cmd_payload_size;

  VexRiscv dut (
    .dBus_cmd_valid(dBus_cmd_valid), .dBus_cmd_ready(1'b1),
    .dBus_cmd_payload_wr(dBus_cmd_payload_wr),
    .dBus_cmd_payload_address(dBus_cmd_payload_address), .dBus_cmd_payload_data(dBus_cmd_payload_data),
    .dBus_cmd_payload_mask(dBus_cmd_payload_mask), .dBus_cmd_payload_size(dBus_cmd_payload_size),

    .timerInterrupt(1'b0), .externalInterrupt(1'b0), .softwareInterrupt(1'b0),

     // JTAG
    .jtag_tms(jtag_tms), 
    .jtag_tdi(jtag_tdi), 
    .jtag_tdo(jtag_tdo), 
    .jtag_tck(jtag_tck),

    .ndmreset(ndmreset),

    .iBus_cmd_valid(iBus_cmd_valid), .iBus_cmd_ready(1'b1),
    
    .iBus_rsp_valid(1'b0), .iBus_rsp_payload_error(1'b0),

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
