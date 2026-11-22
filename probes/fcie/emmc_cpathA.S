/*
 * emmc_cpathA.S -- asm-only probes of the two things the C path adds.
 *
 *  -DCPTEST=1  use the C path's stack page (0x230b0000) and touch the stack
 *  -DCPTEST=2  write the C path's heartbeat address (0x23080fe0)
 *
 * Both write a record at 0x23090000, restore sp = 0 and hand over, exactly
 * like emmc_read.S.  If one of them hangs, that piece of the C scaffolding is
 * the culprit and the compiled code is not.
 */
#ifndef CPTEST
#define CPTEST 1
#endif

	.text
	.globl	_start
_start:
#if CPTEST == 1
	movz	x16, #0x0000
	movk	x16, #0x230b, lsl #16	/* the C path's stack page */
	mov	sp, x16
	mov	x9, #0x1111
	str	x9, [sp, #-16]!
	str	x9, [sp, #-16]!
	str	x9, [sp, #-16]!
	str	x9, [sp, #-16]!
#endif

	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
#if CPTEST == 1
	movz	w7, #0x5341
	movk	w7, #0x2050, lsl #16	/* "ASP " */
#else
	movz	w7, #0x4248
	movk	w7, #0x2020, lsl #16	/* "HB  " */
#endif
	str	w7, [x6, #4]
	mov	w7, #0x40
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	str	x16, [x6, #16]
#if CPTEST == 2
	movz	x11, #0x0fe0
	movk	x11, #0x2308, lsl #16	/* 0x23080fe0 */
	str	w7, [x11]
	mov	w7, #0x4248
	movk	w7, #0x2020, lsl #16
	str	w7, [x11, #4]
	str	x6, [x11, #8]
#endif
	dsb	sy

	mov	x16, xzr
	mov	sp, x16

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
