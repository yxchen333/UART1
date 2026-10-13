class uart_rx_monitor;
    virtual uart_if vif;
    mailbox #(uart_monitor_transaction) mon2scb;

    int rx_done_count;
    int frame_count;

    function new(virtual uart_if vif,
        mailbox #(uart_monitor_transaction) mon2scb);
        this.vif=vif;
        this.mon2scb=mon2scb;
        rx_done_count=0;
        frame_count=0;

    endfunction

    task run();
        
        uart_monitor_transaction tr;
        bit frame_error_d;

        forever begin
           @(posedge vif.rx_done or posedge vif.frame_error);
           frame_count++;

            if(vif.rx_done)begin
                tr=new();

                tr.actual_data=vif.rx_data;
                tr.actual_rx_done=vif.rx_done;
                tr.actual_frame_error=vif.frame_error;

                $display(
                    "[RX_MONITOR] time=%0t  NORMAL data=0x%02h",
                    $time,
                    vif.rx_data
                );
                mon2scb.put(tr);
                rx_done_count++;
            end
            else if(vif.frame_error) begin
                tr=new();

                tr.actual_data=vif.rx_data;
                tr.actual_rx_done=vif.rx_done;
                tr.actual_frame_error=vif.frame_error;

                $display(
                "[RX_MONITOR] time=%0t FRAME_ERROR",
                $time
                );

                mon2scb.put(tr);
                
            end
            
            
        end


       
    endtask

endclass
