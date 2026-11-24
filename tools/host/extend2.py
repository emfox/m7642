import os
D=os.path.expanduser("~/Debian/m7642/probes/handoff")
p=os.path.join(D,"tramp-postmmu.S"); s=open(p).read()
anchor="1:\n\tmovz\tx16, #(BOOT_ARGS_PA & 0xffff)"
assert anchor in s, "tramp anchor missing"
if "mov\tx21, x8" not in s:
    s=s.replace(anchor, "1:\n\tmov\tx21, x8\t\t\t/* the `br x8` target */\n\tmrs\tx22, sctlr_el1\t\t/* was the MMU really on? */\n\n" + anchor[len("1:\n"):], 1)
    open(p,"w").write(s); print("tramp patched")
else: print("tramp already patched")

p=os.path.join(D,"abort-postmmu.S"); s=open(p).read()
if "str\tx21, [x6, #64]" not in s:
    assert "mov\tw7, #0x40" in s and "str\tx4, [x6, #56]" in s
    s=s.replace("mov\tw7, #0x40","mov\tw7, #0x50",1)
    s=s.replace("str\tx4, [x6, #56]\n\tdsb\tsy","str\tx4, [x6, #56]\n\tstr\tx21, [x6, #64]\t\t/* `br x8` target, filled by the tramp */\n\tstr\tx22, [x6, #72]\t\t/* SCTLR_EL1 at the checkpoint */\n\tdsb\tsy",1)
    open(p,"w").write(s); print("abort patched")
else: print("abort already patched")

# verify
for f,needle in (("tramp-postmmu.S","mov\tx21, x8"),("abort-postmmu.S","str\tx21, [x6, #64]")):
    t=open(os.path.join(D,f)).read()
    print(("OK   " if needle in t else "FAIL ")+f)
