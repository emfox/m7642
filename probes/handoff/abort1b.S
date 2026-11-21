/*
 * Diagnostic rung: prove the handover (rung 0) AND report what mboot staged.
 *
 * Records, at stash page 0: "M764", "STEP", 4, then the words read from the
 * staging area -- 0x28000000 should read as the ANDROID! magic 0x21444e41 and
 * 0x28000800 as the arm64 Image's code0 (0x91005a4d).  Then it hands over the
 * way rung 0 does (clear x3/x4, fall into the factory entry).
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x5453
	movk	w7, #0x5045, lsl #16		/* "STEP" */
	str	w7, [x6, #4]
	mov	w7, #4
	str	w7, [x6, #8]

	movz	x9, #0x2800
	lsl	x9, x9, #16			/* 0x28000000: staged ANDROID! header */
	ldr	w10, [x9]
	str	w10, [x6, #12]
	ldr	w10, [x9, #8]			/* kernel_size from the staged header */
	str	w10, [x6, #16]
	add	x9, x9, #0x800
	ldr	w10, [x9]			/* staged kernel code0 */
	str	w10, [x6, #20]
	ldr	w10, [x9, #4]			/* staged kernel code1 */
	str	w10, [x6, #24]
	dsb	sy

	mov	w3, wzr
	mov	w4, wzr
	dsb	sy
	.word	0x14000000
