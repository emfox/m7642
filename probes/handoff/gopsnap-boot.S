/*
 * Boot-time snapshot of the same 128 GOP registers that gopsnap.sh reads from a
 * running Android: 8 banks x 4 windows x (CTRL, STR_L, STR_H, STR_EX).
 *
 * Each bank's win0..win3 sit at consecutive 0x40-byte steps, so a bank is 16
 * consecutive 16-bit registers (32 bytes) starting at CTRL.  Bank b goes to
 * stash page b (64 KB apart), stored as one 32-bit word per register.
 *
 * Comparing this with the Android-time dump shows exactly which registers the
 * vendor kernel flips to take the panel from the boot logo to the fb, which is
 * what a probe has to reproduce to make anything visible.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16			/* stash page 0 */
	movz	x12, #0x1f24
	lsl	x12, x12, #16
	add	x12, x12, #0x400		/* 0x1f240400, bank0 CTRL */
	.rept	8
	.set	R, 0
	.rept	16
	ldrh	w13, [x12, #(R*2)]
	str	w13, [x6, #(R*4)]
	.set	R, R+1
	.endr
	add	x12, x12, #0x200
	add	x6, x6, #0x10000
	.endr
	dsb	sy
	.word	0x14000000			/* patched to b 0xfa0000 */
