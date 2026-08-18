module uart_assertions(
    input logic clk,
    input logic reset_n,

    input logic tx,
    input logic busy,
    input logic tx_done,

    input logic rx_done,
    input logic frame_error
);

    property p_tx_idle_high;
        @(posedge clk)
        disable iff(!reset_n)

        (!busy)|->(tx===1'b1);
    endproperty

    a_tx_idle_high:
    assert property (p_tx_idle_high)
    else begin
        $error("[ASSERT FAIL] time=%0t TX is not high while idle",$time);
    end

    property p_tx_done_one_cycle;
        @(posedge clk)
        disable iff(!reset_n)

        tx_done|=>!tx_done;
    endproperty

    a_tx_done_one_cycle:
    assert property (p_tx_done_one_cycle)
    else begin
        $error("[ASSERT FAIL] time=%0t tx_done lasts more than one cycle",$time);
    end

    property p_rx_done_error_mutex;
        @(posedge clk)
        disable iff(!reset_n)

        !(rx_done&&frame_error);
    endproperty

    a_rx_done_error_mutex:
    assert property (p_rx_done_error_mutex)
    else begin
        $error("[ASSERT FAIL] time=%0t rx_done and frame_error are both high",$time);
    end

    property p_busy_no_early_drop;
        @(posedge clk)
        disable iff(!reset_n)

        (busy&&!tx_done)|=>(busy||tx_done);

    endproperty

    a_busy_no_early_drop:
    assert property(p_busy_no_early_drop)
    else begin
        $error("[ASSERT FAIL] time=%0t busy dropped before transmission completed",$time);
    end

    property p_tx_done_after_busy;
        @(posedge clk)
        disable iff(!reset_n)

        tx_done|->$past(busy);
    endproperty

    a_tx_done_after_busy:
    assert property(p_tx_done_after_busy)
    else begin
        $error("[ASSERT FAIL] time=%0t tx_done occurred without previous busy",$time);
    end

    property p_rx_outputs_clear_during_reset;
        @(posedge clk)
        !reset_n|->(!rx_done&&!frame_error);
    endproperty

    assert property(p_rx_outputs_clear_during_reset)
    else
        $error("[ASSERT FAIL] RX result active during reset");

    property p_rx_clean_after_reset;
        @(posedge clk)

        $rose(reset_n)|=>(!rx_done&&!frame_error);
    endproperty

    assert property (p_rx_clean_after_reset)
    else
        $error(
            "[ASSERT FAIL] RX result not cleared after reset"
        );

    property p_tx_safe_during_reset;
        @(posedge clk)

        !reset_n
        |->
        (
            tx      &&
            !busy   &&
            !tx_done
        );
    endproperty

    assert property (p_tx_safe_during_reset)
    else
        $error(
            "[ASSERT FAIL] TX is not safe during reset"
        );

    property p_tx_clean_after_reset;
        @(posedge clk)

        $rose(reset_n)
        |=>
        (
            tx      &&
            !busy   &&
            !tx_done
        );
    endproperty

    assert property (p_tx_clean_after_reset)
    else
        $error(
            "[ASSERT FAIL] TX not idle after reset"
        );

endmodule
