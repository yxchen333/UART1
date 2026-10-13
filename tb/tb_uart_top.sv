module tb_uart_top;
    timeunit 1ns;
    timeprecision 1ps;

    logic tx_clk;
    logic rx_clk;
    uart_if vif(tx_clk,rx_clk);

    import uart_pkg::*;
    localparam int unsigned UART_BAUD_RATE = uart_params_pkg::UART_BAUD_RATE;
    localparam int unsigned TX_CLK_FREQ_HZ =uart_params_pkg::TX_CLK_FREQ_HZ;
    localparam int unsigned RX_CLK_FREQ_HZ =uart_params_pkg::RX_CLK_FREQ_HZ;

    localparam int unsigned RX_BAUD_RATE = uart_params_pkg::RX_BAUD_RATE;

    localparam real TX_CLK_HALF_PERIOD_NS = 1.0e9 / (2.0 * TX_CLK_FREQ_HZ);
    localparam real RX_CLK_HALF_PERIOD_NS = 1.0e9 / (2.0 * RX_CLK_FREQ_HZ);

    //assign vif.rx=(vif.loopback_en)?vif.tx:vif.rx_driver;
    assign vif.rx=(vif.rx_override_en)?vif.rx_override:vif.tx;


    initial begin
        tx_clk=1'b0;
        forever #(TX_CLK_HALF_PERIOD_NS) tx_clk=~tx_clk;
    end

    initial begin
        rx_clk=1'b0;
        forever #(RX_CLK_HALF_PERIOD_NS) rx_clk=~rx_clk;
    end

    baud_generator#(
        .CLK_FREQ_HZ    (TX_CLK_FREQ_HZ),
        .UART_BAUD_RATE (UART_BAUD_RATE)
    ) u1(
        .clk(tx_clk),
        .reset_n(vif.reset_n),
        .bg_tick(vif.bg_tick)
        );
    uart_tx u_tx(
        .clk(tx_clk),
        .reset_n(vif.reset_n),
        .bg_tick(vif.bg_tick),
        .data(vif.data),
        .tx_valid(vif.tx_valid),
        .tx(vif.tx),
        .busy(vif.busy),
        .tx_done(vif.tx_done)
        );
    
    uart_rx#(
    .CLK_FREQ_HZ    (RX_CLK_FREQ_HZ),
    .UART_BAUD_RATE (RX_BAUD_RATE)
    )  u_rx(
        .clk(rx_clk),
        .reset_n(vif.reset_n),
        .rx(vif.rx),
        .rx_data(vif.rx_data),
        .rx_done(vif.rx_done),
        .frame_error(vif.frame_error)
        );

    uart_assertions u_assertions (
        .tx_clk      (vif.tx_clk),
        .rx_clk      (vif.rx_clk),
        .reset_n     (vif.reset_n),

        .tx          (vif.tx),
        .busy        (vif.busy),
        .tx_done     (vif.tx_done),

        .rx_done     (vif.rx_done),
        .frame_error (vif.frame_error)
    );

    bind baud_generator baud_generator_assertions #(
        .TX_BAUD_DIV    (TX_BAUD_DIV),
        .COUNT_WIDTH (COUNT_WIDTH)
    ) u_baud_generator_assertions (
        .clk     (clk),
        .reset_n (reset_n),
        .count   (count),
        .bg_tick (bg_tick)
    );


    // Testbench专用：读取RTL内部状态
    assign vif.tx_state_dbg   = u_tx.state;
    assign vif.tx_bit_cnt_dbg = u_tx.bit_cnt;

 
    initial begin
        uart_test test;

         //1  rx_test vif.loopback_en = 1'b0;
         //2  tx_test vif.loopback_en = 1'b1;
         
        vif.loopback_en = 1'b1;
        vif.rx_driver   = 1'b1;

        vif.reset_n=1'b1;

        #10 vif.reset_n=1'b0;
        vif.data=8'h00;
        vif.tx_valid=1'b0;

        repeat (3)@(posedge tx_clk);
        @(negedge tx_clk)
        vif.reset_n=1'b1;

        test=new(vif);
        test.run();

        $finish;
    end


    initial begin
        #7ms;
        $fatal(1,"Simulation timeout");
    end

    always @(posedge rx_clk) begin
    if(u_rx.state == 2'd3 &&
       u_rx.sample_cnt == 380) begin

        $display(
            "[%0t] RX_STOP_CHECK: rx=%b, override_en=%b, override=%b",
            $time,
            vif.rx,
            vif.rx_override_en,
            vif.rx_override
        );

    end
end
endmodule




