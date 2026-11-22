/*
 * impostor.S -- the stand-in factory kernel of the full-chain scenario.
 *
 * It is linked at 0x21220000 (the entry the handover stub branches to) and is
 * placed inside the staged payload, so it only becomes reachable *after* the
 * stub has copied 0x12d4a00 bytes from 0x30000800 to 0x20280000 -- i.e. the
 * fact that it runs at all proves the copy ran.
 *
 * The stub enters it with the MMU OFF (it cleared M/C/I itself), so everything
 * here is plain physical addressing.
 *
 * What it does:
 *   - dumps the 0xB0 handover record at 0x23080000 (readable fields + a
 *     probeRW-style hexdump so tools/host/decode-record.py can be run on it),
 *   - checks it (magic, size, x30, the checkpoint's x8, the *kernel's* SCTLR
 *     at +0x70, and the copy sentinel at 0x20380000),
 *   - exits through semihosting: 0 = PASS, 2 = a check failed.
 */
#include "sh.inc"
#include "gen/layout.inc"

	.section .impstr, "a"
	.include "src/impstrs.inc"

	.text

	.set	REC,	0x23080000
	.set	COPYPROBE, 0x20380000

	.text
	.globl	_start
_start:
	LQ	x19, REC

	SH_PUTS	s_hdr
	ldr	x12, [x19, #8]
	PH	s_size, x12
	ldr	x12, [x19, #16]
	PH	s_x30, x12
	ldr	x12, [x19, #24]
	PH	s_x0, x12
	ldr	x12, [x19, #32]
	PH	s_x1, x12
	ldr	x12, [x19, #40]
	PH	s_x2, x12
	SH_PUTS	s_nl
	ldr	x12, [x19, #64]
	PH	s_x21, x12
	ldr	x12, [x19, #112]
	PH	s_sctlr, x12
	LQ	x13, 0x1005
	and	x14, x12, x13
	PH	s_sctlr_mci, x14
	SH_PUTS	s_nl

	/* hardware identity: the seven registers the stub now records */
	ldr	x12, [x19, #120]
	PH	s_midr, x12
	ldr	x12, [x19, #128]
	PH	s_ctr, x12
	SH_PUTS	s_nl
	ldr	x12, [x19, #136]
	PH	s_revidr, x12
	ldr	x12, [x19, #144]
	PH	s_tcr, x12
	SH_PUTS	s_nl
	ldr	x12, [x19, #152]
	PH	s_mair, x12
	ldr	x12, [x19, #160]
	PH	s_mmfr0, x12
	SH_PUTS	s_nl
	ldr	x12, [x19, #168]
	PH	s_mpidr, x12
	LQ	x13, COPYPROBE
	ldr	x14, [x13]
	PH	s_copysig, x14
	SH_PUTS	s_nl

	/* ---- the same record as a probeRW-style hexdump (for decode-record.py) */
	SH_PUTS	s_dump_hdr
	adr	x28, ctab
	mov	x20, x19			/* address cursor */
	mov	x21, #11			/* 0xB0 / 16 */
.Ldq_line:
	adr	x22, linebuf
	mov	x23, x20
	mov	x24, #60
.Ldq_addr:
	lsr	x25, x23, x24
	and	x25, x25, #0xf
	ldrb	w25, [x28, x25]
	strb	w25, [x22], #1
	subs	x24, x24, #4
	b.pl	.Ldq_addr
	mov	w25, #0x3a			/* ':' */
	strb	w25, [x22], #1
	mov	w25, #0x20			/* ' ' */
	strb	w25, [x22], #1
	mov	x26, #16
.Ldq_bytes:
	ldrb	w25, [x20], #1
	lsr	w27, w25, #4
	and	w27, w27, #0xf
	ldrb	w27, [x28, w27, uxtw]
	strb	w27, [x22], #1
	and	w27, w25, #0xf
	ldrb	w27, [x28, w27, uxtw]
	strb	w27, [x22], #1
	mov	w25, #0x20
	strb	w25, [x22], #1
	subs	x26, x26, #1
	b.ne	.Ldq_bytes
	mov	w25, #0x0a
	strb	w25, [x22], #1
	mov	w25, #0
	strb	w25, [x22]
	adr	x1, linebuf
	mov	x0, #0x04
	hlt	#0xf000
	subs	x21, x21, #1
	b.ne	.Ldq_line

	/* ------------------------------- checks ------------------------------ */
	ldr	w12, [x19]			/* "M764" */
	LQ	x13, 0x3436374d
	cmp	w12, w13
	b.ne	.Lfail1
	ldr	w12, [x19, #4]			/* "MMMU" */
	LQ	x13, 0x554d4d4d
	cmp	w12, w13
	b.ne	.Lfail2
	ldr	w12, [x19, #8]			/* size == 0xB0 */
	cmp	w12, #0xB0
	b.eq	.Lck3
	mov	x25, #3
	b	.Lfail
.Lck3:
	ldr	x12, [x19, #16]			/* x30 == checkpoint return */
	LQ	x13, CHECKPOINT_RET
	cmp	x12, x13
	b.eq	.Lck4
	mov	x25, #4
	b	.Lfail
.Lck4:
	ldr	x12, [x19, #64]			/* x21 == the br x8 slot */
	cmp	x12, #0x88
	b.eq	.Lck5
	mov	x25, #5
	b	.Lfail
.Lck5:
	ldr	x12, [x19, #112]		/* the *kernel's* SCTLR: M|C|I */
	LQ	x13, 0x1005
	and	x12, x12, x13
	cmp	x12, x13
	b.eq	.Lck6
	mov	x25, #6
	b	.Lfail
.Lck6:
	LQ	x13, COPYPROBE			/* the 0x12d4a00 byte copy ran */
	ldr	x12, [x13]
	LQ	x13, COPY_SENTINEL
	cmp	x12, x13
	b.eq	.Lck7
	mov	x25, #7
	b	.Lfail
.Lck7:
	ldr	x12, [x19, #120]		/* MIDR/MPIDR are non-zero: the reads
						 * did not get UNDEFINED-ed */
	cbz	x12, .Lfail8
	ldr	x12, [x19, #168]
	cbz	x12, .Lfail8
	ldr	x12, [x19, #128]
	cbz	x12, .Lfail8
	lsl	x12, x12, #48
	lsr	x12, x12, #48			/* CTR_EL0 IminLine != 0 */
	cbz	x12, .Lfail8
	b	.Lpass
.Lfail8:
	mov	x25, #8
	b	.Lfail
.Lfail1:
	mov	x25, #1
	b	.Lfail
.Lfail2:
	mov	x25, #2
.Lfail:
	SH_PUTS	s_fail
	PH	s_chk, x25
	SH_PUTS	s_nl
	mov	x3, #2
	SH_EXIT_CODE x3, exit_blk
.Lpass:
	SH_PUTS	s_pass
	SH_PUTS	s_nl
	mov	x3, #0
	SH_EXIT_CODE x3, exit_blk

	.balign	8
ctab:	.asciz	"0123456789abcdef"
	.balign	8
prbuf:	.space	24
linebuf:.space 96
exit_blk:
	.space	16
