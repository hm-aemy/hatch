// Simple WASM interpreter test using labels (WAMR-style)
// Tests wasm_jump instruction with hardware accelerator

#include <platform.h>
#include <print.h>
#include <uart.h>
#include <timer.h>

#define CSR_HANDLER_TBL 0x7C4
#define CSR_FRAME_IP    0x7C1 
#define CSR_CONFIG      0x7C3
#define CSR_INC         0x7C0
#define CSR_HANDLER     0x7C2


uint8_t wasm_mem[128];

void simple_interpreter(void) {

    static  void *handler_table[] = {&&handler0, &&handler1, &&handler2};
    
    uint32_t handler0_addr = (uint32_t)handler_table[0];
    uint32_t handler1_addr = (uint32_t)handler_table[1];
    uint32_t handler2_addr = (uint32_t)handler_table[2];
    
    printf("handler0 label address: %x\n", handler0_addr);
    printf("handler1 label address: %x\n", handler1_addr);
    printf("handler2 label address: %x\n", handler2_addr);
    
    int offset = 0;
    
    // Handler 0 address
    wasm_mem[offset++] = (uint8_t)(handler0_addr);
    wasm_mem[offset++] = (uint8_t)(handler0_addr >> 8);
    wasm_mem[offset++] = (uint8_t)(handler0_addr >> 16);
    wasm_mem[offset++] = (uint8_t)(handler0_addr >> 24);
    // Handler 0 metadata
    wasm_mem[offset++] = 0x01;  
    wasm_mem[offset++] = 0x02;
    wasm_mem[offset++] = 0x03;
    wasm_mem[offset++] = 0x04;
    
    // Handler 1 address  
    wasm_mem[offset++] = (uint8_t)(handler1_addr);
    wasm_mem[offset++] = (uint8_t)(handler1_addr >> 8);
    wasm_mem[offset++] = (uint8_t)(handler1_addr >> 16);
    wasm_mem[offset++] = (uint8_t)(handler1_addr >> 24);
    // Handler 1 metadata
    wasm_mem[offset++] = 0x05;
    wasm_mem[offset++] = 0x06;
    wasm_mem[offset++] = 0x07;
    wasm_mem[offset++] = 0x08;
    wasm_mem[offset++] = 0x07;
    wasm_mem[offset++] = 0x08;
    
    // Handler 2 address
    wasm_mem[offset++] = (uint8_t)(handler2_addr);
    wasm_mem[offset++] = (uint8_t)(handler2_addr >> 8);
    wasm_mem[offset++] = (uint8_t)(handler2_addr >> 16);
    wasm_mem[offset++] = (uint8_t)(handler2_addr >> 24);
    
    printf("wasm_mem setup complete, %x bytes\n", offset);
    
    uint32_t wasm_mem_addr = (uint32_t)wasm_mem;
    asm volatile("csrw %0, %1" :: "i"(CSR_HANDLER_TBL), "r"(wasm_mem_addr));
    printf("Handler table set to %x\n", wasm_mem_addr);
    
    // Set Frame IP 
    uint32_t frame_ip = wasm_mem_addr + 4;
    asm volatile("csrw %0, %1" :: "i"(CSR_FRAME_IP), "r"(frame_ip));
    printf("Frame IP set to %x\n", frame_ip);
    
    uint32_t config = 0x1;  // Enable fast mode
    asm volatile("csrw %0, %1" :: "i"(CSR_CONFIG), "r"(config));
    printf("Accelerator enabled (CSR_CONFIG = %x)\n", config);
    
    // Jump to first handler 
    goto *handler_table[0];
    
    
handler0:
    {
       
        int a = 5, b = 10;
        int sum = a + b;
        printf("Handler 0 executed: %x + %x = %x\n", a, b, sum);
        
        asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(4));
        asm volatile(".word 0x0000007b");  // wasm_jump
        __builtin_unreachable();
    }
    
handler1:
    {
       
        printf("Handler 1 executed: no math, just jumping\n");
        
        asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(6));
        asm volatile(".word 0x0000007b");  // wasm_jump
        __builtin_unreachable();
    }
    
handler2:
    {
       
        int x = 20, y = 7;
        int diff = x - y;
        printf("Handler 2 executed: %x - %x = %x\n", x, y, diff);
        printf("Interpreter dispatch complete - all handlers executed!\n");
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

