/*
 * emmc_wrtest.S -- one register write (read-modify-write) plus read-back.
 *
 * Built twice with -DWTEST=1 / -DWTEST=2:
 *   1: FUNC_CTL (idx 0x07, offset 0x1c): write orig | 0x1002, read, restore
 *   2: SD_MODE  (idx 0x0b, offset 0x2c): write orig | 0x0001, read, restore
 *
 * Readings at 0x23090000: [0] before, [1] after write, [2] after restore.
 * Marker "M764"/"WT1 "/"WT2 " at 0x23090800.
 */
#ifndef WTEST
#define WTEST 1
#endif

#if WTEST == 1
#define ROFF 0x1c
#define WORDBIT 0x1002
#else
#define ROFF 0x2c
#define WORDBIT 0x0001
#endif

	.text
	.globl	_start
_start:
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16	/* record page */
	movz	x5, #0x2600
	movk	x5, #0x1f22, lsl #16	/* FCIE0 PA */

	ldrh	w8, [x5, #ROFF]		/* before */
	str	w8, [x4, #0]
	mov	w9, #WORDBIT
	orr	w9, w9, w8
	strh	w9, [x5, #ROFF]		/* write orig | bit */
	ldrh	w10, [x5, #ROFF]
	str	w10, [x4, #4]		/* after write */
	strh	w8, [x5, #ROFF]		/* restore */
	ldrh	w11, [x5, #ROFF]
	str	w11, [x4, #8]		/* after restore */

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
#if WTEST == 1
	movz	w7, #0x3154
	movk	w7, #0x2057, lsl #16	/* "WT1 " */
#else
	movz	w7, #0x3254
	movk	w7, #0x2057, lsl #16	/* "WT2 " */
#endif
	str	w7, [x6, #4]
	mov	w7, #3
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
