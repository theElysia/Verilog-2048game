`timescale 1ns/1ps
`include "Zevick_lib.v"

// notice that the board x-right  y-down
module game_control
#(
    parameter   BOARD_X = 4,
                BOARD_Y = 4,
                GRID    = 16,
                DS      = 4,
                BOARD_SIZE  = 64,
                SCORE_SIZE  = 20
)
(
    input CLK_100M,
    input RST,
    input [4:0] user_operation,// restart u l d r(wasd) , async, priority left
    output reg [BOARD_SIZE-1:0] board,
    output reg [SCORE_SIZE-1:0] score,
    output gameover,// high-avtive
    output reg board_flush
);

localparam  ROW = DS*BOARD_X,
            L   = BOARD_X>BOARD_Y?BOARD_X:BOARD_Y;

//local clk
    //wire clk=clkM;//used in testbench
    reg [19:0] clk_cnt;
    wire clk=clk_cnt[19];
    always @(posedge CLK_100M)clk_cnt<=clk_cnt+1;
//    wire clk=CLK_100M;

// user_operation process
    wire [4:0] op;
    genvar gen_i;
    generate
        for(gen_i=0;gen_i<5;gen_i=gen_i+1)begin:gen_1
            async_to_sync ats1(.CP(clk), .RST(RST),
                .D_I(user_operation[gen_i]), .D_O(op[gen_i]));
        end
    endgenerate

// IDLE: wait for user's next input(serial or with lower priority input would be ignored)
// WR: according to the input direction fill the tmp with one line of board
//      merge part is called(valid)
// WB: write back the processed signal in stack to board
// UPD1: all lines is finished, judge whether the game is over and generate a new block id randomly
// UPD2: according to the block id, select a block
// UPD3: fill the new blocks back into the board
// GAMEOVER: wait until RST or retry
localparam  IDLE=3'd0,WR=3'd1,MERGE=3'd2,WB=3'd3,UPD1=3'd4,UPD2=3'd5,UPD3=3'd6,GAMEOVER=3'd7,
            UP=2'd0,LEFT=2'd1,DOWN=2'd2,RIGHT=2'd3;

    reg flag,upd_en,merge_en;
    reg [L*DS-1:0] tmp;
    reg [(L+1)*DS-1:0] stack;// stack[0] is blank
    reg [$clog2(L):0] rp;
    reg [$clog2(GRID):0] filled_num;
    reg [$clog2(L)-1:0] line,new_block_x,new_block_y;
    reg [$clog2(GRID)-1:0] new_block,block_blank_count;
    reg [SCORE_SIZE-1:0] score_tmp;

    reg [2:0] state;
    reg [1:0] direct;
    wire [7:0] random_num;

    wire get_random = (state==IDLE);
    random_8 rd1(.EN(get_random), .RST(RST), .NUM(random_num));

    assign gameover = (state==GAMEOVER);


// control kernel, a FSM
    integer i,j;
    always@(posedge clk)begin
    case(state)
        IDLE:begin
            tmp<=0;
            line<=0;
            filled_num<=0;
            upd_en<=0;
            merge_en<=0;
            board_flush<=1;
            if(RST|op[4])begin
                board<=0;
                score<=0;
                state<=IDLE;
            end
            else if(op[3])begin direct<=UP;      state<=WR;end
            else if(op[2])begin direct<=LEFT;    state<=WR;end
            else if(op[1])begin direct<=DOWN;    state<=WR;end
            else if(op[0])begin direct<=RIGHT;   state<=WR;end
            else state<=IDLE;
        end

        WR:begin
            case(direct)
                LEFT:   for(i=0;i<BOARD_X;i=i+1)tmp[i*DS +: DS]<=board[line*ROW+i*DS +: DS];
                RIGHT:  for(i=0;i<BOARD_X;i=i+1)tmp[i*DS +: DS]<=board[line*ROW+(BOARD_X-1-i)*DS +: DS];
                UP:     for(i=0;i<BOARD_Y;i=i+1)tmp[i*DS +: DS]<=board[i*ROW+line*DS +: DS];
                DOWN:   for(i=0;i<BOARD_Y;i=i+1)tmp[i*DS +: DS]<=board[(BOARD_Y-i-1)*ROW+line*DS +: DS];
            endcase
            state<=MERGE;
            board_flush<=0;
        end

        MERGE:begin
            state<=WB;
            merge_en<=1;
        end

        WB:begin
            case(direct)
                LEFT:begin
                    for(i=0;i<BOARD_X;i=i+1)board[line*ROW+i*DS +: DS]<=stack[(i+1)*DS +: DS];
                    if(line==BOARD_X-1)state<=UPD1;
                    else state<=WR;
                end
                RIGHT:begin
                    for(i=0;i<BOARD_X;i=i+1)board[line*ROW+(BOARD_X-1-i)*DS +: DS]<=stack[(i+1)*DS +: DS];
                    if(line==BOARD_X-1)state<=UPD1;
                    else state<=WR;
                end
                UP:begin
                    for(i=0;i<BOARD_Y;i=i+1)board[i*ROW+line*DS +: DS]<=stack[(i+1)*DS +: DS];
                    if(line==BOARD_Y-1)state<=UPD1;
                    else state<=WR;
                end
                DOWN:begin
                    for(i=0;i<BOARD_Y;i=i+1)board[(BOARD_Y-i-1)*ROW+line*DS +: DS]<=stack[(i+1)*DS +: DS];
                    if(line==BOARD_Y-1)state<=UPD1;
                    else state<=WR;
                end
            endcase
            line<=line+1;
            score<=score+score_tmp;
            filled_num<=filled_num+rp;
            merge_en<=0;
        end

        UPD1:if(filled_num==GRID)state=GAMEOVER;
            else begin
                state<=UPD2;
                new_block<=random_num%(GRID-filled_num);
            end
        
        UPD2:begin 
            state<=UPD3;
            upd_en<=1;
        end
        
        UPD3:begin
            state<=IDLE;
            board[new_block_y*ROW+new_block_x*DS +: DS]<=4'b1;
            score<=score+2;
        end

        GAMEOVER:if(RST|op[4])begin
            state<=IDLE;
            board<=0;
            score<=0;
        end
            else state<=GAMEOVER;

        default:state<=GAMEOVER;

    endcase
    end

// merge part: use a stack to merge adjacent identical items
    always@(posedge merge_en)begin
        stack=0;score_tmp=0;
        rp=0;flag=0;
        for(i=0;i<L;i=i+1)
        if(tmp[i*DS +: DS]!=0)
            if(flag && stack[rp*DS +: DS]==tmp[i*DS +: DS])
            begin
                flag=0;
                stack[rp*DS +: DS]=stack[rp*DS +: DS]+1;
                score_tmp=score_tmp+(1<<stack[rp*DS +: DS]);
            end
            else begin
                flag=1;
                rp=rp+1;
                stack[rp*DS +: DS]=tmp[i*DS +: DS];
            end
    end

// upd part: find a blank block according to random_num
    always@(posedge upd_en)begin
        block_blank_count=0;
        for(j=0;j<BOARD_Y;j=j+1)
        for(i=0;i<BOARD_X;i=i+1)
        if(board[j*ROW+i*DS +: DS]==0)
        begin
            if(block_blank_count==new_block)
            begin
                new_block_x=i;
                new_block_y=j;
            end
            block_blank_count=block_blank_count+1;
        end
    end

endmodule