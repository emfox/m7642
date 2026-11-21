/*
 * Staging diagnostic: same handover as rung 0, but reports what is staged at
 * 0x30000000 (the staging address used by `stagecmd`), to test whether mboot
 * runs the chained `run stagecmd`.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16
	str	w7, [x6]			/* "M764" */
	movz	w7, #0x5453
	movk	w7, #0x5045, lsl #16
	str	w7, [x6, #4]			/* "STEP" */
	mov	w7, #5
	str	w7, [x6, #8]			/* rung 5 */
	movz	x9, #0x3000
	lsl	x9, x9, #16
	ldr	w10, [x9]
	str	w10, [x6, #12]			/* staged header magic */
	ldr	w10, [x9, #8]
	str	w10, [x6, #16]			/* staged kernel_size */
	add	x9, x9, #0x800
	ldr	w10, [x9]
	str	w10, [x6, #20]			/* staged code0 */
	ldr	w10, [x9, #4]
	str	w10, [x6, #24]			/* staged code1 */
	dsb	sy
	mov	w3, wzr
	mov	w4, wzr
	dsb	sy
	.word	0x14000000
