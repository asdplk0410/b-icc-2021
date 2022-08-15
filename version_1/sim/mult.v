module mult #(parameter WIDTH = 10)(a, b, product);

input signed [WIDTH-1:0] a, b;
output [21-1:0] product;

assign product = a * b;

endmodule