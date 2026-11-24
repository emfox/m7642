#!/usr/bin/env python3
"""Fix the leftovers after the ~/kbuild -> ~/Debian/m7642-build relocation."""
import os, subprocess

REPO = os.path.expanduser("~/Debian/m7642")
NEW = "Debian/m7642-build"

def edit(rel, pairs):
    p = os.path.join(REPO, rel)
    if not os.path.exists(p):
        print("  missing", rel); return
    s = open(p).read()
    o = s
    for a, b in pairs:
        s = s.replace(a, b)
    if s != o:
        open(p, "w").write(s)
        print("  edited ", rel)
    else:
        print("  nochange", rel)

# ---- probes/fcie/build.sh: ko lands in the new module dir
edit("probes/fcie/build.sh", [
    ('\tHOME=$HOME "$HOME/Debian/m7642-build/scripts/build-probe.sh" fcie >/dev/null\n'
     '\tcp "$HOME/kbuild/fcie/fcie.ko" "$W/fcie.ko"',
     '\t"$HOME/Debian/m7642-build/scripts/build-probe.sh" fcie >/dev/null\n'
     '\tcp "$HOME/Debian/m7642-build/build/modules/fcie/fcie.ko" "$W/fcie.ko"'),
])

# ---- handoff: the default Image used to be the 4.19 tree
edit("probes/handoff/mk-mainline-abort.py", [
    ('default="/home/emfox/kbuild/tcl-419/arch/arm64/boot/Image"',
     'default="/home/emfox/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image"'),
])
edit("tools/host/mk-mainline-abort.py", [
    ('default="/home/emfox/kbuild/tcl-419/arch/arm64/boot/Image"',
     'default="/home/emfox/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image"'),
])

# ---- assorted script paths
edit("tools/host/prep-env-rec.sh", [("K=/home/emfox/kbuild", "K=/home/emfox/Debian/m7642-build")])
edit("tools/host/run-abort0.sh", [
    ("/home/emfox/kbuild/env-before-abort.bin",
     "/home/emfox/Debian/m7642-build/diag/env-before-abort.bin")])
edit("tools/host/bootarm.sh", [
    ('find "$HOME/kbuild" -maxdepth 2 -name', 'find "$HOME/Debian/m7642-build" -maxdepth 4 -name')])
edit("tools/host/disasm_probe5.py", [
    ('OBJDUMP = "/home/emfox/kbuild/aarch64--glibc--stable-2018.11-1/bin/aarch64-linux-objdump"',
     'OBJDUMP = "/home/emfox/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-objdump"')])
edit("probes/fcie/dumps/README.md", [
    ("~ /kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-objdump",
     "~/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-objdump")])

# ---- docs: env snapshot / mioreg / score dir
edit("Documentation/mstar/m7642/HANDOFF.md", [
    ("| `~/kbuild/env-after-rescue.bin` |",
     "| `~/Debian/m7642-build/diag/env-after-rescue.bin` |"),
    ("~/kbuild/... envtool.py list/get/set/verify <block>",
     "envtool.py list/get/set/verify <block>（env 快照在 ~/Debian/m7642-build/diag/）"),
])
edit("Documentation/mstar/m7642/emmc.md", [
    ("`mioreg` 在 `~/kbuild/tools/mioreg`（aarch64 静态链接，649 KB）。",
     "`mioreg` 原先在 `~/kbuild/tools/mioreg`（aarch64 静态链接，649 KB）；"
     "该静态二进制随 2026-11-22 的 kbuild 清理一起删掉了，需要时按同一节的方法现场编一个"
     "（或直接用 `probeRW` 读物理地址）。"),
    ("adb push ~/kbuild/tools/mioreg /data/local/tmp/mioreg",
     "adb push <编出来的 m ioreg> /data/local/tmp/mioreg"),
])
edit("Documentation/mstar/m7642/portability.md", [
    ("# 日志落在 ~/kbuild/score/<driver>.log，统计：",
     "# 日志落在 ~/Debian/m7642-build/diag/score/<driver>.log，统计："),
    ('grep "error:" ~/kbuild/score/mmc.log',
     'grep "error:" ~/Debian/m7642-build/diag/score/mmc.log'),
])

# ---- 4.19 退役标注
edit("Documentation/mstar/m7642/confirmed-facts.md", [
    ("**4.19**（`~/kbuild/tcl-419`，源自 `Thedemon007/realme_Smart_TV_4K-kernel-source`）",
     "**4.19**（原 `~/kbuild/tcl-419`，源自 `Thedemon007/realme_Smart_TV_4K-kernel-source`；"
     "**2026-11-22 已随 kbuild 清理删除**——post-MMU 检查点仪器与 eMMC 读通道打通后，"
     "4.19 这条绕行路线不再需要；本节保留作为历史结论）"),
])
edit("Documentation/mstar/m7642/discipline.md", [
    ("**4.19 树（`~/kbuild/tcl-419/`）专属**",
     "**4.19 树（原 `~/kbuild/tcl-419/`，2026-11-22 已删除）专属**"),
    ("- 产物一律落 `~/Debian/<项目>/` 或 `~/kbuild/`，不在外面新开目录。",
     "- 产物一律落 `~/Debian/<项目>/` 或 `~/Debian/m7642-build/`，不在外面新开目录。"),
])
edit("Documentation/mstar/m7642/display.md", [
    ("CROSS=$HOME/kbuild/aarch64--glibc--stable-2018.11-1/bin/aarch64-linux-",
     "CROSS=$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-"),
])
print("done")
