//synopsys translate_off
`include "./DW_sqrt.v"
`include "/cad/synopsys/synthesis/2020.09/dw/sim_ver/DW_square.v"
`include "/cad/synopsys/synthesis/2020.09/dw/sim_ver/DW02_mult.v"
//synopsys translate_on

module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output valid;
output is_inside;

localparam IDLE = 3'd0;
localparam RECV = 3'd1;
localparam COMPARE = 3'd2;
localparam SORT = 3'd3;
localparam CALCULATE = 3'd4;
localparam JUDGEMENT = 3'd5;

reg [2:0] ps, ns;
reg [10:0] x_reg[0:5], y_reg[0:5], r_reg[0:5];
reg [2:0] index_i, index_A, index_B;
reg [3:0] index_s;
reg [2:0] index_j;
reg valid;
reg is_inside;

wire [10:0] Ax, Ay, Bx, By;
wire N;
wire signed [21:0] AxBy, BxAy;

//state switch
always@(posedge clk or posedge reset) begin
    if(reset) begin
        ps <= RECV;
    end
    else begin
        ps <= ns;
    end
end

//next state logic
always@(*) begin
    case(ps)
    IDLE: ns = RECV;
    RECV: begin
        ns = (index_i >= 5) ? COMPARE : RECV;
    end
    COMPARE: begin
        ns = SORT;
    end
    SORT: begin
        ns = (index_s > 9) ? CALCULATE : COMPARE;
    end
    CALCULATE: begin
        ns = (index_j > 5) ? JUDGEMENT : CALCULATE; // 5+1 for acc
    end
    JUDGEMENT: ns = IDLE;
    default: ns = IDLE;
    endcase 
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        index_s <= 3'd0;
    end
    else if(ps == COMPARE) begin
        index_s <= index_s + 3'd1;
    end
    else if(ps == SORT) index_s <= index_s;
    else index_s <= 3'd0;
end

assign Ax = x_reg[index_A] - x_reg[0];
assign Ay = y_reg[index_A] - y_reg[0];
assign Bx = x_reg[index_B] - x_reg[0];
assign By = y_reg[index_B] - y_reg[0];

// cross product
DW02_mult #(.A_width(11), .B_width(11)) u_mult_AxBy (.A(Ax), .B(By), .TC(1'd1), .PRODUCT(AxBy));
DW02_mult #(.A_width(11), .B_width(11)) u_mult_BxAy (.A(Bx), .B(Ay), .TC(1'd1), .PRODUCT(BxAy));

assign N = (AxBy - BxAy < 0) ? 1'd1 : 1'd0; 

always @(posedge clk or posedge reset) begin
    if(reset) begin
        index_A <= 3'd0;
    end
    else if(ps == COMPARE) begin
        case (index_s)
            4'd0: index_A <= 3'd1;
            4'd1: index_A <= 3'd2;
            4'd2: index_A <= 3'd3;
            4'd3: index_A <= 3'd4;
            4'd4: index_A <= 3'd1;
            4'd5: index_A <= 3'd2;
            4'd6: index_A <= 3'd3;
            4'd7: index_A <= 3'd1;
            4'd8: index_A <= 3'd2;
            4'd9: index_A <= 3'd1;
            default:;
        endcase
    end
    else if(ps == CALCULATE) begin
        case (index_j)
            4'd0: index_A <= 3'd0;
            4'd1: index_A <= 3'd1;
            4'd2: index_A <= 3'd2;
            4'd3: index_A <= 3'd3;
            4'd4: index_A <= 3'd4;
            4'd5: index_A <= 3'd5;
            default:;
        endcase
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        index_B <= 3'd0;
    end
    else if(ps == COMPARE) begin
        case (index_s)
            4'd0: index_B <= 3'd2;
            4'd1: index_B <= 3'd3;
            4'd2: index_B <= 3'd4;
            4'd3: index_B <= 3'd5;
            4'd4: index_B <= 3'd2;
            4'd5: index_B <= 3'd3;
            4'd6: index_B <= 3'd4;
            4'd7: index_B <= 3'd2;
            4'd8: index_B <= 3'd3;
            4'd9: index_B <= 3'd2;
            default:;
        endcase
    end
    else if(ps == CALCULATE) begin
        case (index_j)
            4'd0: index_B <= 3'd1;
            4'd1: index_B <= 3'd2;
            4'd2: index_B <= 3'd3;
            4'd3: index_B <= 3'd4;
            4'd4: index_B <= 3'd5;
            4'd5: index_B <= 3'd0;
            default:;
        endcase
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        index_i <= 3'd0;
    end
    else if(ps == RECV) begin
        index_i <= index_i + 3'd1;
    end
    else index_i <= 3'd0;
end

integer i;
always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<6;i=i+1) begin
            x_reg[i] <= 10'd0;
        end
    end
    else if(ps == RECV) begin
        x_reg[index_i] <= {1'd0,X};
    end
    else if(ps == SORT) begin
        if(N) begin
            x_reg[index_A] <= x_reg[index_B];
            x_reg[index_B] <= x_reg[index_A];
        end
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<6;i=i+1) begin
            y_reg[i] <= 10'd0;
        end
    end
    else if(ps == RECV) begin
        y_reg[index_i] <= {1'd0,Y};
    end
    else if(ps == SORT) begin
        if(N) begin
            y_reg[index_A] <= y_reg[index_B];
            y_reg[index_B] <= y_reg[index_A];
        end
    end
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<6;i=i+1) begin
            r_reg[i] <= 10'd0;
        end
    end
    else if(ps == RECV) begin
        r_reg[index_i] <= R;
    end
    else if(ps == SORT) begin
        if(N) begin
            r_reg[index_A] <= r_reg[index_B];
            r_reg[index_B] <= r_reg[index_A];
        end
    end
end

// length
wire [21:0] x_2, y_2;
wire [10:0] a, b, c;

DW_square #(.width(11)) u_square_x2 (.a(x_reg[index_A] - x_reg[index_B]), .tc(1'd1), .square(x_2));
DW_square #(.width(11)) u_square_y2 (.a(y_reg[index_A] - y_reg[index_B]), .tc(1'd1), .square(y_2));
DW_sqrt #(.width(22), .tc_mode(0)) u_sqrt_x2_y2 (.a(x_2 + y_2), .root(a));

// tri area
wire [12:0] s;
wire [25:0] s_sa, sb_sc, abs_s_sa, abs_sb_sc; 
wire [25:0] area;
wire [12:0] root_s_sa, root_sb_sc;
reg  [28:0] acc_area;

assign b = r_reg[index_A];
assign c = r_reg[index_B];
assign s = (a + b + c)/2;

DW02_mult #(.A_width(13), .B_width(13)) u_mult_s_sa (.A(s), .B(s - a), .TC(1'd1), .PRODUCT(s_sa));
DW02_mult #(.A_width(13), .B_width(13)) u_mult_sb_sc (.A(s - b), .B(s - c), .TC(1'd1), .PRODUCT(sb_sc));
assign	abs_s_sa = (s_sa[25-1])? (~s_sa + 1'b1) : s_sa;
assign	abs_sb_sc = (sb_sc[25-1])? (~sb_sc + 1'b1) : sb_sc;
DW_sqrt #(.width(26), .tc_mode(0)) u_sqrt_s_sa (.a(abs_s_sa), .root(root_s_sa));
DW_sqrt #(.width(26), .tc_mode(0)) u_sqrt_sb_sc (.a(abs_sb_sc), .root(root_sb_sc));
DW02_mult #(.A_width(13), .B_width(13)) u_mult_area (.A(root_s_sa), .B(root_sb_sc), .TC(1'd1), .PRODUCT(area));

// hexagon area
wire [21:0] xy_AB, xy_BA;
reg [28:0] hex_area; 

DW02_mult #(.A_width(11), .B_width(11)) u_mult_xy_01 (.A(x_reg[index_A]), .B(y_reg[index_B]), .TC(1'd1), .PRODUCT(xy_AB));
DW02_mult #(.A_width(11), .B_width(11)) u_mult_xy_10 (.A(x_reg[index_B]), .B(y_reg[index_A]), .TC(1'd1), .PRODUCT(xy_BA));

always @(posedge clk or posedge reset) begin
    if(reset) begin
        index_j <= 3'd0;
    end
    else if(ps == CALCULATE) begin
        index_j <= index_j + 3'd1;
    end
    else index_j <= 3'd0;
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        acc_area <= 29'd0;
    end
    else if(ps == CALCULATE) begin
        acc_area <= (index_j) ? acc_area + {3'd0,area} : 29'd0; //index_j == 0 dont add
    end
    else if(ps == JUDGEMENT) acc_area <= acc_area;
    else acc_area <= 29'd0;
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        hex_area <= 29'd0;
    end
    else if(ps == CALCULATE) begin
        hex_area <= (index_j) ? hex_area + (xy_AB - xy_BA) : 29'd0; //index_j == 0 dont add
    end
    else if(ps == JUDGEMENT) hex_area <= hex_area;
    else hex_area <= 29'd0;
end

// output
always @(posedge clk or posedge reset) begin
    if(reset) valid <= 1'd0;
    else if(ps == JUDGEMENT) valid <= 1'd1;
    else valid <= 1'd0;
end

always @(posedge clk or posedge reset) begin
    if(reset) is_inside <= 1'd0;
    else if(ps == JUDGEMENT) is_inside <= (acc_area > hex_area/2) ? 1'd0 : 1'd1;
    else is_inside <= 1'd0;
end

endmodule

