/*
 * Entry trampoline for +0xFA0000.
 *
 * probe-entry2 put an identical blob at +0x600000 and +0xFA0000 and the panel
 * turned solid, while the same code inside primary_entry (+0x429038) never
 * showed at all.  So the bootloader does not start the image at +0 -- it starts
 * it where the vendor image keeps its chip-check stub, +0xFA0000.
 *
 * Everything placed at +0 in every earlier attempt was therefore dead code.
 *
 * This blob: steer GOP0's windows, commit with GOP_FWR, flood cyan, hold two
 * seconds (so the colour is readable even if what follows dies), then jump back
 * to primary_entry and let the kernel run for real.
 *
 * The final 'b' is patched in afterwards: its displacement depends on where
 * this blob ends up, so the assembler cannot fill it in.
 */

	.section .text, "ax"
	.global _start
_start:
	movz	x3, #0x0604
	movk	x3, #0x1f24, lsl #16		// 0x1f240604: gop0/bank1/win0 STR_L
	movz	w4, #0x2d10			// HI16BIT(0x2d100000)
	mov	x5, xzr
	mov	x6, #8
1:
	strh	w5, [x3]
	strh	w4, [x3, #4]
	strh	w5, [x3, #8]
	add	x3, x3, #0x40
	subs	x6, x6, #1
	b.ne	1b

	movz	x13, #0x07fc
	movk	x13, #0x1f24, lsl #16		// gop0/bank1 BANK_SEL
	ldrh	w15, [x13]
	orr	w15, w15, #0x0200		// GOP_FWR
	strh	w15, [x13]
	ldrh	w15, [x13]
	bic	w15, w15, #0x0200
	strh	w15, [x13]

	mov	x0, #0x2d10
	lsl	x0, x0, #16
	movz	w1, #0x0000
	movk	w1, #0xffff, lsl #16		// 0xffff0000
	movz	x2, #0x7e9
	lsl	x2, x2, #12
	add	x2, x0, x2
2:
	str	w1, [x0], #4
	cmp	x0, x2
	b.lo	2b
	dsb	sy

	/* hold so the colour is readable even if the kernel dies right after */
	mrs	x6, cntfrq_el0
	add	x6, x6, x6			// 2 s
	mrs	x7, cntvct_el0
	add	x6, x6, x7
3:
	mrs	x7, cntvct_el0
	cmp	x7, x6
	b.lo	3b

	/* patched: b primary_entry */
	.word	0
