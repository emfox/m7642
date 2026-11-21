/*
 * Handover stub for checkpoints AFTER the MMU is on.
 *
 * The kernel's own idmap covers .idmap.text (VA == PA, 0x206d5000..0x206d58e4),
 * so: copy a small "MMU-off handover" routine into that page, flush it to PoC,
 * jump to its idmap VA, then turn the MMU and caches off and do the handover
 * with physical addresses.  The 7.3 kernel executes nothing after that -- this
 * is the abort path, not a continuation, so switching the MMU off here cannot
 * break any later kernel code.
 */
	.text
	.globl	_start
_start:
	/* destination: same physical page, via the linear map (writable) */
	movz	x16, #0x5000
	movk	x16, #0x004d, lsl #16
	movk	x16, #0xffc0, lsl #32
	movk	x16, #0xffff, lsl #48		/* x16 = 0xffffffc0004d5000 */
	adr	x17, off_routine
	mov	x18, #(off_end - off_routine)
1:
	ldrb	w19, [x17], #1
	strb	w19, [x16], #1
	subs	x18, x18, #1
	b.ne	1b
	/* make the copy visible to fetch: clean to PoC, invalidate icache */
	movz	x16, #0x5000
	movk	x16, #0x004d, lsl #16
	movk	x16, #0xffc0, lsl #32
	movk	x16, #0xffff, lsl #48
	mov	x17, x16
	add	x17, x17, #(off_end - off_routine)
2:
	dc	civac, x16
	add	x16, x16, #64
	cmp	x16, x17
	b.lo	2b
	dsb	sy
	ic	iallu
	dsb	sy
	isb
	/* jump into the idmap page (VA == PA) */
	movz	x16, #0x5000
	movk	x16, #0x206d, lsl #16
	br	x16

/* ---- runs at 0x206d5000 with the MMU on, then turns it off ---- */
	.balign	4
off_routine:
	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M = 0: MMU off */
	bic	x16, x16, #4		/* C = 0: data cache off */
	bic	x16, x16, #0x1000	/* I = 0: instruction cache off */
	msr	sctlr_el1, x16
	isb
	/* physical addressing, caches off from here on */
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16
	str	w7, [x6]		/* "M764" */
	movz	w7, #0x4d4d
	movk	w7, #0x554d, lsl #16
	str	w7, [x6, #4]		/* "MMMU" = post-MMU rung */
	mov	w7, #0x40
	str	w7, [x6, #8]
	dsb	sy
	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800
	movz	x7, #0x2028
	lsl	x7, x7, #16
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16
3:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #16
	b.ne	3b
	dsb	sy
	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
off_end:
	.word	0
