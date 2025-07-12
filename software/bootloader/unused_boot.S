.text
.align 4
.globl _start
_start:
    li s0, 0x00555508 #STAT_REG
    li s1, 0x00555504 #SEND_REG
    li s2, 0x00555500 #READ_REG
    li s3, 0x00011000 #BLOCK_ADDR
    # welcome message
    la a0, welcome
    call print_str

    main_loop:
    # read block
    call read_buff
    mv   a0, s3
    call print_buff

    # check block
    li   t0, 0x0A324655 #MAGIC0
    lw   t1, 0(s3)
    bne  t0, t1, bad_block
    li   t0, 0x9E5D5157 #MAGIC1
    lw   t1, 4(s3)
    bne  t0, t1, bad_block
    li   t0, 0x0AB16F30 #MAGICF
    lw   t1, 508(s3)
    bne  t0, t1, bad_block
    li   t0, 0x00002000 #FLAG
    lw   t1, 8(s3)
    bne  t0, t1, bad_block
    li   t0, 0x7AB170D8 #FAMILY_ID
    lw   t1, 28(s3)
    bne  t0, t1, bad_block

    lw   t0, 20(s3) # block no
    lw   t1, 24(s3) # num blocks
    sub  t2, t0, t1
    seqz s4, t2     # is final block.
    
    mv   a0, s3
    lw   a1, 12(s3) # addr.
    bnez t0, skip
    mv   s5, a1    # store first addr.
    skip:
    lw   a2, 16(s3) # data size. 
    call write_block

    la   a0, valid
    call print_str 

    bnez s4, end
    j    main_loop
    end:
    li   sp, 0x00014000 #RAM_END
    jr   s5 

    bad_block:
    la   a0, error
    call print_str 
    j    main_loop

print_str:  # fn print_str(&u8 a0) 
    lbu  t2, 0(a0)
    beqz t2, end_print_str
    poll_w_str:
    lbu  t3, 0(s0)
    andi t3, t3, 0x08
    bnez t3, poll_w_str
    sb   t2, 0(s1) 

    addi a0, a0, 1
    j    print_str
    end_print_str:
    ret

print_buff: #fn print_buff(&[u8, 512] a0)
    xor  t4, t4, t4
    li   t5, 512
    w_buff_loop:
    beq  t4, t5, end_print_buff
    lbu  t2, 0(a0)
    poll_w_buff:
    lbu  t3, 0(s0)
    andi t3, t3, 0x08
    bnez t3, poll_w_buff
    sb   t2, 0(s1) 
    addi t4, t4, 1
    addi a0, a0, 1
    j    w_buff_loop
    end_print_buff:
    ret

read_buff:
    xor  t4, t4, t4
    li   t5, 512
    mv   t6, s3
    r_buff_loop:
    beq  t4, t5, end_read_buff
    poll_r_buff:
    lbu  t3, 0(s0)
    andi t3, t3, 0x01
    bnez t3, poll_r_buff
    lb   t2, 0(s2) 
    sb   t2, 0(t6)
    addi t4, t4, 1
    addi t6, t6, 1
    j    r_buff_loop
    end_read_buff:
    ret    
    

write_block: #fn print_buff(&u8 a0 (src), &[u8, 512] a1(dest), u32 a3 (size))
    xor  t4, t4, t4
    w_block_loop:
    beq  t4, a3, end_print_block
    lbu  t2, 0(a0)
    sb   t2, 0(a1) 
    addi t4, t4, 1
    addi a0, a0, 1
    addi a1, a1, 1
    j    w_block_loop
    end_print_block:
    ret

.align(4)
welcome: .ascii "=== Booltoader v1.0 ===\n\0"
valid:   .ascii "Block: OK\n\0"
error:   .ascii "Block: Invalid, skipping block...\n\0"