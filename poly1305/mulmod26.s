.syntax unified
.cpu cortex-m4

@ This function multiplies 2 poly1305 polynomials and stores the result in the
@ first. (r10,r11) is used as accumulator, with r10 containing the lower bits.
@ This function has pre- and postconditions on h that allow one normalized
@ polynomial to be added without squeezing before passing it back to this
@ function.
@ static void mulmod26(uint32_t h[5], const uint32_t r[5]);
@ Let L be 0x04000000, aka UINT26_MAX + 1. Let LL be L * L
@ Precondition: h[1] < 3L, other h limbs < 2L
@ Precondition: All r limbs < L
@ Postcondition: h[1] < 2L, other h limbs < L
.global mulmod26
.type mulmod26, %function
mulmod26:
	push {r4-r11,lr}
	mov r14, r0
	ldmia r1, {r0-r4}               @ r{0,1,2,3,4} <  L
	ldmia r0, {r5-r9}               @ r{5,7,8,9}   < 2L, r6 < 3L
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
	str r12, [r14, #0]
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
	str r12, [r14, #4]
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
	str r12, [r14, #8]
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
	str r12, [r14, #12]
	lsr r10, #26
	orr r10, r10, r11, lsl #6
	mov r11, 0                      @ r11r10 < 20L < 1LL

	umlal r10, r11, r5, r4          @ r11r10 <  3LL
	umlal r10, r11, r6, r3          @ r11r10 <  6LL
	umlal r10, r11, r7, r2          @ r11r10 <  8LL
	umlal r10, r11, r8, r1          @ r11r10 < 10LL
	umlal r10, r11, r9, r0          @ r11r10 < 12LL

	and r12, r10, #0x03ffffff       @ r12    <   L
	str r12, [r14, #16]
	lsr r10, #26
	orr r10, r10, r11, lsl #6       @ r10    < 12L

	ldmia r14, {r5,r6}              @ r{5,6} <   L
	add r10, r10, r10, lsl #2       @ r10    < 60L
	add r10, r5                     @ r10    < 61L
	and r5, r10, #0x03ffffff        @ r5     <   L
	add r6, r6, r10, lsr #26        @ r6     <  2L
	stmia r14, {r5,r6}

	pop {r4-r11,pc}
