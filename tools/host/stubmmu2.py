import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/abort-postmmu.S")
s=open(p).read()
old="""	cbz	x5, 9f
	mrs	x16, sctlr_el1"""
new="""	mrs	x16, sctlr_el1
	tbz	x16, #0, 9f		/* M == 0 -> the MMU is already off */
				/* (test the hardware, not a value we passed in:
				 * trusting a register once put us here with the MMU
				 * on while the code believed it was off) */"""
assert old in s
open(p,"w").write(s.replace(old,new,1)); print("stub: 用 SCTLR.M 判 MMU 状态")
