// Returns the length of a string as an int
int strlen(const char* string) {
    int length = 0;
    while (string[length] != '\0') {
        length++;
    }
    return length;
}