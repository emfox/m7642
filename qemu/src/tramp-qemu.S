/*
 * tramp-qemu.S -- bench copy of ../../probes/handoff/tramp-postmmu.S
 *
 * The original is read-only for this task, so the bench keeps its own copy.
 * The copy is *byte-for-byte identical* to the original blob as long as none of
 * the bench macros are defined: with the stock -D values (or with none at all,
 * the defaults below are the production values taken from System.map) the
 * assembled .text is the same 756 bytes, md5 f160cdd6e93c3bcebcd645a803185dcd.
 * `verify-identical.sh` re-proves that on every run.
 *
 * Two hardcoded physical addresses had to become parameters, because the
 * address space of the QEMU board is not the address space of the TV:
 *
 *   IDMAP_TABLE_PA  0x23100000 -> where the tramp writes its 1 GB identity table
 *   HANDOVER_PA     0x21680200 -> the physical address it jumps to with the MMU on
 *
 * Both keep the original instruction idiom (movz/movk for the table, movz+lsl16
 * +add for the handover), so the default build is unchanged.
 *
 * INJECT_* macros are *deliberately broken* variants used to prove that the
 * harness can tell right from wrong (P3).  All of them default to 0.
 */

#ifndef BOOT_ARGS_PA
#define BOOT_ARGS_PA 0x207d4000
#endif
#ifndef IMAGE_START_PA
#define IMAGE_START_PA 0x20290000
#endif
#ifndef IMAGE_END_PA
#define IMAGE_END_PA 0x208f0000
#endif
#ifndef KIMAGE_OFFSET
#define KIMAGE_OFFSET 0xffffffc05fd80000
#endif
#ifndef PRIMARY_ENTRY_PA
#define PRIMARY_ENTRY_PA 0x206d5038
#endif
#ifndef MEMSTART_VA
#define MEMSTART_VA 0xffffffc080441dd8
#endif

/* --- bench parameters (defaults = production values) --------------------- */
#ifndef IDMAP_TABLE_PA
#define IDMAP_TABLE_PA 0x23100000
#endif
#ifndef HANDOVER_PA
#define HANDOVER_PA 0x21680200
#endif

/* --- injected faults (test-only, all 0 in the real build) --------------- */
#ifndef INJECT_LIN_ERR			/* add a bogus delta to lin */
#define INJECT_LIN_ERR 0
#endif
#ifndef INJECT_NO_IDMAP			/* skip the 1 GB identity table install */
#define INJECT_NO_IDMAP 0
#endif
#ifndef INJECT_PA_ALIAS			/* always hop to the PA alias (bug ②) */
#define INJECT_PA_ALIAS 0
#endif
#ifndef INJECT_DBL_OFFSET		/* double-count the kimage offset (bug ①) */
#define INJECT_DBL_OFFSET 0
#endif

/* FIX_PAGE_OFFSET=1 repairs bug ③ found by this bench: PAGE_OFFSET is built
 * with "movk x20, #0xff80, lsl #48", which yields 0xff80_0000_0000_0000, not
 * 0xffff_ff80_0000_0000.  All linear-map addresses then come out
 * 0x007f_ffff_0000_0000 too low, so the very first ldr through the linear map
 * faults.  Default 0 keeps this file byte-identical to the shipped blob. */
#ifndef FIX_PAGE_OFFSET
#define FIX_PAGE_OFFSET 0
#endif

	.text
	.globl	_start
_start:
	b	1f			/* straight to the common path */

	.globl	_start_kva
_start_kva:
	b	5f			/* calibrate first (MMU on) */

	.org	0xc0
	.globl	_start_fdt
_start_fdt:
	/* MStar's bootloader leaves x0 = 0 while the factory kernel hardcodes
	 * the tree at 0x23000000; early_map_kernel() parses that pointer before
	 * setup_arch() can substitute the built-in tree, so x0 must be valid.
	 * Record the bootloader's registers first. */
	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16	/* 0x23090000 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4446
	movk	w7, #0x2054, lsl #16	/* "FDT " */
	str	w7, [x6, #4]
	str	wzr, [x6, #8]
	str	wzr, [x6, #12]
	str	x30, [x6, #16]
	stp	x0, x1, [x6, #24]
	stp	x2, x3, [x6, #40]
	stp	x4, x5, [x6, #56]
	dsb	sy

	movz	x0, #0x2300
	lsl	x0, x0, #16		/* 0x23000000: factory DTB */
	movz	x6, #(PRIMARY_ENTRY_PA & 0xffff)
	movk	x6, #((PRIMARY_ENTRY_PA >> 16) & 0xffff), lsl #16
	br	x6

	.org	0x110
5:	/* x16 = our own VA; ask the MMU what physical page that is. */
	adr	x16, 5b
	at	s1e1r, x16
	mrs	x17, par_el1
	tst	x17, #1			/* F = 1 -> not translatable */
	b.ne	6f
	lsr	x17, x17, #12		/* PAR[47:12] = PA, drop the attribute bits */
	lsl	x17, x17, #12
	and	x18, x16, #0xfff
	orr	x17, x17, x18		/* PA of 5b */
	sub	x27, x16, x17		/* x27 = kimage = VA - PA */
	/* memstart_addr is inside the image: reachable via the image mapping. */
	/* arm64 always maps the kernel at KIMAGE_VADDR, so a symbol's runtime VA
	 * is its link VA no matter where the image was loaded.  Do NOT add the
	 * measured offset here (doing that once cost a run: +0x80000 double
	 * count put this load 512 MB off and the following store faulted). */
	movz	x19, #(MEMSTART_VA & 0xffff)
	movk	x19, #((MEMSTART_VA >> 16) & 0xffff), lsl #16
	movk	x19, #((MEMSTART_VA >> 32) & 0xffff), lsl #32
	movk	x19, #((MEMSTART_VA >> 48) & 0xffff), lsl #48
#if INJECT_DBL_OFFSET
	add	x19, x19, x27		/* VARIANT: bug ① -- double-count the offset */
#endif
	ldr	x28, [x19]		/* x28 = memstart_addr */
	/* Sanity: memstart_addr must be a plausible DDR base.  If it is not, do
	 * not invent a linear offset -- fall back to physical addressing (the
	 * caller can still record x28 to show what we read). */
	movz	x20, #0x0000
	movk	x20, #0x0001, lsl #32		/* 0x1_0000_0000 */
	cmp	x28, x20
	b.hs	6f
#if FIX_PAGE_OFFSET
	movz	x20, #0x0000		/* PAGE_OFFSET = 0xffffff8000000000 (39-bit VA) */
	movk	x20, #0xff80, lsl #32
	movk	x20, #0xffff, lsl #48
#else
	movz	x20, #0x0000		/* PAGE_OFFSET = 0xffffff8000000000 (39-bit VA) */
	movk	x20, #0xff80, lsl #48
#endif
	sub	x29, x20, x28		/* x29 = lin = PAGE_OFFSET - memstart_addr */
#if INJECT_LIN_ERR
	add	x29, x29, #(INJECT_LIN_ERR)	/* VARIANT: wrong linear offset */
#endif
	b	7f
6:	mov	x27, xzr			/* untranslatable: PA mode only */
	mov	x28, xzr
	mov	x29, xzr
7:	adr	x16, 1f
#if INJECT_PA_ALIAS
	nop					/* VARIANT: bug ② -- keep hopping to the PA alias */
#else
	cbnz	x5, 9f			/* VA mode: stay at the kernel VA */
#endif
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17		/* PA mode only: hop to the PA alias */
9:	br	x16

	.org	0x200
1:
	/* capture the checkpoint's entry registers before we clobber them;
	 * the handover stub stores x21..x26 into the record. */
	mov	x21, x8
	mov	x22, x0
	mov	x23, x1
	mov	x24, x2
	mov	x25, x3
	mov	x26, x4

	/* x5 = 0 when the MMU is off (addresses are physical), or the linear-map
	 * offset when it is on (every physical address needs + x5).  The handover
	 * stub reads it too, so the same blob serves both worlds. */
	mov	x5, x29

	movz	x16, #(BOOT_ARGS_PA & 0xffff)
	movk	x16, #((BOOT_ARGS_PA >> 16) & 0xffff), lsl #16
	add	x16, x16, x5
	ldp	x0, x1, [x16]
	ldr	x2, [x16, #16]
	mov	x3, xzr
	mov	x4, xzr

	movz	x19, #(IMAGE_START_PA & 0xffff)
	movk	x19, #((IMAGE_START_PA >> 16) & 0xffff), lsl #16
	movz	x20, #(IMAGE_END_PA & 0xffff)
	movk	x20, #((IMAGE_END_PA >> 16) & 0xffff), lsl #16
	add	x19, x19, x5
	add	x20, x20, x5
2:
	dc	civac, x19
	add	x19, x19, #64
	cmp	x19, x20
	b.lo	2b
	dsb	sy
	ic	iallu
	dsb	sy
	isb

	mov	x16, xzr
	mov	sp, x16
	cbz	x5, 8f

#if !INJECT_NO_IDMAP
	/* MMU is on and the identity map may be gone (cpu_uninstall_idmap()).
	 * The handover has to run with the MMU OFF, but clearing SCTLR_EL1.M
	 * requires the very next instruction to be identity-mapped.  So install
	 * our own one-entry identity map first: with T0SZ = 25 a level-1 entry
	 * covers 1 GB, which spans everything we touch (0x20280000..0x30000800).
	 * Table at PA 0x23100000, written through the linear map. */
	movz	x16, #(IDMAP_TABLE_PA & 0xffff)
	movk	x16, #((IDMAP_TABLE_PA >> 16) & 0xffff), lsl #16
	add	x16, x16, x5			/* linear VA of the table */
	movz	x17, #0x0705			/* block|AttrIdx1|SH inner|AF */
	movk	x17, #0x0040, lsl #48		/* UXN */
	str	x17, [x16]			/* L1[0] = 1 GB block @ 0 */
	dsb	sy
	mrs	x18, tcr_el1
	bic	x18, x18, #0x80			/* EPD0 = 0: allow TTBR0 walks */
	msr	tcr_el1, x18
	isb
	movz	x18, #(IDMAP_TABLE_PA & 0xffff)
	movk	x18, #((IDMAP_TABLE_PA >> 16) & 0xffff), lsl #16
	msr	ttbr0_el1, x18
	dsb	nsh
	isb
	/* No TLBI on purpose: any stale TTBR0 entry came from the identity map
	 * and points at the same physical page, and the MMU is off a few
	 * instructions later.  A broadcast TLBI is the one thing here that could
	 * block on an interconnect that owes us nothing. */
#endif
	movz	x16, #((HANDOVER_PA >> 16) & 0xffff)
	lsl	x16, x16, #16
	add	x16, x16, #(HANDOVER_PA & 0xffff)
	br	x16

8:	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M */
	bic	x16, x16, #4		/* C */
	bic	x16, x16, #0x1000	/* I */
	msr	sctlr_el1, x16
	isb
	movz	x16, #((HANDOVER_PA >> 16) & 0xffff)
	lsl	x16, x16, #16
	add	x16, x16, #(HANDOVER_PA & 0xffff)
	br	x16
