interface uart_if(input logic clk);
    logic reset_n;

    logic [7:0] data;
    logic       tx_valid;
    logic   bg_tick;

    logic tx;
    logic busy;
    logic tx_done;

    // 只用于Testbench观察RTL内部状态
    wire [1:0] tx_state_dbg;
    wire [2:0] tx_bit_cnt_dbg;

    logic rx;
    logic [7:0] rx_data;
    logic       rx_done;
    logic       frame_error;

    logic       rx_driver;
    logic       loopback_en;

    

    

endinterface