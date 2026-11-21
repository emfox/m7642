/*
 * Abort-to-vendor stub, rung 0: prove the handover mechanism.
 *
 * mboot stages the factory boot image at 0x28000000 (one extra `mmc read.p` in
 * recoverycmd), boots *this* image from the recovery slot, and this stub:
 *
 *   1. writes a checkpoint record to the stash pages (0x23080000, proven),
 *   2. copies the staged factory kernel (19,745,280 bytes at 0x28000800) down to
 *      its runtime address 0x20280000,
 *   3. falls through to the injected tail branch, which mk-boot-beacon points at
 *      image_base + 0xfa0000 = 0x21220000 -- the factory vendor entry.
 *
 * The vendor kernel then boots Android normally, so the checkpoint and the run
 * that produced it are readable in the SAME boot.  x0..x5 are left untouched:
 * the vendor entry expects mboot's leftovers there.
 *
 * Instruction classes: movz/movk/lsl/add/str/ldp/stp/subs/dsb/b -- nothing new.
 */
	.equ	STASH,   0x23080000
	.equ	STAGE,   0x28000800		/* staged kernel body (after ANDROID! header) */
	.equ	RUNTIME, 0x20280000		/* where the factory kernel is linked */
	.equ	KSIZE,   0x012d4a00		/* factory kernel_size */

	.text
	.globl	_start
_start:
	/* 1. checkpoint record: "M764" + "STEP" + step number */
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x5453
	movk	w7, #0x5045, lsl #16		/* "STEP" */
	str	w7, [x6, #4]
	mov	w7, #1				/* rung 0 */
	str	w7, [x6, #8]
	dsb	sy

	/* 2. copy the staged factory kernel to its runtime address (x6..x10 only) */
	movz	x6, #0x2800
	lsl	x6, x6, #16
	add	x6, x6, #0x800			/* src = 0x28000800 */
	movz	x7, #0x2028
	lsl	x7, x7, #16			/* dst = 0x20280000 */
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16		/* 0x012d4a00 bytes */
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy

	/* 3. last word: mk-boot-beacon turns it into `b image_base + 0xfa0000` */
	.word	0x14000000
