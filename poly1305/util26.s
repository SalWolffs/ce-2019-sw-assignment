.syntax unified
.cpu cortex-m4

@ Add two polynomials without squeezing.
.global add26
.type add26, %function
add26:
	push {r4-r11,lr}
	mov r14, r0
	ldmia r1, {r0-r4}
	ldmia r0, {r5-r9}

	add r5, r0
	add r6, r1
	add r7, r2
	add r8, r3
	add r9, r4

	stmia r14, {r5-r9}
	pop {r4-r11,pc}

@ Fully squeeze and reduce a polynomial h modulo p.
.global reduce26
.type reduce26, %function
reduce26:
	push {r4-r11,lr}
	mov r14, r0
	ldmia r14, {r5-r9}

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

	stmia r14, {r5-r9}
	pop {r4-r11,pc}
