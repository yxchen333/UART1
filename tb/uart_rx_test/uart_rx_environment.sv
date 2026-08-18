class uart_rx_environment;

    uart_rx_generator gen;
    uart_rx_driver    drv;
    uart_rx_scoreboard scb;
    uart_rx_monitor   mon;

    mailbox #(uart_transaction) gen2drv;
    mailbox #(uart_transaction) drv2scb;
    mailbox #(uart_monitor_transaction) mon2scb;

    virtual uart_if vif;

    function new(virtual uart_if vif);
        this.vif=vif;

        gen2drv=new();
        drv2scb=new();
        mon2scb=new();

        gen=new(gen2drv);
        drv=new(vif,gen2drv,drv2scb);
        mon=new(vif,mon2scb);
        scb=new(drv2scb,mon2scb);
    endfunction

    task run();
        fork
           // gen.run();
            //drv.run();
           // drv.run_reset_data_test();

            gen.run_false_start_test();
            drv.run_with_false_start();
            mon.run();
            scb.run();
        join_none
    endtask
endclass