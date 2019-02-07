.syntax unified
.cpu cortex-m4

.global chacha20_core_asm
.type chacha20_core_asm, %function
chacha20_core_asm:
    push {r0-r13} # store args as well as everything we need to restore
    ldm r1, {r10-r13} # load values from instream
    mov r9, #5 # initialize loop counter
    push {r9-r13} # counter and instream will share 2 regs total
    # remember: the stack is full descending: push is STMDB
    # additionally, lower numbered registers are always associated
    # with lower addresses within a single push/pop/ldm/stm
    add sp, #12
    # so now we're pointing in the middle of the stack. Legend:
    # +4 x13 
    # sp x12 ^ IA
    # -4 x15 v DB
    # -8 x14 
    # -12 loop counter
    ldm r2, {r4-r11} # load keyvalues. They'll stay there during the loop
    ldm r3, {r0-r3} # load constant. It'll also stay. 
    # Note: Overwriting r3 like this is legal.
    # r12 and r13 still contain *in+8 and *in+12. What luck: that's x12 and x13

quadround:
    add r0, r4, rol #0
    eor r12, r0, ror #0
    add r8, r12, rol #8
    eor r4, r8, ror #0
    add r0, r4, rol #12
    eor r12, r0, ror #8
    add r8, r12, rol #24
    eor r4, r8, ror #12

    add r1, r5, rol #0
    eor r13, r1, ror #0
    add r9, r13, rol #8
    eor r5, r9, ror #0
    add r1, r5, rol #12
    eor r13, r1, ror #8
    add r9, r13, rol #24
    eor r5, r9, ror #12

    stmia sp, {r12,r13}
    ldmdb sp, {r12,r13} # now r12=x14, r13=x15
    add r2, r6, rol #0
    eor r12, r2, ror #0
    add r10, r12, rol #8
    eor r6, r10, ror #0
    add r2, r6, rol #12
    eor r12, r2, ror #8
    add r10, r12, rol #24
    eor r6, r10, ror #12

    add r3, r7, rol #0
    eor r13, r3, ror #0
    add r11, r13, rol #8
    eor r7, r11, ror #0
    add r3, r7, rol #12
    eor r13, r3, ror #8
    add r11, r13, rol #24
    eor r7, r11, ror #12
# switch to diagonal.
# note that quarterrounds are independent: we're doing the last one
# first, because it's loaded. Then the first, then load x12, x13 and
# do the second and third:
    add r3, r4, rol #19
    eor r12, r3, ror #24
    add r9, r12, rol #0
    eor r4, r9, ror #19
    add r3, r4, rol #31
    eor r12, r3, ror #0
    add r9, r12, rol #16
    eor r4, r9, ror #31

    add r0, r5, rol #19
    eor r13, r0, ror #24
    add r10, r13, rol #0
    eor r5, r10, ror #19
    add r0, r5, rol #31
    eor r13, r0, ror #0
    add r10, r13, rol #16
    eor r5, r10, ror #31

    stmdb sp, {r12,r13} 
    ldmia sp, {r12,r13} # now r12=x12, r13=x13
    add r1, r6, rol #19
    eor r12, r1, ror #24
    add r11, r12, rol #0
    eor r6, r11, ror #19
    add r1, r6, rol #31
    eor r12, r1, ror #0
    add r11, r12, rol #16
    eor r6, r11, ror #31

    add r2, r7, rol #19
    eor r13, r2, ror #24
    add r8, r13, rol #0
    eor r7, r8, ror #19
    add r2, r7, rol #31
    eor r13, r2, ror #0
    add r8, r13, rol #16
    eor r7, r8, ror #31
# second doubleround, to realign r12,r13,x14,x15
    add r0, r4, rol #6
    eor r12, r0, ror #16
    add r8, r12, rol #24
    eor r4, r8, ror #6
    add r0, r4, rol #18
    eor r12, r0, ror #24
    add r8, r12, rol #8
    eor r4, r8, ror #18

    add r1, r5, rol #6
    eor r13, r1, ror #16
    add r9, r13, rol #24
    eor r5, r9, ror #6
    add r1, r5, rol #18
    eor r13, r1, ror #24
    add r9, r13, rol #8
    eor r5, r9, ror #18

    stmia sp, {r12,r13}
    ldmdb sp, {r12,r13} # now r12=x14, r13=x15
    add r2, r6, rol #6
    eor r12, r2, ror #16
    add r10, r12, rol #24
    eor r6, r10, ror #6
    add r2, r6, rol #18
    eor r12, r2, ror #24
    add r10, r12, rol #8
    eor r6, r10, ror #18

    add r3, r7, rol #6
    eor r13, r3, ror #16
    add r11, r13, rol #24
    eor r7, r11, ror #6
    add r3, r7, rol #18
    eor r13, r3, ror #24
    add r11, r13, rol #8
    eor r7, r11, ror #18
# switch to diagonal.
    add r3, r4, rol #25
    eor r12, r3, ror #8
    add r9, r12, rol #16
    eor r4, r9, ror #25
    add r3, r4, rol #5
    eor r12, r3, ror #16
    add r9, r12, rol #0
    eor r4, r9, ror #5

    add r0, r5, rol #25
    eor r13, r0, ror #8
    add r10, r13, rol #16
    eor r5, r10, ror #25
    add r0, r5, rol #5
    eor r13, r0, ror #16
    add r10, r13, rol #0
    eor r5, r10, ror #5

    stmdb sp, {r12,r13} 
    ldr r12, [sp, #-12] # update and test the loop counter between switching.
    subs r12, #1
    str r12, [sp, #-12]
    ldmia sp, {r12,r13} # now r12=x12, r13=x13
    add r1, r6, rol #25
    eor r12, r1, ror #8
    add r11, r12, rol #16
    eor r6, r11, ror #25
    add r1, r6, rol #5
    eor r12, r1, ror #16
    add r11, r12, rol #0
    eor r6, r11, ror #5

    add r2, r7, rol #25
    eor r13, r2, ror #8
    add r8, r13, rol #16
    eor r7, r8, ror #25
    add r2, r7, rol #5
    eor r13, r2, ror #16
    add r8, r13, rol #0
    eor r7, r8, ror #5
#TODO: realign x4-7, and loop. After loop, perform final additions and return




