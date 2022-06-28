module encoder_emulator (
  input clk,
  input reset,

  output encoder_a,
  output encoder_b,

  IAXILite.in    CP
);
    
  typedef enum {
    s_idle,
    s_work
  } fsm_states;

  fsm_states   main_fsm;
  logic [ 1:0] encoder_val;              //[0] - A, [1] - B
  logic        clk_div_cnt_ov;
  logic [15:0] clk_div_cnt;

  logic [ 1:0] increment_value;
  logic [ 1:0] decrement_value;
  logic        change_encoder;

  logic [63:0] position = 0;
  logic [63:0] new_position;
  logic        clear_position;
  
  logic [63:0] end_value;
  logic [15:0] clk_divider;
  logic        clk_divider_upd;
  logic        direction;
  logic [ 7:0] addr_reg;

  parameter p_end_value_addr    = 8'h00;
  parameter p_clk_divider_addr  = 8'h10;
  parameter p_direction_addr    = 8'h20;

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

  assign {encoder_b, encoder_a} = encoder_val;
  assign change_encoder = clk_div_cnt_ov;
  assign clk_div_cnt_ov = (clk_div_cnt + 1 >= clk_divider) ? 1'b1 : 1'b0;

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      clk_div_cnt <= 16'd0;
    end else begin
      if (clk_divider_upd == 1'b1 || clk_div_cnt_ov == 1'b1) begin
        clk_div_cnt <= 16'd0;
      end else begin
        clk_div_cnt <= clk_div_cnt + 16'd1;
      end
    end
  end

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      main_fsm <= s_idle;
      encoder_val <= 2'd0;
    end else begin
      case (main_fsm)
        s_idle : begin
          if (clear_position == 1'b1) begin
            encoder_val <= 2'd0;
            main_fsm <= s_work;
          end
        end

        s_work : begin
          if (position < end_value) begin
            if (change_encoder == 1'b1 && direction == 1'b0) begin
              encoder_val <= f_inc_val(encoder_val);
            end else if (change_encoder == 1'b1) begin
              encoder_val <= f_dec_val(encoder_val);
            end
          end else if (change_encoder == 1'b1) begin
            main_fsm <= s_idle;
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
      if (clear_position == 1'b1) begin
        position <= 64'd0;
      end else if (change_encoder == 1'b1) begin
        position <= position + 'd1;
      end
    end
  end

  // Reading the registers through AXILite bus
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
  // assign CP.WREADY = 1'b1;

  always_ff @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      CP.BVALID <= 1'b0;
      CP.AWREADY <= 1'b0;
      clear_position <= 1'b0;
      addr_reg <= 'd0;
      end_value <= 64'd0;
      direction <= 1'b0;
      clk_divider_upd <= 1'b0;
      clk_divider <= 16'd0;
    end else begin
      if (CP.AWVALID == 1'b1) begin
        addr_reg <= CP.AWADDR;
      end

      if (CP.WREADY == 1'b1) begin
        CP.WREADY <= 1'b0;
      end else if (CP.AWVALID == 1'b1) begin
        CP.WREADY <= 1'b1;
      end

      if (CP.WVALID == 1'b1 && CP.WREADY == 1'b1) begin
        CP.BVALID <= 1'b1;
      end else if (CP.BREADY == 1'b1) begin
        CP.BVALID <= 1'b0;
      end

      if (CP.WVALID == 1'b1 && CP.WREADY == 1'b1 && addr_reg == p_end_value_addr) begin
        clear_position <= 1'b1;
        end_value <= CP.WDATA;
      end else begin
        clear_position <= 1'b0;
      end
      if (CP.WVALID == 1'b1 && CP.WREADY == 1'b1 && addr_reg == p_direction_addr) begin
        direction <= CP.WDATA[0];
      end
      if (CP.WVALID == 1'b1 && CP.WREADY == 1'b1 && addr_reg == p_clk_divider_addr) begin
        clk_divider_upd <= 1'b1;
        clk_divider <= CP.WDATA;
      end else begin
        clk_divider_upd <= 1'b0;
      end
    end
  end

endmodule
