module trace(
    input logic         clk_i,
    input logic         rst_ni,

    input logic [31:0]  csr_trace_data,
    input logic         csr_trace,
    input logic [31:0]  csr_trace_addr,
    input logic         csr_trace_addr_set,

    // Trace interface to memory
    output logic        trace_req_o,
    input  logic        trace_gnt_i,
    input  logic        trace_rvalid_i,
    output logic        trace_we_o,
    output logic [ 3:0] trace_be_o,
    output logic [31:0] trace_addr_o,
    output logic [31:0] trace_wdata_o,
    input  logic [31:0] trace_rdata_i
);

    enum logic[2:0] { IDLE, WAIT_ACK_TIME, DATA, WAIT_ACK_DATA, MISSED } state_q, state_n;

    logic [31:0] timestamp;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            timestamp <= 32'b0;
        end else begin
            timestamp <= timestamp + 1;
        end
    end

    logic [31:0] addr_q, addr_n;
    assign trace_addr_o = addr_q;
    logic [31:0] data_q, data_n;
    logic [31:0] timestamp_q, timestamp_n;
    logic missed_q, missed_n;

    assign trace_we_o    = 1'b1;
    assign trace_be_o    = 4'b1111;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= IDLE;
            addr_q  <= 32'b0;
            missed_q <= 1'b0;
        end else begin
            state_q <= state_n;
            if (csr_trace_addr_set) begin
                addr_q <= csr_trace_addr;
            end else begin
                addr_q  <= addr_n;
            end
            missed_q <= missed_n;
        end
        data_q  <= data_n;
        timestamp_q <= timestamp_n;
    end

    always_comb begin
        state_n = state_q;
        addr_n  = addr_q;
        data_n  = data_q;
        timestamp_n = timestamp_q;
        missed_n = missed_q;

        trace_req_o   = 1'b0;
        trace_wdata_o = 32'b0;

        case (state_q)
            IDLE: begin
                timestamp_n = timestamp;
                trace_wdata_o = timestamp;
                if (csr_trace) begin
                    trace_req_o   = 1'b1;
                    data_n        = csr_trace_data;
                    if (!trace_gnt_i) begin
                        state_n       = WAIT_ACK_TIME;
                    end else begin
                        state_n       = DATA;
                        addr_n  = addr_q + 4;
                    end
                end
            end

            WAIT_ACK_TIME: begin
                trace_wdata_o = timestamp_q;
                trace_req_o   = 1'b1;
                if (csr_trace) begin
                    missed_n = 1'b1;
                end
                if (trace_gnt_i) begin
                    state_n = DATA;
                    addr_n  = addr_q + 4;
                end
            end

            DATA: begin
                trace_wdata_o = data_q;
                trace_req_o   = 1'b1;
                if (csr_trace) begin
                    missed_n = 1'b1;
                end

                if (!trace_gnt_i) begin
                    state_n = WAIT_ACK_DATA;
                end else begin
                    if (missed_q | csr_trace) begin
                        state_n = MISSED;
                    end else begin
                        state_n = IDLE;
                    end
                    addr_n  = addr_q + 4;
                end
            end

            WAIT_ACK_DATA: begin
                trace_wdata_o = data_q;
                trace_req_o   = 1'b1;

                if (csr_trace) begin
                    missed_n = 1'b1;
                end

                if (trace_gnt_i) begin
                    if (missed_q | csr_trace) begin
                        state_n = MISSED;
                    end else begin
                        state_n = IDLE;
                    end
                    addr_n  = addr_q + 4;
                end
            end

            MISSED: begin
                trace_wdata_o = 32'hffffffff;
                trace_req_o   = 1'b1;
                
                missed_n = 1'b0;

                if (trace_gnt_i) begin
                    state_n = IDLE;
                    addr_n  = addr_q + 4;
                end
            end

            default: begin
                state_n = IDLE;
            end
        endcase
    end

endmodule