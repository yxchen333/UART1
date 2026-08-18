class uart_rx_test;
    uart_rx_environment env;
    virtual uart_if vif;
    int expected_compare_num;

    function new(virtual uart_if vif);
        this.vif=vif;
        env=new(vif);
        expected_compare_num=1;
    endfunction

    task run();
    
        vif.loopback_en = 1'b0;
       
        
        //env.gen.transaction_num=20;
       // env.gen.configure_error_recovery();
        //env.drv.reset_point=RX_RESET_START;

        env.run();

        wait(env.scb.compare_count == env.gen.expected_result_num);

        env.scb.report();

        if (
            env.gen.generated_count            == 20 &&
            env.gen.injected_count             == 12  &&
            env.drv.normal_frame_count         == 20 &&
            env.drv.false_start_count          == 12 &&
            env.scb.compare_count              == 20 &&
            env.scb.pass_count                 == 20 &&
            env.scb.fail_count                 == 0
                
           
        ) begin

            $display(
                "[RX_FALSE_START_TEST][PASS]"
            );

        end
        else begin

            $fatal(
                1,
                "[RX_FALSE_START_TEST][FAIL]"
            );

        end

        if(env.scb.fail_count==0)
            $display("UART TEST ALL PASSED");
        else
            $fatal("UART TEST FAILED");
        
    endtask
endclass