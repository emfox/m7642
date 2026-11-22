/*
 * Transition stub for checkpoints AFTER the MMU is on.
 *
 * Injected into the padding at the end of .text (Image+0x36c000).  The
 * checkpoint is patched with "bl tramp"; the handover body lives outside the
 * region the factory kernel copy overwrites (see abort-postmmu.S).
 *
 * Layout (offsets are patched by the build scripts, so they are pinned):
 *   0x000  _start      physical entry: the checkpoint ran at its PA (MMU off)
 *   0x004  _start_kva  kernel-VA entry: the checkpoint ran at a kernel VA
 *   0x0c0  _start_fdt  pre-MMU entry shim, patched over code1
 *   0x110  common path
 *
 * Addressing, and why there is no cleverness here any more:
 *
 *   - Everything we touch while the MMU is on (boot_args, the image we flush)
 *     lies INSIDE the kernel image, which arm64 maps at KIMAGE_VADDR.  That
 *     mapping's offset is a build-time constant, so the addresses are
 *     PA + KIMAGE_OFFSET.  No probing, no memstart_addr, no linear map.
 *   - The linear map would be wrong to rely on anyway: at the checkpoints we
 *     care about, arm64_memblock_init() has not run yet and memstart_addr is
 *     still the poison value -1 (arch/arm64/mm/init.c).  An earlier version
 *     derived an offset from it and put a store 512 MB off; another trusted the
 *     checkpoint's x5 to choose a mode and cleared SCTLR_EL1.M while executing
 *     at a kernel VA.  Both cost a run each.  Hence: mode comes from the
 *     hardware (SCTLR_EL1.M), offsets come from the build.
 *   - The handover must end with the MMU OFF (that is the state mboot gives the
 *     factory kernel).  Clearing M requires the next instruction fetch to be
 *     identity-mapped, which stops being true once the kernel drops its idmap.
 *     So when the MMU is on we install our own one-entry identity map first
 *     (1 GB block at level 1, table inside the image), jump to the handover's
 *     physical address, and let the stub clear M/C/I there.
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
#ifndef TABLE_PA
#define TABLE_PA 0x20601000		/* a page inside .bss of the image */
#endif
#ifndef TABLE_VA
#define TABLE_VA 0xffffffc080601000	/* ... always mapped RW, so safe to write
					 * in any mapping regime.  We never return
					 * to the kernel, so clobbering it is fine;
					 * reserved_pg_dir was a poor choice because
					 * whether .rodata is already read-only at a
					 * given checkpoint cannot be assumed. */
#endif
#ifndef IDMAP_PROBE_PA
#define IDMAP_PROBE_PA 0x20280000	/* _text's PA: inside the init idmap
					 * iff that identity map still exists */
#endif
#ifndef HANDOVER_PA
#define HANDOVER_PA 0x21680200
#endif

	.text
	.globl	_start
_start:
	mov	x5, xzr			/* MMU off: physical addressing */
	b	1f

	/* Pinned: the checkpoint patch is "bl Image+0x36c010", so this entry must
	 * stay at blob offset 0x10.  (It silently drifted to 0x8 once when _start
	 * grew to two instructions, and every checkpoint then jumped into _start's
	 * branch -- skipping the AT probe and running with the wrong x5.  Two runs
	 * were lost to that.  build-postmmu.sh now asserts this offset.) */
	.org	0x10
	.globl	_start_kva
_start_kva:
	/* Two worlds, and they need different code:
	 *
	 *  a) the kernel's identity map is still installed (everything before
	 *     cpu_uninstall_idmap()).  Then the proven path works: hop to our
	 *     physical alias, clear the MMU there, jump to the stub.  No page
	 *     tables, no TCR games -- this is the path f1/ps1z/skmainz used.
	 *  b) it is gone.  A physical address is no longer an address, so we
	 *     stay at the kernel VA and build our own identity map.
	 *
	 * Ask the MMU which world we are in instead of assuming: translate a
	 * physical address that lies inside the init idmap.  F=0 means the
	 * identity map answered, i.e. world (a). */
	movz	x16, #(IDMAP_PROBE_PA & 0xffff)
	movk	x16, #((IDMAP_PROBE_PA >> 16) & 0xffff), lsl #16
	at	s1e1r, x16
	mrs	x17, par_el1
	tbnz	x17, #0, 5f		/* F=1 -> no identity map */
	adr	x16, 1f			/* world (a): run at the physical alias */
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr			/* physical addressing from here */
	br	x16
5:					/* world (b): keep the kernel VA */
	movz	x5, #(KIMAGE_OFFSET & 0xffff)
	movk	x5, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x5, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x5, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	b	1f

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
1:
	/* capture the checkpoint's entry registers before we clobber them;
	 * the handover stub stores x21..x26 into the record. */
	mov	x21, x8
	mov	x22, x0
	mov	x23, x1
	mov	x24, x2
	mov	x25, x3
	mov	x26, x4

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
	cbz	x5, 8f			/* MMU is off: go straight to the handover */

	/* MMU is on.  Build a one-entry identity map so that the handover's
	 * physical address is addressable, then jump there.  The table is
	 * written through its link VA, so nothing has to be measured first. */
	movz	x16, #(TABLE_VA & 0xffff)
	movk	x16, #((TABLE_VA >> 16) & 0xffff), lsl #16
	movk	x16, #((TABLE_VA >> 32) & 0xffff), lsl #32
	movk	x16, #((TABLE_VA >> 48) & 0xffff), lsl #48
	mov	x19, #0
	mov	x20, #512
3:	str	xzr, [x16, x19, lsl #3]	/* leftovers must not look like tables */
	add	x19, x19, #1
	cmp	x19, x20
	b.lo	3b
	movz	x17, #0x0701			/* block|AttrIdx0|SH inner|AF */
	movk	x17, #0x0040, lsl #48		/* UXN */
	str	x17, [x16]			/* L1[0]: 1 GB block covering PA 0 */
	dsb	sy
	/* T0SZ is 16 here (64-IDMAP_VA_BITS: 4 levels, root at L0) and a 1 GB
	 * block at L0 is a reserved encoding, so switch TTBR0's regime to
	 * 39-bit / 3 levels where our entry means what it says. */
	mrs	x18, tcr_el1
	bic	x18, x18, #0x80			/* EPD0 = 0 */
	bic	x18, x18, #0x3f			/* T0SZ = 0 */
	movz	x17, #25			/* T0SZ = 25 */
	orr	x18, x18, x17
	msr	tcr_el1, x18
	isb
	movz	x18, #(TABLE_PA & 0xffff)
	movk	x18, #((TABLE_PA >> 16) & 0xffff), lsl #16
	msr	ttbr0_el1, x18
	dsb	nsh
	tlbi	vmalle1			/* local only; T0SZ changed, so stale
						 * entries are uninterpretable */
	dsb	nsh
	isb
	movz	x16, #(HANDOVER_PA & 0xffff)
	movk	x16, #((HANDOVER_PA >> 16) & 0xffff), lsl #16
	br	x16

8:	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M */
	bic	x16, x16, #4		/* C */
	bic	x16, x16, #0x1000	/* I */
	msr	sctlr_el1, x16
	isb
	movz	x16, #(HANDOVER_PA & 0xffff)
	movk	x16, #((HANDOVER_PA >> 16) & 0xffff), lsl #16
	br	x16
