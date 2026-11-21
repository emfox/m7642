/*
 * Record the CPU state at the handoff (and whether the staging worked), then
 * hand over to the staged factory kernel as usual.
 *
 * The point is the cache question: if SCTLR_EL2.C is set while .M is clear, the
 * kernel runs with caches on and the MMU off, which makes cache maintenance by
 * VA undefined -- and that would explain both the early hang and why the same
 * image behaves differently from run to run.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x5453
	movk	w7, #0x5045, lsl #16		/* "STEP" */
	str	w7, [x6, #4]
	mov	w7, #0x30
	str	w7, [x6, #8]

	mrs	x9, CurrentEL
	str	x9, [x6, #16]
	mrs	x9, SCTLR_EL2
	str	x9, [x6, #24]
	mrs	x9, SCTLR_EL1
	str	x9, [x6, #32]
	mrs	x9, CPACR_EL1
	str	x9, [x6, #40]
	mrs	x9, TCR_EL1
	str	x9, [x6, #48]
	mrs	x9, MIDR_EL1
	str	x9, [x6, #56]
	mrs	x9, MPIDR_EL1
	str	x9, [x6, #64]

	/* did mboot actually stage the factory image? */
	movz	x9, #0x3000
	lsl	x9, x9, #16
	ldr	w10, [x9]
	str	w10, [x6, #72]			/* expect 0x21444e41 "ANDROID!" */
	ldr	w10, [x9, #8]
	str	w10, [x6, #76]			/* expect 0x012d4a00 */
	dsb	sy

	/* handover: copy staged kernel down, drop ramdisk args, jump */
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
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy
	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
