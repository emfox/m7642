/*
 * cpathmin.S -- call one tiny compiled function at code1.
 *   0x23090000: "M764"/"CMIN", 0x40, 0, result (expect 0x42)
 */
	.text
	.globl	_start
_start:
	movz	x16, #0x0000
	movk	x16, #0x230b, lsl #16
	mov	sp, x16
	bl	cpath_entry
	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4e43
	movk	w7, #0x204d, lsl #16	/* "CMIN" */
	str	w7, [x6, #4]
	mov	w7, #0x40
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	str	x0, [x6, #16]
	dsb	sy
	mov	x16, xzr
	mov	sp, x16

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
