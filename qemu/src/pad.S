/*
 * pad.S -- the landing pad: what the tramp's handover address points at on the
 * bench.  On the TV this address holds abort-postmmu.S, which records the
 * checkpoint and chains into the factory kernel; on the bench it records and
 * *checks* instead, then exits through semihosting.
 *
 * It is entered with the MMU still ON (both tramp versions leave it on and let
 * the handover stub clear M/C/I), PC == HANDOVER_PA (a physical address used as
 * an address, resolved through the tramp's own 1 GB identity block), and
 * TTBR1 = the kernel's tables from boot.S.
 *
 * Two tramp generations are supported:
 *   v1 (_start_kva measures its own VA->PA with AT, then derives lin from
 *      memstart_addr):  x27 = kimage, x28 = memstart_addr, x29 = lin, x5 = lin
 *   v2 (no probing: every address is PA + KIMAGE_OFFSET, loaded into x5 by
 *      _start_kva):     x5 = KIMAGE_OFFSET
 * Both leave x0..x2 = boot_args[0..2] (reloaded through the image/linear map),
 * x3/x4 = 0, and must not touch x30.
 *
 * x0/x1 are clobbered by every semihosting call, so they are saved into x8/x9
 * before the first print.
 */
#include "sh.inc"
#include "gen/layout.inc"

	.section .padstr, "aw"
	.include "src/padstrs.inc"

	.section .pad, "ax"
	.globl	landing_pad
landing_pad:
	mov	x8, x0				/* preserve the boot_args view */
	mov	x9, x1
	mov	x6, x2

	SH_PUTS	s_pad_banner
#if TRAMP_V2
	PH	s_pad_x5off, x5
#else
	PH	s_pad_kimage, x27
	PH	s_pad_memstart, x28
	PH	s_pad_lin, x29
#endif
	SH_PUTS	s_pad_nl

	PH	s_pad_x0, x8
	PH	s_pad_x1, x9
	PH	s_pad_x2, x6
	SH_PUTS	s_pad_nl

	PH	s_pad_x5, x5
	PH	s_pad_x30, x30
	mrs	x13, sctlr_el1
	PH	s_pad_sctlr, x13
	mrs	x13, ttbr0_el1
	PH	s_pad_ttbr0, x13
	mrs	x13, tcr_el1
	PH	s_pad_tcr, x13
	SH_PUTS	s_pad_nl

	/* the tramp's identity table entry, re-read through the linear map */
	LQ	x11, IDMAP_TABLE_VA
	ldr	x12, [x11]
	PH	s_pad_desc, x12
	/* boot_args[] re-read through the linear map (compare with x8/x9/x6) */
	LQ	x11, BOOT_ARGS_VA
	ldp	x19, x20, [x11]
	ldr	x22, [x11, #16]
	PH	s_pad_ba0, x19
	PH	s_pad_ba1, x20
	PH	s_pad_ba2, x22
	SH_PUTS	s_pad_nl

	/* ------------------------------- checks ------------------------------ */
#if TRAMP_V2
	LQ	x11, EXPECTED_KIMAGE_OFFSET		/* 1: x5 = KIMAGE_OFFSET */
	CK	1, x5, x11
	CK	2, x8, x19				/* 2..4: boot_args reload */
	CK	3, x9, x20
	CK	4, x6, x22
	mrs	x11, sctlr_el1				/* 5: MMU still on */
	tst	x11, #1
	b.ne	.Lck5
	mov	x25, #5
	b	.Lpad_fail
.Lck5:
	LQ	x11, EXPECTED_TABLE_PA			/* 6: TTBR0 = the tramp table */
	mrs	x12, ttbr0_el1
	cmp	x12, x11
	b.eq	.Lck6
	mov	x25, #6
	b	.Lpad_fail
.Lck6:
	mrs	x11, tcr_el1				/* 7: EPD0 = 0, T0SZ = 25 */
	tst	x11, #0x80
	b.ne	.Lck7b
	and	x12, x11, #0x3f
	cmp	x12, #25
	b.eq	.Lck7
.Lck7b:	mov	x25, #7
	b	.Lpad_fail
.Lck7:
	LQ	x11, IDMAP_TABLE_VA			/* 8: identity table content */
	ldr	x12, [x11]
	LQ	x11, EXPECTED_DESC_V2
	CK	8, x12, x11
	CK	9, x3, xzr				/* 9/10: x3, x4 cleared */
	CK	10, x4, xzr
	LQ	x11, CHECKPOINT_RET			/* 11: x30 preserved */
	CK	11, x30, x11
#else
	/* 1: AT self-calibration.  QEMU returns PAR_EL1[63:56] = memory
	 * attributes (on hardware [63:52] are RES0) and v1 masks only PAR[11:0],
	 * so compare the 48-bit PA part of kimage. */
	LQ	x10, MASK48
	and	x11, x27, x10
	LQ	x12, EXPECTED_KIMAGE
	and	x12, x12, x10
	CK	1, x11, x12
	LQ	x11, EXPECTED_MEMSTART			/* 2: memstart_addr */
	CK	2, x28, x11
	LQ	x11, EXPECTED_LIN			/* 3: lin arithmetic */
	CK	3, x29, x11
	CK	4, x5, x11				/* 4: lin handed over in x5 */
	mrs	x11, sctlr_el1				/* 5: MMU still on */
	tst	x11, #1
	b.ne	.Lck5
	mov	x25, #5
	b	.Lpad_fail
.Lck5:
#if EXPECT_IDMAP
	/* checks 6..8 only make sense when the tramp was supposed to install the
	 * 1 GB identity table (the no-idmap variant deliberately does not) */
	LQ	x11, IDMAP_TABLE_PA			/* 6: TTBR0 = our table */
	mrs	x12, ttbr0_el1
	cmp	x12, x11
	b.eq	.Lck6
	mov	x25, #6
	b	.Lpad_fail
.Lck6:
	mrs	x11, tcr_el1				/* 7: EPD0 = 0 */
	tst	x11, #0x80
	b.eq	.Lck7
	mov	x25, #7
	b	.Lpad_fail
.Lck7:
	LQ	x11, IDMAP_TABLE_VA			/* 8: identity table content */
	ldr	x12, [x11]
	LQ	x11, IDMAP_DESC_EXPECTED
	CK	8, x12, x11
#endif
	CK	9, x3, xzr				/* 9/10: x3, x4 cleared */
	CK	10, x4, xzr
	CK	11, x8, x19				/* 11..13: boot_args reload */
	CK	12, x9, x20
	CK	13, x6, x22
	LQ	x11, CHECKPOINT_RET			/* 14: x30 preserved */
	CK	14, x30, x11
#endif

#if SCENARIO == 1 || SCENARIO == 3
	SH_PUTS	s_pad_pass1
#else
	SH_PUTS	s_pad_pass2
#endif
	SH_PUTS	s_pad_nl
	mov	x3, #0
	SH_EXIT_CODE x3, exit_blk

.Lpad_fail:
	SH_PUTS	s_pad_fail
	PH	s_pad_chk, x25
	SH_PUTS	s_pad_nl
	mov	x3, #2
	SH_EXIT_CODE x3, exit_blk
