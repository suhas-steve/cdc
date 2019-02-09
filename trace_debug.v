module trace_debug
(
    input  wire         clk,
    input  wire         rst_n,

        // DMI Interface
    input  wire         dmi_req_valid,
    input  wire         dmi_req_write,
    input  wire         dmi_resp_valid,

    input  wire [6:0]   dmi_req_addr,
    input  wire [1:0]   dmi_req_op,
    input  wire [31:0]  dmi_req_data,

    input  wire [1:0]   dmi_resp_op,
    input  wire [31:0]  dmi_resp_data,

        // DM Registers
    input  wire         sel_dmcontrol,
    input  wire [31:0]  dmi_req_wdata,

        // Hart Control
    input  wire         haltreq,
    input  wire         resumereq,
    input  wire         ndmreset,

    input  wire         hart_halted,
   // input  wire         resumeack,

        // Abstract Command Engine
   input  wire         cmd_write_pulse,
   input  wire [31:0]  command,

    input  wire         abstract_busy,
    input  wire [2:0]   abstract_cmderr,

        // Program Buffer
    input  wire         execute_progbuf,
    input  wire [31:0]  pb_insn,
       // System Bus Access
    input  wire         sbdata0_read_pulse,
    input  wire         sbdata0_write_pulse,

    input  wire         read_data_valid,
    input  wire         sberror_valid,

    input  wire [31:0]  sbaddress0,
    input  wire [31:0]  sba_read_data_out,

    input  wire [2:0]   sberror_set,

        // Address Decoder
    input  wire         sel_invalid_addr,

        // Outputs
    output reg [7:0]   dbg_event_id,
    output reg [31:0]  dbg_event_data
);

        // Event IDs
    
    localparam EVT_DMI_REQUEST        = 8'd0;
    localparam EVT_DMI_RESPONSE       = 8'd1;
    localparam EVT_DMCONTROL_WRITE    = 8'd2;
    localparam EVT_HALT_REQUEST       = 8'd3;
    localparam EVT_HART_HALTED        = 8'd4;
    localparam EVT_RESUME_REQUEST     = 8'd5;
    localparam EVT_HART_RESUMED       = 8'd6;
    localparam EVT_RESET_REQUEST      = 8'd7;
    localparam EVT_COMMAND_EXECUTE    = 8'd8;
    localparam EVT_COMMAND_COMPLETE   = 8'd9;
    localparam EVT_COMMAND_ERROR      = 8'd10;
    localparam EVT_PROGBUF_EXECUTE    = 8'd11;
    localparam EVT_SBA_ACCESS         = 8'd12;
    localparam EVT_SBA_COMPLETE       = 8'd13;
    localparam EVT_SBA_ERROR          = 8'd14;
    localparam EVT_INVALID_DMI_ACCESS = 8'd15;

    localparam EVT_NONE               = 8'hFF;

        // Edge Detection Registers
    
    reg hart_halted_d;
    reg abstract_busy_d;

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            hart_halted_d   <= 1'b0;
            abstract_busy_d <= 1'b0;
        end
        else
        begin
            hart_halted_d   <= hart_halted;
            abstract_busy_d <= abstract_busy;
        end
    end

        // Event Encoder (Priority Order)
    
    always@(*)
    begin

        dbg_event_id   = EVT_NONE;
        dbg_event_data = 32'd0;

	 if(dmi_req_valid)
        begin
            dbg_event_id   = EVT_DMI_REQUEST;
            dbg_event_data = {dmi_req_addr,dmi_req_op,dmi_req_data[22:0]};
        end

	else if(dmi_resp_valid)
        begin
            dbg_event_id   = EVT_DMI_RESPONSE;
            dbg_event_data = {dmi_resp_op,dmi_resp_data[29:0]};
        end

	 else if(sel_dmcontrol && dmi_req_valid && dmi_req_write)
        begin
            dbg_event_id   = EVT_DMCONTROL_WRITE;
            dbg_event_data = dmi_req_wdata;
        end
	
        else if(haltreq)
        begin
            dbg_event_id   = EVT_HALT_REQUEST;
            dbg_event_data = 32'h1;
        end
	
        else if(hart_halted && !hart_halted_d)
        begin
            dbg_event_id   = EVT_HART_HALTED;
            dbg_event_data = 32'h1;
        end
	
        else if(resumereq)
        begin
            dbg_event_id   = EVT_RESUME_REQUEST;
            dbg_event_data = 32'h1;
        end

        else if(!hart_halted && hart_halted_d)
        begin
            dbg_event_id   = EVT_HART_RESUMED;
            dbg_event_data = 32'h1;
        end
	
        else if(ndmreset)
        begin
            dbg_event_id   = EVT_RESET_REQUEST;
            dbg_event_data = 32'h1;
        end
	
        else if(cmd_write_pulse)
        begin
            dbg_event_id   = EVT_COMMAND_EXECUTE;
            dbg_event_data = command;
        end
 	
	else if(abstract_busy_d && !abstract_busy)
        begin
            dbg_event_id   = EVT_COMMAND_COMPLETE;
            dbg_event_data = {29'd0,abstract_cmderr};
        end
	 else if(abstract_cmderr != 3'd0)
        begin
            dbg_event_id   = EVT_COMMAND_ERROR;
            dbg_event_data = {29'd0,abstract_cmderr};
        end

	 else if(execute_progbuf)
        begin
            dbg_event_id   = EVT_PROGBUF_EXECUTE;
            dbg_event_data = pb_insn;
        end
	 else if(sbdata0_read_pulse || sbdata0_write_pulse)
        begin
            dbg_event_id   = EVT_SBA_ACCESS;
            dbg_event_data = sbaddress0;
        end

        else if(read_data_valid)
        begin
            dbg_event_id   = EVT_SBA_COMPLETE;
            dbg_event_data = sba_read_data_out;
        end

      
        else if(sberror_valid)
        begin
            dbg_event_id   = EVT_SBA_ERROR;
            dbg_event_data = {29'd0,sberror_set};
        end

        else if(sel_invalid_addr)
        begin
            dbg_event_id   = EVT_INVALID_DMI_ACCESS;
            dbg_event_data = {25'd0,dmi_req_addr};
        end
                     
       
               
    end

endmodule
