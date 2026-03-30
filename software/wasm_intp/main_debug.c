// Simple WASM interpreter test using labels (WAMR classic mode)
// Tests wasm_jump instruction with hardware accelerator
//
// Memory layout (WAMR-style):
//   handler_table[] - opcode → handler address mapping 
//   wasm_mem[]      - bytecode containing opcodes and meta datas
//
// Operation:
//   1. Read opcode from frame_ip: opcode = mem[frame_ip]
//   2. Lookup handler: handler_addr = handler_table[opcode]
//   3. Jump to handler: goto *handler_addr
//   4. Handler increments frame_ip and jumps to next

#include <platform.h>
#include <print.h>
#include <uart.h>
#include <timer.h>

#define CSR_HANDLER_TBL 0x7C4
#define CSR_FRAME_IP    0x7C1 
#define CSR_CONFIG      0x7C3
#define CSR_INC         0x7C0
#define CSR_HANDLER     0x7C2


// Handler table: maps opcode → handler address
uint32_t handler_table_data[16];

// WASM bytecode memory: contains opcodes and metadata 
uint8_t wasm_mem[128];

void simple_interpreter(void) {

    handler_table_data[0] = (uint32_t)&&handler0;  // opcode 0
    handler_table_data[1] = (uint32_t)&&handler1;  // opcode 1
    handler_table_data[2] = (uint32_t)&&handler2;  // opcode 2
    
    printf("Handler table (opcode -> address):\n");
    printf("  [0] -> %x (handler0)\n", handler_table_data[0]);
    printf("  [1] -> %x (handler1)\n", handler_table_data[1]);
    printf("  [2] -> %x (handler2)\n", handler_table_data[2]);
    

    int offset = 0;
    wasm_mem[offset++] = 0;  // opcode for handler0
    wasm_mem[offset++] = 0xa0;  //meta data for handler0
    wasm_mem[offset++] = 0xa2;
    wasm_mem[offset++] = 0xa3;
    wasm_mem[offset++] = 0xa4;
    wasm_mem[offset++] = 1;  // opcode for handler1  
    wasm_mem[offset++] = 0xb0;  //meta data for handler1
    wasm_mem[offset++] = 0xb1;
    wasm_mem[offset++] = 0xb2;
    wasm_mem[offset++] = 0xb3;
    wasm_mem[offset++] = 0xb4;
    wasm_mem[offset++] = 0xb5;
    wasm_mem[offset++] = 2;  // opcode for handler2
    wasm_mem[offset++] = 0xFF; // end marker
    
    printf("Bytecode (opcodes): [");
    for (int i = 0; i < offset; i++) {
        printf("%x", wasm_mem[i]);
  
    }
    printf("]\n\n");
    

    uint32_t handler_tbl_addr = (uint32_t)handler_table_data;
    asm volatile("csrw %0, %1" :: "i"(CSR_HANDLER_TBL), "r"(handler_tbl_addr));
    printf("CSR_HANDLER_TBL = %x\n", handler_tbl_addr);
    
  
    uint32_t frame_ip = (uint32_t)wasm_mem +1;
    asm volatile("csrw %0, %1" :: "i"(CSR_FRAME_IP), "r"(frame_ip));
    printf("CSR_FRAME_IP = %x\n", frame_ip);
    
    uint32_t config = 0x0;
    asm volatile("csrw %0, %1" :: "i"(CSR_CONFIG), "r"(config));
    printf("CSR_CONFIG = %x\n\n", config);
    
    // Jump to first handler using table lookup
    goto *((void*)handler_table_data[0]);
    
    
handler0:
    {
        // Opcode 0 handler: simple addition
        int a = 5, b = 10;
        int sum = a + b;
        printf("Handler 0 (opcode 0): %x + %x = %x\n", a, b, sum);
        
        // Advance frame_ip by 1 byte to next opcode
        uint32_t inc = 4; 
        asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(inc));
        asm volatile(".word 0x0000007b");  // wasm_jump
        __builtin_unreachable();
    }
    
handler1:
    {
        // Opcode 1 handler: just print
        printf("Handler 1 (opcode 1): no math, just jumping\n");
        
        // Advance frame_ip by 1 byte to next opcode
        uint32_t inc = 6;
        asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(inc));
        asm volatile(".word 0x0000007b");  // wasm_jump
        __builtin_unreachable();
    }
    
handler2:
    {
        // Opcode 2 handler: subtraction
        int x = 20, y = 7;
        int diff = x - y;
        printf("Handler 2 (opcode 2): %x - %x = %x\n", x, y, diff);
        printf("\nInterpreter dispatch complete - all handlers executed!\n");
        return;
    }
    
exit_error:
    printf("ERROR: Unexpected control flow!\n");
}

int main(void) {
    platform_init();
    
    printf("=== WASM Interpreter Test (Label-based) ===\n");
    printf("Testing wasm_jump with hardware accelerator\n\n");
    
    // Run the interpreter
    simple_interpreter();
    
    printf("\n=== Test PASSED ===\n");
    printf("Returned to main successfully!\n");
    printf("Finish!\n");


    sleep_ms(1);
    return 1;
}

