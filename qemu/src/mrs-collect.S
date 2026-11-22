/* mrs-collect.S -- print the seven identity registers the stub now records.
 * Same instructions, same order, no MMU needed: used to get the numbers from a
 * board where the full chain cannot run (e.g. -M virt, whose RAM does not cover
 * the handover stub's TV addresses). */
#include "sh.inc"
	.text
	.globl	_start
_start:
	SH_PUTS	s_midr
	mrs	x12, midr_el1
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_ctr
	mrs	x12, ctr_el0
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_nl
	SH_PUTS	s_revidr
	mrs	x12, revidr_el1
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_tcr
	mrs	x12, tcr_el1
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_nl
	SH_PUTS	s_mair
	mrs	x12, mair_el1
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_mmfr0
	mrs	x12, id_aa64mmfr0_el1
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_nl
	SH_PUTS	s_mpidr
	mrs	x12, mpidr_el1
	adr	x15, prbuf
	SH_HEX	x12, x15
	SH_PUTS	s_nl
	mov	x3, #0
	SH_EXIT_CODE x3, exit_blk
	.balign 8
prbuf:	.space	24
exit_blk:
	.space	16
s_midr:		.asciz	"MIDR=0x"
s_ctr:		.asciz	" CTR_EL0=0x"
s_revidr:	.asciz	"REVIDR=0x"
s_tcr:		.asciz	" TCR_EL1=0x"
s_mair:		.asciz	"MAIR=0x"
s_mmfr0:	.asciz	" ID_AA64MMFR0=0x"
s_mpidr:	.asciz	"MPIDR=0x"
s_nl:		.asciz	"\n"
