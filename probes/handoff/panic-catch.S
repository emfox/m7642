/*
 * Panic catcher: record panic(fmt, ...) and hand over, so the message is
 * readable in the same boot.
 *
 * The hang has no exception and the kernel gets past __enable_mmu, so an early
 * panic() with no console yet is the best remaining explanation.  panic is
 * noreturn and takes (const char *fmt, ...), so x0..x7 hold the format string
 * and its arguments.  The format string lives in the kernel's rodata, which the
 * handover copy overwrites, so 96 bytes of it are copied into the stash first.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x414e
	movk	w7, #0x4350, lsl #16		/* "PANC" */
	str	w7, [x6, #4]
	str	x0, [x6, #0x10]
	str	x1, [x6, #0x18]
	str	x2, [x6, #0x20]
	str	x3, [x6, #0x28]
	str	x4, [x6, #0x30]
	str	x5, [x6, #0x38]
	str	x6, [x6, #0x40]
	str	x7, [x6, #0x48]

	mov	x9, x0				/* fmt */
	add	x11, x6, #0x60
	mov	x10, #96
1:
	ldrb	w12, [x9], #1
	strb	w12, [x11], #1
	subs	x10, x10, #1
	b.ne	1b
	dsb	sy

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
	subs	x8, x8, #16
	b.ne	2b
	dsb	sy
	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
