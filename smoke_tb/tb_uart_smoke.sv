`timescale 1ns /1ps
module tb_uart_smoke;
    localparam integer BAUD_DIV=10;

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

    reg   rx_driver;
    reg  loopback_en;

    assign rx=loopback_en?tx:rx_driver;

    integer pass_count;
    integer fail_count;


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

    //50 MHz clock
    initial begin
        clk=0;
        forever #10 clk=~clk;
    end

 

    //automatic task check
    task automatic check_result(input logic condition,
                                input string test_name);
        if(condition) begin
            pass_count=pass_count+1;
            $display("[PASS]time=%0t,test=%s",$time,test_name);
        end
        else begin
            fail_count=fail_count+1;
            $display("[FAIL]time=%0t,test=%s",$time,test_name);
        end

    endtask

    //send data by Tx and check rx result

    task automatic tx_loopback_test(
        input logic [7:0] send_data
    );

        wait(busy==1'b0);
        @(posedge clk);
        
        data<=send_data;
        tx_valid<=1'b1;

        wait(busy==1'b1);
        tx_valid<=1'b0;

        @(posedge rx_done);

        #2;

        check_result(
            rx_data===send_data,
            $sformatf("Tx-Rx loopback:expected=0x%02h,actual=0x%02h",send_data,rx_data)
        );

        check_result(
            frame_error===0,
            "loopback frame_error should be 0"
        );

        wait(busy==0);
        repeat(2)@(posedge clk);
    endtask



    task automatic driver_rx_frame(input logic [7:0]data,
                            input logic stop_error);


        int i;

        rx_driver=1'b1;
        repeat(2)@(posedge clk);



        //start bit
        rx_driver=1'b0;
        repeat(BAUD_DIV)@(posedge clk);

        //data bit
        for(i=0;i<8;i++) begin
            rx_driver=data[i];
            repeat(BAUD_DIV)@(posedge clk);
        end 

        //stop bit
        rx_driver=(stop_error)?1'b0:1'b1;
        repeat(BAUD_DIV)@(posedge clk);

    endtask



   
    initial begin
        pass_count=0;
        fail_count=0;

        reset_n=1'b0;
        data=8'b0;
        tx_valid=1'b0;
        loopback_en=1'b1;
        rx_driver=1'b1;

        repeat(3)@(posedge clk);
        reset_n=1'b1;
        repeat(3)@(posedge clk);

        $display("");
        $display("==============UART SMOKE TEST START============");
        

        //test1
        $display("[TEST 1] 8'hAA loopback start");

        tx_loopback_test(8'hAA);
        repeat(3)@(posedge clk);

        //test2
         $display("[TEST 2] 8'h55 loopback start");

        tx_loopback_test(8'h55);
        repeat(3)@(posedge clk);

        //test3
        $display("[TEST 3] 8'h3C loopback start");
        loopback_en=1'b0;
        rx_driver=1'b1;
        repeat(3)@(posedge clk);

        fork
            begin
            driver_rx_frame(8'h3C,1'b0);
            end
            begin
            @(posedge rx_done);

            #3;
            check_result(rx_data===8'h3C,$sformatf("Rx normal frame:expected=0x3C,actual=0x%02h",rx_data));

            check_result(frame_error===1'b0,"Normal frame should not generate frame_error");
            end
        join

        //test4
        $display("[TEST 4] 8'hA5 loopback start");
        driver_rx_frame(8'hA5,1'b1);

        repeat(3)@(posedge clk);

        check_result(frame_error===1'b1,"Invalid stop bit should generate frame_error");

        //report

        $display("");
        $display("============UART TEST REPORT============");
        $display("Pass:%0d",pass_count);
        $display("Fail:%0d",fail_count);
        $display("=========================================");

        if(fail_count==0)begin
            $display("UART SMOKE TEST:ALL PASSED");
        end
        else begin
            $fatal(
                1,"UART SMOKE TEST FAILED:%0d failure",
                fail_count
            );
        end
        $finish;
 
    end

    initial begin
         //$monitor("time=%0t  count=%b tick=%b tx=%b",$time, count,bg_tick,tx);
    end

    initial begin
        #50000
        $fatal(1,"Simulation timeout");
    end
    
endmodule   


