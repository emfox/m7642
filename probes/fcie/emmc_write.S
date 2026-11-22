/*
 * emmc_write.S -- code1 stub for the CMD24 write probe.
 *
 * Runs before the vendor stub, MMU and caches off (CurrentEL=EL2, SCTLR_EL2.M=0,
 * measured), so every access is physical.  Calls fcie_write_probe() which reads
 * the target block first and refuses unless it is uniformly 0x00/0xFF, writes a
 * known pattern with the two-stage CMD24 the vendor source documents, then
 * verifies with the already-proven CMD17 path.
 *
 * Layout (all inside the 0x23000000..0x230FFFFF window mboot just filled):
 *   0x23090000  record: "M764" "EECW" rc diag[0..3]           (48 B)
 *   0x230A0000  write source block
 *   0x230A0200  read-back block
 *   0x230AFC00  diag[4] handed to C
 *   0x230AFF00  saved mboot x0..x5 (the factory entry reads them)
 *   0x230B0000  stack top
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
	/* Save what mboot handed us BEFORE we clobber the argument registers.
	 * The factory entry stores w2 into its boot_args, so these must be
	 * intact at the handover (same rule as emmc_read.S). */
	movz	x9, #0xff00
	movk	x9, #0x230a, lsl #16	/* 0x230AFF00 */
	stp	x0, x1, [x9]
	stp	x2, x3, [x9, #16]
	stp	x4, x5, [x9, #32]

	movz	x16, #0x0000
	movk	x16, #0x230b, lsl #16
	mov	sp, x16

	movz	x0, #(FCIE_BASE & 0xffff)
	movk	x0, #((FCIE_BASE >> 16) & 0xffff), lsl #16
	movz	x1, #(LBA & 0xffff)
	movk	x1, #((LBA >> 16) & 0xffff), lsl #16
	movz	x2, #(BUF_PA & 0xffff)
	movk	x2, #((BUF_PA >> 16) & 0xffff), lsl #16
	movz	x3, #0xfc00
	movk	x3, #0x230a, lsl #16	/* diag[] at 0x230AFC00, off the stack */
	bl	fcie_write_probe

	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4345
	movk	w7, #0x5743, lsl #16	/* "ECW" -> tag "EECW" */
	str	w7, [x6, #4]
	str	w0, [x6, #8]		/* rc (int return value) */
	movz	x9, #0xfc00
	movk	x9, #0x230a, lsl #16
	ldp	x10, x11, [x9]		/* diag[0], diag[1] */
	stp	x10, x11, [x6, #16]
	ldp	x10, x11, [x9, #16]	/* diag[2], diag[3] */
	stp	x10, x11, [x6, #32]
	dsb	sy

	/* Restore mboot's argument registers, drop the stack, hand over. */
	movz	x9, #0xff00
	movk	x9, #0x230a, lsl #16
	ldp	x0, x1, [x9]
	ldp	x2, x3, [x9, #16]
	ldp	x4, x5, [x9, #32]
	mov	x16, xzr
	mov	sp, x16

	/* staged factory kernel 0x30000800 -> runtime image 0x20280000 */
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
