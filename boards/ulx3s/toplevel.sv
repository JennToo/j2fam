module toplevel (
    input logic clk_25mhz_i,
    input logic [27:0] gn_i,
    input logic [6:0] btn_i,
    output logic [7:0] led_o,
    output logic [27:0] gp_o
);

  logic [7:0] cpu_data_input;
  logic cpu_data_input_valid;
  logic [7:0] cpu_data_output;
  logic cpu_data_output_valid;
  logic [15:0] cpu_address_output;
  logic cpu_address_output_valid;

  // Hacks to get some kind of synth to ensure we're in the ballpark for
  // timing etc. until I'm ready to actually hook up signals
  assign gp_o = {
    0, 0, cpu_address_output_valid, cpu_data_output_valid, cpu_address_output, cpu_data_output
  };
  assign cpu_data_input = {gn_i[7:0]};
  assign cpu_data_input_valid = gn_i[8];

  cpu #(
      .CLOCK_DIVIDER(12)
  ) cpu_instance (
      .reset_i(btn_i[0]),
      .clock_i(clk_25mhz_i),
      .data_o(cpu_data_output),
      .data_valid_o(cpu_data_output_valid),
      .address_o(cpu_address_output),
      .address_valid_o(cpu_address_output_valid),
      .data_i(cpu_data_input),
      .data_valid_i(cpu_data_input_valid)
  );

endmodule : toplevel
