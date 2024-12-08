#include <stdint.h>
#include <stddef.h>

#define VIDEO_ADDRESS 0xB8000
#define VIDEO_WIDTH 80
#define VIDEO_HEIGHT 25

static int cursor_position = 0; // Global cursor position

// returns the length of a string as an int
int strlen(const char* string) {
    int length = 0;
    while (string[length] != '\0') {
        length++;
    }
    return length;
}

// Writes a single character into video memory
void write_char_to_video(char character, int address) {
    volatile uint16_t* video_memory = (uint16_t*)VIDEO_ADDRESS;

    video_memory[address] = (0x07 << 8) | character;
    return;
}

// Prints a string, uses cursor_position to automatically place it in the correct place
void print_string(const char* string) {
    for (int i = 0; string[i] != '\0'; i++) {
        if (string[i] == '\n') {
            cursor_position += VIDEO_WIDTH - cursor_position % VIDEO_WIDTH;
            continue;
        }
        write_char_to_video(string[i], cursor_position);
        cursor_position += 1;
    }
}

void kernel_main() {
    // Set the cursor to be after the bootloader messages
    cursor_position = VIDEO_WIDTH * 2 + 27;

    // Print response message to user
    print_string((char[]){"OK\n"});

    // Shut down since there's nothing to do
    while (1) {
        __asm__("hlt");
    }
}
