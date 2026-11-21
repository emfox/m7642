/*
 * Report the boot-time GOP window state to the stash pages.
 *
 * The panel is not scanning 0x2d100000 during boot (a solid fill there is
 * invisible), and the register values seen from a running Android change every
 * frame, so the only useful reading is the one taken here, before any kernel
 * runs.  For each of the eight banks store CTRL + the address triple of win0
 * (STR_L = low 16 bits, STR_H = high 16 bits, STR_EX = extension).
 *
 * Page layout: +0x00 "M764", +0x04 CTRL, +0x08 STR_L, +0x0c STR_H, +0x10 STR_EX
 * Page k holds bank k, 64 KB apart, exactly like the handoff probes.
 *
 * Instruction classes: movz/movk/lsl/add/str/ldrh/dsb -- all already proven in
 * this slot; MMIO *reads* are safe on this SoC (only writes can wedge the bus).
 */
	.equ	BANKS, 8

	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16			/* stash page 0 */
	movz	x11, #0x1f24
	lsl	x11, x11, #16
	add	x11, x11, #0x400		/* 0x1f240400 = bank0 CTRL */
	mov	x12, x11
	movz	w10, #0x374d
	movk	w10, #0x3436, lsl #16		/* "M764" */
	.rept	BANKS
	str	w10, [x6]
	ldrh	w13, [x12]
	str	w13, [x6, #4]
	ldrh	w13, [x12, #4]
	str	w13, [x6, #8]
	ldrh	w13, [x12, #8]
	str	w13, [x6, #12]
	ldrh	w13, [x12, #12]
	str	w13, [x6, #16]
	add	x12, x12, #0x200
	add	x6, x6, #0x10000
	.endr
	dsb	sy
	.word	0x14000000			/* patched to b 0xfa0000 */
