import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/tramp-postmmu.S"); s=open(p).read()
start = s.index("\t.globl\t_start_kva\n_start_kva:\n")
end = s.index("\t.org\t0xc0")
body = """	.globl	_start_kva
_start_kva:
#if WORLD_VA
	/* World (B): the identity map is gone (the checkpoint is at or after
	 * cpu_uninstall_idmap()), so a physical address is no longer an address.
	 * Stay at the kernel VA; the common path installs an identity map. */
	movz	x5, #(KIMAGE_OFFSET & 0xffff)
	movk	x5, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x5, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x5, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	b	1f
#else
	/* World (A): the identity map is still installed.  This is exactly the
	 * path f1/ps1z/skmainz used on hardware: hop to our physical alias and
	 * clear the MMU there.  No page tables, no TCR games, no probing.
	 *
	 * The world is chosen at BUILD time (-DWORLD_VA=1).  A runtime probe with
	 * AT S1E1R was tried and the resulting image hung on the device at a
	 * checkpoint where this very path is known to work, so nothing about the
	 * world is inferred at runtime any more. */
	adr	x16, 1f
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr
	br	x16
#endif

"""
open(p,"w").write(s[:start]+body+s[end:])
t=open(p).read()
print("WORLD_VA present:", "WORLD_VA" in t, "| AT probe left:", t.count("at\ts1e1r"))
