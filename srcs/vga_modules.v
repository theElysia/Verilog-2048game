`timescale 1ns/1ps
`include "Zevick_lib.v"

`define VGA_640x480x60//default VGA_1024x768x60

module vga_control_sample(
    input CP,
    input RST,
    output reg HSync,
    output reg VSync,
    output reg [11:0] RGB//11:8 R  7:4 G  3:0 B
);

`ifdef VGA_640x480x60// PLL clk = 25.2M = 800*525*60
    localparam  HS_1 = 96,   // Sync
                HS_2 = 48,   // Back Porch (Left Border)
                HS_3 = 640,  // Addressable Video
                HS_4 = 16,   // Front Porch (Right Border)
                HS_5 = 800,  // Entire Period
                
                VS_1 = 2,
                VS_2 = 33,
                VS_3 = 480,
                VS_4 = 10,
                VS_5 = 525;
`else //VGA_1024x768x60 PLL clk = 65M
    localparam  HS_1 = 136,
                HS_2 = 160,
                HS_3 = 1024,
                HS_4 = 24,
                HS_5 = 1344,
                
                VS_1 = 6,
                VS_2 = 29,
                VS_3 = 768,
                VS_4 = 3,
                VS_5 = 805;
`endif

    reg [9:0] pos_x,pos_y;

//----------------------Sync signal--------------------------------
    always@(posedge CP or posedge RST)
        if(RST)begin pos_x<=0;pos_y<=0;end
        else if(pos_x == HS_5-1) begin
            pos_x<=0;
            if(pos_y == VS_5-1)pos_y<=0;
            else pos_y<=pos_y+1;
        end
        else pos_x<=pos_x+1;

    always@(posedge CP or posedge RST)
        if(RST)HSync<=1;
        else if(pos_x == HS_3+HS_4 )HSync<=0;
        else if(pos_x == HS_3+HS_4+HS_1 )HSync<=1;

    always@(posedge CP or posedge RST)
        if(RST)VSync<=1;
        else if(pos_y == VS_3+VS_4 )VSync<=0;
        else if(pos_y == VS_3+VS_4+VS_1 )VSync<=1;
    
//----------------------color constant--------------------------------
     
localparam	RED     = 12'hf00,
            GREEN   = 12'h0f0,
            BLUE    = 12'h00f,
            WHITE   = 12'hfff,
            BLACK   = 12'h000;

localparam  BG1     = 12'hffe,//background
            FR      = 12'hbaa,//framework
            NUM1    = 12'h766,//2 4
            NUM2    = 12'hfff,//other number
            B0      = 12'hccb,//blank
            B1      = 12'heed,//2
            B2      = 12'heec,//4
            B3      = 12'hfb7,//8
            B4      = 12'hf96,//16
            B5      = 12'hf75,//32
            B6      = 12'hf53,//64
            B7      = 12'hec7,//128
            B8      = 12'hec6,//256
            B9      = 12'h00c,//512
            B10     = 12'h3be,//1024
            B11     = 12'h009,//2048
            B12     = 12'h006,//4096
            B13     = 12'h003;//8192

//----------------------RGB  generator--------------------------------
    wire en=(pos_x < HS_3)&&(pos_y < VS_3);
/*    always@(posedge CP)
    casex({en,pos_x[9:6]})
        5'b0????:RGB=WHITE;
        5'b10000:RGB=B0;
        5'b10001:RGB=B1;
        5'b10010:RGB=B2;
        5'b10011:RGB=B3;
        5'b10100:RGB=B4;
        5'b10101:RGB=B5;
        5'b10110:RGB=B6;
        5'b10111:RGB=B7;
        5'b11000:RGB=B8;
        5'b11001:RGB=B9;
        default:RGB=BLACK;
    endcase*/
//    always@(posedge CP) RGB=WHITE;
always@(posedge CP)
if(pos_x<160)RGB<=RED;
else if(pos_x<320)RGB<=GREEN;
else if(pos_x<480) RGB<=BLUE;
else if(pos_x<640) RGB<=WHITE;
else RGB<=BLACK;
/*always@(posedge CP)
if(pos_x<160)RGB<=RED;
else if(pos_x<320)RGB<=GREEN;
else RGB<=BLUE;*/

endmodule




module vga_control(
    input CP,
    input RST,
    input [63:0] board,
    input [19:0] score,
    input [15:0] timer,
    input gameover,
    input image_flush,// boardscore timer
    output reg HSync,
    output reg VSync,
    output reg [11:0] RGB//11:8 R  7:4 G  3:0 B
);

`ifdef VGA_640x480x60// PLL clk = 25.2M = 800*525*60
    localparam  HS_1 = 96,   // Sync
                HS_2 = 48,   // Back Porch (Left Border)
                HS_3 = 640,  // Addressable Video
                HS_4 = 16,   // Front Porch (Right Border)
                HS_5 = 800,  // Entire Period
                
                VS_1 = 2,
                VS_2 = 33,
                VS_3 = 480,
                VS_4 = 10,
                VS_5 = 525;
`else //VGA_1024x768x60 PLL clk = 65M
    localparam  HS_1 = 136,
                HS_2 = 160,
                HS_3 = 1024,
                HS_4 = 24,
                HS_5 = 1344,
                
                VS_1 = 6,
                VS_2 = 29,
                VS_3 = 768,
                VS_4 = 3,
                VS_5 = 805;
`endif

    reg [9:0] pos_x,pos_y;

//----------------------Sync signal--------------------------------
    always@(posedge CP or posedge RST)
        if(RST)begin pos_x<=0;pos_y<=0;end
        else if(pos_x == HS_5-1) begin
            pos_x<=0;
            if(pos_y == VS_5-1)pos_y<=0;
            else pos_y<=pos_y+1;
        end
        else pos_x<=pos_x+1;

    always@(posedge CP or posedge RST)
        if(RST)HSync<=1;
        else if(pos_x == HS_3+HS_4 )HSync<=0;
        else if(pos_x == HS_3+HS_4+HS_1 )HSync<=1;

    always@(posedge CP or posedge RST)
        if(RST)VSync<=1;
        else if(pos_y == VS_3+VS_4 )VSync<=0;
        else if(pos_y == VS_3+VS_4+VS_1 )VSync<=1;
    
//----------------------color constant--------------------------------
     
localparam	RED     = 12'hf00,
            GREEN   = 12'h0f0,
            BLUE    = 12'h00f,
            WHITE   = 12'hfff,
            BLACK   = 12'h000;

localparam  BG1     = 12'hffe,//background
            FR      = 12'hbaa,//framework
            NUM1    = 12'h766,//2 4
            NUM2    = 12'hfff,//other number
            B0      = 12'hccb,//blank
            B1      = 12'heed,//2
            B2      = 12'heec,//4
            B3      = 12'hfb7,//8
            B4      = 12'hf96,//16
            B5      = 12'hf75,//32
            B6      = 12'hf53,//64
            B7      = 12'hec7,//128
            B8      = 12'hec6,//256
            B9      = 12'h00c,//512
            B10     = 12'h3be,//1024
            B11     = 12'h009,//2048
            B12     = 12'h006,//4096
            B13     = 12'h003;//8192

//----------------------RGB  generator--------------------------------
    wire en=(pos_x < HS_3)&&(pos_y < VS_3);//9:0
    reg [7:0] board_num_dot [0:1023];
    reg [7:0] dot_ascii_id1,dot_ascii_id2;
    reg [3:0] dot_row1,dot_row2;
    wire [7:0] dot1,dot2;
    reg [7:0] flush_clk_cnt;
    reg [6:0] flush_state1;
    reg [3:0] flush_state2;
    wire [1:0] fflush;

    ascii8x16 asc1(.id(dot_ascii_id1), .row(dot_row1), .dot(dot1));
    ascii8x16 asc2(.id(dot_ascii_id2), .row(dot_row2), .dot(dot2));

    always @(posedge CP) flush_clk_cnt<=flush_clk_cnt+1;
    async_to_sync atsfl1(.CP(flush_clk_cnt[6]), .RST(RST), .D_I(image_flush), .D_O(fflush[1]));

// board    
    always @(posedge flush_clk_cnt[6])
    if(flush_state1==0)begin
        if(image_flush)flush_state1<=64;
        else flush_state1<=0;
    end
    else flush_state1<=flush_state1+1;//everytime update 4 ascii

    always @(*)
        case({flush_state1[1:0],board[{flush_state1[5:2],2'b00} +: 4]})
            6'h21:dot_ascii_id1=8'h32;
            6'h22:dot_ascii_id1=8'h34;
            6'h23:dot_ascii_id1=8'h38;//8
            6'h14:dot_ascii_id1=8'h31;
            6'h24:dot_ascii_id1=8'h36;
            6'h15:dot_ascii_id1=8'h33;
            6'h25:dot_ascii_id1=8'h32;
            6'h16:dot_ascii_id1=8'h36;
            6'h26:dot_ascii_id1=8'h34;//64
            6'h17:dot_ascii_id1=8'h31;
            6'h27:dot_ascii_id1=8'h32;
            6'h37:dot_ascii_id1=8'h38;
            6'h18:dot_ascii_id1=8'h32;
            6'h28:dot_ascii_id1=8'h35;
            6'h38:dot_ascii_id1=8'h36;
            6'h19:dot_ascii_id1=8'h35;
            6'h29:dot_ascii_id1=8'h31;
            6'h39:dot_ascii_id1=8'h32;//512
            6'h0a:dot_ascii_id1=8'h31;
            6'h1a:dot_ascii_id1=8'h30;
            6'h2a:dot_ascii_id1=8'h32;
            6'h3a:dot_ascii_id1=8'h34;
            6'h0b:dot_ascii_id1=8'h32;
            6'h1b:dot_ascii_id1=8'h30;
            6'h2b:dot_ascii_id1=8'h34;
            6'h3b:dot_ascii_id1=8'h38;
            6'h0c:dot_ascii_id1=8'h34;
            6'h1c:dot_ascii_id1=8'h30;
            6'h2c:dot_ascii_id1=8'h39;
            6'h3c:dot_ascii_id1=8'h36;
            6'h0d:dot_ascii_id1=8'h38;
            6'h1d:dot_ascii_id1=8'h31;
            6'h2d:dot_ascii_id1=8'h39;
            6'h3d:dot_ascii_id1=8'h32;//8192
            default:dot_ascii_id1=8'h0;
        endcase

    always @(posedge flush_clk_cnt[1])begin
        dot_row1<=dot_row1+1;
        board_num_dot[{flush_state1[5:0],dot_row1[3:0]}]<=dot1;
    end

// score&timer
    reg [7:0] score_dot [127:0];
    reg [7:0] timer_dot [95:0];

    reg [7:0] character_gameover [0:127];//x 6789 y 6
    reg [7:0] character_dot [0:24*16-1];//x 678 y 1234  1 score  3 time
    wire [7:0] character_dot_wire [0:18*16-1];// constant
    localparam score_ascii = 40'h53636f7265,//Score
                time_ascii = 32'h74696d65,//time
                gameover_ascii = 64'h47414d454f564552;//GAMEOVER

    reg [19:0] score_tmp;
    wire [23:0] score_bcd;//timer[15:0]
    binary_to_decimal #(.SIZE_I(20),.SIZE_O(24))
    btd1(.BIN_I(score_tmp), .BCD_O(score_bcd));
    always @(posedge flush_clk_cnt[6])if(image_flush)score_tmp<=score;

    reg last_timer;
    always @(posedge flush_clk_cnt[6])last_timer<=timer[0];
//    reg flag_prefix0;
    always @(posedge flush_clk_cnt[6])
    if(flush_state2==0)begin
    //    flag_prefix0<=0;
        if(image_flush||(last_timer^timer[0]))flush_state2<=1;
        else flush_state2<=0;
    end
    else if(flush_state2==10)flush_state2<=0;
    else flush_state2<=flush_state2+1;

    always @(*)
        case(flush_state2[3:0])
            4'h1:dot_ascii_id2={4'h3,score_bcd[23:20]};
            4'h2:dot_ascii_id2={4'h3,score_bcd[19:16]};
            4'h3:dot_ascii_id2={4'h3,score_bcd[15:12]};
            4'h4:dot_ascii_id2={4'h3,score_bcd[11:8]};
            4'h5:dot_ascii_id2={4'h3,score_bcd[7:4]};
            4'h6:dot_ascii_id2={4'h3,score_bcd[3:0]};
            4'h7:dot_ascii_id2={4'h3,timer[15:12]};
            4'h8:dot_ascii_id2={4'h3,timer[11:8]};
            4'h9:dot_ascii_id2={4'h3,timer[7:4]};
            4'h10:dot_ascii_id2={4'h3,timer[3:0]};
            default:dot_ascii_id2=8'h0;
        endcase
    
    always @(posedge flush_clk_cnt[1])begin
        dot_row2<=dot_row2+1;
        case(flush_state2[3:0])
            4'h1:character_dot[{5'd6,dot_row2}]<=dot2;
            4'h2:character_dot[{5'd7,dot_row2}]<=dot2;
            4'h3:character_dot[{5'd8,dot_row2}]<=dot2;
            4'h4:character_dot[{5'd9,dot_row2}]<=dot2;
            4'h5:character_dot[{5'd10,dot_row2}]<=dot2;
            4'h6:character_dot[{5'd11,dot_row2}]<=dot2;
            4'h7:character_dot[{5'd19,dot_row2}]<=dot2;
            4'h8:character_dot[{5'd20,dot_row2}]<=dot2;
            4'h9:character_dot[{5'd22,dot_row2}]<=dot2;
            4'h10:character_dot[{5'd23,dot_row2}]<=dot2;
        endcase
    end

    genvar gen_i,gen_j;
    generate
        begin:gen_asci0;
            for(gen_j=0;gen_j<5;gen_j=gen_j+1)
            for(gen_i=0;gen_i<16;gen_i=gen_i+1)begin:gen_asci_1
                ascii8x16 asci_gen1(.id(score_ascii[8*(5-gen_j)-1 -: 8]),
                .row(gen_i), .dot(character_dot_wire[gen_j*16+gen_i]));
            end
            for(gen_j=0;gen_j<4;gen_j=gen_j+1)
            for(gen_i=0;gen_i<16;gen_i=gen_i+1)begin:gen_asci_2
                ascii8x16 asci_gen2(.id(time_ascii[8*(4-gen_j)-1 -: 8]),
                .row(gen_i), .dot(character_dot_wire[(5+gen_j)*16+gen_i]));
            end
            for(gen_j=0;gen_j<8;gen_j=gen_j+1)
            for(gen_i=0;gen_i<16;gen_i=gen_i+1)begin:gen_asci_3
                ascii8x16 asci_gen3(.id(gameover_ascii[8*(8-gen_j)-1 -: 8]),
                .row(gen_i), .dot(character_dot_wire[(9+gen_j)*16+gen_i]));
            end
            for(gen_i=0;gen_i<16;gen_i=gen_i+1)begin:gen_asci_4
                ascii8x16 asci_gen3(.id(8'h3a),// :
                .row(gen_i), .dot(character_dot_wire[17*16+gen_i]));
            end
        end
    endgenerate

    integer int_i,int_j;
    always@(*)begin
        for(int_j=0;int_j<5;int_j=int_j+1)
        for(int_i=0;int_i<16;int_i=int_i+1)
        character_dot[int_j*16+int_i]=character_dot_wire[int_j*16+int_i];

        for(int_j=0;int_j<4;int_j=int_j+1)
        for(int_i=0;int_i<16;int_i=int_i+1)
        character_dot[(12+int_j)*16+int_i]=character_dot_wire[(5+int_j)*16+int_i];

        for(int_j=0;int_j<8;int_j=int_j+1)
        for(int_i=0;int_i<16;int_i=int_i+1)
        character_gameover[int_j*16+int_i]=character_dot_wire[(9+int_j)*16+int_i];

        for(int_i=0;int_i<16;int_i=int_i+1)
        character_dot[21*16+int_i]=character_dot_wire[17*16+int_i];
    end

//--------------------------------------------------------------------
    reg [3:0] board_num;
    reg [11:0] num_back_color,num_color;

    always@(*)
    casex(board_num)
        4'h0:num_back_color=B0;
        4'h1:num_back_color=B1;
        4'h2:num_back_color=B2;
        4'h3:num_back_color=B3;
        4'h4:num_back_color=B4;
        4'h5:num_back_color=B5;
        4'h6:num_back_color=B6;
        4'h7:num_back_color=B7;
        4'h8:num_back_color=B8;
        4'h9:num_back_color=B9;
        4'ha:num_back_color=B10;
        4'hb:num_back_color=B11;
        4'hc:num_back_color=B12;
        default:num_back_color=B13;
    endcase

    always@(*)
    casex(board_num)
        4'h1:num_color=NUM1;
        4'h2:num_color=NUM1;
        default:num_color=NUM2;
    endcase

    reg [7:0] num_dot_line;
    wire [1:0] tttx = pos_x[8:6]-1;
    always@(*)num_dot_line=board_num_dot[{~pos_y[7],pos_y[6],tttx,pt}];
    wire yc=pos_y[5]^pos_y[4];
    wire ycdot=yc&num_dot_line[pos_x[3:1]];
    wire [5:0] pt = {pos_x[5:4],pos_y[5],pos_y[3:1]};
    wire frx=(&pos_x[5:2]),fry=(&pos_y[5:2]);
    wire frxy=frx|fry;
    wire [4:0] chadot_xtmp=pos_x[9:5]+6*pos_y[8:6]-18;

    always@(*)
    casex({pos_y[9:6],en,pos_x[9:6]})
        9'b001010001:board_num=board[3:0];
        9'b001010010:board_num=board[7:4];
        9'b001010011:board_num=board[11:8];
        9'b001010100:board_num=board[15:12];
        9'b001110001:board_num=board[19:16];
        9'b001110010:board_num=board[23:20];
        9'b001110011:board_num=board[27:24];
        9'b001110100:board_num=board[31:28];
        9'b010010001:board_num=board[35:32];
        9'b010010010:board_num=board[39:36];
        9'b010010011:board_num=board[43:40];
        9'b010010100:board_num=board[47:44];
        9'b010110001:board_num=board[51:48];
        9'b010110010:board_num=board[55:52];
        9'b010110011:board_num=board[59:56];
        9'b010110100:board_num=board[63:60];
        default:board_num=board[3:0];
    endcase

    always@(posedge CP)
    casex({pos_y[9:6],en,pos_x[9:6]})//y 0-7 x 0-9
        9'b????0????:RGB=BLACK;
        9'b000110001:RGB=fry?FR:BG1;
        9'b000110010:RGB=fry?FR:BG1;
        9'b000110011:RGB=fry?FR:BG1;
        9'b000110100:RGB=fry?FR:BG1;
        9'b001010000:RGB=frx?FR:BG1;
        9'b001110000:RGB=frx?FR:BG1;
        9'b010010000:RGB=frx?FR:BG1;
        9'b010110000:RGB=frx?FR:BG1;
        //y 2,3,4,5  x 1,2,3,4
        9'b001010001:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001010010:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001010011:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001010100:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001110001:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001110010:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001110011:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b001110100:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010010001:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010010010:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010010011:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010010100:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010110001:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010110010:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010110011:RGB=ycdot?num_color: frxy?FR:num_back_color;
        9'b010110100:RGB=ycdot?num_color: frxy?FR:num_back_color;
        //    9'b????10110://right
        // score&time x 678 y 1234
        9'b00?11011?:RGB=character_dot[{chadot_xtmp,pos_y[5:2]}][pos_x[4:2]]?BLACK:BG1;
        9'b00?111000:RGB=character_dot[{chadot_xtmp,pos_y[5:2]}][pos_x[4:2]]?BLACK:BG1;
        9'b00101011?:RGB=character_dot[{chadot_xtmp,pos_y[5:2]}][pos_x[4:2]]?BLACK:BG1;
        9'b001011000:RGB=character_dot[{chadot_xtmp,pos_y[5:2]}][pos_x[4:2]]?BLACK:BG1;
        9'b01001011?:RGB=character_dot[{chadot_xtmp,pos_y[5:2]}][pos_x[4:2]]?BLACK:BG1;
        9'b010011000:RGB=character_dot[{chadot_xtmp,pos_y[5:2]}][pos_x[4:2]]?BLACK:BG1;
        // gameover y 6 x 5678
        9'b011010101:RGB=(gameover&&character_gameover[{(pos_x[9:5]-10),pos_y[5:2]}][pos_x[4:2]])?BLACK:BG1;
        9'b01101011?:RGB=(gameover&&character_gameover[{(pos_x[9:5]-10),pos_y[5:2]}][pos_x[4:2]])?BLACK:BG1;
        9'b011011000:RGB=(gameover&&character_gameover[{(pos_x[9:5]-10),pos_y[5:2]}][pos_x[4:2]])?BLACK:BG1;
        default:RGB=BG1;
    endcase

endmodule



// using 272 LUT in synthesis
// 8*16 size ascii dot matrix font(32-127)
// so there is huge expansion space
module ascii8x16(
    input [7:0] id,
    input [3:0] row,
    output [7:0] dot
);
    reg [127:0] pic;
    always@(*)
    case(id)
        8'h20:pic<=128'h00000000000000000000000000000000;
        8'h21:pic<=128'h00000010101010101010000010100000;
        8'h22:pic<=128'h00122424480000000000000000000000;
        8'h23:pic<=128'h0000001212127e2424247e2424240000;
        8'h24:pic<=128'h0000083c4a4a48380c0a0a4a4a3c0808;
        8'h25:pic<=128'h00000044a4a8a8b0541a2a2a4a440000;
        8'h26:pic<=128'h00000030484848506ea4949889760000;
        8'h27:pic<=128'h00602020400000000000000000000000;
        8'h28:pic<=128'h00020408081010101010100808040200;
        8'h29:pic<=128'h00402010100808080808081010204000;
        8'h2a:pic<=128'h000000001010d63838d6101000000000;
        8'h2b:pic<=128'h00000000000808087f08080800000000;
        8'h2c:pic<=128'h00000000000000000000000060202040;
        8'h2d:pic<=128'h00000000000000007e00000000000000;
        8'h2e:pic<=128'h00000000000000000000000060600000;
        8'h2f:pic<=128'h00000204040408081010102020404000;
        8'h30:pic<=128'h00000018244242424242424224180000;//0
        8'h31:pic<=128'h000000083808080808080808083e0000;
        8'h32:pic<=128'h0000003c4242420204081020427e0000;
        8'h33:pic<=128'h0000003c4242020418040242423c0000;
        8'h34:pic<=128'h000000040c0c142424447f04041f0000;
        8'h35:pic<=128'h0000007e404040784402024244380000;
        8'h36:pic<=128'h000000182440405c62424242221c0000;
        8'h37:pic<=128'h0000007e420404080810101010100000;
        8'h38:pic<=128'h0000003c4242422418244242423c0000;
        8'h39:pic<=128'h0000003844424242463a020224180000;
        8'h3a:pic<=128'h00000000000018180000000018180000;
        8'h3b:pic<=128'h00000000000000100000000000101010;
        8'h3c:pic<=128'h00000002040810204020100804020000;
        8'h3d:pic<=128'h0000000000007e00007e000000000000;
        8'h3e:pic<=128'h00000040201008040204081020400000;
        8'h3f:pic<=128'h0000003c424262040808080018180000;
        8'h40:pic<=128'h00000038445aaaaaaaaaaa5c423c0000;
        8'h41:pic<=128'h0000001010182828243c444242e70000;//A
        8'h42:pic<=128'h000000f8444444784442424244f80000;
        8'h43:pic<=128'h0000003e424280808080804244380000;
        8'h44:pic<=128'h000000f8444242424242424244f80000;
        8'h45:pic<=128'h000000fc424848784848404242fc0000;
        8'h46:pic<=128'h000000fc424848784848404040e00000;
        8'h47:pic<=128'h0000003c44448080808e844444380000;
        8'h48:pic<=128'h000000e7424242427e42424242e70000;
        8'h49:pic<=128'h0000007c1010101010101010107c0000;
        8'h4a:pic<=128'h0000003e0808080808080808080888f0;
        8'h4b:pic<=128'h000000ee444850705048484444ee0000;
        8'h4c:pic<=128'h000000e0404040404040404042fe0000;
        8'h4d:pic<=128'h000000ee6c6c6c6c6c54545454d60000;
        8'h4e:pic<=128'h000000c7626252524a4a4a4646e20000;
        8'h4f:pic<=128'h00000038448282828282828244380000;
        8'h50:pic<=128'h000000fc424242427c40404040e00000;
        8'h51:pic<=128'h0000003844828282828282b24c380600;
        8'h52:pic<=128'h000000fc4242427c4848444442e30000;
        8'h53:pic<=128'h0000003e4242402018040242427c0000;
        8'h54:pic<=128'h000000fe921010101010101010380000;
        8'h55:pic<=128'h000000e74242424242424242423c0000;
        8'h56:pic<=128'h000000e7424244242428281810100000;
        8'h57:pic<=128'h000000d654545454546c282828280000;
        8'h58:pic<=128'h000000e7422424181818242442e70000;
        8'h59:pic<=128'h000000ee444428281010101010380000;
        8'h5a:pic<=128'h0000007e840408081020204242fc0000;
        8'h5b:pic<=128'h001e1010101010101010101010101e00;
        8'h5c:pic<=128'h00004020202010101008080404040202;
        8'h5d:pic<=128'h00780808080808080808080808087800;
        8'h5e:pic<=128'h00182400000000000000000000000000;
        8'h5f:pic<=128'h000000000000000000000000000000ff;
        8'h60:pic<=128'h00601000000000000000000000000000;
        8'h61:pic<=128'h0000000000000038440c34444c360000;//a
        8'h62:pic<=128'h00000000c04040586442424264580000;
        8'h63:pic<=128'h000000000000001c22404040221c0000;
        8'h64:pic<=128'h000000000602023e42424242463b0000;
        8'h65:pic<=128'h000000000000003c42427e40423c0000;
        8'h66:pic<=128'h000000000c12107c10101010107c0000;
        8'h67:pic<=128'h000000000000003e444438403c42423c;
        8'h68:pic<=128'h00000000c040405c6242424242e70000;
        8'h69:pic<=128'h000000303000007010101010107c0000;
        8'h6a:pic<=128'h0000000c0c00001c0404040404044478;
        8'h6b:pic<=128'h00000000c040404e4850704844ee0000;
        8'h6c:pic<=128'h000000107010101010101010107c0000;
        8'h6d:pic<=128'h00000000000000fe4949494949ed0000;
        8'h6e:pic<=128'h00000000000000dc6242424242e70000;
        8'h6f:pic<=128'h000000000000003c42424242423c0000;
        8'h70:pic<=128'h00000000000000d864424242645840e0;
        8'h71:pic<=128'h000000000000001a26424242261a0207;
        8'h72:pic<=128'h00000000000000ee3220202020f80000;
        8'h73:pic<=128'h000000000000003e42403c02427c0000;
        8'h74:pic<=128'h000000000010107c10101010120c0000;
        8'h75:pic<=128'h00000000000000c642424242463b0000;
        8'h76:pic<=128'h00000000000000ee4444282810100000;
        8'h77:pic<=128'h00000000000000db894a5a5424240000;
        8'h78:pic<=128'h000000000000007624181818246e0000;
        8'h79:pic<=128'h00000000000000e74224241818101060;
        8'h7a:pic<=128'h000000000000007e44081010227e0000;
        8'h7b:pic<=128'h00030404040404040804040404040300;
        8'h7c:pic<=128'h08080808080808080808080808080808;
        8'h7d:pic<=128'h00c0202020202020102020202020c000;
        8'h7e:pic<=128'h205a0400000000000000000000000000;
        default:pic<=128'h0;
    endcase

    wire [3:0] pt={~row[3],~row[2],~row[1],~row[0]};
    assign dot = {pic[{pt,3'd0}],pic[{pt,3'd1}],pic[{pt,3'd2}],pic[{pt,3'd3}],
    pic[{pt,3'd4}],pic[{pt,3'd5}],pic[{pt,3'd6}],pic[{pt,3'd7}]};

endmodule