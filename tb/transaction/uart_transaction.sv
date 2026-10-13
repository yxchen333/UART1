class uart_transaction;
    rand bit[7:0] data;

    protected function void copy_base(uart_transaction dst);
        dst.data=this.data;
       
    endfunction

    virtual function uart_transaction copy();
        uart_transaction tr;
        tr=new();
        copy_base(tr);
        return tr;
    endfunction

    virtual function void display(string name="UART_TRANSACTION");
        $display("[%s] data=0x%02h ",name,data);
    endfunction

endclass