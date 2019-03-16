.syntax unified
.cpu cortex-m4

equal:
    eor r0, r1
    sub r0, #1
    lsr r0, #31
    bx lr

ge:
    sub r0, r1
    lsr r0, #31
    eor r0, #1
    bx lr


.global fe25519_freeze
.type fe25519_freeze, %function
fe25519_freeze:
    push {r4-r9,lr}
    ldmia r0, {r1-r8}
    eor r9, r1, #0x7fffffff
    orn r9, r2
    orn r9, r3
    orn r9, r4
    orn r9, r5
    orn r9, r6
    orn r9, r7
    sub r14, r8, #0xffffffed @ 2^32 - 19
    orrs r9 , r14, lsr #31
    @ now r9 = 0 <=> *r0 >= 2^255 - 19
    movne r9, #0xffffffff
    @ if r9 = 0, clear r0[0:7] and subtract 2^32-19 from r0[7] :
    and r1, r9 
    and r2, r9 
    and r3, r9 
    and r4, r9 
    and r5, r9 
    and r6, r9 
    and r7, r9 
    subeq r8, #0xffffffed
    stmia r0, {r1-r8}
    pop {r4-r9,lr}


    

.global fe25519_iseq
.type fe25519_iseq, %function
fe25519_iszero:
    sub r0, #1
    lsr r0, #31
    bx lr


