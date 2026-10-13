class uart_driver;
    virtual uart_if vif;
    localparam int baud_div_rx=uart_params_pkg::RX_BAUD_DIV;
    localparam int baud_div_tx=uart_params_pkg::TX_BAUD_DIV;

    mailbox #(uart_transaction) gen2drv;
    mailbox #(uart_transaction) drv2scb;

    function new(virtual uart_if vif,
     mailbox #(uart_transaction) gen2drv,
     mailbox #(uart_transaction) drv2scb);
        this.vif=vif;
        this.gen2drv=gen2drv;
        this.drv2scb=drv2scb;
    endfunction

    task drive_one(uart_transaction tr,
                    bit send_expected=1'b1);
        wait(vif.busy==1'b0);

        @(negedge vif.tx_clk);
        vif.data=tr.data;
        vif.tx_valid=1'b1;

        wait(vif.busy==1'b1);
        vif.tx_valid=1'b0;

        if(send_expected)
        drv2scb.put(tr.copy());

        wait(vif.busy==1'b0);


    endtask

    task drive_false_start();

        wait(vif.busy==1'b0);
        vif.rx_override_en=1'b1;
        vif.rx_override=1'b0;
        repeat(2)@(posedge vif.rx_clk);

        vif.rx_override=1'b1;
        repeat(baud_div_rx/2+2)@(posedge vif.rx_clk);

        repeat(2)@(posedge vif.rx_clk);

        vif.rx_override_en=1'b0;

    endtask

    task drive_stop_error(uart_transaction tr);
        wait(vif.busy==1'b0);

        fork
            begin
                drive_one(tr);
            end

            begin
                @(negedge vif.tx);
                repeat(9*baud_div_tx)@(negedge vif.tx_clk);

                vif.rx_override=1'b0;
                vif.rx_override_en=1'b1;

                @(posedge vif.frame_error);       
                @(negedge vif.rx_clk);
                vif.rx_override_en = 1'b0;
            end
        join
    endtask



    task run();
        uart_transaction tr;
        uart_stop_error_transaction stop_tr;

        bit false_start_test=0;
        bit is_stop_error;

        forever begin
            gen2drv.get(tr);
            tr.display("DRIVER");

            if(!false_start_test)begin
                drive_false_start();
                false_start_test=1;
            end

            is_stop_error=1'b0;
            if($cast(stop_tr,tr))
            is_stop_error=stop_tr.stop_error;

            if(is_stop_error)
                drive_stop_error(tr);
            else
                drive_one(tr);
          
        end
    endtask
endclass






