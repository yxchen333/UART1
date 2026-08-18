class uart_stop_error_transaction extends uart_transaction;
    function new();
        super.new();
        stop_error=1'b1;
    endfunction

    virtual function uart_transaction copy();
        uart_stop_error_transaction tr;
        tr=new();
        copy_base(tr);
        return tr;
    endfunction

    virtual function void display(string name="UART_STOP_ERROR_TRANSACTION");
        $display("[%s] data=0x%02h stop_error=%0b,inject bad stop bit",name,data,stop_error);
    endfunction

endclass