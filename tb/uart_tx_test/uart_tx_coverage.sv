class uart_tx_coverage;
    
    mailbox #(uart_transaction) txdrv2cov;

    tx_scenario_t sampled_scenario;
    bit[7:0] sampled_data;
    inject_point_t sampled_reset_point;
    inject_point_t sampled_busy_point;
    int unsigned sampled_busy_data_bit;

    //Statistics
    int sample_count;
    int normal_sample_count;
    int reset_sample_count;
    int busy_sample_count;

    

    covergroup tx_cg;

        cp_scenario:
            coverpoint sampled_scenario{

                bins normal={TX_SCENARIO_NORMAL};
                bins reset={TX_SCENARIO_RESET};
                bins busy={TX_SCENARIO_BUSY};

            }

        cp_normal_data:
            coverpoint sampled_data{

                bins zero={8'h00};
                bins all_one={8'hFF};
                bins alternating_55={8'h55};
                bins alternating_AA={8'hAA};
                bins other=default;

            }

        cp_reset_point:
            coverpoint sampled_reset_point iff(
                sampled_scenario==TX_SCENARIO_RESET
            ) {
                bins start={INJECT_START};
                bins data={INJECT_DATA};
                bins stop={INJECT_STOP};

                illegal_bins none={INJECT_NONE};

            }

        cp_busy_point:
            coverpoint sampled_busy_point iff(
                sampled_scenario==TX_SCENARIO_BUSY
            ) {

                bins start={INJECT_START};
                bins data={INJECT_DATA};
                bins stop={INJECT_STOP};
                illegal_bins none={INJECT_NONE};

            }

        cp_busy_data_bit:
            coverpoint sampled_busy_data_bit iff(
                sampled_scenario==TX_SCENARIO_BUSY&&sampled_busy_point==INJECT_DATA
            ) {
                bins bit_position[]={[0:7]};

                illegal_bins invalid_bit=default;

            }
        
        cross_scenario_data:
            cross cp_scenario,cp_normal_data;

    endgroup

    function new(mailbox #(uart_transaction) txdrv2cov );

        this.txdrv2cov=txdrv2cov;
        tx_cg=new();

        sample_count=0;
        normal_sample_count=0;
        reset_sample_count=0;
        busy_sample_count=0;

        sampled_scenario=TX_SCENARIO_NORMAL;
        sampled_data=8'h00;
        sampled_reset_point=INJECT_NONE;
        sampled_busy_point=INJECT_NONE;
        sampled_busy_data_bit=0;

    endfunction


    

    function void sample_transaction(
        uart_transaction base_tr
    );
        uart_reset_transaction reset_tr;
        uart_busy_transaction busy_tr;

        if(base_tr==null) begin 
            $error("[TX_COVERAGE] received null transaction ");

            return;
        end

        sampled_scenario=TX_SCENARIO_NORMAL;
        sampled_data=base_tr.data;
        sampled_reset_point=INJECT_NONE;
        sampled_busy_point=INJECT_NONE;
        sampled_busy_data_bit=0;

        if($cast(busy_tr,base_tr))begin

            sampled_scenario=TX_SCENARIO_BUSY;
            sampled_data=busy_tr.data;
            sampled_busy_point=busy_tr.busy_inject_point;
            sampled_busy_data_bit=busy_tr.busy_data_bit;

            busy_sample_count++;


        end
        else if($cast(reset_tr,base_tr) && reset_tr.inject_reset) begin

            sampled_scenario=TX_SCENARIO_RESET;
            sampled_data=reset_tr.data;
            sampled_reset_point=reset_tr.tx_reset_point;

            reset_sample_count++;


        end
        else begin

            sampled_scenario=TX_SCENARIO_NORMAL;
            sampled_data=base_tr.data;

            normal_sample_count++;


        end

        tx_cg.sample();

        sample_count++;
        
        $display("[TX_COVERAGE] sample=%0d scenario=%s data=0x%02h reset_point=%s busy_point=%s busy_bit=%0d coverage=%0.2f%%",
                    sample_count,
                    sampled_scenario.name(),
                    sampled_data,
                    sampled_reset_point.name(),
                    sampled_busy_point.name(),
                    sampled_busy_data_bit,
                    tx_cg.get_inst_coverage());

    endfunction

    task run();
        uart_transaction base_tr;
        
        forever begin
            txdrv2cov.get(base_tr);
            sample_transaction(base_tr);

        end

    endtask

    function void report();
        $display("=========================TX COVERAGE REPORT==========================");

        $display("Total sample: %0d",sample_count);

        $display("Normal sample: %0d",normal_sample_count);

        $display("Reset sample: %0d",reset_sample_count);

        $display("Busy sample: %0d",busy_sample_count);

        $display("TX coverage: %0.2f%%",tx_cg.get_inst_coverage());

        $display("=====================================================================");

    endfunction

endclass





    
