module ip_wrapper #(
  parameter DATA_WIDTH = 8
) (
  input wire clk,
  input wire rst,

  input wire in_fifo_wr_en,
  input wire [DATA_WIDTH-1:0] in_fifo_din,
  output wire in_fifo_empty,
  output wire in_fifo_full,

  output wire out_fifo_wr_en,
  output wire [DATA_WIDTH-1:0] out_fifo_dout,
  input wire out_fifo_empty,
  input wire out_fifo_full,

  input wire cs,
  input wire sclk,
  input wire mosi,
  output wire miso
);
  wire [DATA_WIDTH-1:0] pe_din;
  wire [DATA_WIDTH-1:0] pe_dout;
  fifo #(DATA_WIDTH, 8) u_fifo (clk, rst, in_fifo_wr_en, !in_fifo_empty, in_fifo_din, pe_din, in_fifo_empty, in_fifo_full);
  spi u_spi (clk, rst, cs, sclk, mosi, miso);
  pe u_pe (pe_din, !in_fifo_empty, pe_dout, out_fifo_wr_en);
endmodule

module fifo #(
  parameter DATA_WIDTH = 8,
  parameter FIFO_DEPTH = 8
) (
  input wire clk,
  input wire rst,
  input wire wr_en,
  input wire rd_en,
  input wire [DATA_WIDTH-1:0] din,
  output wire [DATA_WIDTH-1:0] dout,
  output wire empty,
  output wire full
);

  reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
  reg [FIFO_DEPTH-1:0] wr_ptr;
  reg [FIFO_DEPTH-1:0] rd_ptr;
  reg [FIFO_DEPTH-1:0] next_wr_ptr;
  reg [FIFO_DEPTH-1:0] next_rd_ptr;
  wire [FIFO_DEPTH-1:0] diff;
  
  assign empty = (wr_ptr == rd_ptr);
  assign full = ((next_wr_ptr == rd_ptr) && (wr_ptr != rd_ptr));
  
  assign dout = mem[rd_ptr];
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
    end
    else begin
      wr_ptr <= next_wr_ptr;
      rd_ptr <= next_rd_ptr;
    end
  end
  
  always @(posedge clk) begin
    if (wr_en && !full) begin
      mem[next_wr_ptr] <= din;
    end
  end
  
  always @(posedge clk) begin
    if (rd_en && !empty) begin
      next_rd_ptr <= next_rd_ptr + 1;
    end
  end
  
  always @(posedge clk) begin
    if (wr_en && !full) begin
      next_wr_ptr <= next_wr_ptr + 1;
    end
  end
  
  assign diff = next_wr_ptr - rd_ptr;
  
endmodule

module spi (
  input wire clk,
  input wire rst,
  input wire cs,
  input wire sclk,
  input wire mosi,
  output wire miso
);

  reg [7:0] data_reg;
  reg [2:0] bit_counter;
  reg [7:0] shift_reg;
  wire mosi_bit;
  reg sclk_prev;
  
  assign mosi_bit = mosi;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_reg <= 0;
      bit_counter <= 0;
      shift_reg <= 0;
      sclk_prev <= 1'b1;
    end
    else begin
      if (cs) begin
        bit_counter <= 0;
        sclk_prev <= 1'b1;
      end
      else begin
        if (sclk && ~sclk_prev) begin
          case (bit_counter)
            0: begin
              shift_reg <= {shift_reg[6:0], mosi_bit};
            end
            1,2,3,4,5,6,7: begin
              shift_reg <= {shift_reg[6:0], mosi_bit};
            end
            8: begin
              data_reg <= shift_reg;
              bit_counter <= 0;
            end
            default: begin
              bit_counter <= 0;
            end
          endcase
          bit_counter <= bit_counter + 1;
        end
        sclk_prev <= sclk;
      end
    end
  end
  
  assign miso = data_reg[7];
  
endmodule

module pe (
  input wire [7:0] din,
  input wire data_valid,
  output wire [7:0] dout,
  output wire data_ready
);
  assign dout = din;
  assign data_ready = 1;
endmodule