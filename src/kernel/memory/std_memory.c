#include <stdint.h>
#include <stddef.h>

// ### Direct memory access functions
// This is totally safe and definitely not a cybersecurity risk :)
// To be fair I don't know if this will be exposed to the user 

// Direct memory write access
void write_memory(int address, int value) {
    volatile uint16_t* memory = (uint16_t*)address;
    *memory = value;
    return;
}

// Direct memory read access
int read_memory(int address) {
    volatile uint16_t* memory = (uint16_t*)address;
    return *memory;
}