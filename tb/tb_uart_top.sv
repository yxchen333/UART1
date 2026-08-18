module tb_uart_top;

    logic clk;

    uart_if vif(clk);
    import uart_pkg::*;

    localparam int unsigned BAUD_DIV =
    uart_params_pkg::UART_BAUD_DIV;
  
    assign vif.rx=(vif.loopback_en)?vif.tx:vif.rx_driver;


    initial begin
        clk=0;
        forever #10 clk=~clk;
    end

    baud_generator#(
    .BAUD_DIV(BAUD_DIV)
    ) u1(
        .clk(clk),
        .reset_n(vif.reset_n),
        .bg_tick(vif.bg_tick)
        );
    uart_tx#(
    .BAUD_DIV(BAUD_DIV)
    ) u_tx(
        .clk(clk),
        .reset_n(vif.reset_n),
        .bg_tick(vif.bg_tick),
        .data(vif.data),
        .tx_valid(vif.tx_valid),
        .tx(vif.tx),
        .busy(vif.busy),
        .tx_done(vif.tx_done)
        );
    
    uart_rx#(
    .BAUD_DIV(BAUD_DIV)
    )  u_rx(
        .clk(clk),
        .reset_n(vif.reset_n),
        .rx(vif.rx),
        .rx_data(vif.rx_data),
        .rx_done(vif.rx_done),
        .frame_error(vif.frame_error)
        );

    uart_assertions u_assertions (
        .clk         (vif.clk),
        .reset_n     (vif.reset_n),

        .tx          (vif.tx),
        .busy        (vif.busy),
        .tx_done     (vif.tx_done),

        .rx_done     (vif.rx_done),
        .frame_error (vif.frame_error)
    );
    // Testbench专用：读取RTL内部状态
    assign vif.tx_state_dbg   = u_tx.state;
    assign vif.tx_bit_cnt_dbg = u_tx.bit_cnt;
    
    

    initial begin
        uart_tx_test test;

         //1  rx_test vif.loopback_en = 1'b0;
         //2  tx_test vif.loopback_en = 1'b1;
         
        vif.loopback_en = 1'b1;
        vif.rx_driver   = 1'b1;

        vif.reset_n=1'b0;
        vif.data=8'h00;
        vif.tx_valid=1'b0;

        repeat (3)@(posedge clk);
        vif.reset_n=1;

        test=new(vif);
        test.run();

        $finish;
    end

    initial begin
        #500000;
        $fatal(1,"Simulation timeout");
    end

endmodule




