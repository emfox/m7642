#!/usr/bin/env python3
"""Repoint every ~/kbuild reference at the relocated ~/Debian/m7642-build tree."""
import os, re, subprocess

REPO = os.path.expanduser("~/Debian/m7642")
NEW = "Debian/m7642-build"

# (old suffix after kbuild/, new suffix after Debian/m7642-build/)
PAIRS = [
    ("linux-main",            "kernel/linux-main"),
    ("kernel_mstar-main",     "kernel/mstar-4.9"),
    ("toolchain-gcc13",       "toolchain/gcc13"),
    ("m7642-out",             "out"),
    ("fcie-build",            "build/fcie-build"),
    ("backup/fix",            "backups/fix"),
    ("backup/",               "backups/"),
    ("rec/",                  "backups/partitions/rec/"),
    ("boot-stock-backup.bin", "backups/partitions/boot-stock-backup.bin"),
    ("rescue/partial",        "backups/rescue/partial"),
    ("m7642-dt",              "ref/m7642-dt"),
    ("emmcboot",              "ref/emmcboot"),
    ("hal-dumps",             "ref/hal-dumps"),
    ("mboot-src",             "ref/mboot-src"),
    ("mpool3.bin",            "diag/mpool3.bin"),
    ("mboot-guide.pdf",       "diag/mboot-guide.pdf"),
    ("live.dtb",              "diag/live.dtb"),
    ("factory-4.9.config",    "diag/factory-4.9.config"),
    ("vendor.config",         "diag/vendor.config"),
    ("dmesg-warm1.txt",       "diag/dmesg-warm1.txt"),
    ("dmesg-cold1.txt",       "diag/dmesg-cold1.txt"),
    ("dmesg-after-boot.txt",  "diag/dmesg-after-boot.txt"),
    ("env-write.bin",         "diag/env-write.bin"),
    ("tvrun.sh",              "scripts/tvrun.sh"),
    ("precheck.sh",           "scripts/precheck.sh"),
    ("scan5555.sh",           "scripts/scan5555.sh"),
    ("wait-dmesg.sh",         "scripts/wait-dmesg.sh"),
    ("build-probe.sh",        "scripts/build-probe.sh"),
    ("score-drivers.sh",      "scripts/score-drivers.sh"),
    ("scan_pkgs.py",          "scripts/scan_pkgs.py"),
    ("mark.bin",              "scripts/mark.bin"),
]

PREFIXES = ["~/kbuild/", "$HOME/kbuild/", "${HOME}/kbuild/", "/home/emfox/kbuild/"]

def new_prefix(p):
    return p.replace("kbuild/", NEW + "/")

def rewrite(text):
    for pre in PREFIXES:
        for old, new in PAIRS:
            text = text.replace(pre + old, new_prefix(pre) + new)
    return text

changed = []
files = subprocess.run(["git", "-C", REPO, "ls-files"], capture_output=True, text=True).stdout.split()
for rel in files:
    p = os.path.join(REPO, rel)
    try:
        s = open(p, "rb").read().decode("utf-8")
    except (UnicodeDecodeError, IsADirectoryError):
        continue
    n = rewrite(s)
    if n != s:
        open(p, "w").write(n)
        changed.append(rel)

print("改动的文件 %d 个:" % len(changed))
for c in changed:
    print("  ", c)

# 剩下的引用（需要人工判断）
print("\n=== 仍含 kbuild 的行（去掉新树自身后）:")
out = subprocess.run(["git", "-C", REPO, "grep", "-n", "kbuild"],
                     capture_output=True, text=True).stdout
left = [l for l in out.splitlines() if NEW not in l]
for l in left[:60]:
    print("  ", l)
print("  共 %d 行" % len(left))
