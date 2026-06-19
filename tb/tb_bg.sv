`timescale 1ns /1ps
module tb_bg;
    reg clk,reset_n;

    reg [7:0]data;
    reg tx_valid;

    wire [7:0]count;
    wire bg_tick;
    wire bg_clk;
    wire tx;
    wire [2:0]bit_cnt;
    wire [1:0]state;
    wire busy;
    wire tx_done;
   
    wire rx;
    wire [7:0] rx_data;
    wire rx_done;
    // 定义一个新的 reg 变量用来控制毛刺
    //reg glitch_en;
   // reg glitch_val;

    // 将 rx 的驱动改为：
    //assign rx = (glitch_en) ? glitch_val : tx; 
    assign rx=tx;

    wire frame_error;


    baud_generator u1(
        .clk(clk),
        .reset_n(reset_n),
        .count(count),
        .bg_tick(bg_tick),
        .bg_clk(bg_clk)
        );
    uart_tx u2(
        .clk(clk),
        .reset_n(reset_n),
        .bg_tick(bg_tick),
        .data(data),
        .tx_valid(tx_valid),
        .tx(tx),
        .bit_cnt(bit_cnt),
        .state(state),
        .busy(busy),
        .tx_done(tx_done)
        );
    
    uart_rx u3(
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .frame_error(frame_error)
        );

    //clock
    initial begin
        clk=0;
        forever #10 clk=~clk;
    end

    //stimulus
    initial begin
        reset_n=0;
        data=8'hAA;
        tx_valid=1'b1;

        #25 reset_n=1;
        #220 tx_valid=1'b0;

        @(posedge tx_done);

        data=8'h55;
        tx_valid=1'b01;
        #2500;
        tx_valid = 1'b0;
    end

     //glitch test   
    //initial begin
    //    glitch_val = 0
    //   glitch_en = 0;
    //    #100;
    //    glitch_en = 1; glitch_val = 0;  // 注入毛刺
    //    #40;
    //    glitch_en = 0;                  // 撤销毛刺

    //end

    //stop_error test
    task uart_send(input [7:0]data,input stop_err);
        integer i;
        force rx=0;#200;
        for(i=0;i<8;i=i+1)begin
            force rx=data[i];#200;
        end
        if(stop_err)force rx=0;
        else force rx=1;
        #200;
        release rx;
    endtask
    initial begin
        force rx=1;
        wait(reset_n==1)
        #100
        uart_send(8'hAA,0);
        force rx=1;
        @(posedge tx_done);
        uart_send(8'h55,0);
        force rx=1;
    end



    initial begin
         //$monitor("time=%0t  count=%b tick=%b tx=%b",$time, count,bg_tick,tx);
    end

    initial begin
        #10000
        $finish;
    end


    
    
endmodule   


