/*
 * halt.S -- write a record, then spin forever.  Deliberately hangs.
 *
 * Purpose: prove the harness, not the kernel.  If recoverycmd is armed with
 * `wdt_enable 10`, a hang here must be followed by a watchdog warm reset and an
 * automatic return to Android in ~20-40 s -- no power key, no unplug.  The
 * record written *before* the spin must survive in DDR and be readable
 * afterwards with probeRW.
 *
 * Writes the record TWICE, because the fence matters:
 *   0x23090000  inside the dtb read window (0x23000000+0x100000) -> wiped by
 *               the next boot's `mmc read.p dtb`; kept as the control
 *   0x23100000  OUTSIDE that window; this is the one that must survive
 *   0x23100800  marker "M764"/"HANG"
 * Both are written before the spin.
 *
 * Entry: code1 (pre-MMU, caches off), so plain physical stores are safe.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4c48
	movk	w7, #0x5441, lsl #16	/* "HALT" */
	str	w7, [x6, #4]
	mov	w7, #0xdead
	str	w7, [x6, #8]
	str	wzr, [x6, #12]

	/* the same record, this time outside the dtb window */
	movz	x8, #0x0000
	movk	x8, #0x2310, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16
	str	w7, [x8]
	movz	w7, #0x4c48
	movk	w7, #0x5441, lsl #16
	str	w7, [x8, #4]
	mov	w7, #0xbeef
	str	w7, [x8, #8]
	str	wzr, [x8, #12]

	movz	x6, #0x0800
	movk	x6, #0x2310, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16
	str	w7, [x6]
	movz	w7, #0x4148
	movk	w7, #0x474e, lsl #16	/* "HANG" */
	str	w7, [x6, #4]
	mov	w7, #4
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	dsb	sy

1:	b	1b
