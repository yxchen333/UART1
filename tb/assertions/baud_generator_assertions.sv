 module baud_generator_assertions #(
    parameter int unsigned TX_BAUD_DIV    = 434,
    parameter int unsigned COUNT_WIDTH = $clog2(TX_BAUD_DIV)
)(
    input logic clk,
    input logic reset_n,
    input logic [COUNT_WIDTH-1:0] count,
    input logic bg_tick
);
 
 
 
 property p_baud_count_increasement;
        @(posedge clk)
        disable iff(!reset_n)

        (count<TX_BAUD_DIV-1)|=>(count==$past(count)+1'b1);
    endproperty

    assert property (p_baud_count_increasement)
    else begin
        $error("[ASSERT FAIL] time=%0t p_baud_count_increasement is  wrong",$time);
    end

    property p_baud_count_rollover;
        @(posedge clk)
        disable iff(!reset_n)

        (count==TX_BAUD_DIV-1)|=>
        ((count==0)&&(bg_tick==1'b1));
    endproperty

    assert property (p_baud_count_rollover)
    else begin
        $error("[ASSERT FAIL] time=%0t p_baud_count_rollover is  wrong",$time);
    end

endmodule