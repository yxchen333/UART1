package uart_params_pkg;

    /*
     * UART默认配置
     */
    parameter int unsigned UART_DATA_WIDTH = 8;
    parameter int unsigned UART_BAUD_RATE  = 115200;

    parameter int unsigned RX_BAUD_RATE  = 115200;

    parameter int unsigned TX_CLK_FREQ_HZ = 50_000_000;
    parameter int unsigned RX_CLK_FREQ_HZ = 40_000_000;

    localparam int unsigned TX_BAUD_DIV =
        (TX_CLK_FREQ_HZ + UART_BAUD_RATE/2)
        / UART_BAUD_RATE;

    localparam int unsigned RX_BAUD_DIV =
        (RX_CLK_FREQ_HZ + RX_BAUD_RATE/2)
        / RX_BAUD_RATE;

   

endpackage