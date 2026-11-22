/*
 * emmc_wr1.S -- decisive single-write test at code1.
 *
 * Writes JOB_BL_CNT (idx 0x08) only: same value, then 2, then back to the
 * original.  Reads it back each time and stores the three readings at
 * 0x23090000.  No clock enable, no event clear, no command, no DMA.
 *
 * If this hangs, a plain 16-bit write to FCIE0 from the code1 context is not
 * usable (and the whole bare-metal approach at code1 needs rethinking).
 * If it returns, writes work and the suspect is FUNC_CTL / SD_MODE / EVENT.
 *
 *   0x23090000  [0] before, [1] after writing 2, [2] after restoring
 *   0x23090800  marker "M764"/"WR1 ", 3, 0
 */
	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16	/* record page */
	movz	x5, #0x2600
	movk	x5, #0x1f22, lsl #16	/* FCIE0 PA */

	ldrh	w8, [x5, #0x20]		/* JOB_BL_CNT idx 0x08 */
	str	w8, [x4, #0]
	strh	w8, [x5, #0x20]		/* write the same value back */
	ldrh	w9, [x5, #0x20]
	str	w9, [x4, #4]		/* should still be 1 */

	mov	w10, #2
	strh	w10, [x5, #0x20]	/* a different (harmless, no job) value */
	ldrh	w11, [x5, #0x20]
	str	w11, [x4, #8]		/* should be 2 */

	strh	w8, [x5, #0x20]		/* restore */
	ldrh	w12, [x5, #0x20]
	str	w12, [x4, #12]		/* should be back to 1 */

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16	/* 0x23090800 (marker page, clear of the values) */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x3152
	movk	w7, #0x2057, lsl #16	/* "WR1 " */
	str	w7, [x6, #4]
	mov	w7, #3
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
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #0x10
	b.ne	1b
	dsb	sy

	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
