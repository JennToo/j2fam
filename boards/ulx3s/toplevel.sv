module toplevel (
    input  logic [6:0] btn,
    output logic [7:0] led
);

  assign led[7:0] = {btn[1], 7'b0};

endmodule : toplevel
