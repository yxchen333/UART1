`timescale 1ns /1ps
module tb_bg;
    reg clk,reset_n;

    reg [7:0]data;
    reg tx_valid;

    wire [7:0]count;
    wire bg_tick;
    wire bg_clk;
    wire tx;
   



    baud_generator u1(clk,reset_n,count,bg_tick,bg_clk);
    uart_tx u2(clk,reset_n,bg_tick,data,tx_valid,tx);


    //clock
    initial begin
        clk=0;
        forever #10 clk=~clk;
    end

    //stimulus
    initial begin
        reset_n=0;
        data=8'b10110100;
        tx_valid=1'b1;
        #25 reset_n=1;
        #220 tx_valid=1'b0;

       
       
    end

    initial begin
         $monitor("time=%0t  count=%b tick=%b tx=%b",$time, count,bg_tick,tx);
    end
    initial begin
        #3000
        $finish;
    end


    
    
endmodule   


