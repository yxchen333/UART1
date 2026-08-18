class uart_transaction;
    rand bit[7:0] data;

    bit stop_error;

    function new();
        stop_error=1'b0;
    endfunction

    protected function void copy_base(uart_transaction dst);
        dst.data=this.data;
        dst.stop_error=this.stop_error;

    endfunction

    virtual function uart_transaction copy();
        uart_transaction tr;
        tr=new();
        copy_base(tr);
        return tr;
    endfunction

    virtual function void display(string name="UART_TRANSACTION");
        $display("[%s] data=0x%02h stop_error=%0b ",name,data,stop_error);
    endfunction

endclass