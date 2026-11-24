import os
p = os.path.expanduser("~/Debian/m7642/probes/handoff/tramp-postmmu.S")
s = open(p).read()
if "_start_count" in s:
    print("already"); raise SystemExit
addition = """
/* --------------------------------------------------------------------- *
 * Counting returning probe.
 *
 * Patched over the head of a sequential loop.  For the first COUNT_N hits it
 * bumps a counter in the SAVE page, *emulates the instruction it replaced* and
 * returns to the kernel -- so the run continues and costs no power cycle.  On
 * hit COUNT_N+1 it stops being polite: it restores TCR_EL1/TTBR0_EL1 (this runs
 * in world B) and takes the proven physical path, so the handover record tells
 * us how far the loop actually got.
 *
 * The counter sits at SAVE_VA+0x78, which is the last slot the handover stub
 * copies into the record (readout slot 7), so the final count is readable.
 *
 * COUNT_EMUL selects what to replay:
 *   ldr  -> ldr x27, [x24, x19, lsl #3]        (loop head of the 14-item walk)
 * --------------------------------------------------------------------- */
	.org	0x700
	.globl	_start_count
_start_count:
	movz	x16, #((SAVE_VA + 0x78) & 0xffff)
	movk	x16, #(((SAVE_VA + 0x78) >> 16) & 0xffff), lsl #16
	movk	x16, #(((SAVE_VA + 0x78) >> 32) & 0xffff), lsl #32
	movk	x16, #(((SAVE_VA + 0x78) >> 48) & 0xffff), lsl #48
	ldr	x17, [x16]
	add	x17, x17, #1
	str	x17, [x16]
	cmp	x17, #(COUNT_N)
	b.hi	7f			/* past N: stop returning, hand over */
	/* still counting: replay the instruction we replaced and go back */
	ldr	x27, [x24, x19, lsl #3]
	dsb	sy
	ret
7:	/* hand over the way _start_restore does: world B -> world A addressable */
	ldr	x17, [x16, #0x18 - 0x78]	/* TCR_EL1 as saved by the d0 probe */
	msr	tcr_el1, x17
	isb
	ldr	x17, [x16, #0x20 - 0x78]	/* the kernel's own init idmap */
	msr	ttbr0_el1, x17
	dsb	nsh
	isb
	tlbi	vmalle1
	dsb	nsh
	isb
	adr	x16, 1b
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr
	br	x16
"""
s = s.rstrip("\n") + "\n" + addition
open(p, "w").write(s)
print("tramp: _start_count(0x700) 已加")
