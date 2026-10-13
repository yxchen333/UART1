class uart_rx_test;
    uart_rx_environment env;
    virtual uart_if vif;
    int transaction_num;
    

    function new(virtual uart_if vif);
        this.vif=vif;
        env=new(vif);
        transaction_num=1;
        
    endfunction

    task run();
    
        vif.loopback_en = 1'b0;
       
        
        transaction_num=20;
        
      

        env.run(transaction_num);

        wait(env.scb.compare_count == env.gen.transaction_num);

        env.scb.report();

        if (
            env.gen.generated_count            == transaction_num &&
            env.drv.normal_frame_count         == transaction_num &&
            env.scb.compare_count              == transaction_num &&
            env.scb.pass_count                 == transaction_num &&
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