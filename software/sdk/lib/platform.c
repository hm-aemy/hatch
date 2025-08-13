#include "platform.h"
#include "uart.h"
#include "print.h"
#include "util.h"

__attribute__ ((interrupt ("machine"),aligned(256),section(".vectors"))) static void interrupt_handler() {
    // Handle the interrupt
}

void platform_init(void) {
    set_mtie(0);
    set_mie(0);
    
    asm volatile("csrw mtvec, %0" :: "r"(interrupt_handler));

    uart_init();
}
