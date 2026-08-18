class uart_tx_environment;

    uart_tx_generator gen;
    uart_tx_driver    drv;
    uart_tx_scoreboard scb;
    uart_tx_monitor   mon;
    uart_tx_coverage  cov;

    mailbox #(uart_transaction) gen2drv;
    mailbox #(uart_transaction) drv2scb;
    mailbox #(uart_monitor_transaction) mon2scb;
    mailbox #(uart_transaction) txdrv2cov;

    virtual uart_if vif;

    function new(virtual uart_if vif);
        this.vif=vif;

        gen2drv=new();
        drv2scb=new();
        mon2scb=new();
        txdrv2cov=new();

        gen=new(gen2drv);
        drv=new(vif,gen2drv,drv2scb,txdrv2cov);
        mon=new(vif,mon2scb);
        scb=new(drv2scb,mon2scb);
        cov=new(txdrv2cov);

    endfunction
    task start_background_components;

        fork
            mon.run();
            scb.run();
            cov.run();

        join_none

    endtask

    task run_normal_phase(input int num);
        int scb_start;
        int cov_start;

        scb_start=scb.compare_count;
        cov_start=cov.sample_count;

        $display("==================TX NORMAL PHASE START===========");

        fork
            gen.run_normal(num);
            drv.run_normal(num);

        join

        wait(scb.compare_count==scb_start+num);
        wait(cov.sample_count==cov_start+num);

        $display("==================TX NORMAL PHASE COMPLETE============");

    endtask

    task run_reset_phase(input int group_num);
        int scb_start;
        int cov_start;

        scb_start=scb.compare_count;
        cov_start=cov.sample_count;

        $display("==================TX RESET PHASE START===========");

        fork
            gen.run_reset(group_num);
            drv.run_reset(group_num);
        join

        wait(scb.compare_count==scb_start+group_num);

        wait(cov.sample_count==cov_start+group_num);

        $display("==================TX RESET PHASE COMPLETE============");

    endtask

    task run_busy_phase(input int num);

        int scb_start;
        int cov_start;

        scb_start=scb.compare_count;
        cov_start=cov.sample_count;

        $display("==================TX BUSY PHASE START=================");

        fork
            gen.run_busy(num);
            drv.run_busy(num);
        join

        wait(scb.compare_count==scb_start+num);
        wait(cov.sample_count==cov_start+num);
        $display("==================TX BUSY PHASE COMPLETE============");

    endtask



    task run();

        int group_num;

        /*
        * 此时expected_result_num已在Generator构造函数中初始化为10。
        */
        group_num = gen.expected_result_num;
        fork
            //gen.run();
           // drv.run();
            //drv.run_reset_data_test();

            gen.run_busy(group_num);
            drv.run_busy(group_num);
            mon.run();
            scb.run();
            cov.run();

        join_none
    endtask
endclass