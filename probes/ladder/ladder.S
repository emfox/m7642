/*
 * Entry ladder, one rung.
 *
 * Assembled twice with different COLOUR/STEP so a single boot reports two
 * independent facts on the panel:
 *
 *   +0x600000  blue  -- the bootloader honoured code1 and started the image
 *   +0xF9FF00  yellow -- the bootloader instead started the image at +0xFA0000
 *
 * Each rung then branches to primary_entry, whose own beacon paints
 * white -> red -> green -> blue -> yellow -> magenta, and a few extra
 * checkpoints in between.  The colour left on the panel names the furthest
 * checkpoint reached:
 *
 *   blue / yellow image entered, primary_entry never painted
 *   white         primary_entry reached
 *   red           record_mmu_state returned
 *   green         preserve_boot_args returned
 *   blue          __pi_create_init_idmap returned
 *   yellow        init_kernel_el returned
 *   magenta       __cpu_setup returned
 *
 * STEP is not a free parameter: it is 1 in the blue rung and 2 in the yellow
 * one, so the number of black bars also says which rung ran.  Treat that as a
 * weak hint only.  Bars have come out shredded into vertical crumbs on this
 * panel before (a 100x32 white bar did, 2026-11-18), which is consistent with
 * a tiled framebuffer layout.  No bar visible therefore does NOT mean the rung
 * did not run -- only a flat full-screen colour is a usable reading.
 *
 * The exact checkpoint list of a given build is whatever ended up in the
 * image; read it back with objdump rather than trusting head.S.  On
 * 2026-11-19 the source and the image disagreed, and the source was wrong.
 *
 * Colours are 16-bit RGB565 duplicated into both halves of a 32-bit word,
 * which is what the panel scanned on the one run that produced a clean
 * full-screen colour.
 *
 * The 2026-11-19 run came out as magenta/blue vertical bars instead.  Reading
 * the GOP block in a running Android showed exactly one enabled window, so the
 * bars were not two layers competing: only the address had been steered, not
 * the control word.  The control word carries the pixel format in bits[7:4]
 * (1 = RGB565, 5 = ARGB8888, per E_GOP_COLOR_* in apiGOP.h) and the enable in
 * bit 0.  Feeding RGB565 data to a window still configured for 32bpp turns
 * 0x001f001f into A=0 R=1f B=1f, i.e. magenta -- exactly what was on screen.
 *
 * So this version programs the control word as well, and additionally encodes
 * STEP as STEP black vertical bars: a count survives any colour
 * misinterpretation, a hue does not.
 *
 * Only x7..x19 are touched.  x0..x5 carry the bootloader's handover state
 * (x0 is the DTB pointer) and must reach primary_entry unchanged -- the
 * earlier entry probe used x0..x2 as fill registers and destroyed it.
 *
 * No stack and no calls, and nothing is written except the framebuffer and
 * one scratch word in the DRAM hole, because this runs before either exists.
 */

	.section .text, "ax"
	.global _start
_start:
	/*
	 * --- steer GOP0's eight windows at 0x2d100000, and force window 0's
	 *     control word to RGB565 + enabled ---
	 *
	 * 0x1f240600 is the control word of gop0/bank1/win0; its address triple
	 * (STR_L/H/EX) follows at +4/+8/+12, and each further window sits 0x40
	 * bytes on.  Bits[7:4] hold E_GOP_COLOR_* and bit 0 is the enable.
	 */
	movz	x7, #0x0600
	movk	x7, #0x1f24, lsl #16		// 0x1f240600: gop0/bank1/win0 CTRL
	ldrh	w16, [x7]
	bic	w16, w16, #0xf0			// drop the format nibble
	orr	w16, w16, #0x10			// bits[7:4] = 1, E_GOP_COLOR_RGB565
	orr	w16, w16, #0x01			// bit 0 = enable
	strh	w16, [x7]
	/*
	 * Read-modify-write on purpose, even though m7642-dtb.S warns against it.
	 * That warning is unverified: it names an "earlier version" of the beacon
	 * that did this, but the images from all four real flashes contain no such
	 * code, so the claim explains nothing that was actually observed.  There is
	 * also only one GOP dump in artifacts/, so "these registers do not read
	 * back what was written" has no measurement behind it either.
	 *
	 * Given that, RMW is the safer of the two: it preserves whatever bits of
	 * the control word mean something we have not decoded, whereas writing a
	 * fixed 0x4011 would clobber them on the strength of a guess.  Change this
	 * only with a snapshot comparison that shows the read is unstable.
	 */

	movz	w8, #0x2d10			// HI16BIT(0x2d100000)
	mov	x9, xzr				// LO16BIT and EX stay zero
	add	x7, x7, #4			// -> STR_L of window 0
	mov	x10, #8
1:
	strh	w9, [x7]			// STR_L
	strh	w8, [x7, #4]			// STR_H
	strh	w9, [x7, #8]			// STR_EX
	add	x7, x7, #0x40			// next window, stride measured, not 0x80
	subs	x10, x10, #1
	b.ne	1b

	/*
	 * --- disable every other window group ---
	 *
	 * A probeS snapshot of the running Android showed four enabled windows:
	 * the main one (bank1: ARGB8888, 1920x1080, scanning 0x2f100000) and
	 * three RGB565 layers at banks 5, 8 and 12.  The steer above only
	 * rewrites the eight windows inside the bank1 group, so those three
	 * keep scanning their own buffers and sit on top of our colour.
	 *
	 * Two formats reading overlapping memory is what made the panel look
	 * shredded: 0x07ff07ff is magenta as ARGB8888 and two cyan pixels as
	 * RGB565.  Clearing bit 0 of each group's control word removes them.
	 * bank1 is skipped because that is the window we want to keep.
	 *
	 * Each bank is 0x200 bytes and its control word sits at the start, so
	 * bank0 is at 0x1f240400 and bank1 at 0x1f240600 -- the latter is the
	 * address this file already used for win0's control word, which is what
	 * pins the whole layout down.
	 */
	movz	x8, #0x0400
	movk	x8, #0x1f24, lsl #16		// 0x1f240400: bank0 control word
	movz	x13, #0x0600
	movk	x13, #0x1f24, lsl #16		// 0x1f240600: bank1, keep this one
	mov	x7, x8
	mov	x10, #16
20:
	cmp	x7, x13
	b.eq	21f
	ldrh	w12, [x7]
	tbz	w12, #0, 21f			// already disabled
	bic	w12, w12, #0x01
	strh	w12, [x7]
21:
	add	x7, x7, #0x200
	subs	x10, x10, #1
	b.ne	20b

	/* --- commit: pulse GOP_FWR, or the writes above are dropped silently --- */
	movz	x11, #0x07fc
	movk	x11, #0x1f24, lsl #16		// 0x1f2407fc: gop0/bank1 BANK_SEL
	ldrh	w12, [x11]
	orr	w12, w12, #0x0200
	strh	w12, [x11]
	ldrh	w12, [x11]
	bic	w12, w12, #0x0200
	strh	w12, [x11]

	/*
	 * --- flood the whole 1920x1080 buffer ---
	 *
	 * COLOUR is a 16-bit RGB565 value and the panel scans this buffer at
	 * 16bpp, so the value has to go into both halves of every word -- this is
	 * exactly what m7642_fill() in the kernel does.  Writing a 32-bit ARGB
	 * colour here instead puts two different pixels in each word, which the
	 * panel renders as a one-pixel vertical stripe pattern; that is
	 * indistinguishable from the bootloader's own mangled logo and would
	 * silently turn the whole ladder into "image never entered".
	 *
	 * movz/movk also give a compile-time guard: a 32-bit COLOUR is out of
	 * imm16 range and fails the build instead of failing on the panel.
	 */
	movz	w15, #COLOUR
	movk	w15, #COLOUR, lsl #16
	movz	x13, #0x2d10
	lsl	x13, x13, #16			// 0x2d100000
	movz	x14, #0x7e9
	lsl	x14, x14, #12			// 0x7e9000
	add	x14, x13, x14
2:
	str	w15, [x13], #4
	cmp	x13, x14
	b.lo	2b
	dsb	sy

	/*
	 * --- push the fill out of the D-cache ---
	 *
	 * dsb sy orders the stores but does not write them back.  If the MMU is
	 * on and this range is cached write-back, the fill sits in the cache and
	 * the panel -- which scans DDR -- never sees it.  That failure mode
	 * looks exactly like what white-halt produced on 2026-11-20: ~225 evenly
	 * spaced white dots on an otherwise magenta screen, i.e. only the few
	 * lines the cache happened to evict.
	 *
	 * dc cvac is a NOP when the D-cache is disabled, so this costs nothing
	 * on a boot where the cache was already off and the write went straight
	 * to DDR.  That keeps it a single-variable test:
	 *   whole screen turns white -> the fill had been trapped in the cache
	 *   still only dots          -> the write never reached DDR, or nothing
	 *                               scans this address; the cause is
	 *                               elsewhere (address/stride/tile layout)
	 */
	mrs	x16, ctr_el0
	ubfx	x16, x16, #16, #4		// CTR_EL0.DminLine
	mov	w17, #4
	lsl	w17, w17, w16			// cache line size in bytes
	movz	x15, #0x2d10
	lsl	x15, x15, #16			// back to the first byte of the fill
12:
	dc	cvac, x15
	add	x15, x15, x17
	cmp	x15, x14
	b.lo	12b
	dsb	sy

	/*
	 * HALT=1 ends the rung here instead of handing over to primary_entry.
	 *
	 * The one question left is whether the fill above reaches the panel at
	 * all.  On 2026-11-19 the last screen was a flat periwinkle with sixteen
	 * evenly spaced noisy bands -- a uniform fill cannot produce bands under
	 * any addressing or format permutation, and no colour this rung or any
	 * checkpoint can emit matches it, so either the fill never landed or
	 * something else is scanning.  Stopping before the handover separates
	 * those two cases: nothing later can overwrite what we painted.
	 */
#if HALT
10:	b	10b
#endif

	/*
	 * --- punch STEP black bars, 40px wide, every 160px from x=120 ---
	 *
	 * The bars are the screen-free part of the reading: a count survives any
	 * colour misinterpretation, a hue does not.  The fill value is 0xff000000
	 * for exactly that reason -- it is black both as RGB565 (low half zero) and
	 * as ARGB8888 (alpha ff, all channels zero), so the bars stay visible even
	 * if the control word ends up meaning 32bpp after all.
	 */
	mov	w18, #STEP
	cbz	w18, 9f
	movz	x13, #0x2d10
	lsl	x13, x13, #16			// back to the start of the buffer
	mov	x14, x13			// pointer to the current row
	movz	x19, #0x1e00			// 1920 pixels * 4 bytes
	mov	w17, #0x438			// 1080 rows
	movz	w9, #0xff00
	lsl	w9, w9, #16			// 0xff000000: black read as RGB565 (low half
						// 0) and as ARGB8888 (A=ff), so the bar count
						// survives a scanout format mismatch
3:
	mov	w16, w18			// bars left in this row
	movz	x11, #480			// x = 120px * 4
	add	x15, x14, x11
4:
	mov	w10, #40			// 40 pixels wide
5:
	str	w9, [x15], #4
	subs	w10, w10, #1
	b.ne	5b
	movz	x11, #480			// 640 - 160: gap to the next bar
	add	x15, x15, x11
	subs	w16, w16, #1
	b.ne	4b
	add	x14, x14, x19
	subs	w17, w17, #1
	b.ne	3b
	dsb	sy
9:

	/*
	 * --- screen-free copy of the same fact, parked in DDR ---
	 *
	 * 0x419A0000 is the middle of the ramoops console data area (ramoops mem
	 * is 0x41900000, measured from /sys/module/ramoops/parameters; two 256K
	 * dump zones, then the 256K console zone at +0x80000).  Writing into the
	 * console *header* does not survive: a kernel that reaches its own
	 * ramoops probe validates the signature, copies the buffer into kmalloc
	 * and zaps start/size, so Android then finds an empty buffer and exports
	 * nothing.  +0x20000 sits past the header and past the 8K of console
	 * text a boot actually produces, so only a DDR wipe can erase it.
	 */
	movz	w19, #STEP
	cmp	w19, #3
	b.eq	11f			// rung 3 has the MMU on; this PA is outside
					// the init idmap, so a store would fault
	movz	x16, #0x419A
	lsl	x16, x16, #16
	movz	w17, #0x3634
	movk	w17, #0x4d37, lsl #16	// "M764"
	str	w17, [x16]
	str	w19, [x16, #4]		// STEP
	mvn	w18, w19
	str	w18, [x16, #8]		// complement, so a stale word is visible
	movz	w17, #0x3645
	movk	w17, #0x4d37, lsl #16	// "M76E"
	str	w17, [x16, #12]
	dsb	sy

#if HOLD
	/*
	 * Keep the fill on screen for HOLD seconds, then fall through and hand
	 * control back.  Needed on the boot slot: there an immediate return would
	 * be overwritten by Android before anyone could look, and a freeze would
	 * leave boot broken with no WDT on that path.  CNTFRQ/CNTVCT are system
	 * registers, readable from EL1 without touching memory, so this cannot
	 * fault -- unlike a fixed-iteration spin, whose duration would be a guess.
	 */
	mrs	x11, CNTFRQ_EL0
	mrs	x12, CNTVCT_EL0
	mov	x13, #HOLD
	madd	x13, x11, x13, x12	// deadline = now + HOLD * frequency
12:	mrs	x12, CNTVCT_EL0
	cmp	x12, x13
	b.lo	12b
#endif

#if FREEZE
11:	b	11b			// hold here so the WDT fires.  A warm
					// reset keeps DDR; handing control back
					// to mboot lands in standby, which cuts
					// power and loses the mark.
#else
11:
#endif

	/* patched by mk-ladder.py: b primary_entry */
	.word	0x14000000
	.word	0x4d373645			// "M76E", end of blob
