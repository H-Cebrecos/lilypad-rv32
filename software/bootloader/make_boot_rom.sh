#!/bin/bash


# Exit on any error
set -e

# Check if at least one argument is passed
if [ $# -lt 1 ]; then
    echo "Usage: $0 <source_files>..."
    exit 1
fi


# Compile C file, optimize for size, remove unsused functions with LTO. Pass crt0.S, which is the entry point of the executable.
riscv64-unknown-elf-gcc -std=c11 -Oz -g0 -flto -Wall -Wextra -Wpedantic -ffreestanding -nostdlib -mabi=ilp32 -march=rv32i  -Wl,-Tboot.ld -Wl,-Map=boot.map  -o intermediate.o  $@ crt0.S -lgcc

#remove debug information
#riscv64-unknown-elf-strip --strip-debug intermediate.o

# Generate temp output to compute size
riscv64-unknown-elf-objcopy  -O binary  intermediate.o intermediate.temp.bin

# Measure binary size in bytes
BIN_SIZE=$(stat --format=%s intermediate.temp.bin)

# Compute next power of 2
next_pow2() {
    local n=$1
    local p=1
    while [ $p -lt $n ]; do
        p=$((p << 1))
    done
    echo $p
}

ROM_SIZE=$(next_pow2 $BIN_SIZE)

# Extract the raw .text section from the elf executable, this is the contents that go into the BOOT ROM.
riscv64-unknown-elf-objcopy --pad-to=$ROM_SIZE --gap-fill=0x00 -O binary  intermediate.o intermediate.bin

# Convert the binary file to hexadecimal values in the COE format.
xxd -p -c 4 intermediate.bin | awk '{print substr($0,7,2) substr($0,5,2) substr($0,3,2) substr($0,1,2)}' | \
awk -v files=$1 -v prog_size=$BIN_SIZE -v size="$ROM_SIZE" 'BEGIN{
    print "; COE file generenated from: " files
    print "; Generated on: " strftime("%Y-%m-%d %H:%M:%S");
    print "; Program size (bytes): " prog_size
    print "; ROM size     (bytes): " size
    print "; ROM size     (words): " int((size + 3) / 4)
    printf("memory_initialization_radix=16;\n");
    printf("memory_initialization_vector=")
}
{
    if (NR > 1) printf(" ");
    printf "%s", $0
} END {
    printf(";\n")
}'

