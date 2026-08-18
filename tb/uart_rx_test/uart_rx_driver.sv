class uart_rx_driver;
    virtual uart_if vif;

    mailbox #(uart_transaction) gen2rxdrv;
    mailbox #(uart_transaction) rxdrv2scb;
    rx_reset_point_t reset_point;

    int baud_div;
    int normal_frame_count;
    int false_start_count;
    

    function new(virtual uart_if vif,
     mailbox #(uart_transaction) gen2rxdrv,
     mailbox #(uart_transaction) rxdrv2scb);
        this.vif=vif;
        this.gen2rxdrv=gen2rxdrv;
        this.rxdrv2scb=rxdrv2scb;
        baud_div=10;
        normal_frame_count = 0;
        false_start_count  = 0;

    endfunction

    task pulse_reset();

        $display(
            "[RX_RESET] assert reset at time=%0t",
            $time
        );

        @(negedge vif.clk);
        vif.reset_n = 1'b0;

        // 保持两个系统时钟周期
        repeat (2) @(negedge vif.clk);

        vif.reset_n = 1'b1;

        $display(
            "[RX_RESET] release reset at time=%0t",
            $time
        );

        // 串行输入恢复空闲状态
        vif.rx_driver = 1'b1;

        repeat (2) @(posedge vif.clk);

    endtask

    task drive_one(uart_transaction tr);
        
        int i;

        //idle 
        vif.rx_driver=1'b1;
        repeat(2)@(posedge vif.clk);

        //start
        vif.rx_driver=1'b0;
        repeat(baud_div)@(posedge vif.clk);
        
        

        //data
        for(i=0;i<8;i++)begin
            vif.rx_driver=tr.data[i];
            repeat(baud_div)@(posedge vif.clk);
        end
        
        //stop
        if(tr.stop_error===1'b1)
            vif.rx_driver=1'b0;
        else
            vif.rx_driver=1'b1;
        
        
        repeat(baud_div)@(posedge vif.clk);

        vif.rx_driver=1'b1;

        if(tr.stop_error) begin
            repeat(baud_div)@(posedge vif.clk);
        end
        rxdrv2scb.put(tr.copy());

    endtask

    task drive_one_with_reset(uart_transaction tr,rx_reset_point_t reset_point);
        int i;

        vif.rx_driver=1'b1;
        repeat(2)@(posedge vif.clk);

        vif.rx_driver=1'b0;
        if(reset_point==RX_RESET_START) begin
            $display(
                "[RESET TEST] START reset, time=%0t  ",
                $time

            );
            
            repeat(baud_div/2)@(posedge vif.clk);

            pulse_reset();
            return;
        end
        repeat(baud_div)@(posedge vif.clk);

        for(i=0;i<8;i=i+1) begin
            vif.rx_driver=tr.data[i];
            if((reset_point==RX_RESET_DATA)&&(i==3)) begin

                 $display(
                    "[RESET TEST] DATA reset at data[%0d], time=%0t",
                    i,
                    $time
                );
                repeat(baud_div/2)@(posedge vif.clk);
                pulse_reset();
                return;
            end

            repeat(baud_div)@(posedge vif.clk);
        end

        vif.rx_driver=tr.stop_error?1'b0:1'b1;

        if(reset_point==RX_RESET_STOP) begin
             $display(  
                "[RESET TEST] STOP reset, time=%0t",
                $time
            );

            repeat (baud_div/2)@(posedge vif.clk);

            pulse_reset();

            return;
        end
        repeat(baud_div)@(posedge vif.clk);
        vif.rx_driver=1'b1;
        if(tr.stop_error) repeat(baud_div)@(posedge vif.clk);

        rxdrv2scb.put(tr);
    endtask

    task drive_false_start_and_observe(uart_false_start_transaction false_tr);
        uart_transaction expected_tr;

      

        vif.rx_driver=1'b1;
        repeat(2) @(posedge vif.clk);

        vif.rx_driver=1'b0;
        repeat(false_tr.false_start_cycles)@(posedge vif.clk);

        
        vif.rx_driver=1'b1;

        $display("[RX_DRIVER] false start injected,cycles=%0d time=%0t",false_tr.false_start_cycles,$time);

        //observe whether induce rx_done
        repeat (12*baud_div) @(posedge vif.clk);

       

    endtask



    task run();
        
        uart_transaction tr;

        forever begin
            gen2rxdrv.get(tr);
            
            tr.display("RX_DRIVER");
            drive_one(tr);
            
        end
    endtask

    task run_with_false_start(input int transaction_num=20);
        
        uart_transaction base_tr;
        uart_false_start_transaction false_tr;

        int i;

        
        bit drive_done;

        
        drive_done         = 1'b0;
        vif.rx_driver      = 1'b1;

        


        for(i=0;i<transaction_num;i++) begin
            gen2rxdrv.get(base_tr);
            
            if(!$cast(false_tr,base_tr))begin
                $fatal(1,"[RX_DRIVER] expected uart_false_start_transaction");
            end

            false_tr.display("RX_DRIVER");

            if(false_tr.inject_false_start) begin
                drive_false_start_and_observe(false_tr);
                false_start_count++;

            end
            drive_one(false_tr);

            normal_frame_count++;
            
        end

        drive_done=1'b1;
    endtask

    task run_reset_data_test();

        uart_transaction interrupted_tr;
        uart_transaction recovery_tr;

        interrupted_tr = new();
        recovery_tr    = new();

        interrupted_tr.data       = 8'hA5;
        interrupted_tr.stop_error = 1'b0;

        recovery_tr.data       = 8'h3C;
        recovery_tr.stop_error = 1'b0;

        // 第一帧在数据阶段被复位打断
        drive_one_with_reset(
            interrupted_tr,
            reset_point
        );
        // 给DUT几个周期，检查没有残留结果
        repeat (3) @(posedge vif.clk);

        if ((vif.rx_done !== 1'b0) ||
            (vif.frame_error !== 1'b0)) begin

            $fatal(
                1,
                "[RESET TEST FAIL] interrupted frame produced a result"
            );

        end
        else begin

            $display(
                "[PASS] interrupted frame was discarded"
            );

        end


        // 复位后重新发送一个完整帧
        drive_one_with_reset(
            recovery_tr,
            RX_RESET_NONE
        );

    endtask
endclass






