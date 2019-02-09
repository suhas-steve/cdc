module dmi_response_buffer (
    input        tck,
    input        trst_n,

    // response input (from dm side via cdc later)
    input          resp_write,    
    input   [31:0] resp_data_in,
    input   [1:0]  resp_op_in,

    // read control (from jtag dmi dr read)
    input         resp_read,      

    // buffered outputs
    output reg  [31:0] resp_data,
    output reg  [1:0]  resp_op,
    output reg         dtm_resp_valid
);
    
    // ---------------------------------------------------------
    // response buffer registers
    // ---------------------------------------------------------
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            resp_data  <= 32'h0;
            resp_op    <= 2'd0;
            dtm_resp_valid <= 1'b0;
        end else begin

            // latch new response
            if (resp_write) begin                
                resp_data  <= resp_data_in;
                resp_op    <= resp_op_in;
                dtm_resp_valid <= 1'b1;
            end

            // clear after read
            else if (resp_read) begin
                dtm_resp_valid <= 1'b0;
            end
        end
    end

endmodule



