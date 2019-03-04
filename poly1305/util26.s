.syntax unified
.cpu cortex-m4

@ Add two polynomials without squeezing.
.global add26
.type add26, %function
add26:
	push {r4-r11,lr}
	mov r14, r0
	ldmia r1, {r5-r9}
	ldmia r0, {r0-r4}

	add r0, r5
	add r1, r6
	add r2, r7
	add r3, r8
	add r4, r9

	stmia r14, {r0-r4}
	pop {r4-r11,pc}

@ Fully squeeze and reduce a polynomial h modulo p.
.global reduce26
.type reduce26, %function
reduce26:
	push {r4-r11,lr}
	mov r14, r0
	ldmia r14, {r0-r4}

	@ Squeeze h (r4r3r2r1r0)
	lsr r10, r4, #26
	and r4, r4, #0x03ffffff
	add r10, r10, r10, lsl #2
	add r10, r0
	and r0, r10, #0x03ffffff
	add r10, r1, r10, lsr #26
	and r1, r10, #0x03ffffff
	add r10, r2, r10, lsr #26
	and r2, r10, #0x03ffffff
	add r10, r3, r10, lsr #26
	and r3, r10, #0x03ffffff
	add r4, r4, r10, lsr #26

	@ Calculate h - p, squeeze and store into r9r8r7r6r5.
	lsr r10, r4, #26
	and r9, r4, #0x03ffffff
	add r10, r10, r10, lsl #2
	add r10, r0
	add r10, #5
	and r5, r10, #0x03ffffff
	add r10, r1, r10, lsr #26
	and r6, r10, #0x03ffffff
	add r10, r2, r10, lsr #26
	and r7, r10, #0x03ffffff
	add r10, r3, r10, lsr #26
	and r8, r10, #0x03ffffff
	add r9, r4, r10, lsr #26
	add r9, #0xfc000000

	@ Select bytes from h or h - p depending on whether result is negative.
	@ r10 = h < p ? 0xffffffff : 0;
	eor r10, r10
	sub r10, r10, r9, lsr #31

	@ if (h >= p) { h -= p; }
	msr apsr_g, r10
	sel r0, r0, r5
	sel r1, r1, r6
	sel r2, r2, r7
	sel r3, r3, r8
	sel r4, r4, r9

	stmia r14, {r0-r4}
	pop {r4-r11,pc}
