module uart_tx(
    input clk,
    input reset_n,
    input bg_tick,
    input [7:0]data,
    input tx_valid,

    output reg tx,
    output reg [2:0]bit_cnt,
    output reg [1:0]state,
    output busy,
    output  reg tx_done
    

);

   
    reg [7:0]shifter;
    
    


    parameter idle=2'd0,start=2'd1,DATA=2'd2,stop=2'd3;
    reg [1:0] next_state;
   

    always @(*)begin
        case(state)
            idle:next_state=(tx_valid)?start:idle;
            start:next_state=DATA;
            DATA:next_state=(bit_cnt==3'd7&&bg_tick)?stop:DATA;
            stop:next_state=idle;
            default:next_state=idle;
        
        endcase
    end

    //low Voltage effective
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            shifter<=8'b0;
            state<=idle;
            bit_cnt<=3'b0;
            tx<=1'b1;
            tx_done <= 1'b0;
            
        end 
        else begin
            
            if(bg_tick)begin
                state<=next_state;
                tx_done <= 1'b0;
                case(state)
                    idle:begin
                        tx<=1'b1;
                        bit_cnt <= 3'd0;
                        if(tx_valid)
                            shifter<=data;
                    end
                    start: tx<=1'b0;
                    DATA:begin
                        tx <= shifter[0];
                        shifter <= shifter >> 1;
                        bit_cnt <= bit_cnt + 1;
                    end
                    stop:begin
                    tx<=1'b1;
                    tx_done <= 1'b1;
                    end
                endcase                 
            end        
        end
    end
   
   //add busy signal
   assign busy=(state!=idle);

   

endmodule
                    


