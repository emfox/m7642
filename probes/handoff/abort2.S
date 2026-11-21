/*
 * Single-step tracer, rung 1: copy-in handover, for tracing an image whose
 * 0xfa0000 is NOT the factory kernel (i.e. the mainline Image).
 *
 * mboot stages the factory boot image at 0x28000000 (one extra `mmc read.p` in
 * recoverycmd).  This stub:
 *
 *   1. writes the checkpoint record to the stash,
 *   2. copies the staged factory kernel body (0x28000800, 19,745,280 bytes) to
 *      its runtime address 0x20280000,
 *   3. clears x3/x4 so the kernel gets NO ramdisk and boots /system (rung 0
 *      proved this is what makes it boot Android instead of recovery),
 *   4. falls through to the patched tail branch = image_base + 0xfa0000.
 *
 * Uses x6..x10 only; x0..x5 stay as mboot left them.
 */
	.equ	STAGE,   0x28000800
	.equ	RUNTIME, 0x20280000
	.equ	KSIZE,   0x012d4a00

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
	mov	w7, #3				/* rung 1 */
	str	w7, [x6, #8]
	dsb	sy

	movz	x6, #0x2800
	lsl	x6, x6, #16
	add	x6, x6, #0x800			/* src */
	movz	x7, #0x2028
	lsl	x7, x7, #16			/* dst */
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16		/* 0x012d4a00 */
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy

	mov	w3, wzr				/* no ramdisk */
	mov	w4, wzr
	dsb	sy
	.word	0x14000000
