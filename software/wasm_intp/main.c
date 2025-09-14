#include <platform.h>
#include <print.h>
#include <timer.h>

void *handler_tbl[256] = {0};
void *frame_ip;

uint8_t wasm_mem[] = {0x00, 0x01, 0x02, 0x03};

void handler0() {
    printf("Handler 0 called\n");
}

void handler1() {
    printf("Handler 1 called\n");
}

void handler2() {
    printf("Handler 2 called\n");
}

void handler3() {
    printf("Handler 3 called\n");
}

int main(void) {
    platform_init();

    #define CSR_TRNG_EN    0x7E0
    #define CSR_TRNG_VALUE 0x7E1
    asm volatile("csrw %0, %1" :: "i"(CSR_TRNG_EN), "r"(1)); // Enable TRNG
    uint32_t trng_val;
    for (int i = 0; i < 5; i++) {
        asm volatile("csrr %0, %1" : "=r"(trng_val) : "i"(CSR_TRNG_VALUE));  
        printf("TRNG Value: %x\n", trng_val);
    }

    #define CSR_TRACE_EN 0x7D0
    #define CSR_TRACE    0x7D1
    #define CSR_TRACE_ADDR 0x7D2

    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE_ADDR), "r"(0x20000000)); // Enable tracing

    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE_EN), "r"(1)); // Enable tracing
    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE), "r"(0xdeadbeef)); //Trace
    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE), "r"(0xbadcab1e)); //Trace

    printf("Read back trace:\n");
    printf(" 0x%x\n", *((uint32_t*)0x20000000));
    printf(" 0x%x\n", *((uint32_t*)0x20000004));
    printf(" 0x%x\n", *((uint32_t*)0x20000008));
    printf(" 0x%x\n", *((uint32_t*)0x2000000c));

    #define CSR_INC      0x7C0
    #define CSR_FRAME_IP 0x7C1
    #define CSR_HANDLER 0x7C2
    #define CSR_HANDLER_TBL 0x7C4
    #define CSR_CONFIG   0x7C3

    printf("WASM Interpreter Test\n");
    // Configure accelerator
    asm volatile("csrw %0, %1" :: "i"(CSR_HANDLER_TBL), "r"(handler_tbl));  

    printf("Handler table set\n");
    uint32_t *test;
    asm volatile("csrr %0, %1" : "=r"(test) : "i"(CSR_HANDLER_TBL));  
    
    printf("Handler table read back: %x\n", test);

    frame_ip = &wasm_mem[0];
    asm volatile("csrw %0, %1" :: "i"(CSR_FRAME_IP), "r"(frame_ip));
    printf("Frame IP set to: %p\n", frame_ip);

    asm volatile("csrw %0, %1" :: "i"(CSR_CONFIG), "r"(0));

    asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(0));

    printf("Starting execution\n");

    sleep_ms(1);

    void* handler;
    asm volatile("csrr %0, %1" : "=r"(handler) : "i"(CSR_HANDLER));

    printf("Handler fetched: %x\n", handler);

    sleep_ms(1);
    return 1; // normal termination
}
