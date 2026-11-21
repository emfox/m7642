/*
 * Mainline checkpoint stub: record what was reached, then hand over to the
 * staged factory kernel so Android boots and the record can be read in the same
 * boot.
 *
 * Placed at the end of the mainline Image (see mk-mainline-abort.py, which also
 * patches the Image's code1 to branch here).  It must NOT return to the image:
 * it copies the factory kernel staged by mboot at 0x30000000 down to its runtime
 * address, drops the ramdisk arguments and jumps to the factory entry.
 *
 * Everything is written to the stash page for this rung; registers of interest
 * (the mainline entry state) come next once the plumbing is proven.
 */
	.equ	STASH,   0x23080000
	.equ	STAGE,   0x30000800
	.equ	RUNTIME, 0x20280000
	.equ	ENTRY,   0x21220000		/* runtime + 0xfa0000 */

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
	mov	w7, #0x10			/* rung 0x10 = mainline entry reached */
	str	w7, [x6, #8]
	str	x0, [x6, #16]
	str	x1, [x6, #24]
	str	x2, [x6, #32]
	str	x3, [x6, #40]
	str	x4, [x6, #48]
	str	x5, [x6, #56]
	dsb	sy

	/* copy staged factory kernel down to its runtime address */
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

	mov	w3, wzr				/* no ramdisk */
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
