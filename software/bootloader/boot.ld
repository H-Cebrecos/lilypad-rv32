ENTRY(boot)

MEMORY
{
        ROM (rx ) : ORIGIN = 0x00000000, LENGTH = 2K
        RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 16K
}

__ram_end = ORIGIN(RAM) + LENGTH(RAM);

/*Top 2K is reseved as bootloader RAM/ program stack*/
/* 1K stack followed by 1K of data and bss*/


SECTIONS
{
        . = ORIGIN(ROM);

        .text : ALIGN(4)
        {
                KEEP(*(.text.boot));
                *(.text .text.*);
        } > ROM

        .rodata : ALIGN(4)
        { 
                *(.rodata .rodata.*);
        } > ROM

        /* bootloader stack */
        .padding : ALIGN(4)
        {
                . = (LENGTH(RAM) + ORIGIN(RAM)) - 524;
                __stack_top = .;
        } > RAM

        .data : ALIGN(4)
        {
                __data_load = LOADADDR(.data);
                __data_start = .;
                *(.data .data.* .sdata .sdata.*);
                __data_end = .;
        } > RAM AT > ROM

        .bss : ALIGN(4)
        {
                __bss_start = .;
                *(.bss .bss.* .sbss .sbss.*);
                __bss_end = .;
        } > RAM  
}
