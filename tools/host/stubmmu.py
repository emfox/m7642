import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/abort-postmmu.S")
s=open(p).read()
if "cbz\tx5, 9f" in s: print("already"); raise SystemExit
old="""handover_phys:
	/* x5 = 0 (MMU off, physical addressing) or the linear-map offset
	 * (MMU on, so every physical address needs + x5).  Set by the tramp:
	 * after cpu_uninstall_idmap() the identity map is gone and a bare
	 * physical address is an unmapped user VA. */"""
new="""handover_phys:
	/* The tramp may enter here with the MMU still on (it installs a 1 GB
	 * identity block just before jumping, so this physical address is
	 * addressable).  Clear M/C/I now that we are identity-mapped and never
	 * come back: from here on everything is plain physical addressing, which
	 * is the state mboot hands the factory kernel. */
	cbz	x5, 9f
	mrs	x16, sctlr_el1
	bic	x16, x16, #1
	bic	x16, x16, #4
	bic	x16, x16, #0x1000
	msr	sctlr_el1, x16
	isb
	mov	x5, xzr
9:"""
assert old in s
open(p,'w').write(s.replace(old,new,1)); print("stub: 进来先关 MMU")
