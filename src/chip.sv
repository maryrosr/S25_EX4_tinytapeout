`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
    // Basic counter design as an example
    // TODO: remove the counter design and use this module to insert your own design
    // DO NOT change the I/O header of this design

    wire [6:0] led_out;
    assign io_out[6:0] = led_out; 


    logic [3:0] data_in;
    logic go, finish;
    logic [3:0] range;
    logic debug_error;
    logic [3:0] low_q, high_q;
    logic seq_error, comb_error;

    assign data_in = io_in[3:0];
    assign go = io_in[4];
    assign finish = io_in[5];
    enum logic [1:0] {Wait = 2'b0, Go = 2'b1, Error = 2'b10} curr_state, next_state;
    always_comb begin
        next_state = curr_state;
        debug_error = 1'b0;
        range = 'b0;
        case (curr_state) 
            Wait: begin
                if(finish) begin
                    next_state = Error;
                    debug_error = 1'b1;
                end
                else if (go)
                    next_state = Go;
            end
            Go: begin
                if (finish) begin // assert
                  if(data_in < low_q && data_in > high_q) begin
                        range = 'b0;
                    end
                  else if (data_in > high_q) begin
                        range = data_in - low_q;
                    end
                  else if(data_in < low_q) begin
                        range = high_q - data_in;
                    end
                    else begin
                        range = high_q - low_q;
                    end
                    next_state = Wait;
                end
            end
            Error: begin
                if (go)
                    next_state = Go;
				
                debug_error = 1'b1;
            end
        endcase
    end
    always_ff @(posedge clock, posedge reset) begin
        if(reset) begin
            curr_state <= Wait;
            low_q <= 'b0;
            high_q <= 'b0;
        end
        else begin
          if((curr_state == Error || curr_state == Wait) && next_state == Go) begin
                low_q <= data_in;
                high_q <= data_in;
            end
            else if (curr_state == Go) begin
              if(data_in < low_q) low_q <= data_in;
              if(data_in > high_q) high_q <= data_in;
            end
          curr_state <= next_state;
        end
    	
        
    end
    // instantiate segment display
    seg7 seg7(.counter(range), .segments(led_out));

endmodule
