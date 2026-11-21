/*
 * Mainline rung stub: one stub for every rung.
 *
 * The rung offset is patched with `bl _start`, so x30 holds rung+4 -- recorded
 * here along with x0..x5.  Then the staged factory kernel is copied down to its
 * runtime address, the ramdisk arguments are dropped, and control goes to the
 * factory entry.  Android boots and the record is read back in the SAME boot.
 *
 * Lives outside the copied region (builder places it at 0x1400000).
 */
	.equ	STAGE,   0x30000800
	.equ	RUNTIME, 0x20280000
	.equ	ENTRY,   0x21220000

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
	mov	w7, #0x21			/* rung stub marker */
	str	w7, [x6, #8]
	str	x30, [x6, #16]			/* rung address + 4 */
	str	x0, [x6, #24]
	str	x1, [x6, #32]
	str	x2, [x6, #40]
	str	x3, [x6, #48]
	str	x4, [x6, #56]
	str	x5, [x6, #64]
	dsb	sy

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

	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
