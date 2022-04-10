module toplevel (
    input  logic [6:0] btn_i,
    output logic [7:0] led_o
);

  logic [7:0] counter;

  always @(posedge btn[1]) counter <= counter + 1;

  assign led[7:0] = counter[7:0];

endmodule : toplevel
