/*
 * pad.S -- the landing pad: what the tramp's handover address points at on the
 * bench.  On the TV this address holds abort-postmmu.S; on the bench it records
 * and *checks* instead, then exits through semihosting.
 *
 * It can be entered in two states, and it checks both:
 *
 *   world (a) -- the v4 tramp found the kernel's identity map alive, hopped to
 *                its physical alias and cleared M/C/I itself.  So the MMU is
 *                OFF here, TTBR0/TCR are still the kernel's, and the tramp must
 *                not have touched the identity-table page at all.
 *   world (b) -- no identity map: the tramp stayed at the kernel VA, built its
 *                own 1 GB block, switched TTBR0 and jumped to the physical
 *                handover address.  The MMU is ON and PC is a physical address
 *                resolved through that block.
 *
 * Every address used below therefore has to work in both regimes: the strings
 * are ADR-relative (correct either way), and the data reads use physical
 * addresses (no translation when the MMU is off; identity-mapped by the
 * tramp's own block when it is on).
 *
 * x0/x1 are clobbered by every semihosting call, so they are saved first.
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
#if TRAMP_V4
	mrs	x11, sctlr_el1
	tbz	x11, #0, .Lworld_a_print
	SH_PUTS	s_pad_world
	SH_PUTS	s_pad_world_b
	b	.Lworld_done
.Lworld_a_print:
	SH_PUTS	s_pad_world
	SH_PUTS	s_pad_world_a
.Lworld_done:
#else
	SH_PUTS	s_pad_world
	SH_PUTS	s_pad_world_b
#endif

#if TRAMP_VERSION_1
	PH	s_pad_kimage, x27
	PH	s_pad_memstart, x28
	PH	s_pad_lin, x29
	SH_PUTS	s_pad_nl
#else
	PH	s_pad_x5off, x5
	SH_PUTS	s_pad_nl
#endif

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

	/* the identity-table page, read as a physical address: valid with the MMU
	 * off (world a) and through the tramp's own 1 GB block (world b) */
	LQ	x11, TABLE_PA
	ldr	x12, [x11]
	PH	s_pad_table0, x12
	LQ	x11, TABLE_PA			/* PH clobbers x11..x15: reload */
	LQ	x13, SENTINEL_OFF
	ldr	x12, [x11, x13]
	PH	s_pad_table1, x12
	SH_PUTS	s_pad_nl

	/* boot_args[] re-read at its physical address (works in both regimes) */
	LQ	x11, BOOT_ARGS_PA
	ldp	x19, x20, [x11]
	ldr	x22, [x11, #16]
	PH	s_pad_ba0, x19
	PH	s_pad_ba1, x20
	PH	s_pad_ba2, x22
	SH_PUTS	s_pad_nl

	/* ------------------------------- checks ------------------------------ */
#if TRAMP_V4
	mrs	x11, sctlr_el1
	tbz	x11, #0, .Lv4_world_a
	/* ===== world (b): own identity table installed ===== */
	SH_PUTS	s_pad_chkb
	LQ	x11, EXPECTED_KIMAGE_OFFSET		/* 1: x5 = KIMAGE_OFFSET */
	CK	1, x5, x11
	LQ	x11, TABLE_PA				/* 2: TTBR0 = our table */
	mrs	x12, ttbr0_el1
	CK	2, x12, x11
	LQ	x11, TABLE_PA				/* 3: block descriptor */
	ldr	x12, [x11]
	LQ	x11, EXPECTED_DESC_V2
	CK	3, x12, x11
	/* with T0SZ16 the tramp must have rewritten T0SZ 16 -> 25 here, which is
	 * what makes a level-1 1 GB block meaningful; asserted in check 4 */
	mrs	x11, tcr_el1				/* 4: T0SZ=25, EPD0=0 */
	tst	x11, #0x80
	b.eq	.Lv4b_t0
	mov	x25, #4
	b	.Lpad_fail
.Lv4b_t0:
	and	x12, x11, #0x3f
	cmp	x12, #25
	b.eq	.Lv4b_5
	mov	x25, #4
	b	.Lpad_fail
.Lv4b_5:
	mrs	x11, sctlr_el1				/* 5: MMU on */
	tst	x11, #1
	b.ne	.Lv4b_6
	mov	x25, #5
	b	.Lpad_fail
.Lv4b_6:
	CK	6, x8, x19				/* 6..8: boot_args reload */
	CK	7, x9, x20
	CK	8, x6, x22
	CK	9, x3, xzr
	CK	10, x4, xzr
	LQ	x11, CHECKPOINT_RET			/* 11: x30 preserved */
	CK	11, x30, x11
	b	.Lpad_ok

.Lv4_world_a:
	/* ===== world (a): the kernel's identity map carried us ===== */
	SH_PUTS	s_pad_chka
	CK	1, x5, xzr				/* 1: x5 == 0 (PA mode) */
	mrs	x11, sctlr_el1				/* 2: the tramp cleared M/C/I */
	tst	x11, #1
	b.eq	.Lv4a_3
	mov	x25, #2
	b	.Lpad_fail
.Lv4a_3:
	LQ	x11, EXPECTED_TTBR0			/* 3: TTBR0 still the kernel's */
	mrs	x12, ttbr0_el1
	CK	3, x12, x11
	LQ	x11, TABLE_PA				/* 4: ... and not our table */
	cmp	x12, x11
	b.ne	.Lv4a_5
	mov	x25, #4
	b	.Lpad_fail
.Lv4a_5:
#if T0SZ16
	LQ	x11, TCR_VAL_T0SZ16			/* 5: TCR untouched */
#else
	LQ	x11, TCR_VAL				/* 5: TCR untouched */
#endif
	mrs	x12, tcr_el1
	CK	5, x12, x11
	LQ	x11, TABLE_PA				/* 6: table page untouched */
	ldr	x12, [x11]
	LQ	x13, SENTINEL_A
	CK	6, x12, x13
	LQ	x11, TABLE_PA				/* 7: second sentinel too */
	LQ	x13, SENTINEL_OFF
	ldr	x12, [x11, x13]
	LQ	x13, SENTINEL_A
	CK	7, x12, x13
	CK	8, x8, x19				/* 8..10: boot_args reload */
	CK	9, x9, x20
	CK	10, x6, x22
	CK	11, x3, xzr
	CK	12, x4, xzr
	LQ	x11, CHECKPOINT_RET			/* 13: x30 preserved */
	CK	13, x30, x11
	b	.Lpad_ok
#elif TRAMP_V2
	/* v2/v3: x5 = KIMAGE_OFFSET, own table installed, MMU on */
	SH_PUTS	s_pad_chkb
	LQ	x11, EXPECTED_KIMAGE_OFFSET
	CK	1, x5, x11
	CK	2, x8, x19
	CK	3, x9, x20
	CK	4, x6, x22
	mrs	x11, sctlr_el1
	tst	x11, #1
	b.ne	.Lv23_5
	mov	x25, #5
	b	.Lpad_fail
.Lv23_5:
	LQ	x11, TABLE_PA
	mrs	x12, ttbr0_el1
	CK	6, x12, x11
	mrs	x11, tcr_el1
	tst	x11, #0x80
	b.ne	.Lv23_7
	and	x12, x11, #0x3f
	cmp	x12, #25
	b.eq	.Lv23_8
.Lv23_7:
	mov	x25, #7
	b	.Lpad_fail
.Lv23_8:
	LQ	x11, TABLE_PA
	ldr	x12, [x11]
	LQ	x11, EXPECTED_DESC_V2
	CK	8, x12, x11
	CK	9, x3, xzr
	CK	10, x4, xzr
	LQ	x11, CHECKPOINT_RET
	CK	11, x30, x11
	b	.Lpad_ok
#else
	/* ---- v1: AT self-calibration + linear map ---- */
	SH_PUTS	s_pad_chka
	/* 1: kimage.  QEMU returns PAR_EL1[63:56] = memory attributes (on hardware
	 * [63:52] are RES0) and v1 masks only PAR[11:0], so compare the 48-bit PA
	 * part of kimage. */
	LQ	x10, MASK48
	and	x11, x27, x10
	LQ	x12, EXPECTED_KIMAGE
	and	x12, x12, x10
	CK	1, x11, x12
	LQ	x11, EXPECTED_MEMSTART
	CK	2, x28, x11
	LQ	x11, EXPECTED_LIN
	CK	3, x29, x11
	CK	4, x5, x11
	mrs	x11, sctlr_el1
	tst	x11, #1
	b.ne	.Lv1_5
	mov	x25, #5
	b	.Lpad_fail
.Lv1_5:
#if EXPECT_IDMAP
	LQ	x11, IDMAP_TABLE_PA
	mrs	x12, ttbr0_el1
	CK	6, x12, x11
	mrs	x11, tcr_el1
	tst	x11, #0x80
	b.eq	.Lv1_7
	mov	x25, #7
	b	.Lpad_fail
.Lv1_7:
	LQ	x11, IDMAP_TABLE_VA
	ldr	x12, [x11]
	LQ	x11, IDMAP_DESC_EXPECTED
	CK	8, x12, x11
#endif
	CK	9, x3, xzr
	CK	10, x4, xzr
	CK	11, x8, x19
	CK	12, x9, x20
	CK	13, x6, x22
	LQ	x11, CHECKPOINT_RET
	CK	14, x30, x11
	b	.Lpad_ok
#endif

.Lpad_ok:
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
