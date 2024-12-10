#include "../memory/memory.h"   // memory util functions to write to video memory

#define VIDEO_ADDRESS 0xB8000   // Video memory address
#define VIDEO_WIDTH 80          // VGA Text console width
#define VIDEO_HEIGHT 25         // VGA Text console height
#define VIDEO_SIZE (VIDEO_WIDTH * VIDEO_HEIGHT) * 2 // Total size of video memory in bytes

static int cursor_position = VIDEO_WIDTH + 27; // Global cursor position 
// Note that the cursor position is not tied directly to video address
// The correct way to get the address of the cursor is: VIDEO_ADDRESS + (cursor_position * 2)
// This is automatically calculated by the write_char_to_video function (by adding the property to the end of the writable data)
// So it's instead tied to the exact character on the screen

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

        // Tabs
        if (string[i] == '\t') {
            cursor_position += 4;
            continue;
        }

        // Yeah so I need something to do a single jump forward so it's this (effectively a space)
        // definitely not using it for the wrong purpose or something
        if (string[i] == '\r') {
            cursor_position += 1;
            continue;
        }

        // Actual printing
        write_char_to_video(string[i], VIDEO_ADDRESS + cursor_position * 2);
        cursor_position += 1;
    }
    return;
}