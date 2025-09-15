#include <platform.h>
#include <print.h>
#include <timer.h>

void *handler_tbl[256] = {0};
void *frame_ip;

uint8_t wasm_mem[] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                      0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                      0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                      0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F};

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
    /*asm volatile("csrw %0, %1" :: "i"(CSR_TRNG_EN), "r"(1)); // Enable TRNG
    uint32_t trng_val;
    for (int i = 0; i < 5; i++) {
        asm volatile("csrr %0, %1" : "=r"(trng_val) : "i"(CSR_TRNG_VALUE));  
        printf("TRNG Value: %x\n", trng_val);
    }*/

    #define CSR_TRACE_EN 0x7D0
    #define CSR_TRACE    0x7D1
    #define CSR_TRACE_ADDR 0x7D2

    /*asm volatile("csrw %0, %1" :: "i"(CSR_TRACE_ADDR), "r"(0x20000000)); // Enable tracing

    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE_EN), "r"(1)); // Enable tracing
    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE), "r"(0xdeadbeef)); //Trace
    asm volatile("csrw %0, %1" :: "i"(CSR_TRACE), "r"(0xbadcab1e)); //Trace

    printf("Read back trace:\n");
    printf(" 0x%x\n", *((uint32_t*)0x20000000));
    printf(" 0x%x\n", *((uint32_t*)0x20000004));
    printf(" 0x%x\n", *((uint32_t*)0x20000008));
    printf(" 0x%x\n", *((uint32_t*)0x2000000c));*/

    #define CSR_INC      0x7C0
    #define CSR_FRAME_IP 0x7C1
    #define CSR_HANDLER 0x7C2
    #define CSR_HANDLER_TBL 0x7C4
    #define CSR_CONFIG   0x7C3
    #define CSR_ACC_BUSY 0x7C5

    handler_tbl[0] = handler0;
    handler_tbl[1] = handler1;
    handler_tbl[2] = handler2;
    handler_tbl[3] = handler3;

    printf("handler_tbl[0] = %x\n", handler_tbl[0]);
    printf("handler_tbl[1] = %x\n", handler_tbl[1]);
    printf("handler_tbl[2] = %x\n", handler_tbl[2]);
    printf("handler_tbl[3] = %x\n", handler_tbl[3]);

    printf("WASM Interpreter Test\n");
    // Configure accelerator
    asm volatile("csrw %0, %1" :: "i"(CSR_HANDLER_TBL), "r"(handler_tbl));  

    printf("Handler table set\n");
    uint32_t *test;
    asm volatile("csrr %0, %1" : "=r"(test) : "i"(CSR_HANDLER_TBL));  
    
    printf("Handler table read back: %x\n", test);

    frame_ip = &wasm_mem[0];
    asm volatile("csrw %0, %1" :: "i"(CSR_FRAME_IP), "r"(frame_ip));
    printf("Frame IP set to: %x\n", frame_ip);

    asm volatile("csrw %0, %1" :: "i"(CSR_CONFIG), "r"(0));

    asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(0));

    printf("Starting execution\n");

    sleep_ms(1);

    void* handler;
    uint32_t busy;
    asm volatile("csrr %0, %1" : "=r"(handler) : "i"(CSR_HANDLER));
    printf("Handler fetched: %x\n", handler);

    asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(1));
    asm volatile("csrr %0, %1" : "=r"(busy) : "i"(CSR_ACC_BUSY)); // Read busy status
    printf("Busy status: %x\n", busy);

    sleep_ms(1);
    asm volatile("csrr %0, %1" : "=r"(busy) : "i"(CSR_ACC_BUSY)); // Read busy status
    printf("Busy status: %x\n", busy);

    asm volatile("csrr %0, %1" : "=r"(handler) : "i"(CSR_HANDLER));

    printf("Handler fetched: %x\n", handler);

    sleep_ms(1);

    return 1; // normal termination
}
