class uart_scoreboard;

    mailbox #(uart_transaction) drv2scb;
    mailbox #(uart_monitor_transaction) mon2scb;

    int pass_count;
    int fail_count;

    function new(mailbox #(uart_transaction) drv2scb,
        mailbox #(uart_monitor_transaction) mon2scb);
        this.drv2scb=drv2scb;
        this.mon2scb=mon2scb;
        pass_count=0;
        fail_count=0;

    endfunction

    task run();
        uart_transaction expected;
        uart_monitor_transaction actual;

        forever begin
            drv2scb.get(expected);
            mon2scb.get(actual);

            if(expected.data===actual.data)begin
                pass_count++;

                $display("[PASS] expected=0x%02h actual=0x%02h",expected.data,actual.data);

            end
            else begin
                fail_count++;

                $error("[FAIL] expected=0x%02h actual=0x%02h",expected.data,actual.data);
            end
        end
    endtask

    function void report();
        $display("====================UART  TEST REPORT============");
        $display("PASS: %0d",pass_count);
        $display("FAIL: %0d",fail_count);
        $display("=================================================");

    endfunction

endclass



