`timescale 1ns/1ps
`include "Zevick_lib.v"
`include "game_kernel.v"
`include "vga_modules.v"
`include "segment_led_modules.v"

module game_top(
    input CLK_100M,
    input [15:0] SW,
    input [4:0] BTN,//U0 D3 L1 R2 C4
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE,
    output VGA_HS,
    output VGA_VS,
    output [7:0] SSEG_CA,
    output [3:0] SSEG_AN

);
localparam  BOARD_X = 4,
            BOARD_Y = 4,
            GRID    = BOARD_X*BOARD_Y,
            DS      = $clog2(GRID),
            BOARD_SIZE  = DS*GRID,
            SCORE_SIZE  = 20,
            BLOCK_WIDTH = 80;

wire rst_sys=SW[15];// high-avtive

// pll
    wire CLK_VGA, clk_locked;
//    reg [1:0] clk_vga;
//    assign CLK_VGA=clk_vga[1];
//    assign CLK_VGA=CLK_100M;
//    assign CLK_VGA=CLK_100M;

    clk_wiz_0 clk_wiz_0_inst(
        .clk_in1(CLK_100M),     // IN 100Mhz
        // Clock out ports
        .clk_out1(CLK_VGA),     // OUT 25.2Mhz
        // Status and control signals	 
        .reset(rst_sys),       // pll reset, high-active
        .locked(clk_locked));   // OUT

/*    always@(posedge CLK_100M or posedge rst_sys)
    if(rst_sys)clk_vga<=0;
    else clk_vga<=clk_vga+1;*/

    
// vga singal
    wire rst_vga=SW[14]|rst_sys;// high-avtive

    vga_control vga1(
        .CP(CLK_VGA),
        .RST(rst_vga),
        .HSync(VGA_HS),
        .VSync(VGA_VS),
        .RGB({VGA_RED,VGA_GREEN,VGA_BLUE}),
        .board(board),
        .score(score),
        .timer(timer),
        .gameover(gameover),
        .image_flush(board_flush)
    );
/*
    vga_control_sample vga1(
        .CP(CLK_VGA),
        .RST(rst_vga),
        .HSync(VGA_HS),
        .VSync(VGA_VS),
        .RGB({VGA_RED,VGA_GREEN,VGA_BLUE})
    );
*/
// game kernel
    wire rst_game = SW[13]|rst_sys;// high-avtive
    wire gameover;// high-avtive
    wire [4:0] user_operation={BTN[4]|SW[8],BTN[0],BTN[1],BTN[3],BTN[2]};//restart u l d r(wasd) ,active high
    wire [BOARD_SIZE-1:0] board;
    wire [SCORE_SIZE-1:0] score;
    wire board_flush;
    game_control  gc1(
        .CLK_100M(CLK_100M),
        .RST(rst_game),
        .user_operation(user_operation),
        .board(board),
        .score(score),
        .gameover(gameover),
        .board_flush(board_flush)
    );


// timer
    wire timer_en = ~gameover, timer_rst = user_operation[4]|rst_sys;
//    wire timer_en = 1, timer_rst = 0;
    wire [15:0] timer;//minute:second


    led_timer lt1(.en(timer_en), .rst(timer_rst), .CLK_100M(CLK_100M),
    .SSEG_CA(SSEG_CA), .SSEG_AN(SSEG_AN), .timer(timer));



endmodule