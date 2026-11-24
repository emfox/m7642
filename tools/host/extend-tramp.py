import os
D=os.path.expanduser("~/Debian/m7642/probes/handoff")

# 1) tramp: 在已证明能用的路径上多抓两个值
p=os.path.join(D,"tramp-postmmu.S")
s=open(p).read()
if "x21" not in s:
    s=s.replace("""1:
	movz	x16, #(BOOT_ARGS_PA & 0xffff)""","""1:
	/* record what we were told, before anything else: x8 is the `br x8`
	 * target the kernel was about to jump to, and SCTLR says whether the
	 * MMU was really on.  x21/x22 are untouched by the handover stub. */
	mov	x21, x8
	mrs	x22, sctlr_el1

	movz	x16, #(BOOT_ARGS_PA & 0xffff)""")
    open(p,"w").write(s)
    print("tramp: 抓 x8 / sctlr_el1")

# 2) abort: 把 x21/x22 也写进记录
p=os.path.join(D,"abort-postmmu.S")
s=open(p).read()
if "x21" not in s:
    s=s.replace("""	mov	w7, #0x40
	str	w7, [x6, #8]""","""	mov	w7, #0x50
	str	w7, [x6, #8]""")
    s=s.replace("""	str	x4, [x6, #56]
	dsb	sy""","""	str	x4, [x6, #56]
	str	x21, [x6, #64]		/* the `br x8` target (from the tramp) */
	str	x22, [x6, #72]		/* SCTLR_EL1 at the checkpoint */
	dsb	sy""")
    s=s.replace(""" * It records "M764"/"MMMU", x30 (the checkpoint return address) and the boot
 * arguments into 0x23080000""",""" * It records "M764"/"MMMU", x30 (the checkpoint return address), the boot
 * arguments, and x21/x22 (which the tramp fills with the `br x8` target and
 * SCTLR_EL1 at the checkpoint) into 0x23080000""")
    open(p,"w").write(s)
    print("abort: 记录扩展到 0x50 字节（x8 目标 + SCTLR）")
