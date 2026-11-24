#!/usr/bin/env python3
"""Final doc touch-ups after the attic move."""
import os
D = os.path.expanduser("~/Debian/m7642")

NOTE = ("> ⚠️ **原始数据不在仓库里**：本文引用的 `artifacts/probe-out/` 下 dump "
        "已移到仓库外 `~/Debian/m7642-attic/`（原因见 "
        "[paths.md](paths.md) §0，清单见该目录的 `ATTIC.md`）。\n\n")

# --- gop-registers.md: the main data-citing doc
p = os.path.join(D, "Documentation/mstar/m7642/gop-registers.md")
s = open(p).read()
if "原始数据不在仓库里" not in s:
    i = s.index("\n## ")
    s = s[:i] + "\n" + NOTE.rstrip("\n") + "\n" + s[i:]
    open(p, "w").write(s)
    print("gop-registers.md noted")

# --- probes/README.md: table no longer matches the directory
p = os.path.join(D, "probes/README.md")
s = open(p).read()
s = s.replace(
    "| `probeD/`、`probe1..8.c` | 早期一次性探针，保留作参考 |\n",
    "| `probeRW/` | 读物理内存（`op=r addr= len=`），code1 记录的标准读出工具 |\n"
    "| `wdtdump/` | 按符号 dump 代码（`sym=`），取证反汇编用 |\n"
    "| `fcie/` | eMMC/FCIE：18 步 CMD17 读通道 + 各级诊断镜像 |\n"
    "| `handoff/` | post-MMU 检查点仪器（tramp + handover + 运行脚本） |\n"
    "| `ladder/` | pre-MMU 梯级 stub（`-DCOLOUR= -DSTEP= -DHALT=`） |\n"
    "| `feat/`、`pmbase/`、`rstcall/`、`panicmod/`、`hangmod/`、`mark600/`、`pstub/`、`tramp/`、`pmsg/` | 专题小工具 |\n")
if "早期一次性探针" not in s and "`probeD/`" not in s:
    s = s.replace(
        "## 用法",
        "早期一次性探针（`probeD/`、`probe1..8.c`、颜色期与入口期的 `paint*/`、\n"
        "`entry2/`、`entry-race/`、`factory-hook/` 等）已移到仓库外\n"
        "`~/Debian/m7642-attic/probes/`；本目录只留仍在使用的源码。\n\n"
        "构建产物（`.bin`/`.elf`/`.ko`/`.o`）一律不入库，用各目录的 `build*.sh` 现生成。\n\n"
        "## 用法")
open(p, "w").write(s)
print("probes/README.md updated")
