/*
 * boot.S -- the "fake kernel" of the offline bench.
 *
 * It does exactly what the real kernel has done by the time the checkpoint
 * runs, and nothing more:
 *
 *   1. puts a fake memstart_addr and a fake boot_args[] where the tramp's -D
 *      constants say they are;
 *   2. builds a 39-bit-VA (T0SZ=T1SZ=25) page-table set:  a kernel image map
 *      at KIMAGE_VADDR (kimage map), a linear map at PAGE_OFFSET, and an
 *      identity map (1 GB block) in TTBR0;
 *   3. turns the MMU on (M/C/I) and continues executing from the linear map,
 *      which is the state of an arm64 kernel after __primary_switched();
 *   4. [P2 only] kills the identity map the way cpu_uninstall_idmap() does:
 *      TTBR0 -> an all-zero page, EPD0 stays 0, TLBI + dsb + isb;
 *   5. prints the AT_S1E1R self-checks and the addresses it is about to use,
 *      then does `bl`-equivalent (`br` with a checkpoint return address in x30)
 *      into the tramp's kernel-VA entry _start_kva.
 *
 * The image is linked at IMAGE_BASE, i.e. every label is a physical address;
 * the kernel VA of a label is PA + KIMAGE_OFFSET.
 */
#include "sh.inc"
#include "gen/layout.inc"

/* ------------------------------------------------------------------ entry */
	.section .text.start, "ax"
	.globl	_start
_start:
	b	boot_main

/* ---------------------------------------------------------------- vectors
 * 16 entries, 0x80 apart: they all land in the same "die loudly" handler.
 * VBAR holds the physical address until the MMU is on and the linear address
 * afterwards, so the handler is reachable in either regime.
 */
	.section .vectors, "ax"
vec_table:
	.irp off, 0x00,0x80,0x100,0x180,0x200,0x280,0x300,0x380
	.org	\off
	b	vec_die
	.endr
	.irp off, 0x400,0x480,0x500,0x580,0x600,0x680,0x700,0x780
	.org	\off
	b	vec_die
	.endr

/* -------------------------------------------------------------- fake data */
	.section .fake, "aw"
fake_memstart_addr:
	.quad	0
	.org	0x100
fake_boot_args:
	.quad	0
	.quad	0
	.quad	0

/* ------------------------------------------------------------------ strings */
	.section .benchstr, "a"
	.include "src/strs.inc"
	.include "gen/banner.inc"

/* --------------------------------------------------------------- main code */
	.section .text.boot, "ax"
	.globl	boot_main
boot_main:
	mov	x20, x0			/* x0 = DTB physical address from QEMU */
	LQ	x9, STACK_TOP
	mov	sp, x9
	mov	x29, xzr
	mov	x30, xzr

	/* ---- 1. fake kernel variables ----------------------------------- */
	LQ	x9, MEMSTART
	LQ	x10, FAKE_MEMSTART_PA
	str	x9, [x10]			/* memstart_addr = MEMSTART */
	LQ	x10, BOOT_ARGS_PA
	str	x20, [x10]			/* boot_args[0] = DTB pointer */
	LQ	x9, ARG1
	str	x9, [x10, #8]
	LQ	x9, ARG2
	str	x9, [x10, #16]

	/* ---- 2. page tables --------------------------------------------- */
	LQ	x9, L1T_PA
	bl	zero_page
	LQ	x9, L2K_PA
	bl	zero_page
	LQ	x9, L2LIN_PA
	bl	zero_page
	LQ	x9, L1T0_PA
	bl	zero_page
	LQ	x9, ZEROT_PA
	bl	zero_page

	/* TTBR1 L1 -> kimage L2 table */
	LQ	x9, L1T_PA
	LQ	x10, L2K_PA
	add	x10, x10, #3			/* table descriptor */
	LQ	x11, KIMAGE_L1_OFF
	str	x10, [x9, x11]

	/* kimage L2 entry = 2 MB block, executable at EL1 */
	LQ	x9, L2K_PA
	LQ	x10, KIMAGE_BLOCK_PA
	LQ	x11, DESC_KERNEL
	orr	x10, x10, x11
	LQ	x11, KIMAGE_L2_OFF
	str	x10, [x9, x11]

	/* TTBR1 L1 -> linear map L2 table */
	LQ	x9, L1T_PA
	LQ	x10, L2LIN_PA
	add	x10, x10, #3
	LQ	x11, TMAP_L1_OFF
	str	x10, [x9, x11]

	/* linear map: 512 x 2 MB blocks from MEMSTART, not EL0-executable */
	LQ	x9, L2LIN_PA
	LQ	x10, MEMSTART
	LQ	x11, DESC_UXN
	orr	x10, x10, x11
	LQ	x11, TMAP_STEP
	LQ	x12, TMAP_COUNT
.Llin_fill:
	str	x10, [x9], #8
	add	x10, x10, x11
	subs	x12, x12, #1
	b.ne	.Llin_fill

	/* TTBR0 identity map: one 1 GB block covering IMAGE_BASE */
	LQ	x9, L1T0_PA
	LQ	x10, IDMAP_BLOCK_PA
	LQ	x11, DESC_KERNEL
	orr	x10, x10, x11
	LQ	x11, IDMAP_L1_OFF
	str	x10, [x9, x11]
	dsb	sy

	/* ---- 3. MAIR / TCR / TTBR / VBAR, then MMU on ------------------- */
	LQ	x9, MAIR_VAL
	msr	mair_el1, x9
	LQ	x9, TCR_VAL
	msr	tcr_el1, x9
	LQ	x9, L1T0_PA
	msr	ttbr0_el1, x9
	LQ	x9, L1T_PA
	msr	ttbr1_el1, x9
	LQ	x9, IMAGE_BASE
	add	x9, x9, #0x800			/* vec_table, physical */
	msr	vbar_el1, x9
	dsb	sy
	isb

	mrs	x9, sctlr_el1
	orr	x9, x9, #1			/* M */
	orr	x9, x9, #4			/* C */
	orr	x9, x9, #0x1000			/* I */
	msr	sctlr_el1, x9
	isb

	/* VBAR -> linear address of the vector table (survives TTBR0 changes) */
	LQ	x9, VEC_VA
	msr	vbar_el1, x9
	isb

	/* continue executing from the linear map, like a real kernel does */
	adr	x9, .Llin_exec
	LQ	x10, LIN
	add	x9, x9, x10
	br	x9

.Llin_exec:
	/* ---- 4. [P2] remove the identity map (cpu_uninstall_idmap) ------ */
#if KILL_IDMAP
	LQ	x9, ZEROT_PA
	msr	ttbr0_el1, x9			/* walks still enabled, table all 0 */
	tlbi	vmalle1
	dsb	nsh
	isb
#endif

	/* ---- 5. report ------------------------------------------------- */
	SH_PUTS	s_banner
	LQ	x13, IMAGE_BASE
	PH	s_image, x13
	LQ	x13, TRAMP_PA
	PH	s_tramp_pa, x13
	LQ	x13, TRAMP_VA
	PH	s_tramp_va, x13
	SH_PUTS	s_nl

	LQ	x13, MEMSTART
	PH	s_memstart, x13
	LQ	x13, LIN
	PH	s_lin, x13
	SH_PUTS	s_nl

	mrs	x13, tcr_el1
	PH	s_tcr, x13
	mrs	x13, mair_el1
	PH	s_mair, x13
	mrs	x13, sctlr_el1
	PH	s_sctlr, x13
	SH_PUTS	s_nl

	/* diagnostics: identity table + TTBR0, read through the linear map */
	LQ	x10, L1T0_PA
	LQ	x11, LIN
	add	x10, x10, x11
	ldr	x12, [x10]
	PH	s_diag_l1t0, x12
	mrs	x12, ttbr0_el1
	PH	s_diag_ttbr0, x12
	LQ	x13, VEC_VA
	mrs	x12, vbar_el1
	PH	s_diag_vbar, x12
	SH_PUTS	s_nl

	/* AT on a physical address used as an address: the P1/P2 difference */
	LQ	x16, AT_PROBE_PA
	PH	s_atpa, x16
	at	s1e1r, x16
	isb
	mrs	x17, par_el1
	PH	s_par, x17
	tst	x17, #1
	b.ne	.Lat_gone
	SH_PUTS	s_idmap_alive
	b	.Lat_done
.Lat_gone:
	SH_PUTS	s_idmap_gone
.Lat_done:
	SH_PUTS	s_nl

	/* AT on a kernel VA: must be translatable in both scenarios */
	LQ	x16, TRAMP_VA
	PH	s_atva, x16
	at	s1e1r, x16
	isb
	mrs	x17, par_el1
	PH	s_par, x17
	movz	x19, #0xf000
	movk	x19, #0xffff, lsl #16
	movk	x19, #0xffff, lsl #32
	movk	x19, #0x0000, lsl #48
	and	x17, x17, x19
	PH	s_pa_par, x17
	LQ	x18, TRAMP_PA
	PH	s_pa_want, x18
	SH_PUTS	s_nl

	/* read back the table entries we built -- through the LINEAR map, because
	 * in P2 no identity mapping exists for a physical address any more */
	LQ	x10, L1T_PA
	LQ	x14, LIN
	add	x10, x10, x14
	LQ	x11, KIMAGE_L1_OFF
	ldr	x12, [x10, x11]
	PH	s_l1k, x12
	LQ	x10, L2K_PA
	LQ	x14, LIN
	add	x10, x10, x14
	ldr	x12, [x10]
	PH	s_l2k, x12
	LQ	x10, L1T0_PA
	LQ	x14, LIN
	add	x10, x10, x14
	ldr	x12, [x10]
	PH	s_l1t0, x12
	mrs	x12, ttbr0_el1
	PH	s_ttbr0, x12
	mrs	x12, ttbr1_el1
	PH	s_ttbr1, x12
	SH_PUTS	s_nl

	LQ	x13, TRAMP_VA_ENTRY
	PH	s_jump, x13
	LQ	x13, MODE_X5
	PH	s_x5, x13
	SH_PUTS	s_nl

	/* ---- 6. enter the tramp at its kernel VA ------------------------ */
	LQ	x0, 0xa0a0a0a0a0a0a0a0
	LQ	x1, 0xa1a1a1a1a1a1a1a1
	LQ	x2, 0xa2a2a2a2a2a2a2a2
	LQ	x3, 0xa3a3a3a3a3a3a3a3
	LQ	x4, 0xa4a4a4a4a4a4a4a4
	mov	x8, #0x88			/* "br x8 target" slot */
	LQ	x5, MODE_X5			/* entry x5: nonzero = VA mode */
	LQ	x30, CHECKPOINT_RET		/* checkpoint return address */
	LQ	x16, TRAMP_VA_ENTRY
	br	x16
	SH_EXIT_FAIL				/* never reached */

/* ------------------------------------------------------------------ helpers */
	.balign	4
zero_page:					/* x9 = page to clear */
	mov	x10, #256
.Lzp:
	stp	xzr, xzr, [x9], #16
	subs	x10, x10, #1
	b.ne	.Lzp
	ret

/* De-loudly handler: prints ESR/FAR/ELR with semihosting, then exits non-zero.
 * No stack, no memory access other than the adr-relative buffer, so it also
 * works when SP is 0 (the tramp zeroes SP) and when TTBR0 translates nothing. */
vec_die:
	mrs	x20, esr_el1
	mrs	x21, far_el1
	mrs	x22, elr_el1
	PH	s_exc, x20
	PH	s_exc_far, x21
	PH	s_exc_elr, x22
	SH_PUTS	s_nl
	mov	x3, #3
	SH_EXIT_CODE x3, exc_exit_blk

	.balign	8
exc_buf:
	.space	24
	.balign	8
exc_exit_blk:
	.space	16
prbuf:
	.space	24
