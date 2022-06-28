module encoder_monitor (
  input clk,
  input reset,

  input encoder_a,
  input encoder_b,

  IAXILite.in    CP,
  IAXIStream.out MSG
);
    
  typedef enum {
    s_idle,
    s_work
  } fsm_states;

  fsm_states  main_fsm;
  logic [1:0] encoder_val;              //[0] - A, [1] - B
  logic [1:0] encoder_val_z   = 2'b00;
  logic [1:0] encoder_val_zz  = 2'b00;
  logic [1:0] encoder_val_zzz = 2'b00;
  logic [1:0] increment_value;
  logic [1:0] decrement_value;
  logic       change_encoder;
  logic       change_encoder_z;

  logic [63:0] position = 0;
  logic [63:0] new_position;
  logic        set_position;

  function logic[1:0] f_inc_val(logic [1:0] val);
      case (val)
          2'b00 : 
              return 2'b01;
          2'b11 :
              return 2'b10;
          2'b01 :
              return 2'b11;
          default :
              return 2'b00;
      endcase
  endfunction

  function logic[1:0] f_dec_val(logic [1:0] val);
      case (val)
          2'b00 : 
              return 2'b10;
          2'b10 :
              return 2'b11;
          2'b11 :
              return 2'b01;
          default :
              return 2'b00;
      endcase
  endfunction

  assign encoder_val = {encoder_b, encoder_a};
  always_ff @(posedge clk) begin
    encoder_val_zzz <= encoder_val_zz;
    encoder_val_zz <= encoder_val_z;
    encoder_val_z <= encoder_val;
  end

  assign change_encoder = (encoder_val_zzz != encoder_val_zz) ? 1'b1 : 1'b0;

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      main_fsm <= s_idle;
    end else begin
      case (main_fsm)
        s_idle : begin
          increment_value <= f_inc_val(encoder_val_zz);
          decrement_value <= f_dec_val(encoder_val_zz);
          main_fsm <= s_work;
        end

        s_work : begin
          if (change_encoder == 1'b1) begin
            increment_value <= f_inc_val(encoder_val_zz);
            decrement_value <= f_dec_val(encoder_val_zz);
          end
        end

        default: begin
          main_fsm <= s_idle;
        end
      endcase
    end
  end

  // The position counter
  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      position <= 64'd0;
    end else begin
      if (set_position == 1'b1) begin
        position <= new_position;
      end else if (change_encoder == 1'b1 && encoder_val_zz == increment_value) begin
        position <= position + 'd1;
      end else if (change_encoder == 1'b1 && encoder_val_zz == decrement_value) begin
        position <= position - 'd1;
      end else if (change_encoder == 1'b1) begin
        position <= position;
        // synthesis translate_off
        $error(">>> %0tfs | Unexpected encoder sequence!", $time);
        // synthesis translate_on
      end
    end
  end

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      change_encoder_z <= 1'b0;
    end else begin
      change_encoder_z <= change_encoder;
    end
  end

  // Send message after encoder position is changed
  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      MSG.tvalid <= 1'b0;
    end else begin
      if (MSG.tready == 1'b1) begin
        MSG.tvalid <= 1'b0;
      end
      if (change_encoder_z == 1'b1 && (MSG.tvalid == 1'b0 || MSG.tready == 1'b1)) begin
        MSG.tdata <= position;
        MSG.tvalid <= 1'b1;
      end
    end
  end

  // Reading the position through AXILite bus
  assign CP.RRESP = 2'b00;
  assign CP.ARREADY = 1'b1;

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      CP.RVALID <= 1'b0;
    end else begin
      if (CP.RREADY == 1'b1) begin
        CP.RVALID <= 1'b0;
      end

      if (CP.ARVALID == 1'b1) begin
        CP.RVALID <= 1'b1;
        CP.RDATA <= position;
      end
    end
  end

  // Clear the position register through AXILite bus
  assign CP.BRESP = 2'b00;
  assign CP.AWREADY = 1'b1;
  assign CP.WREADY = 1'b1;

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      CP.BVALID <= 1'b0;
      set_position <= 1'b0;
    end else begin
      if (CP.WVALID == 1'b1) begin
        CP.BVALID <= 1'b1;
      end else if (CP.BREADY == 1'b1) begin
        CP.BVALID <= 1'b0;
      end

      if (CP.WVALID == 1'b1) begin
        set_position <= 1'b1;
        new_position <= CP.WDATA;
      end else begin
        set_position <= 1'b0;
      end
    end
  end

endmodule