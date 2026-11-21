/*
 * Handoff dump, rung 2: write the handoff registers to plain DDR instead of
 * the ramoops pmsg zone.
 *
 * Why: the previous rungs wrote 0x419c0000, which sits in the memory hole just
 * past the end of the first DRAM region.  Every probe that touched it died,
 * and 0x419c0000 itself still reads 0xff, i.e. nothing was ever written there.
 * A store to plain DDR inside region 1 is the one write class already proven
 * from this exact code1 slot (confirmed-facts.md B: a 144 B rung wrote the FDT
 * /model and Android still came up), so this rung uses only that class.
 *
 * 0x23080000..0x230fffff is the upper half of the 1 MB dtb load region.  mboot
 * loads the 23 KB dtb blob at 0x23000000 and leaves the rest as zeros (read
 * back over probeRW while Android was up: all zero after 166 s).  The kernel
 * only reserves the blob itself, so these pages are free RAM and may or may
 * not survive until adb answers -- hence eight copies, 64 KB apart, and the
 * same record written to each.
 *
 * Record, 64 bytes per copy:
 *
 *   +0x00 u32 "M764"      marker, so a stale copy is not mistaken for a hit
 *   +0x04 u32 step = 2    which rung wrote it
 *   +0x08 u64 x0 ... x5   handoff registers
 *   +0x38 u64 sp
 *
 * Instruction classes: movz / movk / lsl / mov / str / add / dsb.  No mrs, no
 * dc cvac, no exception-vector setup.
 */

	.equ	PAGES, 8

	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16			/* x6 = 0x23080000 */
	movz	x9, #1
	lsl	x9, x9, #16			/* x9 = 0x10000, one page step */
	mov	x10, sp

	movz	w11, #0x374d
	movk	w11, #0x3436, lsl #16		/* 0x3436374d -> bytes "M764" */
	movz	w12, #2				/* step */

	.rept	PAGES
	str	w11, [x6]
	str	w12, [x6, #4]
	str	x0,  [x6, #8]
	str	x1,  [x6, #16]
	str	x2,  [x6, #24]
	str	x3,  [x6, #32]
	str	x4,  [x6, #40]
	str	x5,  [x6, #48]
	str	x10, [x6, #56]
	add	x6, x6, x9
	.endr

	dsb	sy

	/* Must be the last word: mk-boot-beacon.py patches it into `b 0xfa0000`
	 * and asserts this placeholder is still here. */
	.word	0x14000000
