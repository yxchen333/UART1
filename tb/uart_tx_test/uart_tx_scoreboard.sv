class uart_tx_scoreboard;

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
            fork
            drv2scb.get(expected);
            mon2scb.get(actual);
            join
           
            if(expected.data===actual.actual_data)begin
                pass_count++;

                $display("[PASS] normal frame expected=0x%02h actual=0x%02h",expected.data,actual.actual_data);

            end
            else begin
                fail_count++;

                $error("[FAIL] normal frame expected=0x%02h ",expected.data);
            end

            compare_count++;
          
           

        end
    endtask

    function void report();
        $display("====================UART  TEST REPORT============");
        $display("PASS: %0d",pass_count);
        $display("FAIL: %0d",fail_count);
        $display("EXPECTED: %0d",compare_count);
        $display("=================================================");

    endfunction

endclass



