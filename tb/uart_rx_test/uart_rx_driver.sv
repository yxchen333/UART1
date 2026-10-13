class uart_rx_driver;
    virtual uart_if vif;

    mailbox #(uart_transaction) gen2rxdrv;
    mailbox #(uart_transaction) rxdrv2scb;

    localparam int baud_div=uart_params_pkg::RX_BAUD_DIV;
    int normal_frame_count;
    int false_start_count;
    

    function new(virtual uart_if vif,
     mailbox #(uart_transaction) gen2rxdrv,
     mailbox #(uart_transaction) rxdrv2scb);
        this.vif=vif;
        this.gen2rxdrv=gen2rxdrv;
        this.rxdrv2scb=rxdrv2scb;
        
        normal_frame_count = 0;
        false_start_count  = 0;
        

    endfunction



    task drive_one(uart_stop_error_transaction tr);
        
        int i;

        //idle 
        vif.rx_driver=1'b1;
        repeat(2)@(negedge vif.rx_clk);

        //start
        vif.rx_driver=1'b0;
        repeat(baud_div)@(posedge vif.rx_clk);
        
        

        //data
        for(i=0;i<8;i++)begin
            vif.rx_driver=tr.data[i];
            repeat(baud_div)@(posedge vif.rx_clk);
        end
        @(negedge vif.rx_clk);
        //stop
        if(tr.stop_error===1'b1)
            vif.rx_driver=1'b0;
        else
            vif.rx_driver=1'b1;
        
        
        repeat(baud_div)@(posedge vif.rx_clk);

        vif.rx_driver=1'b1;

        if(tr.stop_error) begin
            repeat(baud_div)@(posedge vif.rx_clk);
        end
        rxdrv2scb.put(tr.copy());

    endtask


    task drive_false_start(uart_false_start_transaction false_tr);

        vif.rx_driver=1'b1;
        repeat(2) @(posedge vif.rx_clk);

        @(negedge vif.rx_clk);
        vif.rx_driver=1'b0;
        repeat(false_tr.false_start_cycles)@(posedge vif.rx_clk);

        @(negedge vif.rx_clk);
        vif.rx_driver=1'b1;

        $display("[RX_DRIVER] false start injected,cycles=%0d time=%0t",false_tr.false_start_cycles,$time);

        //observe  window whether induce rx_done
        repeat (12*baud_div) @(posedge vif.rx_clk);

    endtask

    task run_with_false_start(input int transaction_num=20);
        
        uart_transaction base_tr;
        uart_false_start_transaction false_tr;

        int i;
     
        vif.rx_driver      = 1'b1;

        for(i=0;i<transaction_num;i++) begin
            gen2rxdrv.get(base_tr);
            
            if(!$cast(false_tr,base_tr))begin
                $fatal(1,"[RX_DRIVER] expected uart_false_start_transaction");
            end

            false_tr.display("RX_DRIVER");

            if(false_tr.inject_false_start) begin
                drive_false_start(false_tr);
                false_start_count++;

            end
            drive_one(false_tr);

            normal_frame_count++;
            
        end

       
    endtask

   
endclass






