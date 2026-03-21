#include <platform.h>
#include <print.h>
#include <uart.h>
#include <stdint.h>

#define CSR_TRNG_EN    0x7E0
#define CSR_TRNG_VALUE 0x7E1
#define NUM_SAMPLES    8
#define WARMUP_CYCLES  256

static inline void trng_enable(uint32_t enable)
{
    asm volatile("csrw %0, %1" :: "i"(CSR_TRNG_EN), "r"(enable));
}

static inline uint32_t trng_read_word(void)
{
    uint32_t value;
    asm volatile("csrr %0, %1" : "=r"(value) : "i"(CSR_TRNG_VALUE));
    return value;
}

static void delay_cycles(uint32_t cycles)
{
    for (volatile uint32_t i = 0; i < cycles; ++i) {
        asm volatile("nop");
    }
}

int main(void)
{
    uint32_t samples[NUM_SAMPLES];
    uint32_t first_sample;
    int all_equal = 1;

    platform_init();
    uart_loopback_disable();

    printf("TRNG core integration test\n");
    printf("Enabling CSR-backed TRNG conditioner...\n");
    uart_write_flush();

    trng_enable(1);
    delay_cycles(WARMUP_CYCLES);

    for (int i = 0; i < NUM_SAMPLES; ++i) {
        samples[i] = trng_read_word();
        printf("sample[%x] = 0x%x\n", i, samples[i]);
        uart_write_flush();
        delay_cycles(WARMUP_CYCLES);
    }

    first_sample = samples[0];
    for (int i = 1; i < NUM_SAMPLES; ++i) {
        if (samples[i] != first_sample) {
            all_equal = 0;
            break;
        }
    }

    if (all_equal) {
        printf("WARNING: all TRNG samples are identical\n");
    } else {
        printf("TRNG core appears active: samples changed over time\n");
    }

        (0);
    uart_write_flush();
    return 1;
}
