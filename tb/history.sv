//old rx reset check 
 //nowadays,we don't pay attention to reset scenerio in single rx test
 //rx_drive


    task drive_one_with_reset(uart_stop_error_transaction tr,rx_reset_point_t reset_point);
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
     
    endtask

    task run_reset_data_test();
        uart_transaction base_tr;
        uart_stop_error_transaction input_tr;

        gen2rxdrv.get(base_tr);
        if(!$cast(input_tr,base_tr))begin
                $fatal(1,"[RX_DRIVER] expected uart_reset_transaction");
            end
        // 第一帧在数据阶段被复位打断
        drive_one_with_reset(
            input_tr,
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
        //FIFO get data in line
        gen2rxdrv.get(base_tr);
        if(!$cast(input_tr,base_tr))begin
                $fatal(1,"[RX_DRIVER] expected uart_reset_transaction");
            end
        // 复位后重新发送一个完整帧
      drive_one(input_tr);

    endtask

//uart_package

 typedef enum {
        RX_RESET_START,
        RX_RESET_DATA,
        RX_RESET_STOP
    } rx_reset_point_t;

//rx_generator
 task run_reset();
        uart_stop_error_transaction interrupted_tr;
        uart_stop_error_transaction recovery_tr;

        interrupted_tr = new();
        recovery_tr    = new();

        interrupted_tr.data       = 8'hA5;
        interrupted_tr.stop_error = 1'b0;

        recovery_tr.data       = 8'h3C;
        recovery_tr.stop_error = 1'b0;

        gen2rxdrv.put(interrupted_tr);
        gen2rxdrv.put(recovery_tr);

    endtask

