import os
p = os.path.expanduser("~/Debian/m7642-build/kernel/linux-git/probes_placeholder")
# 实际文件在仓库里
p = os.path.expanduser("~/Debian/m7642/probes/handoff/tramp-postmmu.S")
s = open(p).read()

if "_start_save" in s:
    print("already present"); raise SystemExit

# 常量
s = s.replace("""#ifndef HANDOVER_PA""",
"""/* Where the returning probe parks TCR_EL1/TTBR0_EL1 for the restore probe.
 * Inside the image (.bss), so it is reachable through the kernel mapping no
 * matter whether the identity map is still alive. */
#ifndef SAVE_VA
#define SAVE_VA 0xffffffc080603000
#endif
#ifndef HANDOVER_PA""")

addition = """
/* --------------------------------------------------------------------- *
 * World (A) returning probe: park TCR_EL1/TTBR0_EL1 before the kernel tears
 * down its identity map, then re-execute the instruction we replaced and
 * return.  It writes a "SAVE" record first, so a later checkpoint proves the
 * kernel survived the round trip (otherwise a hang here is indistinguishable
 * from the kernel's own hang).
 * --------------------------------------------------------------------- */
	.org	0x200
	.globl	_start_save
_start_save:
	movz	x16, #(SAVE_VA & 0xffff)
	movk	x16, #((SAVE_VA >> 16) & 0xffff), lsl #16
	movk	x16, #((SAVE_VA >> 32) & 0xffff), lsl #32
	movk	x16, #((SAVE_VA >> 48) & 0xffff), lsl #48
	mrs	x17, tcr_el1
	str	x17, [x16, #0x18]
	mrs	x17, ttbr0_el1
	str	x17, [x16, #0x20]
	movz	w17, #0x374d
	movk	w17, #0x3436, lsl #16	/* "M764" */
	str	w17, [x16, #0x10]
	movz	w17, #0x4153
	movk	w17, #0x5645, lsl #16	/* "SAVE" */
	str	w17, [x16, #0x14]
	dsb	sy
	mov	x0, #0xc0		/* the instruction this checkpoint replaced */
	ret

/* --------------------------------------------------------------------- *
 * World (B) entry: put the kernel's own TCR_EL1/TTBR0_EL1 back, so the
 * identity map is valid again, then take the proven physical path.
 * --------------------------------------------------------------------- */
	.org	0x240
	.globl	_start_restore
_start_restore:
	movz	x16, #(SAVE_VA & 0xffff)
	movk	x16, #((SAVE_VA >> 16) & 0xffff), lsl #16
	movk	x16, #((SAVE_VA >> 32) & 0xffff), lsl #32
	movk	x16, #((SAVE_VA >> 48) & 0xffff), lsl #48
	ldr	x17, [x16, #0x18]
	msr	tcr_el1, x17
	isb
	ldr	x17, [x16, #0x20]
	msr	ttbr0_el1, x17
	dsb	nsh
	isb
	tlbi	vmalle1
	dsb	nsh
	isb
	adr	x16, 1f
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr
	br	x16
"""
# 插在 shim 之前的 .org 0xc0 之前？不行——必须在 shim 之后。插到文件末尾（blob 尾部）
s = s.rstrip("\n") + "\n" + addition
open(p, "w").write(s)
print("tramp: _start_save(0x200) 与 _start_restore(0x240) 已加")
