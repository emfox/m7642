/*
 * emmc_regs.S -- read-only FCIE0 + EMMC_PLL dump taken at code1.
 *
 * Runs straight from mboot's handoff (MMU and caches off), reads the 34
 * implemented FCIE0 registers and the two EMMC_PLL registers the driver
 * touches, stores them and hands the machine over to the staged factory
 * kernel so Android boots and probeRW can read the values back.
 *
 * Layout (physical):
 *   0x23090000 + idx*4   FCIE0 register idx (32-bit slot, low half = value)
 *   0x23090400           EMMC_PLL idx 0x1a
 *   0x23090404           EMMC_PLL idx 0x45
 *   0x23090800           "M764"/"REG ", 34, 0
 *
 * READ ONLY: no writes to the controller at all.
 */
	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16	/* record base */
	movz	x5, #0x2600
	movk	x5, #0x1f22, lsl #16	/* FCIE0 PA 0x1f222600 */

	/* idx 0x00..0x18 (contiguous, no holes) */
	mov	x6, xzr
1:
	lsl	x7, x6, #2
	ldrh	w8, [x5, x7]
	str	w8, [x4, x7]
	add	x6, x6, #1
	cmp	x6, #0x19
	b.ne	1b

	/* sparse indices: 0x29, 0x34..0x39, 0x3f, 0x63 */
	.macro	rd idx
	mov	x6, #(\idx)
	lsl	x7, x6, #2
	ldrh	w8, [x5, x7]
	str	w8, [x4, x7]
	.endm
	rd	0x29
	rd	0x34
	rd	0x35
	rd	0x36
	rd	0x37
	rd	0x38
	rd	0x39
	rd	0x3f
	rd	0x63

	/* EMMC_PLL: idx 0x1a and 0x45 */
	movz	x5, #0x7e00
	movk	x5, #0x1f24, lsl #16	/* 0x1f247e00 */
	ldrh	w8, [x5, #0x68]		/* 0x1a * 4 */
	str	w8, [x4, #0x400]
	ldrh	w8, [x5, #0x114]	/* 0x45 * 4 */
	str	w8, [x4, #0x404]

	/* marker */
	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16	/* 0x23090800 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4552
	movk	w7, #0x2047, lsl #16	/* "REG " */
	str	w7, [x6, #4]
	mov	w7, #34
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
