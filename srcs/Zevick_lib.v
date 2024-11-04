`timescale 1ns/1ps


`ifndef ZEVICK_LIB
`define ZEVICK_LIB


module sync_counter
#(  
    parameter MAX_COUNT = 16
)
(
    input CP,
    input LOAD_N,
    input CLR_N,
    input ENP,
    input ENT,//carry control
    input [$clog2(MAX_COUNT)-1:0] LOAD_NUM,
    output reg [$clog2(MAX_COUNT)-1:0] Q,
    output wire RCO//extended carry flag
);

    always@(posedge CP)begin
        if(!CLR_N)Q<=0;
        else if(!LOAD_N)Q<=LOAD_NUM;
        else if(ENP&ENT)begin
            if(Q == MAX_COUNT-1)Q<=0;
            else Q<=Q+1;
        end
        else Q<=Q;
    end

    assign RCO=(Q == MAX_COUNT-1)&&ENT;

endmodule


module simple_counter
#(  
    parameter MAX_COUNT = 16
)
(
    input CP,
    input RST,
    input ENP,
    input ENT,//carry control
    output reg [$clog2(MAX_COUNT)-1:0] Q,
    output RCO//extended carry flag
);

    always@(posedge CP or posedge RST)begin
        if(RST)Q<=0;
        else if(ENP&ENT)begin
            if(Q == MAX_COUNT-1)Q<=0;
            else Q<=Q+1;
        end
        else Q<=Q;
    end

    assign RCO=(Q == MAX_COUNT-1)&&ENT;

endmodule

//default 100M,only support even division
module frequency_divider
#(  
    parameter DIV_COUNT = 100_000_000
)
(
    input CLK_I,
    input RST,
    output reg CLK_O//1:1 duty cycle
);

    reg [$clog2(DIV_COUNT)-2:0] reg_count;

    always@(posedge CLK_I, posedge RST)
        if(RST)begin 
            reg_count<=0;
            CLK_O<=0;
        end
        else if(reg_count < (DIV_COUNT/2-1))begin
            reg_count<=reg_count+1;
            CLK_O<=CLK_O;
        end
        else begin
            reg_count<=0;
            CLK_O<=~CLK_O;
        end

endmodule


//min input interval=2, ignore serial inputs(active high)
//this implies if current cycle output is 1, next must be 0
module async_to_sync(
    input CP,
    input RST,
    input D_I,
    output reg D_O//last 1 CP, 1 CP delay
);

    reg get;//extend posedge D_I to next posedge CP
    always@(posedge CP or posedge RST)
    if(RST)get<=0;
    else if(D_I)get<=1;
    else get<=0;

    reg ready;//record last state(for interval)
    always@(posedge CP or posedge RST)
    if(RST)ready<=1;
    else ready<=~get;

    always@(posedge CP)
    if(get & ready)D_O<=1;
    else D_O<=0;

endmodule


// Double dabble(combinational circuit), shift + add3
module binary_to_decimal
#(
    parameter   SIZE_I=8,
                SIZE_O=(SIZE_I+(SIZE_I+4)/5+3)/4*4//BCD_w > 1.2*BIN_w
)
(
    input [SIZE_I-1:0] BIN_I,
    output reg [SIZE_O-1:0] BCD_O
);

    integer i,j;
    always@(*)begin
        BCD_O=0;
        BCD_O[SIZE_I-1:0]=BIN_I;

    /*  for(i=0;i<SIZE_I-3;i=i+1)
        for(j=0;j<=i/3;j=j+1)
        if(BCD_O[SIZE_I-i+4*j -: 4] > 4)
            BCD_O[SIZE_I-i+4*j -: 4] = BCD_O[SIZE_I-i+4*j -: 4] + 4'd3;*/
        
        for(i=SIZE_I;i>3;i=i-1)
        for(j=i;j<SIZE_O;j=j+4)
        case(BCD_O[j -: 4])
            4'd0:BCD_O[j -: 4]=4'd0;
            4'd1:BCD_O[j -: 4]=4'd1;
            4'd2:BCD_O[j -: 4]=4'd2;
            4'd3:BCD_O[j -: 4]=4'd3;
            4'd4:BCD_O[j -: 4]=4'd4;
            4'd5:BCD_O[j -: 4]=4'd8;
            4'd6:BCD_O[j -: 4]=4'd9;
            4'd7:BCD_O[j -: 4]=4'd10;
            4'd8:BCD_O[j -: 4]=4'd11;
            4'd9:BCD_O[j -: 4]=4'd12;
            default:BCD_O[j -: 4]=4'd0;
        endcase

    end

endmodule


// Galois LFSRs
// x^8+x^6+x^5+x^4+1
// ff is prohibited
module random_8(
    input EN,
    input RST,
    output reg [7:0] NUM
);

    always@(posedge EN or posedge RST)
    if(RST)NUM<=8'h0;// inclusive or, ff is prohibited
    else NUM<={NUM[6],NUM[5]~^NUM[7],NUM[4]~^NUM[7],NUM[3]~^NUM[7],NUM[2:0],NUM[7]};

endmodule

// Galois LFSRs
// x^32+x^22+x^2+x^1+1
// ffffffff is prohibited
module random_32(
    input EN,
    input RST,
    output reg [31:0] NUM
);

    always@(posedge EN or posedge RST)
    if(RST)NUM<=32'b0;
    else 
        NUM<={NUM[30:22],NUM[21]~^NUM[31],NUM[20:2],NUM[1]~^NUM[31],NUM[0]~^NUM[31],NUM[31]};

endmodule

`endif // ZEVICK_LIB