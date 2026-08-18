class uart_test;
    uart_environment env;
    virtual uart_if vif;

    function new(virtual uart_if vif);
        this.vif=vif;
        env=new(vif);
    endfunction

    task run();
        env.gen.transaction_num=20;

        env.run();

        wait(env.scb.pass_count+env.scb.fail_count==env.gen.transaction_num);

        env.scb.report();

        if(env.scb.fail_count==0)
            $display("UART TEST ALL PASSED");
        else
            $fatal("UART TEST FAILED");
        
    endtask
endclass