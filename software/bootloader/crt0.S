.section .text.boot
.align 4

.globl boot
boot:
        la   t1, __bss_start
        la   t2, __bss_end
clear_bss:
        beq  t2, t1, end_clear_bss  # remaining data?.
        sb zero, (t1)           # clear byte-
        addi t1, t1, 1          # increment start of bss.
        j    clear_bss
end_clear_bss:
        la   t1, __data_load    # address of data section in ROM.
        la   t2, __data_start   # address of start of data in RAM.
        la   t3, __data_end
load_data:
        beq t3, t2, end_load_data  # remaining data?
        lb   t5, (t1)           # get byte at __data_load.
        sb   t5, (t2)           # store it at __data_start.
        addi t1, t1, 1          # increment __data_load and __data_start.
        addi t2, t2, 1
        j    load_data
end_load_data:
init_stack:
        la   sp, __stack_top

        call  main
main_ret:
        j main_ret              # main should not return. 
                
