package uart_pkg;

    //==================================================
    // 公共数据对象
    //==================================================

    import uart_params_pkg::*;

     typedef enum {
        GEN_RANDOM,
        GEN_BOUNDARY,
        GEN_RESET
    } uart_gen_mode_t;

    typedef enum logic[1:0] {
        TX_SCENARIO_NORMAL,
        TX_SCENARIO_RESET,
        TX_SCENARIO_BUSY
    } tx_scenario_t;

 
    typedef enum logic [1:0] {
    INJECT_NONE  = 2'd0,
    INJECT_START = 2'd1,
    INJECT_DATA  = 2'd2,
    INJECT_STOP  = 2'd3
    } inject_point_t;

    `include "transaction/uart_transaction.sv"
    `include "transaction/uart_stop_error_transaction.sv"
    `include "transaction/uart_monitor_transaction.sv"
    `include "transaction/uart_busy_transaction.sv"
    `include "transaction/uart_reset_transaction.sv"
    `include "transaction/uart_false_start_transaction.sv"
    
   

    typedef enum {
    RX_GEN_RANDOM,
    RX_GEN_BOUNDARY,
    RX_GEN_ERROR_RECOVERY
    } uart_rx_gen_mode_t;

    typedef enum {
        RX_RESET_NONE,
        RX_RESET_START,
        RX_RESET_DATA,
        RX_RESET_STOP
    } rx_reset_point_t;

    

    //==================================================
    // TX-RX 回环验证组件
    //==================================================

    `include "uart_loopback_test/uart_generator.sv"
    `include "uart_loopback_test/uart_driver.sv"
    `include "uart_loopback_test/uart_monitor.sv"
    `include "uart_loopback_test/uart_scoreboard.sv"
    `include "uart_loopback_test/uart_environment.sv"

    `include "uart_loopback_test/uart_test.sv"

    //==================================================
    // 独立 RX 验证组件
    //==================================================

    `include "uart_rx_test/uart_rx_generator.sv"
    `include "uart_rx_test/uart_rx_driver.sv"
    `include "uart_rx_test/uart_rx_monitor.sv"
    `include "uart_rx_test/uart_rx_scoreboard.sv"
    `include "uart_rx_test/uart_rx_environment.sv"
    `include "uart_rx_test/uart_rx_test.sv"

    //==================================================
    // 独立 TX 验证组件
    //==================================================

    `include "uart_tx_test/uart_tx_generator.sv"
    `include "uart_tx_test/uart_tx_driver.sv"
    `include "uart_tx_test/uart_tx_monitor.sv"
    `include "uart_tx_test/uart_tx_scoreboard.sv"
    `include "uart_tx_test/uart_tx_coverage.sv"
    `include "uart_tx_test/uart_tx_environment.sv"
    `include "uart_tx_test/uart_tx_test.sv"

endpackage