

module dmi_data_register #(
    parameter abits  = 7,
    parameter dr_len = 32 + abits + 2
)(
    input  wire              tck,
    input  wire              trst_n,

    input  wire              capture_dr,
    input  wire              shift_dr,
    input  wire              update_dr,

    input  wire              dmi_enable,

    // ---------------------------------------------------------
    // Response from DMI response buffer
    // ---------------------------------------------------------
    input  wire [31:0]       resp_data,
    input  wire [1:0]        resp_op,
    input  wire              dtm_resp_valid,

    // ---------------------------------------------------------
    // JTAG serial
    // ---------------------------------------------------------
    input  wire              tdi,
    output reg               tdo,

    // ---------------------------------------------------------
    // DMI request toward CDC / DM
    // ---------------------------------------------------------
    output wire [abits-1:0]  dtm_dmi_addr,
    output wire [31:0]       dmi_data,
    output wire [1:0]        dtm_dmi_op,
    output reg               dmi_req_pulse
);

    // =========================================================
    // DMI REQUEST REGISTERS
    // =========================================================

    reg [abits-1:0] dtm_dmi_addr_r;
    reg [31:0]      dmi_data_r;
    reg [1:0]       dtm_dmi_op_r;

    assign dtm_dmi_addr = dtm_dmi_addr_r;
    assign dmi_data     = dmi_data_r;
    assign dtm_dmi_op   = dtm_dmi_op_r;



    reg [dr_len-1:0] shift_reg;

    reg dmi_pending;


    reg        response_available;
    reg [31:0] response_data_r;
    reg [1:0]  response_op_r;


    always @(posedge tck or negedge trst_n) begin

        if (!trst_n) begin

            shift_reg          <= {dr_len{1'b0}};

            dtm_dmi_addr_r     <= {abits{1'b0}};
            dmi_data_r         <= 32'h00000000;
            dtm_dmi_op_r       <= 2'b00;

            dmi_req_pulse      <= 1'b0;

            dmi_pending        <= 1'b0;

            response_available <= 1'b0;
            response_data_r    <= 32'h00000000;
            response_op_r      <= 2'b00;

        end
        else begin


            dmi_req_pulse <= 1'b0;

            if (dtm_resp_valid) begin

                response_data_r    <= resp_data;
                response_op_r      <= resp_op;

                response_available <= 1'b1;

                dmi_pending        <= 1'b0;

            end


            if (dmi_enable) begin


                // =================================================
                // CAPTURE-DR
                // =================================================

                if (capture_dr) begin


                    if (dtm_resp_valid) begin

                        shift_reg <= {
                            dtm_dmi_addr_r,
                            resp_data,
                            resp_op
                        };

                 
                        response_available <= 1'b0;

                    end

                    else if (response_available) begin

                        shift_reg <= {
                            dtm_dmi_addr_r,
                            response_data_r,
                            response_op_r
                        };

                 
                        response_available <= 1'b0;

                    end


                    else if (dmi_pending) begin

                        shift_reg <= {
                            dtm_dmi_addr_r,
                            32'h00000000,
                            2'b11
                        };

                    end
   

                    else begin

                        shift_reg <= {
                            {abits{1'b0}},
                            32'h00000000,
                            2'b00
                        };

                    end

                end


                // =================================================
                // SHIFT-DR
                // =================================================

                else if (shift_dr) begin

                    shift_reg <= {
                        tdi,
                        shift_reg[dr_len-1:1]
                    };

                end


                // =================================================
                // UPDATE-DR
                // =================================================

                else if (update_dr) begin


                    dtm_dmi_addr_r <= shift_reg[33+abits:34];

                    dmi_data_r     <= shift_reg[33:2];

                    dtm_dmi_op_r   <= shift_reg[1:0];


                    if (shift_reg[1:0] == 2'b00) begin


                        dmi_req_pulse <= 1'b0;

                    end


                    else begin

      

                        if (!dmi_pending) begin

                            dmi_req_pulse <= 1'b1;

                            dmi_pending   <= 1'b1;

                        end
                        else begin


                            dmi_req_pulse <= 1'b0;

                        end

                    end

                end

            end

        end

    end


    // =========================================================
    // TDO
   
    always @(negedge tck or negedge trst_n) begin

        if (!trst_n) begin

            tdo <= 1'b0;

        end
        else if (dmi_enable && shift_dr) begin

            tdo <= shift_reg[0];

        end
        else begin

            tdo <= 1'b0;

        end

    end

endmodule

