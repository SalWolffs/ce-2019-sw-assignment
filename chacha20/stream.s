.syntax unified
.cpu cortex-m4

.global crypto_stream_chacha20_asm
.type crypto_stream_chacha20_asm, %function
crypto_stream_chacha20_asm:
	@ r0     output stream pointer
	@ r1     unused
	@ r2     output stream length in bytes, lower half
	@ r3     output stream length in bytes, upper half, assumed zero
	@ [sp+0] nonce pointer, 8 bytes
	@ [sp+4] key pointer, 32 bytes

	@ If r3 is nonzero, we'd be writing the entire memory space, which makes
	@ no sense, so we will assume it is zero.

	push {r2,r4-r11,lr}
	sub sp, #80
	movs r4, r2, lsr #6
	sub r4, #1
	add r0, r0, r4, lsl #6
	mov r3, #0
	str r3, [sp, #12]
	ldr r1, [sp, #120]
	ldmia r1, {r2-r3}
	mov r1, sp
	stmia r1, {r2-r3}
	ldr r2, [sp, #124]
	ldr r3, =constant
	beq partial_block

	@ r0      output stream pointer
	@ [r1+ 0] nonce, 8 bytes
	@ [r1+ 8] not yet initialized
	@ [r1+12] zero
	@ r2      key pointer
	@ r3      constant pointer
	@ r4      counter

block_loop:
	str r4, [r1, #8]
	bl chacha20_core_asm
	subs r4, #1
	sub r0, #64
	bpl block_loop

partial_block:
	ldr r4, [sp, #80] @ output size
	ands r5, r4, #63
	beq return
	mov r4, r4, lsr #6
	str r4, [r1, #8]
	add r5, r0, r4, lsl #6
	add r0, sp, #16
	bl chacha20_core_asm

	add r0, r5, #64
	add r1, sp, #16
	ldr r2, [sp, #80]
	and r2, #63
	bl memcpy

return:
	add sp, #80
	pop {r0,r4-r11,lr}
	mov r0, #0
	bx lr

.data
constant:
	.string "expand 32-byte k"
