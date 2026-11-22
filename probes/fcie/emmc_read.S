/*
 * emmc_read.S -- pre-MMU entry shim for the boot-path CMD17 probe.
 *
 * Patched over code1, so it runs straight from mboot's handoff with the MMU
 * and caches off, before anything else touches the eMMC controller.  The
 * controller has just finished mboot's own mmc reads and the card is in TRAN;
 * this is the quietest possible moment to issue one CMD17.
 *
 *   x0 = 0 (LBA 0, user area) -> data at PA 0x23080000
 *                                heartbeat at 0x23080FE0 ("FCIE1", rc, R1, SD_STATUS)
 *                                record at 0x23090000 ("M764"/"EMMC", rc)
 *   then the staged factory kernel is copied down and entered, so Android
 *   boots and the three buffers can be read back with probeRW.
 *
 * READ ONLY.  No CMD24/CMD25/CMD38 anywhere.
 */
	.text
	.globl	_start
_start:
	/* The C code clobbers x0..x5, and the factory kernel entry uses x2
	 * (it stores w2 into its boot_args).  Save what mboot handed over and
	 * put it back before the handover. */
	movz	x16, #0xaf00
	movk	x16, #0x230a, lsl #16	/* 0x230aff00, below the C stack frame */
	stp	x0, x1, [x16]
	stp	x2, x3, [x16, #16]
	stp	x4, x5, [x16, #32]

	/* fcie_probe_once() has a stack frame; this page is inside the mboot
	 * dtb read window, far above the payload (0x23080000) and the records. */
	movz	x16, #0x0000
	movk	x16, #0x230b, lsl #16	/* 0x230b0000 */
	mov	sp, x16
	mov	x0, xzr			/* LBA 0 */
	bl	fcie_probe_once

	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16	/* 0x23090000 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4d45
	movk	w7, #0x434d, lsl #16	/* "EMMC" */
	str	w7, [x6, #4]
	mov	w7, #0x20
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	str	x0, [x6, #16]		/* return code */
	dsb	sy

	/* Restore the boot registers the C code clobbered (x2 especially),
	 * drop the ramdisk arguments (x3/x4), and hand over with sp = 0 as
	 * measured. */
	movz	x16, #0xaf00
	movk	x16, #0x230a, lsl #16
	ldp	x0, x1, [x16]
	ldr	x2, [x16, #16]
	mov	w3, wzr
	mov	w4, wzr
	ldr	x5, [x16, #40]

	mov	x16, xzr
	mov	sp, x16

	/* handover: 0x30000800 -> 0x20280000, drop the ramdisk, enter vendor */
	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800
	movz	x7, #0x2028
	lsl	x7, x7, #16
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #0x10
	b.ne	1b
	dsb	sy

	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
