#include <platform.h>
#include <print.h>
#include <timer.h>

int main() {
    platform_init();

    printf("Hello World!\n");
    for (int i=0; i<10000; i++) asm volatile("nop");
    
    return 1;
}
