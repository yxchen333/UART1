class uart_rx_generator;
    mailbox #(uart_transaction) gen2rxdrv;
    int transaction_num;
    bit error_pattern[$];

    uart_rx_gen_mode_t mode;

    int expected_result_num;
    int generated_count;
    int injected_count;

    function new(mailbox #(uart_transaction) gen2rxdrv);

        this.gen2rxdrv=gen2rxdrv;
        this.transaction_num=20;
        mode            = RX_GEN_RANDOM;

        expected_result_num=20;
        generated_count=0;
        injected_count=0;

    endfunction

    function void configure_error_recovery();

        mode = RX_GEN_ERROR_RECOVERY;

        error_pattern.delete();

        // 正常 → 正常
        error_pattern.push_back(1'b0);
        error_pattern.push_back(1'b0);

        // 正常 → 错误 → 正常
        error_pattern.push_back(1'b1);
        error_pattern.push_back(1'b0);

        // 错误 → 错误 → 正常
        error_pattern.push_back(1'b1);
        error_pattern.push_back(1'b1);
        error_pattern.push_back(1'b0);

        transaction_num = error_pattern.size();

    endfunction

    function void error_pattern1();
        

        error_pattern.push_back(1'b0); // normal
        error_pattern.push_back(1'b0); // normal

        error_pattern.push_back(1'b0); // normal
        error_pattern.push_back(1'b1); // error

        error_pattern.push_back(1'b1); // error
        error_pattern.push_back(1'b0); // recovery normal

        error_pattern.push_back(1'b1); // error
        error_pattern.push_back(1'b1); // consecutive errors

    endfunction

    task run();

        uart_transaction tr;

        case(mode)
            RX_GEN_ERROR_RECOVERY:begin

                foreach(error_pattern[i])begin
                    tr=new();

                    if(!tr.randomize()) begin
                        $fatal(1,"[RX_GENERATOR] randomization failed");
                    end

                    tr.stop_error=error_pattern[i];

                    $display("[RX_GENERATOR] recovery[%0d] data=0x%02h stop_error=%0b",i,tr.data,tr.stop_error);

                    gen2rxdrv.put(tr);
                end
            end

            RX_GEN_RANDOM: begin

                repeat (transaction_num) begin

                    tr = new();

                    if (!tr.randomize()) begin
                        $fatal(
                            1,
                            "[RX_GENERATOR] randomization failed"
                        );
                    end

                    gen2rxdrv.put(tr);

                end

            end


            default: begin
                $fatal(
                    1,
                    "[RX_GENERATOR] unsupported generator mode"
                );
            end

        endcase


    endtask

    task run_false_start_test();
        uart_false_start_transaction tr;

        bit inject_plan[$];

        int i;

        
        int false_start_target=12;

       
        bit generation_done=1'b0;

        repeat (false_start_target)
            inject_plan.push_back(1'b1);
        repeat (expected_result_num-false_start_target)inject_plan.push_back(1'b0);

        inject_plan.shuffle();
        
        for(i=0;i<expected_result_num;i++) begin
            tr=new();

            if(!tr.randomize()with{inject_false_start==inject_plan[i];})
            begin 
                $fatal(1,"[RX_GENERATOR] false-start transaction randomize failed");
            end

            if(tr.inject_false_start)
                injected_count++;
            
            tr.display("RX_GENERATOR");

            gen2rxdrv.put(tr);
            generated_count++;
        end

        generation_done=1'b1;

        $display(
            "[RX_GENERATOR] complete total =%0d false_start=%0d normal_only=%0d",
            generated_count,
            injected_count,
            generated_count-injected_count
        );


    endtask
endclass
