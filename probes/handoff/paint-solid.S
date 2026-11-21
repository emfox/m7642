/*
 * Screen probe: flood the framebuffer with one solid colour, then hang.
 *
 * Deliberately touches NO GOP register (no 0x1f240600, no window steering, no
 * 0x1f2407fc commit).  The panel is already scanning 0x2d100000 -- that is the
 * same buffer Android's /dev/graphics/fb0 uses (smem_start=0x2d100000,
 * smem_len=8294400, bpp=32), so a plain fill is enough and nothing can be
 * left in a broken display state.
 *
 * The panel reads only the low 16 bits of each 32-bit word, so 0x07e0 shows as
 * pure green.
 */
	.equ	COLOUR, 0x07e0
	.equ	WORDS,  0x200000		/* 2 M words = 8 MiB, one full screen */

	.text
	.globl	_start
_start:
	movz	x6, #0x2d10
	lsl	x6, x6, #16			/* x6 = 0x2d100000 */
	movz	w7, #COLOUR
	movz	x8, #0x1000
	lsl	x8, x8, #9			/* x8 = 0x200000 words */
1:
	str	w7, [x6], #4
	subs	x8, x8, #1
	b.ne	1b
	dsb	sy
	/* last word: mk-boot-beacon.py --stay leaves it as `b .`, so the screen
	 * keeps showing the fill instead of being repainted by a booting kernel. */
	.word	0x14000000
