module top_tb();
  `define DUT encoder_emulator

  logic clk;
  logic reset;
  logic encoder_a;
  logic encoder_b;

  IAXILite #(.ADDR_WIDTH(8), .DATA_WIDTH(64)) CP();
  assign CP.clk = clk;

  `DUT DUT(
    .clk        (clk),
    .reset      (reset),

    .encoder_a  (encoder_a),
    .encoder_b  (encoder_b),

    .CP         (CP)
  );

  initial begin
    clk = 1'b0;
    reset = 1'b0;
    #10ns;
    encoder_a = 1'b0;
    encoder_b = 1'b0;
    CP.master_init();
    reset = 1'b1;
    #50ns;
    @(posedge clk);
    reset = 1'b0;
    
    CP.write(8'h00, 1000);
    CP.write(8'h20, 0);
    CP.write(8'h10, 10);

    #100us;
    CP.write(8'h00, 1000);
    CP.write(8'h20, 1);
    CP.write(8'h10, 10);
    #100us;

    $stop;
  end

  always 
    #5ns clk = ~clk;

endmodule