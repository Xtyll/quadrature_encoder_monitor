interface IAXIStream #(
  parameter DATA_WIDTH = 64
);
  // synthesis translate_off
  logic clk;
  // synthesis translate_on

  logic [DATA_WIDTH - 1 : 0] tdata;
  logic                      tvalid;
  logic                      tready;


  modport in (
    input tdata, tvalid,
    output tready
  );

  modport out (
    input tready,
    output tdata, tvalid
  );


  // synthesis translate_off

  task master_init();
    tdata  = 'b0;
    tvalid = 'b0;
  endtask

  task write(logic [DATA_WIDTH - 1 : 0] data);
    tdata  = data;
    tvalid = 1'b1;
    @(posedge clk iff tready == 1'b1);
    tdata  = 'b0;
    tvalid = 1'b0;
  endtask

  // synthesis translate_on

endinterface //IAXIStream