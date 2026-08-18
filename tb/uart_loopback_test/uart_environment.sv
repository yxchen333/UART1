class uart_environment;

    uart_generator gen;
    uart_driver    drv;
    uart_scoreboard scb;
    uart_monitor   mon;

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
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none
    endtask
endclass