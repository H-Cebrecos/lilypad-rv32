ENTRY(main)

MEMORY
{
        RAM (rwx) : ORIGIN = 0x000010000, LENGTH = 16K - 600
}

SECTIONS
{
        .text : ALIGN(4)
        {
                KEEP(*(.text.main));
                *(.text .text.*);
        } > RAM

        .rodata : ALIGN(4)
        { 
                *(.rodata .rodata.*);
        } > RAM

        .data : ALIGN(4)
        {
                *(.data .data.* .sdata .sdata.*);
        } > RAM

        .bss : ALIGN(4)
        {
                *(.bss .bss.* .sbss .sbss.*);
        } > RAM
}
