/*
 * emmc_write.S -- code1 stub for the CMD24 write probe.
 *
 * Runs before the vendor stub, with the MMU and caches off, so every access is
 * physical.  Calls fcie_write_probe() (offline, never run yet) which:
 *   - reads the target block first and REFUSES unless it is uniformly 0x00/0xFF
 *     (so a mis-computed LBA cannot clobber real data),
 *   - writes a known pattern with each candidate direction encoding,
 *   - reads the block back with the verified CMD17 path and only accepts the
 *     candidate whose read-back matches.
 *
 * LBA comes from the build (-DLBA=...); the runner computes it from the device's
 * partition table.
 *
 *   0x23090000  "M764" "EMMCW" rc ctl_attempts lastrc orig_head
 *   0x230A0000  scratch (write source)
 *   0x230A0200  scratch (read-back target)
 */
#ifndef LBA
#define LBA 0
#endif
#ifndef FCIE_BASE
#define FCIE_BASE 0x1F222600
#endif
#ifndef BUF_PA
#define BUF_PA 0x230A0000
#endif

	.text
	.globl	_start
_start:
	movz	x16, #0x0000
	movk	x16, #0x230b, lsl #16	/* stack page, above the buffers */
	mov	sp, x16

	movz	x0, #(FCIE_BASE & 0xffff)
	movk	x0, #((FCIE_BASE >> 16) & 0xffff), lsl #16
	movz	x1, #(LBA & 0xffff)
	movk	x1, #((LBA >> 16) & 0xffff), lsl #16
	movz	x2, #(BUF_PA & 0xffff)
	movk	x2, #((BUF_PA >> 16) & 0xffff), lsl #16
	sub	x3, sp, #128		/* diag[4] on the stack */
	bl	fcie_write_probe

	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4545
	movk	w7, #0x5743, lsl #16	/* "EE" "CW" -> "EECW" */
	str	w7, [x6, #4]
	str	x0, [x6, #8]		/* rc */
	ldr	x9, [sp, #-128]		/* diag[0] = ctl that verified */
	str	x9, [x6, #16]
	ldr	x9, [sp, #-120]		/* diag[1] = last rc */
	str	x9, [x6, #24]
	ldr	x9, [sp, #-112]		/* diag[2] = candidates tried */
	str	x9, [x6, #32]
	ldr	x9, [sp, #-104]		/* diag[3] = original first 4 bytes */
	str	x9, [x6, #40]
	dsb	sy

	mov	x16, xzr
	mov	sp, x16

	/* handover: staged factory kernel -> runtime image, drop ramdisk args */
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
