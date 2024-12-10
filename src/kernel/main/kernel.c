#include "../drivers/drivers.h"

/* Code commentary (mostly to-do stuff)
    (VGA)
    FIXME: Potential edge case, where a really long printable string could skip over the line protection
        - Simply check if the string goes above the limit before printing
*/

// kernel main function
void kernel_main() {
    // Print response message to user
    print_string((char[]){"\n\n"});                             // this is truly great programming (trust me)
    print_string((char[]){"\t\t\t\t\t\t\r\r\rOK\n"});           // moving the VGA to a different file broke the cursor position so we get this now      
    print_string((char[]){"Kernel loaded successfully!\n"});    // besides this monstrosity, it works fine (besides not being able to manually set it)

    // Shut down since there's nothing to do
    while (1) {
        __asm__("hlt");
    }
}
