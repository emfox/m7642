/*
 * emmc_clk.S -- read-only check of the generic timer at code1.
 *
 * All the probe's timeouts are CNTPCT/CNTFRQ based.  If the counter does not
 * run in the code1 context, every deadline never fires and the waits degrade
 * to very long spins.  This records, read-only:
 *
 *   0x23090000  CNTFRQ_EL0
 *   0x23090008  CNTPCT_EL0 at t0
 *   0x23090010  CNTPCT_EL0 after a ~1e6-iteration loop (t1)
 *   0x23090018  CurrentEL
 *   0x23090020  SCTLR_EL1
 *   0x23090800  "M764"/"CLK ", 5, 0
 *
 * It touches no FCIE register and hands over to the factory kernel, so it
 * cannot hang.
 */
	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16	/* record page */

	mrs	x8, cntfrq_el0
	str	x8, [x4, #0]
	mrs	x9, cntpct_el0
	str	x9, [x4, #8]

	movz	x10, #0x4240		/* 0x0f4240 = 1,000,000 iterations */
	movk	x10, #0x000f, lsl #16
1:
	subs	x10, x10, #1
	b.ne	1b

	mrs	x11, cntpct_el0
	str	x11, [x4, #16]
	mrs	x12, currentel
	str	x12, [x4, #24]
	mrs	x13, sctlr_el1
	str	x13, [x4, #32]

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16	/* 0x23090800 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4c43
	movk	w7, #0x204b, lsl #16	/* "CLK " */
	str	w7, [x6, #4]
	mov	w7, #5
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	dsb	sy

	/* handover: 0x30000800 -> 0x20280000, drop ramdisk, enter vendor */
	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800
	movz	x7, #0x2028
	lsl	x7, x7, #16
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16
2:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #0x10
	b.ne	2b
	dsb	sy

	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
