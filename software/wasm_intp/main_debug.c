//  test whether the bug causing uart stucked at loop related to interface between core and accelerator
//  data request or not

#include <platform.h>
#include <print.h>
#include <timer.h>
#include <uart.h>

#define CSR_HANDLER_TBL 0x7C4
#define CSR_FRAME_IP    0x7C1 
#define CSR_CONFIG      0x7C3
#define CSR_INC         0x7C0
#define CSR_ACC_BUSY    0x7C5
#define CSR_HANDLER     0x7C2
#define WASM_JUMP_INST 0x0000007b

void *frame_ip;

// Interpreter Fast mode wasm_memory
uint8_t wasm_mem[128]; 
int offset = 0; 

void handler0() {
    printf("Handler 0 called\n");
    uint32_t inc = 4;
    asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(inc));
    // Set ra to return address after wasm_jump so handler1 can return here
    asm volatile(
        "auipc ra, 0\n"           // ra = PC
        "addi ra, ra, 12\n"       // ra = PC + 12 (points to instruction after wasm_jump)
        ".word 0x0000007b\n"      // wasm_jump to handler1 (4 bytes)
        ::: "ra"
    );
    // handler1 will return here (after the wasm_jump instruction)
}

void handler1() {
    printf("Handler 1 called\n");
    asm volatile("nop");  // Prevent tail call optimization
}

void handler2() {
    printf("Handler 2 called\n");
}

void handler3() {
    printf("Handler 3 called\n");
}
void *handler_tbl[256] = {
    [0] = handler0,
    [1] = handler1,
    [2] = handler2,
    [3] = handler3,
};

int main(void) {
    platform_init();
    // Setup WASM memory and handlers as before...
    uint32_t addr0 = (uint32_t)handler0;
    wasm_mem[offset++] = (uint8_t ) addr0;
    wasm_mem[offset++] = (uint8_t )((addr0 >> 8) & 0xFF);
    wasm_mem[offset++] = (uint8_t )((addr0 >> 16) & 0xFF);
    wasm_mem[offset++] = (uint8_t )((addr0 >> 24) & 0xFF);
    wasm_mem[offset++] = 0x02;
    wasm_mem[offset++] = 0x03;
    wasm_mem[offset++] = 0xFB;
    wasm_mem[offset++] = 0xAC;
    
    // Continue with handler setup...
    uint32_t addr1 = (uint32_t)handler1;
    wasm_mem[offset++] = (uint8_t ) addr1;
    wasm_mem[offset++] = (uint8_t )((addr1 >> 8) & 0xFF);
    wasm_mem[offset++] = (uint8_t )((addr1 >> 16) & 0xFF);
    wasm_mem[offset++] = (uint8_t )((addr1 >> 24) & 0xFF);
    wasm_mem[offset++] = 0x05;
    wasm_mem[offset++] = 0xFF;
    wasm_mem[offset++] = 0x02;
    wasm_mem[offset++] = 0x35;
    
    // [Setup continues...]
    
    handler_tbl[0] = handler0;
    handler_tbl[1] = handler1; 
    handler_tbl[2] = handler2;
    handler_tbl[3] = handler3;



    printf("handler_tbl[0] = %x\n", handler_tbl[0]);
    printf("handler_tbl[1] = %x\n", handler_tbl[1]);
    printf("handler_tbl[2] = %x\n", handler_tbl[2]);
    printf("handler_tbl[3] = %x\n", handler_tbl[3]);

    printf("WASM Memory has %x bytes\n", offset);  
    for (int i = 0; i < 32 && i < offset; i++) {
        printf("%x ", wasm_mem[i]);
    }
    printf(" address of wasm_mem: %x\n", wasm_mem);
    asm volatile("csrw %0, %1" :: "i"(CSR_HANDLER_TBL), "r"(handler_tbl));  

    printf("Handler table set\n");
    uint32_t *test;
    asm volatile("csrr %0, %1" : "=r"(test) : "i"(CSR_HANDLER_TBL));  
    

    frame_ip = wasm_mem +4;
    printf("Frame IP set to %x\n", frame_ip);


    uint32_t *hand_tbl;
    asm volatile ("csrr %0, %1" : "=r"(hand_tbl) : "i"(CSR_HANDLER_TBL));
    // printf ("Handler table read back: %x\n",hand_tbl);
    
    asm volatile("csrw %0, %1" :: "i"(CSR_FRAME_IP), "r"(frame_ip));
    uint32_t config = 0x1;
    asm volatile("csrw %0, %1" :: "i"(CSR_CONFIG), "r"(config));
    // printf ("Write on custom csrs are completed!!");
    uint32_t inc = 4;
    

    
    // asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(inc));  // TRIGGER ACCELERATOR
    handler0();
    // asm volatile (".word 0x0000007b"); // WASM JUMP INSTRUCTION

    // handler1();
    // handler2();
    // handler3();
    

    printf ("Finish");

    return 1;



}
