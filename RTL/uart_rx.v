module uart_rx #(
    parameter int unsigned CLK_FREQ_HZ    = 50_000_000,
    parameter int unsigned UART_BAUD_RATE = 115200
)(
    input clk,
    input reset_n,
    input rx,

    output reg[7:0] rx_data,
    output reg rx_done,
    output reg frame_error
);
    localparam int unsigned BAUD_DIV =(CLK_FREQ_HZ + UART_BAUD_RATE/2)/ UART_BAUD_RATE;
    localparam int unsigned SAMPLE_CNT_WIDTH =$clog2(BAUD_DIV);

    reg [SAMPLE_CNT_WIDTH-1:0] sample_cnt;
    reg [1:0]state;
    reg [2:0]bit_cnt_rx;//counter 0-7
    reg [7:0]shifter;
    reg rx1;
    reg rx2;

    parameter idle=2'd0,start=2'd1,DATA=2'd2,stop=2'd3;
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

    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            rx1<=1'b1;
            rx2<=1'b1;
        end
        else begin
            rx1<=rx;
            rx2<=rx1;
        end
    end
    
    

    always @(posedge clk or negedge rst_n_syn2)begin
        
        if(!rst_n_syn2)begin
            rx_data<=8'b0;
            state<=idle;
            shifter<=8'b0;
            rx_done <= 1'b0;
            sample_cnt<='0;
            bit_cnt_rx<=4'b0;
            frame_error<=1'b0;
           
            end
        else begin
           rx_done <=1'b0;
           frame_error<=1'b0;
            case(state)
                idle: begin
                    if(rx2==0)
                        begin
                            sample_cnt<='0;
                            state<=start;
                            bit_cnt_rx<=4'b0;
                            
                        end
                end
                start:begin
                    sample_cnt<=sample_cnt+1'b1;
                    if(sample_cnt==BAUD_DIV/2-1)
                         begin
                        if(rx2==0)begin
                            state<=DATA;
                            
                        end
                        else state<=idle;
                        sample_cnt<='0;
                        end
                        
                end
                DATA:begin
                    
                    if(sample_cnt==BAUD_DIV-1)begin
                        sample_cnt<='0;
                        shifter[bit_cnt_rx]<=rx2;
                        if(bit_cnt_rx==7)
                            state<=stop;
                        else
                            bit_cnt_rx<=bit_cnt_rx+1;
                    end
                    else
                        sample_cnt<=sample_cnt+1'b1;
                    
 
                end
                stop:begin
                     sample_cnt<=sample_cnt+1'b1;
                     if(sample_cnt==BAUD_DIV-1)begin
                            if(rx2==1)begin
                            rx_done<=1;
                            rx_data<=shifter;
                            
                            end
                            else 
                            frame_error<=1'b1;
                            
                            state<=idle;
                            
                        end
                    end
            endcase 
        end
                   
    end
endmodule








