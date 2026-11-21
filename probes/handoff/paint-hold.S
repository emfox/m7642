/*
 * Screen probe, hold version: flood the framebuffer with a solid colour, spin
 * for a fixed count (roughly ten seconds) so a human can actually see it, then
 * fall through to the injected branch back to 0xfa0000.
 *
 * Same as paint-solid.S: no GOP register is touched, and the panel reads only
 * the low 16 bits of each 32-bit word, so 0x07e0 is pure green.
 */
	.equ	COLOUR, 0x07e0
	.equ	WORDS,  0x200000		/* 2 M words = 8 MiB */

	.text
	.globl	_start
_start:
	movz	x6, #0x2d10
	lsl	x6, x6, #16
	movz	w7, #COLOUR
	movz	x8, #0x1000
	lsl	x8, x8, #9
1:
	str	w7, [x6], #4
	subs	x8, x8, #1
	b.ne	1b
	dsb	sy

	/* ~10 s at ~1.5 GHz, 2 cycles per iteration: 0x200000000 = 8.6e9 */
	movz	x9, #0x0
	movk	x9, #0x0, lsl #16
	movk	x9, #0x0, lsl #32
	movk	x9, #0x2, lsl #48
2:
	subs	x9, x9, #1
	b.ne	2b
	dsb	sy
	.word	0x14000000			/* patched to b 0xfa0000 */
