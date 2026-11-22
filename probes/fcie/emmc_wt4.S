/*
 * emmc_wt4.S -- the two "clear" operations, with the clock on.
 *
 * Everything else in the setup stage has now been shown safe individually
 * (FUNC_CTL, SD_MODE+SD_STATUS read, plain write).  This is the remaining
 * difference: write EVENT=0x3F (W1C) and SD_STATUS=0x3F (W1C) with the card
 * clock running, then read both back and restore.
 *
 *   0x23090000 [0] FUNC_CTL before, [1] SD_MODE before,
 *              [2] EVENT after clear, [3] SD_STATUS after clear
 *   0x23090800 marker "M764"/"WT4 "
 */
	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	movz	x5, #0x2600
	movk	x5, #0x1f22, lsl #16

	ldrh	w8, [x5, #0x1c]		/* FUNC_CTL before */
	str	w8, [x4, #0]
	mov	w9, #0x1002
	orr	w9, w9, w8
	strh	w9, [x5, #0x1c]		/* SD_EN | EMMC_ACTIVE */

	ldrh	w10, [x5, #0x2c]	/* SD_MODE before */
	str	w10, [x4, #4]
	orr	w11, w10, #1
	strh	w11, [x5, #0x2c]	/* clock on */

	mov	w12, #0x3f
	strh	w12, [x5, #0]		/* EVENT = 0x3F (W1C) */
	ldrh	w13, [x5, #0]
	str	w13, [x4, #8]		/* EVENT readback */

	strh	w12, [x5, #0x34]	/* SD_STATUS = 0x3F (W1C) */
	ldrh	w14, [x5, #0x34]
	str	w14, [x4, #12]		/* SD_STATUS readback */

	strh	w10, [x5, #0x2c]	/* clock off */
	strh	w8, [x5, #0x1c]		/* FUNC_CTL restore */

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x3454
	movk	w7, #0x2057, lsl #16	/* "WT4 " */
	str	w7, [x6, #4]
	mov	w7, #4
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	dsb	sy

	/* handover */
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
