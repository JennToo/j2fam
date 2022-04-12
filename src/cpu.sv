module cpu #(
    parameter unsigned CLOCK_DIVIDER = 12
) (
    input logic clock_i,
    input logic reset_i,

    input logic [7:0] data_i,
    input logic data_valid_i,

    output logic [7:0] data_o,
    output logic [15:0] address_o,
    output logic data_valid_o
);

  // TODO: Size should be based on divider
  logic [7:0] clock_divider;
  logic clock_ready;

  assign clock_ready = (clock_divider == CLOCK_DIVIDER - 1);
  // TODO: Hacks just to get something to synthesize
  assign data_o = clock_divider;

  always @(posedge clock_i) begin
    if (clock_ready) begin
      clock_divider <= 0;
    end else begin
      clock_divider <= clock_divider + 1;
    end
  end

endmodule : cpu