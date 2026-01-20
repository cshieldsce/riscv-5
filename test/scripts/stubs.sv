// Dummy stubs for Xilinx IP cores to allow simulation/linting without Vivado libraries

module clk_wiz_0 (
    input  logic clk_in1,
    output logic clk_out1,
    output logic locked
);
    assign clk_out1 = clk_in1;
    assign locked = 1'b1;
endmodule

module ila_0 (
    input logic clk,
    input logic [255:0] probe0
);
endmodule
