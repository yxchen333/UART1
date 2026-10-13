class uart_generator;
    mailbox #(uart_transaction) gen2drv;
    int transaction_num;

    function new(mailbox #(uart_transaction) gen2drv);
        this.gen2drv=gen2drv;
        this.transaction_num=20;
    endfunction

    task run();

        uart_stop_error_transaction tr;

        for(int i=0;i<transaction_num;i++) begin
            tr=new();

            assert(tr.randomize())
            else $fatal("Transaction randomize failed");

            tr.stop_error = (i == transaction_num-1);

            tr.display("Generator");

            gen2drv.put(tr);
        end

        


    endtask
endclass
