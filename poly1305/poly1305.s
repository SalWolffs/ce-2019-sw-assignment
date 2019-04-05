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

	@ Convert key to 26-bit limbs.
	ldr r10, [sp, #80]
	ldmia r10, {r5-r8}
	@ This bit pattern happens to match the mask needed, so it is reused.
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

	@ Store the key below the stack pointer.
	stmdb sp, {r5-r9}

	@ [sp-20] key in 26-bit limbs
	@ [sp+ 0] computed multiplication
	@ [sp+20] partial block
	@ [sp+36] pointer to output, 16 bytes
	@ [sp+80] pointer to key, 32 bytes

	eor r5, r5
	eor r6, r6
	eor r7, r7
	eor r8, r8
	eor r9, r9

	@ r0-r4   scratch
	@ r5-r9   accumulator polynomial
	@ r10,r11 limb accumulator
	@ r14     loop counter

loop:
	@ Update input pointer and counter and check for end.
	ldr r1, [sp, #40]               @ input stream pointer
	add r3, r1, #16
	subs r14, #16

	@ If at least 16 bytes remaining, set bit 128 and load.
	ittt cs
	strcs r3, [sp, #40]             @ input stream pointer
	movcs r4, #0x01000000
	bcs fast_load

	@ Less than 16 bytes remaining, memcpy them to a place where we can
	@ access 16 bytes safely.
	add r0, sp, #20                 @ Output buffer
	add r2, r14, #16                @ Length
	add r10, r2, r0

	@ Clear buffer, then memcpy to it.
	eor r4, r4
	strd r4, r4, [r0]
	strd r4, r4, [r0, #8]
	bl memcpy
	mov r1, r0

	@ Write a 1 byte at the end of the buffer.
	mov r0, #1
	strb r0, [r10]

fast_load:
	@ Load 16 bytes of input from memory at r1.
	@ r4 already contains the upper two bits, so don't clear it.
	ldmia r1, {r0-r3}
	mov r10, #0x03ffffff

	@ Convert block to 26-bit limbs
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

	@ Load second operand and clear accumulator.
	ldmdb sp, {r0-r4}
	eor r10, r10
	eor r11, r11

	@ Accumulute first limb.
	umlal r10, r11, r5, r0          @ r11r10 <  2LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r6, r12         @ r11r10 < 17LL
	add r12, r3, r3, lsl #2         @ r12    <  5L
	umlal r10, r11, r7, r12         @ r11r10 < 27LL
	add r12, r2, r2, lsl #2         @ r12    <  5L
	umlal r10, r11, r8, r12         @ r11r10 < 37LL
	add r12, r1, r1, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r11r10 < 47LL

	@ Write first limb and carry accumulator.
	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #0]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	eor r11, r11                    @ r11r10 < 47L < 1LL

	@ Accumulate second limb.
	umlal r10, r11, r5, r1          @ r11r10 <  3LL
	umlal r10, r11, r6, r0          @ r11r10 <  6LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r7, r12         @ r11r10 < 16LL
	add r12, r3, r3, lsl #2         @ r12    <  5L
	umlal r10, r11, r8, r12         @ r11r10 < 26LL
	add r12, r2, r2, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r111r0 < 36LL

	@ Write second limb and carry accumulator.
	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #4]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	eor r11, r11                    @ r11r10 < 36L < 1LL

	@ Accumulate third limb.
	umlal r10, r11, r5, r2          @ r11r10 <  3LL
	umlal r10, r11, r6, r1          @ r11r10 <  6LL
	umlal r10, r11, r7, r0          @ r11r10 <  8LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r8, r12         @ r11r10 < 18LL
	add r12, r3, r3, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r11r10 < 28LL

	@ Write third limb and carry accumulator.
	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #8]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	eor r11, r11                    @ r11r10 < 28L < 1LL

	@ Accumulate fourth limb.
	umlal r10, r11, r5, r3          @ r11r10 <  3LL
	umlal r10, r11, r6, r2          @ r11r10 <  6LL
	umlal r10, r11, r7, r1          @ r11r10 <  8LL
	umlal r10, r11, r8, r0          @ r11r10 < 10LL
	add r12, r4, r4, lsl #2         @ r12    <  5L
	umlal r10, r11, r9, r12         @ r11r10 < 20LL

	@ Write fourth limb and carry accumulator.
	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #12]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	eor r11, r11                    @ r11r10 < 20L < 1LL

	@ Accumulate final limb.
	umlal r10, r11, r5, r4          @ r11r10 <  3LL
	umlal r10, r11, r6, r3          @ r11r10 <  6LL
	umlal r10, r11, r7, r2          @ r11r10 <  8LL
	umlal r10, r11, r8, r1          @ r11r10 < 10LL
	umlal r10, r11, r9, r0          @ r11r10 < 12LL

	@ Write final limb and carry accumulator.
	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [sp, #16]
	lsr r10, #26
	orr r10, r10, r11, lsl #6       @ r10    < 12L

	@ Load result and carry the first two limbs.
	ldmia sp, {r5-r9}
	add r10, r10, r10, lsl #2       @ r10    < 60L
	add r10, r5                     @ r10    < 61L
	and r5, r10, #0x03ffffff        @ r5     <   L
	add r6, r6, r10, lsr #26        @ r6     <  2L

	@ Flags were set near the start of the loop.
	bhi loop

	@ Load upper half of key into 26-bit limbs.
	ldr r10, [sp, #80]              @ Pointer to key, 32 bytes
	add r10, #16
	ldmia r10, {r0-r3}
	mov r10, #0x03ffffff

	@ Convert upper half of key to 26-bit limbs.
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

	@ Convert 26-bit limbs back to machine words.
	lsl r9, #8
	orr r9, r9, r8, lsr #18
	lsl r8, #14
	orr r8, r8, r7, lsr #12
	lsl r7, #20
	orr r7, r7, r6, lsr #6
	orr r6, r5, r6, lsl #26

	@ Store result in output
	ldr r10, [sp, #36]              @ Output pointer
	stmia r10, {r6-r9}

	add sp, #44
	eor r0, r0
	pop {r4-r11,pc}
