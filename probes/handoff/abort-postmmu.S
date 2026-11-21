/*
 * Handover stub for checkpoints AFTER the MMU is on.
 *
 * The stub blob lives at PA 0x21680000 (Image +0x1400000), which is OUTSIDE the
 * region the handover copies into (0x20280000..0x21554a00) -- so the physical
 * handover code must run there, not from the idmap page.
 *
 *   1. (post-MMU entry, kernel VA) copy a tiny routine into the physical page
 *      0x206d5000 through the LINEAR map (writable) -- the idmap alias of that
 *      page is read-only after the switch, so writing via the idmap VA faults.
 *   2. flush it (clean to PoC + ic iallu) and jump to its idmap VA (VA == PA).
 *   3. routine turns the MMU and caches off, then jumps to handover_phys
 *      (0x21680200) which -- now running with physical addressing and caches
 *      off -- records the checkpoint, copies the staged factory kernel down,
 *      drops the ramdisk args and enters the factory kernel.
 *
 * The 7.3 kernel executes nothing after this: it is the abort path.
 */
	.text
	.globl	_start
_start:
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
	movz	x16, #0x5000
	movk	x16, #0x206d, lsl #16		/* idmap VA == PA */
	br	x16

off_routine:
	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M = 0: MMU off */
	bic	x16, x16, #4		/* C = 0: data cache off */
	bic	x16, x16, #0x1000	/* I = 0: instruction cache off */
	msr	sctlr_el1, x16
	isb
	movz	x16, #0x2168
	lsl	x16, x16, #16
	add	x16, x16, #0x200	/* handover_phys, outside the copy range */
	br	x16
off_end:

	.org	0x200
handover_phys:
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4d4d
	movk	w7, #0x554d, lsl #16		/* "MMMU" */
	str	w7, [x6, #4]
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
