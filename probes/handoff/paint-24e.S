/*
 * Fill the boot-stage scanout buffer the GOP actually points at.
 *
 * The boot-time GOP dump (gopstash) shows bank7/win0 = 0x24e00000, CTRL 0x0091
 * (enabled), while 0x2d100000 is only what the *kernel* is handed later -- a
 * fill there is invisible during boot.  So paint 0x24e00000 instead, 8 MiB of
 * it, then return to the factory entry as usual.
 *
 * No GOP register is written; the panel reads only the low 16 bits of each
 * 32-bit word, so 0x07e0 is pure green.
 */
	.equ	COLOUR, 0x07e0
	.equ	WORDS,  0x200000

	.text
	.globl	_start
_start:
	movz	x6, #0x24e0
	lsl	x6, x6, #16			/* x6 = 0x24e00000 */
	movz	w7, #COLOUR
	movz	x8, #0x1000
	lsl	x8, x8, #9			/* 0x200000 words */
1:
	str	w7, [x6], #4
	subs	x8, x8, #1
	b.ne	1b
	dsb	sy
	.word	0x14000000			/* patched to b 0xfa0000 */
