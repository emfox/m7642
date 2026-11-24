import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/abort-postmmu.S")
s=open(p).read()

# 1) 在关 MMU 之前把内核原本的 SCTLR_EL1 留下来（x27 槽位复用）
old_head = """	mrs	x16, sctlr_el1
	tbz	x16, #0, 9f		/* M == 0 -> the MMU is already off */"""
new_head = """	mrs	x16, sctlr_el1
	mov	x27, x16		/* keep the kernel's own SCTLR for the record */
	tbz	x16, #0, 9f		/* M == 0 -> the MMU is already off */"""
assert old_head in s
s = s.replace(old_head, new_head, 1)

# 2) 记录：0x90 -> 0xB0，尾部加硬件身份寄存器
old_tail = """	str	x27, [x6, #112]		/* kimage = VA - PA (measured with AT) */
	str	x28, [x6, #120]		/* memstart_addr */
	str	x29, [x6, #128]		/* lin = PAGE_OFFSET - memstart_addr */
	dsb	sy"""
new_tail = """	str	x27, [x6, #112]		/* SCTLR_EL1 as the kernel had it */
	/* Hardware identity.  Read on the TV and in QEMU so that we can say how
	 * faithful the emulation is for the parts we exercise (page tables and
	 * cache maintenance depend on CTR/TCR/MAIR, not on the core's marketing
	 * name).  These need no MMU, so they are safe here. */
	mrs	x17, midr_el1
	str	x17, [x6, #120]
	mrs	x17, ctr_el0
	str	x17, [x6, #128]
	mrs	x17, revidr_el1
	str	x17, [x6, #136]
	mrs	x17, tcr_el1
	str	x17, [x6, #144]
	mrs	x17, mair_el1
	str	x17, [x6, #152]
	mrs	x17, id_aa64mmfr0_el1
	str	x17, [x6, #160]
	mrs	x17, mpidr_el1
	str	x17, [x6, #168]
	dsb	sy"""
assert old_tail in s
s = s.replace(old_tail, new_tail, 1)
s = s.replace("\tmov\tw7, #0x90\n\tstr\tw7, [x6, #8]", "\tmov\tw7, #0xB0\n\tstr\tw7, [x6, #8]",1)
open(p,"w").write(s); print("stub: 记录 0xB0，含 7 个身份寄存器")
