class uart_tx_test;
    uart_tx_environment env;
    virtual uart_if vif;

    function new(virtual uart_if vif);
        this.vif=vif;
        env=new(vif);
    endfunction

    task run();
    
        
        
        int normal_num;
        int reset_num;
        int busy_num;
        int total_expected;
        int total_cov_samples;

        vif.loopback_en = 1'b0;
        normal_num=20;
        reset_num=30;
        busy_num=30;

        total_expected=normal_num+reset_num+busy_num;
        total_cov_samples=normal_num+reset_num+busy_num;

        env.start_background_components();

        env.run_normal_phase(normal_num);
        env.run_reset_phase(reset_num);
        env.run_busy_phase(busy_num);
        
        wait(env.scb.compare_count==total_expected);
        wait(env.cov.sample_count==total_cov_samples);

        wait(env.gen2drv.num()==0&&env.drv2scb.num()==0&&env.mon2scb.num()==0
                &&env.txdrv2cov.num()==0);
        
        repeat(2)@(posedge env.vif.clk);



        env.scb.report();

        env.cov.report();

        if(env.scb.compare_count ==
            total_expected
        &&
        env.scb.fail_count == 0
        &&
        env.cov.sample_count ==
            total_cov_samples)
            $display("UART COMBINE TEST ALL PASSED");
        else
            $fatal("UART COMBINE TEST FAILED");
        
    endtask
endclass