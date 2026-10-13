class uart_tx_generator;
    mailbox #(uart_transaction) gen2txdrv;
  
    int generated_group_count;
  

    function new(mailbox #(uart_transaction) gen2txdrv);
        this.gen2txdrv=gen2txdrv;
        
        generated_group_count = 0;
    

    endfunction


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
          

            interrupted_tr.display("TX_RESET_GENERATOR interrupted_data");

            gen2txdrv.put(interrupted_tr);



            recovery_tr=new();
             if(!recovery_tr.randomize() with {
                inject_reset==1'b0;
            }) begin
                $fatal(1,"[TX GENERATOR] reset recovery transaction randomize failed ");
            end 

            

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
            

            interrupted_tr.display("TX_RESET_GENERATOR interrupted_data");

            gen2txdrv.put(interrupted_tr);



            recovery_tr=new();
             if(!recovery_tr.randomize() with {
                inject_reset==1'b0;
            }) begin
                $fatal(1,"[TX GENERATOR] reset recovery transaction randomize failed ");
            end 

            

            recovery_tr.display("TX_RESET_GENERATOR recovery_data");

            gen2txdrv.put(recovery_tr);

        end
    endtask


    task run_busy(input int num);

        uart_busy_transaction tr;

        bit [7:0] directed_data[4];
        int bit_idx;

        directed_data[0] = 8'h00;
        directed_data[1] = 8'hFF;
        directed_data[2] = 8'h55;
        directed_data[3] = 8'hAA;

        foreach(directed_data[i]) begin
            tr=new();

            if(!tr.randomize()with {
            data == directed_data[i];
             } )
            begin
                $fatal(
                    1,
                    "[TX_GENERATOR] directed busy randomize failed"
                );
            end
            gen2txdrv.put(tr);
            generated_group_count++;

            $display(
            "[TX_GENERATOR] boundary[%0d]: data=0x%02h interference_data=0x%02h inject_point=%s",
            i,
            tr.data,
            tr.interference_data,
            tr.busy_inject_point.name()
            );

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
            generated_group_count++;

            $display(
                "[TX_GENERATOR] directed DATA bit=%0d data=0x%02h interference=0x%02h",
                tr.busy_data_bit,
                tr.data,
                tr.interference_data
            );

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
        generated_group_count++;
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
        generated_group_count++;
        
        repeat(num-4-8-2) begin
            tr=new();
            if(!tr.randomize())$fatal(1,"[TX_GENERATOR] busy transaction randomize failed");

            tr.display("TX_GENERATOR ");
            generated_group_count++;

            gen2txdrv.put(tr);
        end
      

        $display(
            "[TX_GENERATOR] generation complete, groups=%0d data_values=%0d",
            generated_group_count,
            generated_group_count * 2
        );

    endtask
    
endclass
