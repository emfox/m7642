/*
 * emmc_wt5.S -- the DMA/JOB register group, with the clock running.
 *
 * Last untested group of the setup stage.  Writes JOB_BL_CNT, BLK_SIZE,
 * DMA_LEN, MMA_PRI, DMA_ADDR (3 regs) and CMD_RSP_SIZE exactly as the probe
 * does, reads a couple back, then restores everything.
 *
 *   0x23090000 [0] FUNC_CTL before, [1] SD_MODE before,
 *              [2] DMA_LEN after, [3] DMA_ADDR_H after
 *   0x23090800 marker "M764"/"WT5 "
 */
	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	movz	x5, #0x2600
	movk	x5, #0x1f22, lsl #16

	ldrh	w20, [x5, #0x0c]	/* save DMA_ADDR_L */
	ldrh	w21, [x5, #0x10]	/* save DMA_ADDR_H */

	ldrh	w8, [x5, #0x1c]		/* FUNC_CTL before */
	str	w8, [x4, #0]
	mov	w9, #0x1002
	orr	w9, w9, w8
	strh	w9, [x5, #0x1c]

	ldrh	w10, [x5, #0x2c]	/* SD_MODE before */
	str	w10, [x4, #4]
	orr	w11, w10, #1
	strh	w11, [x5, #0x2c]	/* clock on */

	mov	w12, #1
	strh	w12, [x5, #0x20]	/* JOB_BL_CNT = 1 */

	mov	w12, #512
	strh	w12, [x5, #0x24]	/* BLK_SIZE = 512 */
	strh	w12, [x5, #0x14]	/* DMA_LEN_L = 512 */
	strh	wzr, [x5, #0x18]	/* DMA_LEN_H = 0 */

	ldrh	w13, [x5, #0x08]	/* MMA_PRI &= ~0xC */
	bic	w13, w13, #0xc
	strh	w13, [x5, #0x08]

	strh	wzr, [x5, #0x0c]	/* DMA_ADDR_L = 0x0000 (MIU 0x03080000) */
	mov	w12, #0x0308
	strh	w12, [x5, #0x10]	/* DMA_ADDR_H = 0x0308 */
	strh	wzr, [x5, #0xa4]	/* DMA_ADDR_47_32 = 0 */

	ldrh	w13, [x5, #0x28]	/* CMD_RSP_SIZE = (v & ~0x3F) | 5 */
	and	w13, w13, #0xffc0
	mov	w12, #5
	orr	w13, w13, w12
	strh	w13, [x5, #0x28]

	ldrh	w14, [x5, #0x14]
	str	w14, [x4, #8]		/* DMA_LEN readback */
	ldrh	w15, [x5, #0x10]
	str	w15, [x4, #12]		/* DMA_ADDR_H readback */

	/* restore */
	strh	wzr, [x5, #0xa4]
	strh	w21, [x5, #0x10]
	strh	w20, [x5, #0x0c]
	strh	w10, [x5, #0x2c]
	strh	w8, [x5, #0x1c]

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x3554
	movk	w7, #0x2057, lsl #16	/* "WT5 " */
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
