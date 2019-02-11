.syntax unified
.cpu cortex-m4

.global quarterround_asm
.type quarterround_asm, %function
quarterround_asm:
    push {r0-r12,lr} 
    # store args as well as everything we need to restore
    # Note: lr==r14. We'll be using it as a general-purpose register
    # minor gripe: this'd be a bit neater if sp were r14
    ldr r0, [r0]
    ldr r1, [r1]
    ldr r2, [r2]
    ldr r3, [r3]

    add r0, r0, r1, ror #0
    eor r3, r3, r0, ror #0
    add r2, r2, r3, ror #16
    eor r1, r1, r2, ror #0
    add r0, r0, r1, ror #12
    eor r3, r3, r0, ror #16
    add r2, r2, r3, ror #24
    eor r1, r1, r2, ror #20
    pop {r4-r7}
    str r0, [r4]
    str r1, [r5]
    str r2, [r6]
    str r3, [r7]
    pop {r4-r12,lr}
    bx lr

