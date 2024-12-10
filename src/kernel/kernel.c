#include <stdint.h>
#include <stddef.h>

#define VIDEO_ADDRESS 0xB8000   // Video memory address
#define VIDEO_WIDTH 80          // VGA Text console width
#define VIDEO_HEIGHT 25         // VGA Text console height
#define VIDEO_SIZE (VIDEO_WIDTH * VIDEO_HEIGHT) * 2 // Total size of video memory in bytes

static int cursor_position = 0; // Global cursor position 
// Note that the cursor position is not tied directly to video address
// The correct way to get the address of the cursor is: VIDEO_ADDRESS + (cursor_position * 2)
// This is automatically calculated by the write_char_to_video function (by adding the property to the end of the writable data)
// So it's instead tied to the exact character on the screen

/* Code commentary (mostly to-do stuff)
    (Misc.)
    TODO: Split the functions into reasonable modules and/or files so it's actually organized

    (Text printing)
    FIXME: Potential edge case, where a really long printable string could skip over the line protection
        - Simply check if the string goes above the limit before printing

*/

// Returns the length of a string as an int
int strlen(const char* string) {
    int length = 0;
    while (string[length] != '\0') {
        length++;
    }
    return length;
}

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

// Shifts video memory by amount
void shift_video(int amount) {
    for (int i = 0; i < VIDEO_SIZE; i++) {
        // Handle the last byte(s) that go out of bounds
        if (i >= VIDEO_SIZE - 2 * amount) {
            write_memory(VIDEO_ADDRESS + i, 0);
            write_memory(VIDEO_ADDRESS + i + 1, 0); // ensure that the properties byte is also 0
            continue;
        }
        // Shift the entire memory by one
        write_memory(VIDEO_ADDRESS + i, read_memory(VIDEO_ADDRESS + i + 2 * amount));
    }
    return;
}

// Writes a single character into video memory
void write_char_to_video(char character, int address) {
    if (address < VIDEO_ADDRESS || address >= (VIDEO_ADDRESS + VIDEO_WIDTH * VIDEO_HEIGHT * 2) - 3) {
        return;
    }
    write_memory(address, character);
    write_memory(address + 1, 0x07);
    return;
}

// Prints a string, uses global cursor_position to automatically place it in the correct place
void print_string(const char* string) {
    for (int i = 0; string[i] != '\0'; i++) {

        // If the cursor goes beyond the memory limit
        if (cursor_position >= VIDEO_SIZE / 2) {
            cursor_position -= VIDEO_WIDTH - (cursor_position % VIDEO_WIDTH);
            shift_video(VIDEO_WIDTH);
        }

        // Handle newlines
        if (string[i] == '\n') {
            cursor_position += VIDEO_WIDTH - (cursor_position % VIDEO_WIDTH);
            continue;
        }

        // Actual printing
        write_char_to_video(string[i], VIDEO_ADDRESS + cursor_position * 2);
        cursor_position += 1;
    }
    return;
}

void kernel_main() {
    // Set the cursor to be after the bootloader messages
    cursor_position = VIDEO_WIDTH * 2 + 27;

    // Print response message to user
    print_string((char[]){"OK\n"});
    print_string((char[]){"Kernel loaded successfully!\n"});

    // Shut down since there's nothing to do
    while (1) {
        __asm__("hlt");
    }
}
