#include <platform.h>
#include <print.h>
#include <timer.h>
#include <stdlib.h>

// Minimal memcpy for freestanding environment
void *memcpy(void *dest, const void *src, unsigned int n) {
    char *d = (char *)dest;
    const char *s = (const char *)src;
    for (unsigned int i = 0; i < n; i++)
        d[i] = s[i];
    return dest;
}

// Minimal memset for freestanding environment
void *memset(void *dest, int val, unsigned int n) {
    char *d = (char *)dest;
    for (unsigned int i = 0; i < n; i++)
        d[i] = (char)val;
    return dest;
}
//convert uint32_t to string
static void uint2string(uint32_t value, char *buf, unsigned int size) {
    if (size == 0) return;

    char *p = buf;
    unsigned int remaining = size;

    if (value == 0) {
        if (remaining > 1) { *p++ = '0'; *p = '\0'; }
        return;
    }

    uint32_t powers[] = {1000000000,100000000,10000000,1000000,100000,10000,1000,100,10,1};
    int started = 0;

    for (int i = 0; i < 10 && remaining > 1; i++) {
        int d = 0;
        while (value >= powers[i]) { value -= powers[i]; d++; }
        if (d > 0 || started) {
            *p++ = '0' + d;
            started = 1;
            remaining--;
        }
    }

    *p = '\0';
}
// Minimal printf: only prints a string
static void my_printf(const char *s) {
    while (*s) {
        putchar(*s++);
    }
}

int main(void) {
    platform_init();
    printf("Start test arbiter\n");

    #define CSR_INC      0x7C0
    #define CSR_FRAME_IP 0x7C1
    #define CSR_CONFIG   0x7C3

    const int TEST_SIZE = 64;    
    const int ITERATIONS = 2; 
    const int frame_ip = 0x10000100; // Frame IP address

    volatile uint32_t test_mem[TEST_SIZE];

    // Initialize test memory
    for (int i = 0; i < TEST_SIZE; i++) {
        test_mem[i] =  i;
    //     printf(" Initialize Iteration: ");
    //     char buf[16];
    //     uint2string(i, buf, sizeof(buf));
    //     my_printf(buf);
    //     printf("\n");
    //     printf("test_mem:");
    //     char mem_buf[16];
    //     uint2string(test_mem[i], mem_buf, sizeof(mem_buf));
    //     my_printf(mem_buf);
    //     printf("\n");
    }
    sleep_ms(1);

    // Configure accelerator
    asm volatile("csrw %0, %1" :: "i"(CSR_FRAME_IP), "r"(frame_ip));  
    asm volatile("csrw %0, %1" :: "i"(CSR_CONFIG), "r"(1));  

    volatile uint32_t sum = 0;

    for (int iter = 0; iter < ITERATIONS; iter++) {
        uint32_t trigger_val = iter + 2;

        // Trigger accelerator
        asm volatile("csrw %0, %1" :: "i"(CSR_INC), "r"(trigger_val));

        // Simple memory access pattern
        for (int i = 0; i < 16; i++) {
            // printf("Iteration: ");
            // char buf[16];
            // uint2string(i, buf, sizeof(buf));
            // my_printf(buf);
            // printf("\n");
            sum += test_mem[i];        // load
            test_mem[i + 4] = trigger_val+i; // store
            sum += test_mem[i + 2];    // load
            sum += test_mem[i + 4];    // load
            printf("Sum: ");
            char sum_buf[16];
            uint2string(sum, sum_buf, sizeof(sum_buf));
            my_printf(sum_buf);
            printf("\n");

        }

        // Shift memory region to avoid cache-like effects
        //test_mem = (volatile uint32_t*)((((uint32_t)test_mem) + 32) & 0x00100FFC);
    }

    // Report results
    printf("Arbiter test DONE\n");
    sleep_ms(1);

    return 1; // normal termination
}
