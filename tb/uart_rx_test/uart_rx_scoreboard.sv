class uart_rx_scoreboard;

    mailbox #(uart_transaction) drv2scb;
    mailbox #(uart_monitor_transaction) mon2scb;

    int pass_count;
    int fail_count;
    int compare_count;

    function new(mailbox #(uart_transaction) drv2scb,
        mailbox #(uart_monitor_transaction) mon2scb);
        this.drv2scb=drv2scb;
        this.mon2scb=mon2scb;
        pass_count=0;
        fail_count=0;
        compare_count=0;

    endfunction

    task run();
        uart_transaction expected;
        uart_monitor_transaction actual;

        forever begin
            drv2scb.get(expected);
            mon2scb.get(actual);
            
            $display("[RX_SCB] waiting expected...");
            if(expected.stop_error==1'b0)begin
                if(expected.data===actual.actual_data&&actual.actual_frame_error==1'b0&&actual.actual_rx_done==1'b1)begin
                    pass_count++;

                    $display("[PASS] normal frame expected=0x%02h actual=0x%02h",expected.data,actual.actual_data);

                end
                else begin
                    fail_count++;

                    $error("[FAIL] normal frame expected=0x%02h ",expected.data);
                end
          
            end
            else begin
                if(actual.actual_rx_done==1'b0&&actual.actual_frame_error==1'b1)begin

                    pass_count++;
                    $display("[PASS]stop error detected,data=0x%02h",expected.data);
                end
                else begin
                    fail_count++;
                    $error("[FAIL] stop error not detected,data=0x%02h",expected.data);
                end
            end
            compare_count++;

            $display(
                "[RX_SCB] frame=%0d expected_data=0x%02h stop_error=%0b",
                compare_count,
                expected.data,
                expected.stop_error
            );

        end
    endtask

    function void report();
        $display("====================UART  TEST REPORT============");
        $display("PASS: %0d",pass_count);
        $display("FAIL: %0d",fail_count);
        $display("EXPECTED RESULTS: %0d",compare_count);
        $display("=================================================");

    endfunction

endclass



