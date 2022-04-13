module cpu #(
    parameter unsigned CLOCK_DIVIDER = 12
) (
    input logic clock_i,
    input logic reset_i,

    input logic [7:0] data_i,
    input logic data_valid_i,

    output logic [7:0] data_o,
    output logic [15:0] address_o,
    output logic data_valid_o,

    // Testbench signals
    output logic clock_ready_o
);

  logic [7:0] clock_divider;

  logic clock_ready;

  always_ff @(posedge clock_i) begin
    if (reset_i == 1) begin
      clock_ready   <= 0;
      clock_divider <= 0;
    end else if (clock_divider == CLOCK_DIVIDER - 1) begin
      clock_divider <= 0;
      clock_ready   <= 1;
    end else begin
      clock_divider <= clock_divider + 1;
      clock_ready   <= 0;
    end
  end

  assign clock_ready_o = clock_ready;

endmodule : cpu
