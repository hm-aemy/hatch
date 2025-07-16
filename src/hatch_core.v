module hatch_core(
    // Clock and reset
    input  logic            clk_i,
    input  logic            rst_ni,
    
    //intruction memory interface
    output logic                          instr_req_o,
    input  logic                          instr_gnt_i,
    input  logic                          instr_rvalid_i,
    output logic [31:0]                   instr_addr_o,
    output logic [1:0]                    instr_memtype_o,
    output logic [2:0]                    instr_prot_o,
    output logic                          instr_dbg_o,
    input  logic [31:0]                   instr_rdata_i,
    input  logic                          instr_err_i,

    // Data memory interface
    output logic                          data_req_o,
    input  logic                          data_gnt_i,
    input  logic                          data_rvalid_i,
    output logic [31:0]                   data_addr_o,
    output logic [3:0]                    data_be_o,
    output logic                          data_we_o,
    output logic [31:0]                   data_wdata_o,
    output logic [1:0]                    data_memtype_o,
    output logic [2:0]                    data_prot_o,
    output logic                          data_dbg_o,
    output logic [5:0]                    data_atop_o,
    input  logic [31:0]                   data_rdata_i,
    input  logic                          data_err_i,
    input  logic                          data_exokay_i,

    // CPU control signals
    input  logic            fetch_enable_i,
    output logic            core_sleep_o
    );

    cv32e40x_if_xif ext_if();

    cv32e40x_core core(
        // Clock and reset
      .clk_i                 ( clk_i                 ),
      .rst_ni                ( rst_ni                ),
      .scan_cg_en_i          ( 1'b0                  ),

      // Static configuration
      .boot_addr_i           ( BootAddr              ),
      .dm_exception_addr_i   ( '0                    ),
      .dm_halt_addr_i        ( '0                    ),
      .mhartid_i             ( HartId                ),
      .mimpid_patch_i        ( 4'b0                  ),
      .mtvec_addr_i          ( MtvecAddr             ),

      // Instruction memory interface
     .instr_req_o            ( instr_req_o          ),
     .instr_gnt_i            ( instr_gnt_i          ),
     .instr_rvalid_i         ( instr_rvalid_i       ),
     .instr_addr_o           ( instr_addr_o         ),
     .instr_memtype_o        ( instr_memtype_o      ),
     .instr_prot_o           ( instr_prot_o         ),
     .instr_dbg_o            ( instr_dbg_o          ),
     .instr_rdata_i          ( instr_rdata_i        ),
     .instr_err_i            ( instr_err_i          ),

      // Data memory interface
     .data_req_o             ( data_req_o           ),
     .data_gnt_i             ( data_gnt_i           ),
     .data_rvalid_i          ( data_rvalid_i        ),
     .data_addr_o            ( data_addr_o          ),
     .data_be_o              ( data_be_o            ),
     .data_we_o              ( data_we_o            ),
     .data_wdata_o           ( data_wdata_o         ),
     .data_memtype_o         ( data_memtype_o       ),
     .data_prot_o            ( data_prot_o          ),
     .data_dbg_o             ( data_dbg_o           ),
     .data_atop_o            ( data_atop_o          ),
     .data_rdata_i           ( data_rdata_i         ),
     .data_err_i             ( data_err_i           ),
     .data_exokay_i          ( data_exokay_i        ),

      // Cycle count
      .mcycle_o              (                       ),

      // Time input
      .time_i                ( time_counter          ),

      // eXtension interface
      .xif_compressed_if     ( ext_if                ),
      .xif_issue_if          ( ext_if                ),
      .xif_commit_if         ( ext_if                ),
      .xif_mem_if            ( ext_if                ),
      .xif_mem_result_if     ( ext_if                ),
      .xif_result_if         ( ext_if                ),

      // Basic interrupt architecture
      .irq_i                 ( irq                   ),

      // Event wakeup signals
      .wu_wfe_i              ( 1'b0                  ),

      // CLIC interrupt architecture
      .clic_irq_i            ( 1'b0                  ),
      .clic_irq_id_i         ( '0                    ),
      .clic_irq_level_i      ( 8'h0                  ),
      .clic_irq_priv_i       ( 2'h0                  ),
      .clic_irq_shv_i        ( 1'b0                  ),

      // Fence.i flush handshake
      .fencei_flush_req_o    (                       ),
      .fencei_flush_ack_i    ( 1'b1                  ),

      // Debug interface
      .debug_req_i           ( 1'b0                  ),
      .debug_havereset_o     (                       ),
      .debug_running_o       (                       ),
      .debug_halted_o        (                       ),
      .debug_pc_valid_o      (                       ),
      .debug_pc_o            (                       ),

      // CPU control signals
      .fetch_enable_i        ( fetch_enable_i        ),
      .core_sleep_o          ( core_sleep_o          )
    );
endmodule