.syntax unified
.cpu cortex-m4

.global chacha20_core_asm
.type chacha20_core_asm, %function
chacha20_core_asm:
    push {r0-r12,lr} 
    # store args as well as everything we need to restore
    # Note: lr==r14. We'll be using it as a general-purpose register
    # minor gripe: this'd be a bit neater if sp were r14
    ldm r1, {r10-r12,r14} 
    # load values from instream: in+0, in+4, in+8, in+12, aka x14,x15,x12,x13
    mov r9, #5 
    # initialize loop counter
    push {r9-r12,r14} 
    # counter and instream will share 2 regs total
    # remember: the stack is full descending: push is STMDB
    # additionally, lower numbered registers are always associated
    # with lower addresses within a single push/pop/ldm/stm
    add sp, #12
    # so now we're pointing in the middle of the stack. Legend:
    # +60 lr   return address
    # +56 r12 ---- callee-stored ----
    # ... ...       ...........
    # +24 r4  ---- callee-stored ----
    # +20 r3  (c)
    # +16 r2  (k)
    # +12 r1  (in)
    # +8  r0  (out)
    # +4  x13 
    # sp  x12 ^ IA
    # -4  x15 v DB
    # -8  x14 
    # -12 loop counter
    ldm r2, {r4-r11} 
    # load keyvalues. They'll stay there during the loop
    ldm r3, {r0-r3} 
    # load constant. It'll also stay. Note: Overwriting r3 like this is legal.
    # r12 and r14 still contain *in+8 and *in+12. What luck: that's x12 and x13

quadround:
# Note: quadround, as in two full vertical and two full diagonal rounds
# This'll be a slog, so it's mostly script-generated
    add r0, r0, r4, ror #0
    eor r12, r12, r0, ror #0
    add r8, r8, r12, ror #16
    eor r4, r4, r8, ror #0
    add r0, r0, r4, ror #12
    eor r12, r12, r0, ror #16
    add r8, r8, r12, ror #24
    eor r4, r4, r8, ror #20

    add r1, r1, r5, ror #0
    eor r14, r14, r1, ror #0
    add r9, r9, r14, ror #16
    eor r5, r5, r9, ror #0
    add r1, r1, r5, ror #12
    eor r14, r14, r1, ror #16
    add r9, r9, r14, ror #24
    eor r5, r5, r9, ror #20

    stmia sp, {r12,r14}
    ldmdb sp, {r12,r14} 
        # now r12=x14, r14=x15
    add r2, r2, r6, ror #0
    eor r12, r12, r2, ror #0
    add r10, r10, r12, ror #16
    eor r6, r6, r10, ror #0
    add r2, r2, r6, ror #12
    eor r12, r12, r2, ror #16
    add r10, r10, r12, ror #24
    eor r6, r6, r10, ror #20

    add r3, r3, r7, ror #0
    eor r14, r14, r3, ror #0
    add r11, r11, r14, ror #16
    eor r7, r7, r11, ror #0
    add r3, r3, r7, ror #12
    eor r14, r14, r3, ror #16
    add r11, r11, r14, ror #24
    eor r7, r7, r11, ror #20

# switch to diagonal.
# note that quarterrounds are independent: we're doing the last one
# first, because it's loaded. Then the first, then load x12, x13 and
# do the second and third:
    add r3, r3, r4, ror #19
    eor r12, r12, r3, ror #8
    add r9, r9, r12, ror #8
    eor r4, r4, r9, ror #13
    add r3, r3, r4, ror #31
    eor r12, r12, r3, ror #24
    add r9, r9, r12, ror #16
    eor r4, r4, r9, ror #1

    add r0, r0, r5, ror #19
    eor r14, r14, r0, ror #8
    add r10, r10, r14, ror #8
    eor r5, r5, r10, ror #13
    add r0, r0, r5, ror #31
    eor r14, r14, r0, ror #24
    add r10, r10, r14, ror #16
    eor r5, r5, r10, ror #1

    stmdb sp, {r12,r14} 
    ldmia sp, {r12,r14} 
        # now r12=x12, r14=x13
    add r1, r1, r6, ror #19
    eor r12, r12, r1, ror #8
    add r11, r11, r12, ror #8
    eor r6, r6, r11, ror #13
    add r1, r1, r6, ror #31
    eor r12, r12, r1, ror #24
    add r11, r11, r12, ror #16
    eor r6, r6, r11, ror #1

    add r2, r2, r7, ror #19
    eor r14, r14, r2, ror #8
    add r8, r8, r14, ror #8
    eor r7, r7, r8, ror #13
    add r2, r2, r7, ror #31
    eor r14, r14, r2, ror #24
    add r8, r8, r14, ror #16
    eor r7, r7, r8, ror #1
# second doubleround, to realign x12,x13,x14,x15
    add r0, r0, r4, ror #6
    eor r12, r12, r0, ror #16
    add r8, r8, r12, ror #0
    eor r4, r4, r8, ror #26
    add r0, r0, r4, ror #18
    eor r12, r12, r0, ror #0
    add r8, r8, r12, ror #8
    eor r4, r4, r8, ror #14

    add r1, r1, r5, ror #6
    eor r14, r14, r1, ror #16
    add r9, r9, r14, ror #0
    eor r5, r5, r9, ror #26
    add r1, r1, r5, ror #18
    eor r14, r14, r1, ror #0
    add r9, r9, r14, ror #8
    eor r5, r5, r9, ror #14

    stmia sp, {r12,r14}
    ldmdb sp, {r12,r14} 
        # now r12=x14, r14=x15
    add r2, r2, r6, ror #6
    eor r12, r12, r2, ror #16
    add r10, r10, r12, ror #0
    eor r6, r6, r10, ror #26
    add r2, r2, r6, ror #18
    eor r12, r12, r2, ror #0
    add r10, r10, r12, ror #8
    eor r6, r6, r10, ror #14

    add r3, r3, r7, ror #6
    eor r14, r14, r3, ror #16
    add r11, r11, r14, ror #0
    eor r7, r7, r11, ror #26
    add r3, r3, r7, ror #18
    eor r14, r14, r3, ror #0
    add r11, r11, r14, ror #8
    eor r7, r7, r11, ror #14

# switch to diagonal.
    add r3, r3, r4, ror #25
    eor r12, r12, r3, ror #24
    add r9, r9, r12, ror #24
    eor r4, r4, r9, ror #7
    add r3, r3, r4, ror #5
    eor r12, r12, r3, ror #8
    add r9, r9, r12, ror #0
    eor r4, r4, r9, ror #27

    add r0, r0, r5, ror #25
    eor r14, r14, r0, ror #24
    add r10, r10, r14, ror #24
    eor r5, r5, r10, ror #7
    add r0, r0, r5, ror #5
    eor r14, r14, r0, ror #8
    add r10, r10, r14, ror #0
    eor r5, r5, r10, ror #27

    stmdb sp, {r12,r14} 
    ldr r12, [sp, #-12] 
        # update and test the loop counter between switching.
    subs r12, #1
    str r12, [sp, #-12]
    ldmia sp, {r12,r14} 
        # now r12=x12, r14=x13
    add r1, r1, r6, ror #25
    eor r12, r12, r1, ror #24
    add r11, r11, r12, ror #24
    eor r6, r6, r11, ror #7
    add r1, r1, r6, ror #5
    eor r12, r12, r1, ror #8
    add r11, r11, r12, ror #0
    eor r6, r6, r11, ror #27

    add r2, r2, r7, ror #25
    eor r14, r14, r2, ror #24
    add r8, r8, r14, ror #24
    eor r7, r7, r8, ror #7
    add r2, r2, r7, ror #5
    eor r14, r14, r2, ror #8
    add r8, r8, r14, ror #0
    eor r7, r7, r8, ror #27

    mov r4, r4, ror #12
    mov r5, r5, ror #12
    mov r6, r6, ror #12
    mov r7, r7, ror #12
    bne quadround

# TODO: optimize this bit, if possible
    # we can't do the additions in one or two sets, so split it in 3 batches of 6
    sub sp, #8 
        # restore sp but drop the loop counter
    push {r6-r12,r14} 
        # create a run of xvals on the stack. sp-=4*8
    ldr r12, [sp, #48] 
        # arg:out

    ldr r14, [sp, #60] 
        # arg:c
    ldm r14, {r6-r9} 
        # j0-j3
    ldr r14, [sp, #56] 
        # arg:k
    ldm r14!, {r10,r11} 
        # j4,j5
    add r0, r6
    add r1, r7
    add r2, r8
    add r3, r9
    add r4, r10
    add r5, r11
    stm r12!, {r0-r5} 
        # x0-x5

    pop {r0-r5} 
        # x6-x11    NB: sp+=4*6
    ldm r14!, {r6-r11} 
        # j6-j11
    add r0, r6
    add r1, r7
    add r2, r8
    add r3, r9
    add r4, r10
    add r5, r11
    stm r12!, {r0-r5} 
        # x6-x11

    pop {r0-r3} 
        # x12-x15       NB: sp+=4*4, back at loop-sp
    add sp, #24 
        # back at function entry push sp, skip args and stale x12,x13

    ldr r14, [sp, #-12] 
        # arg:in
    ldm r14, {r6-r9} 
        # j14,j15,j12,j13
    add r0, r8
    add r1, r9
    add r2, r6
    add r3, r7
    stm r12, {r0-r3}
    
    # We're done, 20 rounds executed, added to original, and written to output.
    # restore registers and return 0:
    pop {r4-r12,lr}
    mov r0, #0
    bx lr

