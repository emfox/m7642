/*
 * kvacheck.S -- at __primary_switch's `br x8` (Image+0x4555b0) ask one question
 * about the MMU-on context, then hand over.
 *
 * Lesson that forced this rewrite (2026-11-22 11:22, two wasted power cycles):
 * with the MMU on, the stash pages are NOT necessarily reachable.  The normal
 * tramp gets away with reading boot_args (0x207d4000) but it never *writes* a
 * stash page while the MMU is on -- it disables the MMU first.  Probes that
 * wrote 0x23090000 before disabling the MMU hung, and the hang said nothing
 * about the question being asked.  So: keep the answer in a register, drop the
 * MMU, and only then store it.
 *
 * -DKVA_TEST=4  read *0xffffffc080000000 (_text, kernel VA) into a register
 *               -- the only memory access performed with the MMU on.
 * -DKVA_TEST=5  write 0xded to 0x23090020 with the MMU on, read it back after
 *               the MMU is off: tells whether DDR is writable under the MMU.
 *
 * Record (written with the MMU off, so always safe):
 *   0x23090000  [0] x8 (the `br x8` target)   [1] the value read
 *               [2] 0x600d if the read returned, else 0xbad
 *               [3] for test 5: 0xded if the pre-MMU write became visible
 *   0x23090800  "M764"/"KVA4"|"KVA5", 4, 0
 *
 * Installed at Image+0x36d000 (the vector-free padding), never at 0x36c000:
 * the code1 FDT shim sits at 0x36c0c0 and a big blob there silently clobbers it.
 */
#ifndef KVA_TEST
#define KVA_TEST 4
#endif
#ifndef BOOT_ARGS_PA
#define BOOT_ARGS_PA 0x207d4000
#endif
#ifndef IMAGE_START_PA
#define IMAGE_START_PA 0x20290000
#endif
#ifndef IMAGE_END_PA
#define IMAGE_END_PA 0x208f0000
#endif

	.text
	.globl	_start
_start:
	mov	x20, x8			/* the branch target; no memory access */

#if KVA_TEST == 4
	/* the single memory access performed with the MMU on */
	movz	x10, #0x0000
	movk	x10, #0x8000, lsl #16
	movk	x10, #0xffc0, lsl #32
	movk	x10, #0xffff, lsl #48	/* 0xffffffc080000000 = _text */
	ldr	x21, [x10]
	mov	x22, #0x600d
#else
	/* test 5: is DDR writable while the MMU is on? */
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	mov	w5, #0xded
	str	w5, [x4, #0x20]
	mov	x21, #0
	mov	x22, #0x600d
#endif

	/* ---- MMU off: from here on every access is physical ---- */
	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M */
	bic	x16, x16, #4		/* C */
	bic	x16, x16, #0x1000	/* I */
	msr	sctlr_el1, x16
	isb

	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	str	x20, [x4, #0]
	str	x21, [x4, #8]
	str	x22, [x4, #16]

#if KVA_TEST == 5
	movz	x6, #0x0020
	movk	x6, #0x2309, lsl #16
	ldr	w7, [x6]
	str	w7, [x4, #24]
#else
	str	wzr, [x4, #24]
#endif

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x564b		/* 'K','V' */
#if KVA_TEST == 4
	movk	w7, #0x3441, lsl #16	/* 'A','4' */
#else
	movk	w7, #0x3541, lsl #16	/* 'A','5' */
#endif
	str	w7, [x6, #4]
	mov	w7, #4
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	dsb	sy

	/* drop dirty lines over the image, then the usual physical handover */
	movz	x19, #(IMAGE_START_PA & 0xffff)
	movk	x19, #((IMAGE_START_PA >> 16) & 0xffff), lsl #16
	movz	x20, #(IMAGE_END_PA & 0xffff)
	movk	x20, #((IMAGE_END_PA >> 16) & 0xffff), lsl #16
1:
	dc	civac, x19
	add	x19, x19, #64
	cmp	x19, x20
	b.lo	1b
	dsb	sy

	movz	x16, #(BOOT_ARGS_PA & 0xffff)
	movk	x16, #((BOOT_ARGS_PA >> 16) & 0xffff), lsl #16
	ldp	x0, x1, [x16]
	ldr	x2, [x16, #16]
	mov	x3, xzr
	mov	x4, xzr
	mov	x16, xzr
	mov	sp, x16
	movz	x16, #0x2168
	lsl	x16, x16, #16
	add	x16, x16, #0x200
	br	x16
