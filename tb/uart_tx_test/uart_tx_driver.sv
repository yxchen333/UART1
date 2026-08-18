class uart_tx_driver;
    virtual uart_if vif;

    mailbox #(uart_transaction) gen2txdrv;
    mailbox #(uart_transaction) txdrv2scb;
    mailbox #(uart_transaction) txdrv2cov;

    localparam int baud_div=uart_params_pkg::UART_BAUD_DIV;
    int inter_frame_gap;
    inject_point_t reset_point;

    int normal_frame_count;
    int expected_send_count;
    int interference_request_count;

    bit driver_done;

    localparam TX_IDLE  = 2'd0;
    localparam TX_START = 2'd1;
    localparam TX_DATA  = 2'd2;
    localparam TX_STOP  = 2'd3;


    function new(virtual uart_if vif,
        mailbox #(uart_transaction) gen2txdrv,
        mailbox #(uart_transaction) txdrv2scb,
        mailbox #(uart_transaction) txdrv2cov);
        begin
     
        this.vif=vif;
        this.gen2txdrv=gen2txdrv;
        this.txdrv2scb=txdrv2scb;
        this.txdrv2cov=txdrv2cov;
        
        inter_frame_gap=2;
        reset_point = INJECT_NONE;

        normal_frame_count         = 0;
        expected_send_count        = 0;
        interference_request_count = 0;

        driver_done = 1'b0;

        end

    endfunction

    task drive_one(uart_transaction tr);

        wait(vif.reset_n===1'b1);
        wait(vif.busy==1'b0);

        @(negedge vif.clk)
        vif.data=tr.data;
        vif.tx_valid=1'b1;

        wait(vif.busy==1'b1);
        vif.tx_valid=1'b0;

        $display("[TX_DRIVER] time=%0t data=0x%02h",$time,tr.data);

        txdrv2scb.put(tr.copy());


        wait(vif.tx_done==1'b1);

        repeat(inter_frame_gap)@(posedge vif.clk);

    endtask

    task start_tx(uart_transaction tr);

        // 等待复位释放
        wait(vif.reset_n === 1'b1);

        // 等待TX空闲
        wait(vif.busy === 1'b0);

        // 在下降沿驱动输入
        @(negedge vif.clk);

        vif.data     = tr.data;
        vif.tx_valid = 1'b1;

        // 等待DUT接受发送请求
        wait(vif.busy === 1'b1);

        /*
        * 等到下降沿再撤销tx_valid，
        * 避免和DUT在posedge采样产生竞争。
        */
        @(negedge vif.clk);
        vif.tx_valid = 1'b0;

        $display(
            "[TX_DRIVER] start time=%0t data=0x%02h",
            $time,
            tr.data
        );

    endtask


    task pulse_reset();

        @(negedge vif.clk);
         vif.tx_valid = 1'b0;
         vif.reset_n  = 1'b0;

          $display(
            "[TX_RESET] assert reset time=%0t",
            $time
        );

        repeat (2) @(negedge vif.clk);

        vif.reset_n = 1'b1;
        $display(
            "[TX_RESET] release reset time=%0t",
            $time
        );

        repeat (2) @(posedge vif.clk);

    endtask

    task pulse_reset_now();

        // 调用者已经选择好了准确时间
        vif.tx_valid = 1'b0;
        vif.reset_n  = 1'b0;

        $display(
            "[TX_RESET] assert reset time=%0t",
            $time
        );

        repeat (2) @(negedge vif.clk);

        vif.reset_n = 1'b1;

        $display(
            "[TX_RESET] release reset time=%0t",
            $time
        );

        repeat (2) @(posedge vif.clk);

    endtask



    task drive_one_with_reset(
       uart_reset_transaction reset_tr
        );

        // 启动TX发送
        start_tx(reset_tr);

        case (reset_tr.tx_reset_point)

            INJECT_START: begin

                // 等待真正出现Start bit
                wait(vif.tx === 1'b0);

                // 在Start bit中间复位
                repeat (baud_div / 2)
                    @(posedge vif.clk);

                $display(
                    "[TX_RESET] reset during START time=%0t",
                    $time
                );

                pulse_reset();

            end


            INJECT_DATA: begin

                // 等待Start bit开始
                wait(vif.tx === 1'b0);

                /*
                * 等待一个Start bit，再进入若干数据位。
                * 这里示例在data[3]附近复位。
                */
                repeat (
                    baud_div +
                    reset_tr.reset_data_bit* baud_div +
                    reset_tr.reset_phase_offset
                ) @(posedge vif.clk);

                $display(
                    "[TX_RESET] reset during DATA time=%0t",
                    $time
                );

                pulse_reset();

            end


            INJECT_STOP: begin

                 wait(vif.tx_state_dbg == TX_STOP);

                repeat (baud_div / 4)
                    @(posedge vif.clk);

                @(negedge vif.clk);

                $display(
                    "[TX_RESET] selected STOP reset time=%0t",
                    $time
                );

                pulse_reset_now();

            end


            INJECT_NONE: begin

                // 完整发送，作为正常expected
                @(posedge vif.tx_done);

                txdrv2scb.put(reset_tr.copy());
                 $display(
                    "[TX_DRIVER] complete time=%0t data=0x%02h",
                    $time,
                    reset_tr.data
                );

            end

             default: begin
                $fatal(
                    1,
                    "[TX_RESET] invalid reset point"
                );
            end

        endcase

    endtask

    task drive_one_with_busy(uart_busy_transaction busy_tr);

        uart_transaction expected_tr;
        start_tx(busy_tr);

        expected_tr=new();
        expected_tr.data=busy_tr.data;
        expected_tr.stop_error=busy_tr.stop_error;

        txdrv2scb.put(expected_tr.copy());
        expected_send_count++;

        case(busy_tr.busy_inject_point)

            INJECT_START: begin

                // 等待真正出现Start bit
                wait(vif.tx_state_dbg==TX_START);


                // 在Start bit中间
                repeat (baud_div / 2)
                    @(posedge vif.clk);
                @(negedge vif.clk);

                vif.data=busy_tr.interference_data;
                vif.tx_valid=1'b1;

                interference_request_count++;

                $display("[TX_BUSY] inject during START time=%0t  normal_data=0x%02h interference_data=0x%02h ",
                $time,busy_tr.data,busy_tr.interference_data);

                repeat (busy_tr.tx_valid_hold_cycles) @(posedge vif.clk);
                
                vif.tx_valid=1'b0;                

            end

            INJECT_DATA:begin
                wait(vif.tx_state_dbg==TX_DATA);

                repeat(busy_tr.busy_data_bit*baud_div+baud_div/2)@(posedge vif.clk);

                vif.data=busy_tr.interference_data;
                vif.tx_valid=1'b1;

                interference_request_count++;

                $display("[TX_BUSY] inject during DATA time=%0t  normal_data=0x%02h interference_data=0x%02h ",
                $time,busy_tr.data,busy_tr.interference_data);

                repeat (busy_tr.tx_valid_hold_cycles) @(posedge vif.clk);
                
                vif.tx_valid=1'b0; 
            end

            INJECT_STOP:begin
                wait(vif.tx_state_dbg==TX_STOP);

                repeat (baud_div / 2)  @(posedge vif.clk);
                @(negedge vif.clk);

                vif.data=busy_tr.interference_data;
                vif.tx_valid=1'b1;

                interference_request_count++;

                $display("[TX_BUSY] inject during STOP time=%0t  normal_data=0x%02h interference_data=0x%02h ",
                $time,busy_tr.data,busy_tr.interference_data);

                repeat (busy_tr.tx_valid_hold_cycles) @(posedge vif.clk);
                
                vif.tx_valid=1'b0;  
            end

            INJECT_NONE:begin
                $fatal(1,"[TX_BUSY] INJECT_NONE is illegal in busy test");

            end

            default: begin
                $fatal(1,"[TX_BUSY] invalid busy inject point");
            end

        endcase

        @(posedge vif.tx_done);

        normal_frame_count++;

        $display("[TX_BUSY] normal frame complete time=%0t data=0x%02h",$time,busy_tr.data);

        wait(vif.busy===1'b0);

    endtask




    task run_normal(input int num);
        uart_transaction tr;

        int i;

        for(i=0;i<num ;i++)begin

            gen2txdrv.get(tr);

            drive_one(tr);
            txdrv2cov.put(tr.copy());

        end
    
    endtask

    task run_reset(input int group_num);
        
        uart_transaction       base_tr;
        uart_reset_transaction reset_tr;

        int i;

        vif.data=8'h00;
        vif.tx_valid=1'b0;

        for(i=0;i<group_num;i++)begin
            gen2txdrv.get(base_tr);

            if (!$cast(reset_tr, base_tr)) begin

                $fatal(
                    1,
                    "[TX_DRIVER] expected reset transaction"
                );

            end

            if (!reset_tr.inject_reset) begin

                $fatal(
                    1,
                    "[TX_DRIVER] interrupted transaction has inject_reset=0"
                );

            end

            drive_one_with_reset(reset_tr);
            txdrv2cov.put(reset_tr.copy());

            gen2txdrv.get(base_tr);
            drive_one(base_tr);
        end

    endtask



    task run_busy(input int group_num);
        uart_transaction base_tr;
        uart_busy_transaction busy_tr;

        int i;

        vif.data=8'h00;
        vif.tx_valid=1'b0;

        driver_done = 1'b0;
        for (i = 0; i < group_num; i++) begin

            gen2txdrv.get(base_tr);

            if(!$cast(busy_tr,base_tr)) begin
                $fatal(1,"[TX_DRIVER] transaction is not uart_busy_transaction");

            end

            busy_tr.display("TX_DRIVER");

            drive_one_with_busy(busy_tr);
            txdrv2cov.put(busy_tr.copy());

        end  

        driver_done = 1'b1;

        $display(
            "[TX_DRIVER] busy test complete, frames=%0d expected=%0d interference=%0d",
            normal_frame_count,
            expected_send_count,
            interference_request_count
        );
        
    endtask

endclass






