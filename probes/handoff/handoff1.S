/*
 * Handoff dump, rung 1: minimum-risk version.
 *
 * Same idea as handoff.S but stripped down to instructions that are proven to
 * work in this exact context -- paint3 already ran store-only code from the
 * same code1 slot and returned cleanly.  Everything new compared to paint3 is
 * listed here, so a hang is attributable:
 *
 *   - movz/movk/str     header + payload      (same class as paint3)
 *   - mov x7, sp        register read only, never faults
 *   - dsb sy            paint3 does this too
 *   - .word branch      identical to paint3
 *
 * Deliberately absent: dc cvac (by-VA maintenance with MMU off is
 * implementation-defined and can raise a data abort) and every mrs
 * (SCTLR/TTBR0/TCR/MAIR/CurrentEL/MPIDR/ID_AA64MMFR0/CNTFRQ).
 * Those come back one rung at a time once this one is known to return.
 *
 * Record layout, as fs/pstore/ram_core.c expects it:
 *
 *   +0x00 u32 sig   = 0x43474244 "DBGC"
 *   +0x04 u32 start = 0          no wrap, oldest byte first
 *   +0x08 u32 size  = 72         valid data bytes that follow
 *   +0x0c data[72]  = "M7642H1 " (8) + x0..x5, sp (7 * 8)
 */

	.equ	PAYLOAD, 72

	.text
	.globl	_start
_start:
	movz	x6, #0x419c
	lsl	x6, x6, #16			/* x6 = ZONE */
	movz	w7, #0x4244
	movk	w7, #0x4347, lsl #16		/* 0x43474244 "DBGC" */
	str	w7, [x6]
	str	wzr, [x6, #4]			/* start = 0 */
	mov	w7, #PAYLOAD
	str	w7, [x6, #8]			/* size = PAYLOAD */

	add	x6, x6, #12			/* data area */
	/* Little endian: the low half of each word lands first, so the stored
	 * bytes read "M764" then "2H1 ". */
	movz	w7, #0x374d
	movk	w7, #0x3634, lsl #16
	str	w7, [x6], #4
	movz	w7, #0x4832
	movk	w7, #0x2031, lsl #16
	str	w7, [x6], #4

	str	x0, [x6], #8
	str	x1, [x6], #8
	str	x2, [x6], #8
	str	x3, [x6], #8
	str	x4, [x6], #8
	str	x5, [x6], #8
	mov	x7, sp
	str	x7, [x6], #8

	dsb	sy

	/* Must be the last word: mk-boot-beacon.py patches it into `b 0xfa0000`
	 * and asserts this placeholder is still here. */
	.word	0x14000000
