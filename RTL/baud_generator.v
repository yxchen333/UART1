module baud_generator#(
    parameter int unsigned CLK_FREQ_HZ    = 50_000_000,
    parameter int unsigned UART_BAUD_RATE = 115200
)(
    input clk,
    input reset_n,
    output reg bg_tick
    
);
        
    

    //4 drop and 5 add 1
    localparam int unsigned TX_BAUD_DIV =(CLK_FREQ_HZ + UART_BAUD_RATE/2)/ UART_BAUD_RATE;

    localparam int unsigned COUNT_WIDTH = $clog2(TX_BAUD_DIV);
    reg [COUNT_WIDTH-1:0] count;
    reg rst_n_syn1;
    reg rst_n_syn2;

    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            rst_n_syn1<=1'b0;
            rst_n_syn2<=1'b0;
        end
        else begin
            rst_n_syn1<=1'b1;
            rst_n_syn2<=rst_n_syn1;
        end
    end
  
   
    always @(posedge clk or negedge rst_n_syn2)begin
        if(!rst_n_syn2)begin
            bg_tick<=1'b0;
            count<='0;
           
        end
        else begin  
            if(count==TX_BAUD_DIV -1)begin
                bg_tick<=1'b1;
                count<='0;
            end
            else begin
                count<=count+1'b1;
                bg_tick<=1'b0;
                
            end
        end
    end

endmodule 

