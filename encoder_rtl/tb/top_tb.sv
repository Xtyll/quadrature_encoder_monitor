module top_tb();
  `define DUT encoder_monitor

  logic clk;
  logic reset;
  logic encoder_a;
  logic encoder_b;

  IAXILite #(.ADDR_WIDTH(4), .DATA_WIDTH(64)) CP();
  assign CP.clk = clk;

  IAXIStream #(.DATA_WIDTH(64)) MSG();

  `DUT DUT(
    .clk        (clk),
    .reset      (reset),

    .encoder_a  (encoder_a),
    .encoder_b  (encoder_b),

    .CP         (CP),
    .MSG        (MSG)
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
    MSG.tready = 1'b1;
    
    fork
      repeat(3) begin
        CP.write(0, 0);
        repeat(30) begin
          repeat(10) @(posedge clk);
          encoder_a = 1'b1;
          repeat(10) @(posedge clk);
          encoder_b = 1'b1;
          repeat(10) @(posedge clk);
          encoder_a = 1'b0;
          repeat(10) @(posedge clk);
          encoder_b = 1'b0;
        end

        repeat(25) begin
          repeat(10) @(posedge clk);
          encoder_b = 1'b1;
          repeat(10) @(posedge clk);
          encoder_a = 1'b1;
          repeat(10) @(posedge clk);
          encoder_b = 1'b0;
          repeat(10) @(posedge clk);
          encoder_a = 1'b0;
        end

        repeat(300) @(posedge clk);
      end
      repeat(1000) begin : random_pos_reading
        logic [63:0] data;

        repeat($random(50)) @(posedge clk);
        CP.read(0, data);
        $display(">>> %0tfs | Readed value = %0h", $time, data);
      end
    join

    $stop;
  end

  always 
    #5ns clk = ~clk;

endmodule