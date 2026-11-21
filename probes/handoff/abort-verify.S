/*
 * Handover stub with copy verification and retry.
 *
 * The rung at 0x465e80 never returns while rungs 8 bytes earlier do, and the
 * ldrb in between makes no difference.  One unresolved possibility is that the
 * copy of the staged factory kernel is not landing correctly once the kernel
 * has already executed code.  So: copy, verify the first 64 bytes against the
 * source, retry up to three times, and only then hand over.  If it still hangs
 * after this, the checkpoint really is not being reached.
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
	mov	w7, #0x22
	str	w7, [x6, #8]
	str	x30, [x6, #16]
	dsb	sy

	mov	x11, #3
retry:
	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800
	movz	x7, #0x2028
	lsl	x7, x7, #16
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy

	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800
	movz	x7, #0x2028
	lsl	x7, x7, #16
	mov	x8, #8
2:
	ldr	x9, [x6], #8
	ldr	x10, [x7], #8
	cmp	x9, x10
	b.ne	3f
	subs	x8, x8, #1
	b.ne	2b
	b	4f
3:
	subs	x11, x11, #1
	b.ne	retry
	/* copy never verified: leave a marker and hang */
	movz	x6, #0x2308
	lsl	x6, x6, #16
	mov	w9, #0x0bad
	str	w9, [x6, #8]
5:
	b	5b
4:
	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
