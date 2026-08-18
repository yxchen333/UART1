class uart_false_start_transaction extends uart_transaction;

    rand bit inject_false_start;
    rand int unsigned false_start_cycles;
    

    constraint c_false_start_cycles{
        if(inject_false_start)
            false_start_cycles inside {
                [1:4]
            };
        else 
            false_start_cycles==0;

    };

    constraint c_inject_probability{
        inject_false_start dist{
            1:=30,
            0:=70
        };
    };

    function new();
        super.new();
        false_start_cycles=1;
        inject_false_start=1'b0;

    endfunction

    protected function void copy_false_start(
        uart_false_start_transaction dst
    );
        copy_base(dst);
        dst.false_start_cycles=this.false_start_cycles;
        dst.inject_false_start=this.inject_false_start;

    endfunction

    virtual function uart_transaction copy();
        uart_false_start_transaction tr;
        tr=new();
        copy_false_start(tr);

        return tr;
    endfunction

    virtual function void display(
        string name="UART_FALSE_START_TRANSACTION"
    );
        $display("[%s] data=0x%02h inject_false_start=%0b false_start_cycles=%0d",name,data,inject_false_start,false_start_cycles);

    endfunction


endclass



