/*
 * emmc_wt3.S -- does reading SD_STATUS work once the card clock is enabled?
 *
 * wt1/wt2 proved writing FUNC_CTL |= 0x1002 and SD_MODE |= 1 individually
 * works and reads back.  The setup stage then enables the clock and polls
 * SD_STATUS -- a register in the SD clock domain.  If that read stalls when
 * the card clock source is not actually running, this test hangs here.
 *
 *   0x23090000 [0] FUNC_CTL before, [1] SD_MODE before,
 *              [2] SD_STATUS after enabling the clock, [3] SD_STATUS after
 *              restoring FUNC_CTL/SD_MODE
 *   0x23090800 marker "M764"/"WT3 "
 */
	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	movz	x5, #0x2600
	movk	x5, #0x1f22, lsl #16

	ldrh	w8, [x5, #0x1c]		/* FUNC_CTL */
	str	w8, [x4, #0]
	mov	w9, #0x1002
	orr	w9, w9, w8
	strh	w9, [x5, #0x1c]		/* |= SD_EN | EMMC_ACTIVE */

	ldrh	w10, [x5, #0x2c]	/* SD_MODE */
	str	w10, [x4, #4]
	orr	w11, w10, #1
	strh	w11, [x5, #0x2c]	/* clock on */

	ldrh	w12, [x5, #0x34]	/* SD_STATUS with the clock on */
	str	w12, [x4, #8]

	strh	w10, [x5, #0x2c]	/* restore clock off */
	strh	w8, [x5, #0x1c]		/* restore FUNC_CTL */
	ldrh	w13, [x5, #0x34]
	str	w13, [x4, #12]

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x3354
	movk	w7, #0x2057, lsl #16	/* "WT3 " */
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
