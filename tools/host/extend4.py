import os
D=os.path.expanduser("~/Debian/m7642/probes/handoff")

p=os.path.join(D,"tramp-postmmu.S"); s=open(p).read()
old="""1:
	mov	x21, x8"""
new="""1:
	/* capture the checkpoint's entry registers before we clobber them;
	 * the handover stub stores x21..x26 into the record.  This is how a
	 * checkpoint on a function *entry* reports its arguments. */
	mov	x21, x8
	mov	x22, x0
	mov	x23, x1
	mov	x24, x2
	mov	x25, x3
	mov	x26, x4"""
assert old in s, "tramp anchor missing"
if "mov\tx23, x1" not in s:
    s=s.replace(old,new,1)
    s=s.replace("\tmrs\tx22, sctlr_el1\t\t/* was the MMU really on? */\n","",1)
    open(p,"w").write(s); print("tramp: 记录 entry x0..x4（+x8）")
else: print("tramp already")

p=os.path.join(D,"abort-postmmu.S"); s=open(p).read()
if "str\tx26, [x6, #96]" not in s:
    s=s.replace("mov\tw7, #0x50","mov\tw7, #0x70",1)
    s=s.replace("str\tx21, [x6, #64]\n\tstr\tx22, [x6, #72]",
                "str\tx21, [x6, #64]\n\tstr\tx22, [x6, #72]\n\tstr\tx23, [x6, #80]\n"
                "\tstr\tx24, [x6, #88]\n\tstr\tx25, [x6, #96]\n\tstr\tx26, [x6, #104]",1)
    open(p,"w").write(s); print("abort: 记录 6 个值（0x70 字节）")
else: print("abort already")
print("verify:", "mov\tx23, x1" in open(os.path.join(D,"tramp-postmmu.S")).read(),
      "str\tx26, [x6, #96]" in open(os.path.join(D,"abort-postmmu.S")).read())
