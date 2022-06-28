module encoder_emulator_wrap(
  input clk,
  input reset,

  output encoder_a,
  output encoder_b,


  input  [ 7:0] CP_AWADDR,
  input  [ 2:0] CP_AWPROT,
  input         CP_AWVALID,
  output        CP_AWREADY,

  input  [63:0] CP_WDATA,
  input  [ 7:0] CP_WSTRB,
  input         CP_WVALID,
  output        CP_WREADY,

  output [ 1:0] CP_BRESP,
  output        CP_BVALID,
  input         CP_BREADY,

  input  [ 7:0] CP_ARADDR,
  input  [ 2:0] CP_ARPROT,
  input         CP_ARVALID,
  output        CP_ARREADY,

  output [63:0] CP_RDATA,
  output [ 1:0] CP_RRESP,
  output        CP_RVALID,
  input         CP_RREADY
);
    
  IAXILite   #(.DATA_WIDTH(64), .ADDR_WIDTH(8)) CP();

  assign CP.AWADDR  = CP_AWADDR;
  assign CP.AWPROT  = CP_AWPROT;
  assign CP.AWVALID = CP_AWVALID;
  assign CP_AWREADY = CP.AWREADY;

  assign CP.WDATA  = CP_WDATA;
  assign CP.WSTRB  = CP_WSTRB;
  assign CP.WVALID = CP_WVALID;
  assign CP_WREADY = CP.WREADY;

  assign CP_BRESP  = CP.BRESP;
  assign CP_BVALID = CP.BVALID;
  assign CP.BREADY = CP_BREADY;

  assign CP.ARADDR  = CP_ARADDR;
  assign CP.ARPROT  = CP_ARPROT;
  assign CP.ARVALID = CP_ARVALID;
  assign CP_ARREADY = CP.ARREADY;

  assign CP_RDATA  = CP.RDATA;
  assign CP_RRESP  = CP.RRESP;
  assign CP_RVALID = CP.RVALID;
  assign CP.RREADY = CP_RREADY;

  encoder_emulator encoder_emulator_inst (
    .clk        (clk),
    .reset      (reset),

    .encoder_a  (encoder_a),
    .encoder_b  (encoder_b),

    .CP         (CP)
  );
endmodule