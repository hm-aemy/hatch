#include "platform.h"
#include "uart.h"
#include "print.h"
#include "util.h"

static void interrupt_handler() {
    // Handle the interrupt
    asm volatile("mret");
}

void platform_init(void) {
    set_mtie(0);
    set_mie(0);
    
    asm volatile("csrw mtvec, %0" :: "r"(interrupt_handler));

    uart_init();
}
