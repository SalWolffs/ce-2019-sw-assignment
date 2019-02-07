@ vim: ft=arm
.syntax unified
.cpu cortex-m4

.global benchmark
.type benchmark, %function
benchmark:
	@ Store saved registers
	push {r4-r12}

	mov r9, r0
	mov r7, #0x10000

	@ Initialize variables here:
	ldr r1, =0x12458723
	ldr r2, =0x15323984
	mov r4, #3
	mov r5, #5

	@ Load cycle count into r8
	ldr r8, [r9]
loop:
	nop

	@ Insert benchmarkable code here:
	nop

	nop
	subs r7, #1
	bne loop

	@ Compute cycle count into r0
	ldr r0, [r9]
	sub r0, r8
	sub r0, #0x50000

	@ Restore saved registers and return
	pop {r4-r12}
	bx lr
