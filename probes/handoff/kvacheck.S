/*
 * kvacheck.S -- at __primary_switch's `br x8` (checkpoint 0x4555b0), record the
 * branch target and probe the kernel VA from this exact context.
 *
 *   x8 is the literal that `ldr x8, [pc]` just loaded, i.e. the address the
 *   kernel is about to jump to.  Then:
 *
 *   0x23090000  [0] x8
 *               [1] *(u64 *)0xffffffc080000000   (_text, kernel VA)
 *               [2] *x8                          (the branch target)
 *               [3] *(u64 *)0xffffffc08036c000   (the tramp page, kernel VA)
 *   0x23090800  "M764"/"KVA "
 *
 * Then the usual post-MMU handover: restore x0..x2 from boot_args, clear the
 * dirty cache lines over the image, turn the MMU/caches off, jump to the
 * physical handover.
 */
#ifndef BOOT_ARGS_PA
#define BOOT_ARGS_PA 0x207d4000
#endif
#ifndef IMAGE_START_PA
#define IMAGE_START_PA 0x20290000
#endif
#ifndef IMAGE_END_PA
#define IMAGE_END_PA 0x208f0000
#endif

	.text
	.globl	_start
_start:
	b	1f
	.org	0x20
1:
	/* record x8 and probe the kernel VA (MMU on, D-cache on) */
	movz	x4, #0x0000
	movk	x4, #0x2309, lsl #16
	str	x8, [x4, #0]

	movz	x10, #0x0000
	movk	x10, #0x8000, lsl #16
	movk	x10, #0xffc0, lsl #32
	movk	x10, #0xffff, lsl #48	/* 0xffffffc080000000 */
	ldr	x11, [x10]
	str	x11, [x4, #8]

	cbnz	x8, 2f
	mov	x12, #0xdead
	str	x12, [x4, #16]
	b	3f
2:
	ldr	x12, [x8]
	str	x12, [x4, #16]
3:
	movz	x13, #0xc000
	movk	x13, #0x8036, lsl #16
	movk	x13, #0xffc0, lsl #32
	movk	x13, #0xffff, lsl #48	/* 0xffffffc08036c000 */
	ldr	x14, [x13]
	str	x14, [x4, #24]

	movz	x6, #0x0800
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16
	str	w7, [x6]
	movz	w7, #0x564b
	movk	w7, #0x2041, lsl #16	/* "KVA " */
	str	w7, [x6, #4]
	mov	w7, #4
	str	w7, [x6, #8]
	str	wzr, [x6, #12]

	/* handover: x0..x2 from boot_args, x3/x4 = 0 */
	movz	x16, #(BOOT_ARGS_PA & 0xffff)
	movk	x16, #((BOOT_ARGS_PA >> 16) & 0xffff), lsl #16
	ldp	x0, x1, [x16]
	ldr	x2, [x16, #16]
	mov	x3, xzr
	mov	x4, xzr

	movz	x19, #(IMAGE_START_PA & 0xffff)
	movk	x19, #((IMAGE_START_PA >> 16) & 0xffff), lsl #16
	movz	x20, #(IMAGE_END_PA & 0xffff)
	movk	x20, #((IMAGE_END_PA >> 16) & 0xffff), lsl #16
4:
	dc	civac, x19
	add	x19, x19, #64
	cmp	x19, x20
	b.lo	4b
	dsb	sy
	ic	iallu
	dsb	sy
	isb

	mov	x16, xzr
	mov	sp, x16
	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M */
	bic	x16, x16, #4		/* C */
	bic	x16, x16, #0x1000	/* I */
	msr	sctlr_el1, x16
	isb
	movz	x16, #0x2168
	lsl	x16, x16, #16
	add	x16, x16, #0x200
	br	x16
