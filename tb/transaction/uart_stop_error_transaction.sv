class uart_stop_error_transaction extends uart_transaction;

    bit stop_error;

    function new();
        super.new();
        stop_error=1'b1;
    endfunction

    protected function void copy_stop(
        uart_stop_error_transaction dst
    );
        copy_base(dst);
        dst.stop_error=this.stop_error;
    endfunction

    virtual function uart_transaction copy();
        uart_stop_error_transaction tr;
        tr=new();
        copy_stop(tr);
        return tr;
    endfunction

    virtual function void display(string name="UART_STOP_ERROR_TRANSACTION");
        $display("[%s] data=0x%02h stop_error=%0b",name,data,stop_error);
    endfunction

endclass