module toplevel (
    input  logic [6:0] btn,
    output logic [7:0] led
);

  assign led = {btn[1], 7'0};

endmodule : toplevel
