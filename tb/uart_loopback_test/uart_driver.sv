class uart_driver;
    virtual uart_if vif;

    mailbox #(uart_transaction) gen2drv;
    mailbox #(uart_transaction) drv2scb;

    function new(virtual uart_if vif,
     mailbox #(uart_transaction) gen2drv,
     mailbox #(uart_transaction) drv2scb);
        this.vif=vif;
        this.gen2drv=gen2drv;
        this.drv2scb=drv2scb;
    endfunction

    task drive_one(uart_transaction tr);
        wait(vif.busy==1'b0);

        @(negedge vif.clk)
        vif.data=tr.data;
        vif.tx_valid=1'b1;

        wait(vif.busy==1'b1);
        vif.tx_valid=1'b0;

        drv2scb.put(tr.copy());

        wait(vif.busy==1'b0);

    endtask


    task run();
        uart_transaction tr;

        forever begin
            gen2drv.get(tr);
            tr.display("DRIVER");
            drive_one(tr);
        end
    endtask
endclass






