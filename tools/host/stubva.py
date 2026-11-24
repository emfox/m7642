import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/abort-postmmu.S")
s=open(p).read()
if "add\tx6, x6, x5" in s:
    print("already"); raise SystemExit
reps=[("""handover_phys:
	movz	x6, #0x2308
	lsl	x6, x6, #16		/* 0x23080000 */""",
"""handover_phys:
	/* x5 = 0 (MMU off, physical addressing) or the linear-map offset
	 * (MMU on, so every physical address needs + x5).  Set by the tramp:
	 * after cpu_uninstall_idmap() the identity map is gone and a bare
	 * physical address is an unmapped user VA. */
	movz	x6, #0x2308
	lsl	x6, x6, #16		/* 0x23080000 */
	add	x6, x6, x5"""),
("""	add	x6, x6, #0x800		/* staged factory kernel */
	movz	x7, #0x2028
	lsl	x7, x7, #16		/* runtime image base */""",
"""	add	x6, x6, #0x800		/* staged factory kernel */
	add	x6, x6, x5
	movz	x7, #0x2028
	lsl	x7, x7, #16		/* runtime image base */
	add	x7, x7, x5"""),
("""	movz	x9, #0x2122
	lsl	x9, x9, #16		/* factory entry 0x21220000 */
	br	x9""",
"""	movz	x9, #0x2122
	lsl	x9, x9, #16		/* factory entry 0x21220000 */
	add	x9, x9, x5
	br	x9""")]
for a,b in reps:
    assert a in s, a[:40]
    s=s.replace(a,b,1)
open(p,"w").write(s); print("stub: x5 偏移已加")
