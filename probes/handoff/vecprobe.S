/*
 * Early exception-vector probe.
 *
 * The kernel reaches 0x465e78 and never 0x465e80, and every memory access in
 * between is statically safe.  The one class of cause left is an exception:
 * this early, VBAR_EL2 still holds whatever mboot left, so any fault quietly
 * flies off into garbage and looks like a hang.
 *
 * So: install our own table at EL2/EL1, record the syndrome and faulting
 * address, and hand over to the staged factory kernel so the record is readable
 * in the same boot.  x16/x17 are scratch by ABI and we are aborting anyway, so
 * the handler touches no stack (SP may be the thing that broke).
 */
	.text
	.globl	_start
_start:
	movz	x9, #0x2168
	lsl	x9, x9, #16
	add	x9, x9, #0x1000		/* table at 0x21681000 */
	msr	vbar_el2, x9
	msr	vbar_el1, x9
	isb
	movz	x9, #0x206d
	lsl	x9, x9, #16
	movz	x10, #0x5038
	add	x9, x9, x10		/* 7.3 primary_entry = 0x206d5038 */
	br	x9

	/* --- common handler: x9 = vector class index --- */
	.align	7
handler:
	movz	x16, #0x2308
	lsl	x16, x16, #16
	movz	w17, #0x374d
	movk	w17, #0x3436, lsl #16		/* "M764" */
	str	w17, [x16]
	movz	w17, #0x5845
	movk	w17, #0x5043, lsl #16		/* "EXCP" */
	str	w17, [x16, #4]
	str	w9, [x16, #8]			/* vector index */
	mrs	x17, esr_el2
	str	x17, [x16, #16]			/* syndrome */
	mrs	x17, elr_el2
	str	x17, [x16, #24]			/* faulting PC */
	mrs	x17, far_el2
	str	x17, [x16, #32]			/* faulting address */
	mrs	x17, spsr_el2
	str	x17, [x16, #40]
	dsb	sy
	/* hand over to the staged factory kernel */
	movz	x16, #0x3000
	lsl	x16, x16, #16
	add	x16, x16, #0x800
	movz	x17, #0x2028
	lsl	x17, x17, #16
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16
1:
	ldp	x9, x10, [x16], #16
	stp	x9, x10, [x17], #16
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy
	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9

	/* --- vector table at blob offset 0x1000 --- */
	.org	0x1000
	.set	V, 0
	.rept	16
	movz	x9, #V
	b	handler
	.set	V, V+1
	.balign	0x80
	.endr
