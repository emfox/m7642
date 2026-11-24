import os
D=os.path.expanduser("~/Debian/m7642/probes/handoff")

p=os.path.join(D,"tramp-postmmu.S"); s=open(p).read()
anchor="1:\n\tmovz\tx16, #(BOOT_ARGS_PA & 0xffff)"
assert anchor in s, "anchor missing"
if "\tmov\tx21, x8\n" not in s:
    s=s.replace(anchor, "1:\n\tmov\tx21, x8\t\t\t/* the `br x8` target, for the record */\n"
                        "\tmrs\tx22, sctlr_el1\t\t/* was the MMU really on? */\n\n" + anchor[3:], 1)
    open(p,"w").write(s)
assert "\tmov\tx21, x8\n" in open(p).read(), "tramp not patched"
print("tramp OK")

p=os.path.join(D,"abort-postmmu.S"); s=open(p).read()
if "str\tx21, [x6, #64]" not in s:
    s=s.replace("mov\tw7, #0x40","mov\tw7, #0x50",1)
    s=s.replace("str\tx4, [x6, #56]\n\tdsb\tsy",
                "str\tx4, [x6, #56]\n\tstr\tx21, [x6, #64]\n\tstr\tx22, [x6, #72]\n\tdsb\tsy",1)
    open(p,"w").write(s)
assert "str\tx21, [x6, #64]" in open(p).read(), "abort not patched"
print("abort OK")
