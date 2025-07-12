riscv64-unknown-elf-gcc -std=c11 -Oz -g0 -flto -ffreestanding -nostdlib -mabi=ilp32 -march=rv32i -Wl,-Tlink.ld -o program.elf $@
riscv64-unknown-elf-objcopy -O binary program.elf program.bin
python3 uf2conv.py program.bin -b 0x10000 -f 0x7AB170D8 -o program.uf2