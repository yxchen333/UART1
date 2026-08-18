class uart_monitor_transaction extends uart_transaction;
    bit [7:0] actual_data;

    bit actual_stop_bit;
    bit actual_rx_done;
    bit actual_frame_error;
    
    time sample_time;

    function new();
        super.new();
        actual_data=8'h00;
        actual_stop_bit=1'b1;
        actual_rx_done=1'b0;
        sample_time=0;
        actual_frame_error=1'b0;

    endfunction

    function void set_sample(
        bit[7:0] sampled_data,
        bit      sampled_stop_bit,
        bit      sampled_rx_done,
        bit      sampled_frame_error
    );
        actual_data=sampled_data;
        actual_stop_bit=sampled_stop_bit;
        actual_rx_done=sampled_rx_done;
        sample_time=$time;
        actual_frame_error=sampled_frame_error;

        stop_error=(sampled_stop_bit!=1'b1);

    endfunction

    protected function void copy_monitor(
        uart_monitor_transaction dst
    );
        copy_base(dst);
        dst.actual_data=this.actual_data;
        dst.actual_stop_bit=this.actual_stop_bit;
        dst.actual_rx_done=this.actual_rx_done;
        dst.actual_frame_error=this.actual_frame_error;
        dst.sample_time=this.sample_time;

    endfunction

    virtual function uart_transaction copy();
        uart_monitor_transaction tr;
        tr=new();
        copy_monitor(tr);
        return tr;
    endfunction

    virtual function void display(
        string name="UART_MONITOR_TRANSACTION"
    );
        $display(
            "[%s] actual_data=0x%02h stop_bit=%0b stop_error=%0b",
            name,
            actual_data,
            actual_stop_bit,
            stop_error
        );

        $display(
            "    rx_done=%0b sample_time=%0t frame_error=%0b",
            actual_rx_done,
            sample_time,
            actual_frame_error
        );
    endfunction

endclass