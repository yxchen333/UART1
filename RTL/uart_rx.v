module uart_rx #(
    parameter BAUD_DIV = 10
)(
    input clk,
    input reset_n,
    input rx,

    output reg[7:0] rx_data,
    output reg rx_done,
    output reg frame_error
);
    reg [1:0]state;
    reg [3:0]bit_cnt_rx;//counter 0-7
    reg [7:0]sample_cnt;//sample clk 0-BAUD_DIV-1
    reg [7:0]shifter;
    parameter idle=2'd0,start=2'd1,DATA=2'd2,stop=2'd3;
    
    

    always @(posedge clk or negedge reset_n)begin
        
        if(!reset_n)begin
            rx_data<=8'b0;
            state<=idle;
            shifter<=8'b0;
            rx_done <= 0;
            sample_cnt<=8'b0;
            bit_cnt_rx<=4'b0;
            frame_error<=0;
           
            end
        else begin
           rx_done <=1'b0;
           frame_error<=1'b0;
            case(state)
                idle: begin
                    rx_done<=0;
                    if(rx==0)
                    begin
                        sample_cnt<=8'b0;
                        state<=start;
                        bit_cnt_rx<=4'b0;
                        
                    end
                end
                start:begin
                    sample_cnt<=sample_cnt+1;
                    if(sample_cnt==BAUD_DIV/2-1)
                         begin
                        if(rx==0)begin
                            state<=DATA;
                            
                        end
                        else state<=idle;
                        sample_cnt<=0;
                        end
                        
                end
                DATA:begin
                    
                    if(sample_cnt==BAUD_DIV-1)begin
                        sample_cnt<=8'b0;
                        shifter[bit_cnt_rx]<=rx;
                        if(bit_cnt_rx==7)
                            state<=stop;
                        else
                            bit_cnt_rx<=bit_cnt_rx+1;
                    end
                    else
                        sample_cnt<=sample_cnt+1;
                    
 
                end
                stop:begin
                     sample_cnt<=sample_cnt+1;
                     if(sample_cnt==BAUD_DIV-1)begin
                            if(rx==1)begin
                            rx_done<=1;
                            rx_data<=shifter;
                            
                            end
                            else 
                            frame_error<=1;
                            
                            state<=idle;
                            sample_cnt<=8'b0;
                        end
                    end
            endcase 
        end
                   
    end
endmodule








