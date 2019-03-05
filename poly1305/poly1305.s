.syntax unified
.cpu cortex-m4

.global crypto_onetimeauth_poly1305
.type crypto_onetimeauth_poly1305, %function
crypto_onetimeauth_poly1305:
	@ r0     output pointer, 16 bytes
	@ r1     input stream pointer
	@ r2     input stream length, lower half
	@ r3     input stream length, upper half, assumed zero
	@ [sp+0] key pointer, 32 bytes

	push {r0,r1,r4-r11,lr}
	sub sp, #36
	mov r14, r2

	@ Convert key to 26-bit limbs
	ldr r10, [sp, #80]
	ldmia r10, {r5-r8}
	mov r10, #0x03ffffff
	and r5, #0x0fffffff
	and r6, r6, r10, lsl #2
	and r7, r7, r10, lsl #2
	and r8, r8, r10, lsl #2

	lsr r9, r8, #8
	and r8, r10, r8, lsl #18
	orr r8, r8, r7, lsr #14
	and r7, r10, r7, lsl #12
	orr r7, r7, r6, lsr #20
	and r6, r10, r6, lsl #6
	orr r6, r6, r5, lsr #26
	and r5, r10

	stmdb sp, {r5-r9}

	@ [sp-20] key in 26-bit limbs
	@ [sp+ 0] mulmod temporary storage
	@ [sp+40] pointer to output, 16 bytes
	@ [sp+80] pointer to key, 32 bytes

	eor r5, r5
	eor r6, r6
	eor r7, r7
	eor r8, r8
	eor r9, r9

	@ r0-r4 scratch
	@ r5-r9 accumulator polynomial
	@ r14   loop counter

loop:
	@ If inlen < 16, memcpy, then use new pointer, else set bit 128

	eor r4, r4
	ldr r1, [sp, #40]               @ input stream pointer
	add r3, r1, #16
	subs r14, #16
	ittt cs
	strcs r3, [sp, #40]
	movcs r4, #0x01000000
	bcs fast_load

	add r0, sp, #20
	add r2, r14, #16
	add r10, r2, r0
	strd r4, r4, [r0]
	strd r4, r4, [r0, #8]
	bl memcpy
	mov r1, r0
	mov r0, #1
	strb r0, [r10]

fast_load:
	@ Load 16 bytes of input from memory at r1.
	@ r4 already contains the upper two bits, so don't clear it.
	ldmia r1, {r0-r3}
	mov r10, #0x03ffffff

	orr r4, r4, r3, lsr #8
	and r3, r10, r3, lsl #18
	orr r3, r3, r2, lsr #14
	and r2, r10, r2, lsl #12
	orr r2, r2, r1, lsr #20
	and r1, r10, r1, lsl #6
	orr r1, r1, r0, lsr #26
	and r0, r10

	@ add26(h, c);
	add r5, r0
	add r6, r1
	add r7, r2
	add r8, r3
	add r9, r4

	@ mulmod26(h, r);
	ldmdb sp, {r0-r4}
	mov r10, 0
	mov r11, 0

	umlal r10, r11, r5, r0          @ r11r10 <  2LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r6, r12         @ r11r10 < 17LL
	add r12, r3, r3, lsl #2         @ r12    <  5L
	umlal r10, r11, r7, r12         @ r11r10 < 27LL
	add r12, r2, r2, lsl #2         @ r12    <  5L
	umlal r10, r11, r8, r12         @ r11r10 < 37LL
	add r12, r1, r1, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r11r10 < 47LL

	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #0]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	mov r11, 0                      @ r11r10 < 47L < 1LL

	umlal r10, r11, r5, r1          @ r11r10 <  3LL
	umlal r10, r11, r6, r0          @ r11r10 <  6LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r7, r12         @ r11r10 < 16LL
	add r12, r3, r3, lsl #2         @ r12    <  5L
	umlal r10, r11, r8, r12         @ r11r10 < 26LL
	add r12, r2, r2, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r111r0 < 36LL

	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #4]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	mov r11, 0                      @ r11r10 < 36L < 1LL

	umlal r10, r11, r5, r2          @ r11r10 <  3LL
	umlal r10, r11, r6, r1          @ r11r10 <  6LL
	umlal r10, r11, r7, r0          @ r11r10 <  8LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r8, r12         @ r11r10 < 18LL
	add r12, r3, r3, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r11r10 < 28LL

	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #8]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	mov r11, 0                      @ r11r10 < 28L < 1LL

	umlal r10, r11, r5, r3          @ r11r10 <  3LL
	umlal r10, r11, r6, r2          @ r11r10 <  6LL
	umlal r10, r11, r7, r1          @ r11r10 <  8LL
	umlal r10, r11, r8, r0          @ r11r10 < 10LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r11r10 < 20LL

	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #12]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	mov r11, 0                      @ r11r10 < 20L < 1LL

	umlal r10, r11, r5, r4          @ r11r10 <  3LL
	umlal r10, r11, r6, r3          @ r11r10 <  6LL
	umlal r10, r11, r7, r2          @ r11r10 <  8LL
	umlal r10, r11, r8, r1          @ r11r10 < 10LL
	umlal r10, r11, r9, r0          @ r11r10 < 12LL

	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #16]
	lsr r10, #26
	orr r10, r10, r11, lsl #6       @ r10    < 12L

	ldmia sp, {r5-r9}
	add r10, r10, r10, lsl #2       @ r10    < 60L
	add r10, r5                     @ r10    < 61L
	and r5, r10, #0x03ffffff        @ r5     <   L
	add r6, r6, r10, lsr #26        @ r6     <  2L

	bhi loop

	@ Load upper half of key into 26-bit limbs.
	ldr r10, [sp, #80]              @ Pointer to key, 32 bytes
	add r10, #16
	ldmia r10, {r0-r3}
	mov r10, #0x03ffffff

	lsr r4, r3, #8
	and r3, r10, r3, lsl #18
	orr r3, r3, r2, lsr #14
	and r2, r10, r2, lsl #12
	orr r2, r2, r1, lsr #20
	and r1, r10, r1, lsl #6
	orr r1, r1, r0, lsr #26
	and r0, r10

	@ Add in upper half of key.
	add r5, r0
	add r6, r1
	add r7, r2
	add r8, r3
	add r9, r4

	@ Squeeze h (r9r8r7r6r5)
	lsr r10, r9, #26
	and r9, r9, #0x03ffffff
	add r10, r10, r10, lsl #2
	add r10, r5
	and r5, r10, #0x03ffffff
	add r10, r6, r10, lsr #26
	and r6, r10, #0x03ffffff
	add r10, r7, r10, lsr #26
	and r7, r10, #0x03ffffff
	add r10, r8, r10, lsr #26
	and r8, r10, #0x03ffffff
	add r9, r9, r10, lsr #26

	@ Calculate h - p, squeeze and store into r4r3r2r1r0.
	lsr r10, r9, #26
	and r4, r9, #0x03ffffff
	add r10, r10, r10, lsl #2
	add r10, r5
	add r10, #5
	and r0, r10, #0x03ffffff
	add r10, r6, r10, lsr #26
	and r1, r10, #0x03ffffff
	add r10, r7, r10, lsr #26
	and r2, r10, #0x03ffffff
	add r10, r8, r10, lsr #26
	and r3, r10, #0x03ffffff
	add r4, r9, r10, lsr #26
	add r4, #0xfc000000

	@ Select bytes from h or h - p depending on whether result is negative.
	@ r10 = h < p ? 0xffffffff : 0;
	eor r10, r10
	sub r10, r10, r4, lsr #31

	@ if (h >= p) { h -= p; }
	msr apsr_g, r10
	sel r5, r5, r0
	sel r6, r6, r1
	sel r7, r7, r2
	sel r8, r8, r3
	sel r9, r9, r4

	@ Convert 26-bit limbs back to machine words
	lsl r9, #8
	orr r9, r9, r8, lsr #18
	lsl r8, #14
	orr r8, r8, r7, lsr #12
	lsl r7, #20
	orr r7, r7, r6, lsr #6
	orr r6, r5, r6, lsl #26

	@ Store result in output
	ldr r10, [sp, #36]
	stmia r10, {r6-r9}

	add sp, #44
	eor r0, r0
	pop {r4-r11,pc}
