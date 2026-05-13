module uart_tx(
    input clk,
    input reset_n,
    input bg_tick,
    input [7:0]data,
    input tx_valid,

    output reg tx
);

    reg [2:0]bit_cnt;

    parameter idle=2'd0,start=2'd1,DATA=2'd2,stop=2'd3;
    reg [1:0]state,next_state;
   

    always @(*)begin
        case(state)
            idle:next_state=(tx_valid)?start:idle;
            start:next_state=DATA;
            DATA:next_state=(bit_cnt==3'd7&bg_tick)?stop:DATA;
            stop:next_state=idle;
            default:next_state=idle;
        
        endcase
    end


    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            state<=idle;
            bit_cnt<=3'b0;
            tx<=1'b1;
        end 
        else begin
            
            if(bg_tick)begin
                state<=next_state;
                case(state)
                    idle:tx<=1'b1;
                    start: tx<=1'b0;
                    DATA:begin
                        tx<=data[bit_cnt];
                        if(bit_cnt==3'd7)
                            bit_cnt<=3'd0;
                        else
                            bit_cnt<=bit_cnt+1;
                    end
                    stop:tx<=1'b1;
                endcase                 
            end        
        end
    end
   
endmodule
                    


