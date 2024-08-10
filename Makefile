ASM=nasm
CC=gcc
TOOLS_DIR=tools
SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image kernel bootloader clean always tools_fat

all: floppy_image tools_fat

#Floppy Image
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
#creates a blank floppy disk simulating file filled with zeroes
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
#creates FAT12 file system on created blank floppy disk image	
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
#places bootloader code at start of floppy disk image	
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
#copies kernel.bin to root directory of floppy disk image with name kernel.bin


#Bootloader
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#Kernel
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always	
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

#Tools
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c
#Always
always: 
	mkdir -p $(BUILD_DIR)

#clean
clean: rm -rf $(BUILD_DIR)/*
