class uart_generator;
    mailbox #(uart_transaction) gen2drv;
    int transaction_num;

    function new(mailbox #(uart_transaction) gen2drv);
        this.gen2drv=gen2drv;
        this.transaction_num=20;
    endfunction

    task run();

        uart_transaction tr;

        repeat(transaction_num) begin
            tr=new();

            assert(tr.randomize())
            else $fatal("Transaction randomize failed");

            tr.display("Generator");

            gen2drv.put(tr);
        end
    endtask
endclass
