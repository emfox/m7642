/*
 * sh.inc -- semihosting helpers for the offline bench.
 *
 * Everything is a macro on purpose: the fault handlers must work with a broken
 * MMU and with SP = 0 (the tramp zeroes SP), so no stack, no BL, no literal
 * pools are used anywhere in here.
 *
 * QEMU exit-code semantics (measured on 11.1.3, see README):
 *   SYS_EXIT          (0x18)              -> qemu exits 1, whatever the reason
 *   SYS_EXIT_EXTENDED (0x20) {0x20026, n} -> qemu exits n
 * so the fatal path uses SYS_EXIT (always non-zero = FAIL) and needs no memory
 * at all, while the landing pad (which runs with a working identity map) uses
 * SYS_EXIT_EXTENDED to hand back a specific code.
 *
 * SYS_WRITEC (0x03) is *not* usable in this QEMU: it writes 0x00 instead of the
 * character, so every print goes through SYS_WRITE0 with a string.
 */
#ifndef SH_INC
#define SH_INC 1

/* debug aid: spin in the fault handler so the QEMU monitor can read registers */
#ifndef SPIN_ON_FAULT
#define SPIN_ON_FAULT 0
#endif

/* reg <- 64-bit immediate constant (symbols included: GAS resolves them) */
.macro LQ reg, val
	movz	\reg, #((\val) & 0xffff)
	movk	\reg, #(((\val) >> 16) & 0xffff), lsl #16
	movk	\reg, #(((\val) >> 32) & 0xffff), lsl #32
	movk	\reg, #(((\val) >> 48) & 0xffff), lsl #48
.endm

/* SYS_WRITE0: print the NUL-terminated string that \reg points at */
.macro SH_PUTS_REG reg
	mov	x0, #0x04
	mov	x1, \reg
	hlt	#0xf000
.endm

/* SYS_WRITE0 with an ADR-relative label (works in PA and VA regime alike) */
.macro SH_PUTS lbl
	adr	x11, \lbl
	mov	x0, #0x04
	mov	x1, x11
	hlt	#0xf000
.endm

/*
 * Print \valreg as 16 hex digits through the NUL-terminated buffer \bufreg.
 * clobbers x11..x14.
 */
.macro SH_HEX valreg, bufreg
	mov	x11, \bufreg
	mov	x12, \valreg
	mov	x13, #60
1:	lsr	x14, x12, x13
	and	x14, x14, #0xf
	cmp	x14, #9
	b.hi	2f
	add	x14, x14, #0x30
	b	3f
2:	add	x14, x14, #0x37
3:	strb	w14, [x11], #1
	subs	x13, x13, #4
	b.pl	1b
	mov	w14, #0
	strb	w14, [x11]
	mov	x0, #0x04
	mov	x1, \bufreg
	hlt	#0xf000
.endm

/* print "label + 16 hex digits"; prbuf must exist in the caller's section.
 * clobbers x11..x15 */
.macro PH lbl, valreg
	SH_PUTS	\lbl
	adr	x15, prbuf
	SH_HEX	\valreg, x15
.endm

/* assert \valreg == \wantreg; on mismatch record the check number and bail out */
.macro CK num, valreg, wantreg
	cmp	\valreg, \wantreg
	b.eq	.Lck_ok\@
	mov	x25, #\num
	b	.Lpad_fail
.Lck_ok\@:
.endm

/* fatal: exit non-zero without touching memory (needs no valid translation) */
.macro SH_EXIT_FAIL
#if SPIN_ON_FAULT
1:	b	1b
#else
	mov	x0, #0x18
	movz	x1, #0x0026
	movk	x1, #0x2, lsl #16
	hlt	#0xf000
1:	b	1b
#endif
.endm

/* landing pad: exit with \codereg as the QEMU exit status (0 = PASS) */
.macro SH_EXIT_CODE codereg, blklbl
	adr	x1, \blklbl
	movz	x2, #0x0026
	movk	x2, #0x2, lsl #16		/* ADP_Stopped_ApplicationExit */
	str	x2, [x1]
	str	\codereg, [x1, #8]
	mov	x0, #0x20			/* SYS_EXIT_EXTENDED */
	hlt	#0xf000
1:	b	1b
.endm

#endif /* SH_INC */
