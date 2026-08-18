class uart_tx_generator;
    mailbox #(uart_transaction) gen2txdrv;
    int transaction_num;
    uart_gen_mode_t mode;

    int expected_result_num;
    int generated_group_count;

    bit generation_done;

    bit [7:0] boundary_data[$];
    bit [7:0] reset_data[$];

    inject_point_t reset_point;

    function new(mailbox #(uart_transaction) gen2txdrv);
        this.gen2txdrv=gen2txdrv;
        this.transaction_num=20;
        mode=GEN_RANDOM;

        expected_result_num=10;
        generated_group_count = 0;
        generation_done       = 1'b0;

        reset_point       = INJECT_NONE;
    endfunction

    function void configure_boundary_mode();
        mode=GEN_BOUNDARY;

        boundary_data.delete();

        boundary_data.push_back(8'h00);
        boundary_data.push_back(8'hFF);
        boundary_data.push_back(8'h55);
        boundary_data.push_back(8'hAA);
        boundary_data.push_back(8'h01);
        boundary_data.push_back(8'h80);

        transaction_num=boundary_data.size();

    endfunction

    function void configure_random_mode(int num=20);
        mode=GEN_RANDOM;
        transaction_num=num;
        expected_result_num = num;
    endfunction

    function void configure_reset_mode(
            inject_point_t point,
            bit [7:0] interrupted_data = 8'hA5,
            bit [7:0] recovery_data    = 8'h3C
        );

        mode        = GEN_RESET;
        reset_point = point;

        reset_data.delete();

        // 第一笔：发送中途复位
        reset_data.push_back(interrupted_data);

        // 第二笔：复位后正常发送
        reset_data.push_back(recovery_data);

        /*
         * 尝试发送2笔，
         * 但只有恢复帧进入Scoreboard。
         */
        transaction_num     = reset_data.size();
        expected_result_num = 1;

    endfunction


    task run();

        uart_reset_transaction tr;
        int i;
            

        if(mode==GEN_BOUNDARY)begin
            configure_boundary_mode();

            foreach(boundary_data[i])begin
                tr=new();
                tr.data=boundary_data[i];

                tr.stop_error=1'b0;
                tr.inject_reset   = 1'b0;
                tr.tx_reset_point = INJECT_NONE;

                $display("[TX_GENERATOR] boundary[%0d] data=0x%02h",i,tr.data);
                gen2txdrv.put(tr);
            end
        end
        else if(mode==GEN_RANDOM)begin

            
            for(i=0;i<transaction_num;i++)begin
                tr=new();

                assert(tr.randomize())
                else $fatal("[TX_GENERATOR] Transaction randomize failed");
                
                if(i<transaction_num/2)
                    tr.stop_error=1'b0;
                else
                    tr.stop_error=1'b0;

                tr.inject_reset   = 1'b0;
                tr.tx_reset_point = INJECT_NONE;

                $display(
                    "[TX_GENERATOR] random data=0x%02h",
                    tr.data
                );

                gen2txdrv.put(tr);
            end
        end
        else if(mode==GEN_RESET)begin
             for (i = 0; i < reset_data.size(); i = i + 1) begin

                    tr = new();

                    tr.data       = reset_data[i];
                    tr.stop_error = 1'b0;

                    if (i == 0) begin

                        // 第一帧需要在发送过程中复位
                        tr.inject_reset   = 1'b1;
                        tr.tx_reset_point = reset_point;

                        $display(
                            "[TX_GENERATOR] interrupted data=0x%02h reset_point=%0d",
                            tr.data,
                            tr.tx_reset_point
                        );

                    end
                    else begin

                        // 第二帧为复位后的正常恢复帧
                        tr.inject_reset   = 1'b0;
                        tr.tx_reset_point = INJECT_NONE;

                        $display(
                            "[TX_GENERATOR] recovery data=0x%02h",
                            tr.data
                        );

                    end

                    gen2txdrv.put(tr);

                end

            end


    endtask

    task run_normal(input int num);

        uart_transaction tr;
        bit[7:0] directed_data[4];

        directed_data[0]=8'h00;
        directed_data[1]=8'hFF;
        directed_data[2]=8'h55;
        directed_data[3]=8'hAA;

        foreach(directed_data[i]) begin
            tr=new();

            if(!tr.randomize() with{
                data==directed_data[i];
            }) begin
                $fatal(1,"[TX_GENERATOR] directed normal randomize failed");
                end

                gen2txdrv.put(tr);
        end

        repeat (num-4)begin

            tr=new();

            assert(tr.randomize())
            else $fatal("[TX_GENERATOR]  Normal Transaction randomize failed");

            gen2txdrv.put(tr);

        end

    endtask

    task run_reset(input int group_num);

        uart_reset_transaction interrupted_tr;
        uart_reset_transaction recovery_tr;

        bit [7:0] directed_data[4];
        int i;

        directed_data[0] = 8'h00;
        directed_data[1] = 8'hFF;
        directed_data[2] = 8'h55;
        directed_data[3] = 8'hAA;
        
        foreach(directed_data[i])begin
            interrupted_tr=new();

            if(!interrupted_tr.randomize() with {
                inject_reset==1'b1;
                data==directed_data[i];
            })
            begin
                $fatal(
                    1,
                    "[TX_GENERATOR] directed reset randomize failed"
                );
            end
            interrupted_tr.stop_error = 1'b0;

            interrupted_tr.display("TX_RESET_GENERATOR interrupted_data");

            gen2txdrv.put(interrupted_tr);



            recovery_tr=new();
             if(!recovery_tr.randomize() with {
                inject_reset==1'b0;
            }) begin
                $fatal(1,"[TX GENERATOR] reset recovery transaction randomize failed ");
            end 

            recovery_tr.stop_error = 1'b0;

            recovery_tr.display("TX_RESET_GENERATOR recovery_data");

            gen2txdrv.put(recovery_tr);
        end


        

        for(i=0;i<group_num-4;i++) begin

            interrupted_tr=new();            
            if(!interrupted_tr.randomize() with {
                inject_reset==1'b1;
            }) begin
                $fatal(1,"[TX GENERATOR] reset interrupted transaction randomize failed ");
            end 
            interrupted_tr.stop_error = 1'b0;

            interrupted_tr.display("TX_RESET_GENERATOR interrupted_data");

            gen2txdrv.put(interrupted_tr);



            recovery_tr=new();
             if(!recovery_tr.randomize() with {
                inject_reset==1'b0;
            }) begin
                $fatal(1,"[TX GENERATOR] reset recovery transaction randomize failed ");
            end 

            recovery_tr.stop_error = 1'b0;

            recovery_tr.display("TX_RESET_GENERATOR recovery_data");

            gen2txdrv.put(recovery_tr);

        end
    endtask


    task run_busy(input int num);

        uart_busy_transaction tr;
        

        bit [7:0] directed_data[4];
        int bit_idx;
        generation_done = 1'b0;

        directed_data[0] = 8'h00;
        directed_data[1] = 8'hFF;
        directed_data[2] = 8'h55;
        directed_data[3] = 8'hAA;

        foreach(directed_data[i]) begin
            tr=new();

            if(!tr.randomize() )
            begin
                $fatal(
                    1,
                    "[TX_GENERATOR] directed busy randomize failed"
                );
            end
            gen2txdrv.put(tr);

        end

       

        for(bit_idx=0;bit_idx<8;bit_idx++)begin
            tr=new();
          
            case(bit_idx)
                0:begin
                    if(!tr.randomize() with{
                    busy_inject_point==INJECT_DATA;
                    busy_data_bit==0;
                    data==8'h55;
                    })
                    begin
                        $fatal(
                            1,
                            "[TX_GENERATOR] directed busy randomize failed"
                        );
                    end
                    end

                default:begin
                    if(!tr.randomize() with{
                    busy_inject_point==INJECT_DATA;
                        busy_data_bit==bit_idx;
                    })
                    begin
                        $fatal(
                            1,
                            "[TX_GENERATOR] directed busy randomize failed"
                        );
                    end
                end

            endcase
            gen2txdrv.put(tr);
        end
        //1
        tr = new();

        if (!tr.randomize() with {
            busy_inject_point == INJECT_START;
            data              == 8'hFF;
        }) begin

            $fatal(
                1,
                "[TX_GENERATOR] directed busy START failed"
            );

        end

        $display(
            "[TX_GENERATOR] directed busy START data=0x%02h",
            tr.data
        );

        gen2txdrv.put(tr);
        //2
        tr = new();

        if (!tr.randomize() with {
            busy_inject_point == INJECT_STOP;
            data              == 8'hAA;
        }) begin

            $fatal(
                1,
                "[TX_GENERATOR] directed busy STOP failed"
            );

        end

        $display(
            "[TX_GENERATOR] directed busy STOP data=0x%02h",
            tr.data
        );

        gen2txdrv.put(tr);
        
        repeat(num-4-8-2) begin
            tr=new();
            if(!tr.randomize())$fatal(1,"[TX_GENERATOR] busy transaction randomize failed");

            tr.display("TX_GENERATOR ");
            generated_group_count++;

            gen2txdrv.put(tr);
        end
        generation_done = 1'b1;

        $display(
            "[TX_GENERATOR] generation complete, groups=%0d data_values=%0d",
            generated_group_count,
            generated_group_count * 2
        );

    endtask
    
endclass
