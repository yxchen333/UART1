class uart_monitor;
    virtual uart_if vif;
    mailbox #(uart_monitor_transaction) mon2scb;

    function new(virtual uart_if vif,
        mailbox #(uart_monitor_transaction) mon2scb);
        this.vif=vif;
        this.mon2scb=mon2scb;

    endfunction

    task run();
        uart_monitor_transaction tr;

        forever begin
            @(posedge vif.rx_done or posedge vif.frame_error );

            tr=new();
            tr.data=vif.rx_data;
            tr.actual_rx_done=vif.rx_done;
            tr.actual_frame_error=vif.frame_error;

            tr.display("MONITOR:");
            mon2scb.put(tr);
        end
    endtask

endclass
