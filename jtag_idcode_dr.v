
module jtag_idcode_dr #(
    // example idcode:
    // [31:28] version
    // [27:12] part number
    // [11:1]  manufacturer id
    // [0]     always 1
    parameter [31:0] idcode_value = 32'h1234_567B
)(
    input       tck,
    input       trst_n,

    // tap control signals
    input       capture_dr,
    input       shift_dr,
    //input       update_dr,

    // instruction decoder enable
    input       idcode_enable,

    // serial interface
    input       tdi,
    output reg  idcode_tdo
);



    // ------------------------------------------------------------
    // 32-bit shift register for idcode
    // ------------------------------------------------------------
    reg [31:0] idcode_shift;

    // ------------------------------------------------------------
    // capture / shift logic (posedge tck)
    // ------------------------------------------------------------
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            idcode_shift <= idcode_value;
        end
        else if (idcode_enable) begin

            // capture-dr: load fixed idcode value
            if (capture_dr)
                idcode_shift <= idcode_value;

            // shift-dr
            else if (shift_dr)
                idcode_shift <= { tdi, idcode_shift[31:1] };

            // update-dr: ignored for idcode 
        end
    end

    // ------------------------------------------------------------
    // tdo logic (negedge tck, ieee-1149.1 compliant)
    // ------------------------------------------------------------
    always @(negedge tck or negedge trst_n) begin
//    always @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            idcode_tdo <= 1'b0;
        else if (idcode_enable && shift_dr)
            idcode_tdo <= idcode_shift[0];
        else
            idcode_tdo <= 1'b0;
    end

endmodule



