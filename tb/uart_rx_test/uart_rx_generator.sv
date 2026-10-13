class uart_rx_generator;
    mailbox #(uart_transaction) gen2rxdrv;
    int transaction_num;
    
    bit error_pattern[$];  // 决定 stop_error
    bit inject_plan[$];    // 决定 inject_false_start

    int generated_count;
    int injected_count;

    function new(mailbox #(uart_transaction) gen2rxdrv);

        this.gen2rxdrv=gen2rxdrv;
        this.transaction_num=20;     

        generated_count=0;
        injected_count=0;

    endfunction

    function void configure_stop_and_start_error_pattern();

        int i;
        int j;
        bit tmp;
        

        error_pattern.delete();
        inject_plan.delete();

        
        error_pattern.push_back(1'b0);
        inject_plan.push_back(1'b0);

        error_pattern.push_back(1'b0);
        inject_plan.push_back(1'b1);

        error_pattern.push_back(1'b1);
        inject_plan.push_back(1'b0);

        error_pattern.push_back(1'b1);
        inject_plan.push_back(1'b1);

        repeat(transaction_num - 4) begin
            error_pattern.push_back($urandom_range(0,1));
            inject_plan.push_back($urandom_range(0,1));
        end

        //two queues are disorganized
        

        for(i = error_pattern.size()-1; i > 0; i--) begin

            j = $urandom_range(0, i);

            // error_pattern交换
            tmp = error_pattern[i];
            error_pattern[i] = error_pattern[j];
            error_pattern[j] = tmp;

            // inject_plan必须交换相同的两个位置
            tmp = inject_plan[i];
            inject_plan[i] = inject_plan[j];
            inject_plan[j] = tmp;

        end

    endfunction

    
    

    task run_false_start_test();

        int i;
        uart_false_start_transaction tr;

        configure_stop_and_start_error_pattern();

        for(i=0;i<transaction_num;i++) begin
            tr=new();

            if(!tr.randomize()with{inject_false_start==inject_plan[i];})
            begin 
                $fatal(1,"[RX_GENERATOR] false-start transaction randomize failed");
            end

            if(tr.inject_false_start)
                injected_count++;
            
            tr.stop_error = error_pattern[i];
            tr.display("RX_GENERATOR");

            gen2rxdrv.put(tr);
            generated_count++;
        end


        $display(
            "[RX_GENERATOR] complete total =%0d false_start=%0d ",
            generated_count,
            injected_count
        );


    endtask

   

endclass
