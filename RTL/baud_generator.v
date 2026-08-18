module baud_generator#(
    parameter BAUD_DIV = 10
)(
    input clk,
    input reset_n,
    output reg bg_tick
    
);
    reg bg_clk;
    
    reg [7:0]count;
  
   
    always @(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            bg_tick<=1'b0;
            count<=8'b0;
            bg_clk<=1'b0;
        end
        else begin  
            if(count==BAUD_DIV -1)begin
                bg_tick<=1'b1;
                count<=8'b0;
                bg_clk<=~bg_clk;
            end
            else begin
                count<=count+8'b1;
                bg_tick<=1'b0;
            end
        end
    end

endmodule 

