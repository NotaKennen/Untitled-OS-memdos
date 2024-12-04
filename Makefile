ASM=nasm
CC=gcc
CRCPATH=$(HOME)/opt/cross/bin

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always

all: floppy_image

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader ss_bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img bs=512 count=1 conv=notrunc
	dd if=$(BUILD_DIR)/ss_bootloader.bin of=$(BUILD_DIR)/main_floppy.img bs=512 seek=1 count=1 conv=notrunc
	dd if=$(BUILD_DIR)/kernel.bin of=$(BUILD_DIR)/main_floppy.img bs=512 seek=2 conv=notrunc

#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always 
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

ss_bootloader: $(BUILD_DIR)/ss_bootloader.bin

$(BUILD_DIR)/ss_bootloader.bin: always 
	$(ASM) $(SRC_DIR)/bootloader/boot_ss.asm -f bin -o $(BUILD_DIR)/ss_bootloader.bin

#
# Kernel
#
#kernel: $(BUILD_DIR)/kernel.bin

#$(BUILD_DIR)/kernel.bin: always 
#	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

#
# Always
#
always:
	mkdir -p $(BUILD_DIR) 

#
# Kernel ?
#
kernel:
	$(ASM) -f elf32 $(SRC_DIR)/kernel/kernelboot.asm -o $(BUILD_DIR)/kernelboot.o
	$(CRCPATH)/i686-elf-gcc -m32 -c $(SRC_DIR)/kernel/kernel.c -o $(BUILD_DIR)/kernel.o
	$(CRCPATH)/i686-elf-ld -m elf_i386 -Ttext 0x9200 -o $(BUILD_DIR)/kernel.elf $(BUILD_DIR)/kernelboot.o $(BUILD_DIR)/kernel.o
	objcopy -O binary $(BUILD_DIR)/kernel.elf $(BUILD_DIR)/kernel.bin

#
# Clean
#
clean:
	rm -rf $(BUILD_DIR)/*