class uart_tx_monitor;
    virtual uart_if vif;
    mailbox #(uart_monitor_transaction) mon2scb;
    int baud_div;

    int frame_count;
    int tx_done_count;
    int monitor_error_count;

    function new(virtual uart_if vif,
        mailbox #(uart_monitor_transaction) mon2scb);
        this.vif=vif;
        this.mon2scb=mon2scb;
        baud_div=10;

        frame_count         = 0;
        tx_done_count       = 0;
        monitor_error_count = 0;

    endfunction

    

    task monitor_frames();

        uart_monitor_transaction tr;

        bit frame_aborted;
        int i;

        forever begin


            // 等待复位释放
            wait(vif.reset_n === 1'b1);

            // 等待DUT开始一笔新的发送
            wait(vif.busy === 1'b1);

            // 等待Start bit真正出现
            wait(vif.tx === 1'b0);

            tr = new();
            tr.actual_data = 8'h00;

            frame_aborted = 1'b0;

            fork : FRAME_MONITOR

                //==================================================
                // 正常解析UART帧
                //==================================================
                begin : DECODE_FRAME

                    // Start bit中心
                    repeat(baud_div / 2)
                        @(posedge vif.clk);

                    if (vif.tx !== 1'b0) begin
                        $error(
                            "[TX_MONITOR] invalid start bit, time=%0t",
                            $time
                        );
                    end

                    // 从Start中心移动到data[0]中心
                    repeat(baud_div)
                        @(posedge vif.clk);

                    // LSB-first采样8个数据位
                    for (i = 0; i < 8; i = i + 1) begin

                        tr.actual_data[i] = vif.tx;

                        if (i < 7) begin
                            repeat(baud_div)
                                @(posedge vif.clk);
                        end

                    end

                    // 移动到Stop bit中心
                    repeat(baud_div)
                        @(posedge vif.clk);

                    if (vif.tx !== 1'b1) begin
                        $error(
                            "[TX_MONITOR] invalid stop bit, time=%0t",
                            $time
                        );
                    end

                    /*
                    * 只有完整帧、并且没有被复位打断，
                    * 才能送给Scoreboard。
                    */
                    if ((!frame_aborted) &&
                        (vif.reset_n === 1'b1)) begin

                        $display(
                            "[TX_MONITOR] time=%0t data=0x%02h",
                            $time,
                            tr.actual_data
                        );
                        frame_count++;
                        mon2scb.put(tr);


                    end

                end


                //==================================================
                // 同时监测复位
                //==================================================
                begin : WATCH_RESET

                    @(negedge vif.reset_n);

                    frame_aborted = 1'b1;

                    $display(
                        "[TX_MONITOR] frame aborted by reset, time=%0t",
                        $time
                    );

                end

            join_any

            /*
            * 正常解析和复位监测中，谁先结束就退出；
            * 随后停止另一个并行进程。
            */
            disable FRAME_MONITOR;


            //==================================================
            // 如果被复位打断，重新等待安全状态
            //==================================================
            if (frame_aborted) begin

                // 等待复位释放
                wait(vif.reset_n === 1'b1);

                // 等待TX真正回到空闲
                wait(vif.busy === 1'b0);
                wait(vif.tx   === 1'b1);

                // 给Monitor一个重新启动的边界
                @(posedge vif.clk);

            end

            

            

            $display(
                "[TX_MONITOR] frame_count=%0d data=0x%02h time=%0t",
                frame_count,
                tr.actual_data,
                $time
            );

        end

    endtask

    task count_tx_done();

        forever begin

            @(posedge vif.tx_done);

            tx_done_count++;

            $display(
                "[TX_MONITOR] tx_done_count=%0d time=%0t",
                tx_done_count,
                $time
            );

        end

    endtask
    task run();

        fork
            monitor_frames();
            count_tx_done();
        join

    endtask


endclass
