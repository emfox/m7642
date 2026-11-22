/*
 * kvacheck.S -- ask ONE question at __primary_switch's `br x8` (Image+0x4555b0),
 * then hand over to the staged factory kernel.
 *
 * Hard rules this file exists to obey (each learned by hanging the TV):
 *
 *  1. With the MMU on, the stash pages are NOT reachable.  Keep the answer in
 *     registers, drop the MMU first, and only then store.  There must be no
 *     path through this file that stores to 0x2309xxxx before `msr sctlr_el1`.
 *     (2026-11-22: kvacheck v1/v2 hung for exactly this.  v3 added `b 2f`,
 *     which jumped *over* the `msr` and reproduced the same hang.)
 *  2. The blob must not land on Image+0x36c0c0, where the code1 FDT shim lives.
 *     It is installed at Image+0x36d000.
 *  3. Control flow falls straight through: no forward branch may skip the
 *     MMU-off sequence.  check-probe.py verifies both this and rule 1.
 *
 * -DKVA_TEST=4  read *0xffffffc080000000 (_text VA) into a register
 * -DKVA_TEST=5  write 0xded to 0x23090020 with the MMU on (does DDR work at all?)
 * -DKVA_TEST=6  zero memory accesses: latch x8/SCTLR/TTBR1/TCR/VBAR/ESR/FAR
 *
 * Record written with the MMU off.  Address 0x23080100, NOT 0x23090000: after
 * the handover something clobbers the 0x23090000 page (measured 2026-11-22
 * 13:37 -- the FDT shim record and our own writes were both gone), while the
 * 0x23080000 page demonstrably survives.  The abort stub owns +0x00..+0x38, so
 * the probe uses +0x100.
 *   0x23080100  [0] x8 (the `br x8` target)   [1] value read / SCTLR
 *               [2] 0x600d if the read returned, else 0xbad
 *               [3] kva5: pre-MMU write readback
 *               [4..7] kva6: TTBR1, TCR, VBAR, ESR     [8] FAR
 *   0x23080180  "M764"/"KVA4"|"KVA5"|"KVA6", 4, 0
 */
#ifndef KVA_TEST
#define KVA_TEST 6
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
	movz	x10, #0x0000
	movk	x10, #0x8000, lsl #16
	movk	x10, #0xffc0, lsl #32
	movk	x10, #0xffff, lsl #48	/* 0xffffffc080000000 = _text */
	ldr	x21, [x10]
	mov	x22, #0x600d
#elif KVA_TEST == 5
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	mov	w5, #0xded
	str	w5, [x4, #0x20]		/* the one MMU-on store being tested */
	mov	x21, #0
	mov	x22, #0x600d
#else
	mrs	x21, sctlr_el1
	mrs	x22, ttbr1_el1
	mrs	x23, tcr_el1
	mrs	x24, vbar_el1
	mrs	x25, esr_el1
	mrs	x26, far_el1
#endif

	/* ---- from here on: MMU off, every access is physical ---- */
	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M */
	bic	x16, x16, #4		/* C */
	bic	x16, x16, #0x1000	/* I */
	msr	sctlr_el1, x16
	isb

	movz	x4, #0x0100
	movk	x4, #0x2308, lsl #16	/* 0x23080100: the page that survives */
	str	x20, [x4, #0]
	str	x21, [x4, #8]
	str	x22, [x4, #16]

#if KVA_TEST == 5
	movz	x6, #0x0120
	movk	x6, #0x2308, lsl #16
	ldr	w7, [x6]
	str	w7, [x4, #24]
#elif KVA_TEST == 6
	str	x23, [x4, #32]
	str	x24, [x4, #40]
	str	x25, [x4, #48]
	str	x26, [x4, #56]
#else
	str	wzr, [x4, #24]
#endif

	movz	x6, #0x0180
	movk	x6, #0x2308, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x564b		/* 'K','V' */
#if KVA_TEST == 4
	movk	w7, #0x3441, lsl #16	/* 'A','4' */
#elif KVA_TEST == 5
	movk	w7, #0x3541, lsl #16	/* 'A','5' */
#else
	movk	w7, #0x3641, lsl #16	/* 'A','6' */
#endif
	str	w7, [x6, #4]
	mov	w7, #4
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	dsb	sy

	/* drop dirty lines over the image, then the usual physical handover */
	movz	x19, #(IMAGE_START_PA & 0xffff)
	movk	x19, #((IMAGE_START_PA >> 16) & 0xffff), lsl #16
	movz	x27, #(IMAGE_END_PA & 0xffff)
	movk	x27, #((IMAGE_END_PA >> 16) & 0xffff), lsl #16
1:
	dc	civac, x19
	add	x19, x19, #64
	cmp	x19, x27
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
