module toplevel (
    input logic clk_25mhz_i,
    input logic [6:0] btn_i,
    output logic [7:0] led_o
);

  cpu #(
      .CLOCK_DIVIDER(12)
  ) cpu_instance (
      .reset_i(btn_i[0]),
      .clock_i(clk_25mhz_i),
      .clock_ready_o(led_o[0])
  );

endmodule : toplevel
