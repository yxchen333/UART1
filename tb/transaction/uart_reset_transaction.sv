class uart_reset_transaction extends uart_transaction;
    rand bit inject_reset;
    rand inject_point_t tx_reset_point;

    //will be used later
   rand int unsigned reset_data_bit;
   rand int unsigned reset_phase_offset;
   rand int unsigned reset_low_cycles;
   

   

    constraint c_reset_point{
        if(inject_reset){

            tx_reset_point inside{
                INJECT_START,
                INJECT_DATA,
                INJECT_STOP
            };

        }
        else 
            tx_reset_point==INJECT_NONE;
        
    }

    constraint c_reset_point_dist {

        if (inject_reset) 
        {
               tx_reset_point dist {
                INJECT_START := 1,
                INJECT_DATA  := 1,
                INJECT_STOP  := 1
            };

        } 

    }

    constraint c_reset_data_bit {
        if(tx_reset_point==INJECT_DATA)
            reset_data_bit inside {[0:7]};
        else 
            reset_data_bit==0;
    }

    constraint c_reset_phase{
        reset_phase_offset inside {[1:UART_BAUD_DIV/2]};
    }

    constraint c_reset_width{
        reset_low_cycles inside {[1:4]};
    }
    
    function new();
        super.new();
        inject_reset=1'b0;

    endfunction

     protected function void copy_reset(
        uart_reset_transaction dst
    );
        copy_base(dst);
        dst.inject_reset=this.inject_reset;
        dst.tx_reset_point=this.tx_reset_point;
        dst.reset_data_bit     = this.reset_data_bit;
        dst.reset_phase_offset = this.reset_phase_offset;
        dst.reset_low_cycles   = this.reset_low_cycles;

    endfunction

    virtual function uart_transaction copy();
        uart_reset_transaction tr;
        tr=new();
        copy_reset(tr);
        return tr;
    endfunction

    virtual function void display(
        string name="UART_RESET_TRANSACTION"
    );
        $display("[%s] data=0x%02h inject_reset=%0b,tx_reset_point=%0d",name,data,inject_reset,tx_reset_point); 
    endfunction
endclass