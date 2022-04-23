module toplevel (
    input logic clk_25mhz_i,
    input logic [27:0] gn_i,
    input logic [6:0] btn_i,
    output logic [7:0] led_o,
    output logic [27:0] gp_o
);
  logic system_clock;

  logic [7:0] cpu_data_input;
  logic cpu_data_input_valid;
  logic [7:0] cpu_data_output;
  logic cpu_data_output_valid;
  logic [15:0] cpu_address_output;
  logic cpu_bus_read_output;

  // Hacks to get some kind of synth to ensure we're in the ballpark for
  // timing etc. until I'm ready to actually hook up signals
  assign gp_o = {
    0, 0, cpu_bus_read_output, cpu_data_output_valid, cpu_address_output, cpu_data_output
  };
  assign cpu_data_input = gn_i[7:0];
  assign cpu_data_input_valid = gn_i[8];

  cpu #(
      .CLOCK_DIVIDER(12)
  ) cpu_instance (
      .reset_i(btn_i[0]),
      .clock_i(system_clock),
      .data_o(cpu_data_output),
      .bus_write_o(cpu_data_output_valid),
      .address_o(cpu_address_output),
      .bus_read_o(cpu_bus_read_output),
      .data_i(cpu_data_input),
      .data_valid_i(cpu_data_input_valid)
  );

  ECP5_PLL #(
      .IN_MHZ  (25),
      .OUT0_MHZ(21.477272),
      .OUT1_MHZ(30),
      .OUT3_MHZ(100)
  ) pll (
      .clkin  (clk_25mhz_i),
      .reset  (1'b0),
      .standby(1'b0),
      .locked (locked),
      .clkout0(system_clock)
  );

endmodule : toplevel
