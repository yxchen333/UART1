class uart_busy_transaction extends uart_transaction;

   rand bit[7:0] interference_data;

   rand inject_point_t busy_inject_point;
   rand int unsigned busy_data_bit;
   rand int unsigned tx_valid_hold_cycles;

   constraint c_different_data{
    interference_data!=data;
   }

    constraint c_busy_inject_point{
        busy_inject_point inside{
            INJECT_DATA,
            INJECT_START,
            INJECT_STOP
        };
    }
    constraint c_busy_data_bit{
        if(busy_inject_point==INJECT_DATA)
            busy_data_bit inside{[0:7]};
        else
            busy_data_bit==0;

    }


    
    constraint c_tx_valid_hold{
        tx_valid_hold_cycles==1;

    }

    function new();
        super.new();
        interference_data=8'h00;
        busy_inject_point=INJECT_START;
        busy_data_bit=0;
        tx_valid_hold_cycles=1;
    endfunction

    protected function void copy_busy(
        uart_busy_transaction dst
    );
        copy_base(dst);
        dst.interference_data=this.interference_data;
        dst.busy_inject_point=this.busy_inject_point;
        dst.busy_data_bit=this.busy_data_bit;
        dst.tx_valid_hold_cycles=this.tx_valid_hold_cycles;
    endfunction

    virtual function uart_transaction copy();
        uart_busy_transaction tr;
        tr=new();
        copy_busy(tr);
        return tr;
    endfunction
    

    virtual function void display(
        string name = "UART_BUSY_TRANSACTION"
    );

        $display(
            "[%s] normal_data=0x%02h interference_data=0x%02h",
            name,
            data,
            interference_data
        );

        if (busy_inject_point == INJECT_DATA) begin

            $display(
                "    inject_point=%s data_bit=%0d tx_valid_hold=%0d",
                busy_inject_point,
                busy_data_bit,
                tx_valid_hold_cycles
            );

        end
        else begin

            $display(
                "    inject_point=%s tx_valid_hold=%0d",
                busy_inject_point,
                tx_valid_hold_cycles
            );

        end

    endfunction
endclass


