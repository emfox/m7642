#!/usr/bin/env python3
"""Repository tidy-up: docs edits for the asset-only repo."""
import io, os, re, sys

D = os.path.expanduser("~/Debian/m7642")
DOC = os.path.join(D, "Documentation/mstar/m7642")

def edit(path, fn):
    p = os.path.join(D, path) if not path.startswith("/") else path
    s = open(p).read()
    new = fn(s)
    if new == s:
        print("nochange", path)
    else:
        open(p, "w").write(new)
        print("edited  ", path)

# ---------- index.md ----------
def f_index(s):
    s = s.replace(
        "| [boot-test.md](boot-test.md) | 启动路径：实测 boot image 参数、分区、可观察性 |\n",
        "")
    s = s.replace(
        "| [ladder6-readout.md](ladder6-readout.md) ~ [ladder9-readout.md](ladder9-readout.md) | 第 6–9 次梯级的实测读out |\n",
        "")
    old = "| [prior-art.md](prior-art.md) |"
    add = ("\n> **早期原始记录不在仓库里**：`boot-test.md`（5600 行的启动路径研究日志）、\n"
           "> `ladder6`–`ladder9-readout.md`（已作废的颜色判据读out）已移出，见\n"
           "> [paths.md](paths.md) §0。它们的结论都已并入 `confirmed-facts.md`、\n"
           "> `factory49-entry.md`、`display.md`。\n\n")
    if old in s and "早期原始记录不在仓库里" not in s:
        s = s.replace(old, add + old, 1)
    return s

edit("Documentation/mstar/m7642/index.md", f_index)

# ---------- paths.md ----------
def f_paths(s):
    s = s.replace(
        "| [ladder6-readout.md](ladder6-readout.md) ~ [ladder9-readout.md](ladder9-readout.md) | 第 6–9 次梯级的实测读out |\n", "")
    s = s.replace(
        "| [boot-test.md](boot-test.md) | 启动路径、boot image 参数、分区、可观察性（最大的一份） |\n", "")
    s = s.replace(
        "| `~/Debian/m7642/` | **本项目主仓库**（git，分支 `master`，**无远端**，本地历史） | 文档 / 补丁 / 探针 / 主机侧工具 / 刷机包工具 |",
        "| `~/Debian/m7642/` | **本项目主仓库**（git，分支 `master`，远端 `git@github.com:emfox/m7642.git`） | 文档 / 补丁 / 探针源码 / 脚本 / 刷机包工具 |\n"
        "| `~/Debian/m7642-attic/` | **仓库外留存区**：原始导出、构建产物、一次性实验、作废读数日志 | 不进 git；清单见其 `ATTIC.md` |")
    section = """## 0 仓库收什么（2026-11-22 定）

**入库**：文档（结论 + 方法论）、可复用源码（`.c/.h/.S/.dts/.dtsi`）、脚本（`.sh/.py`）、
补丁、`Makefile`/`README`，以及少量必需的参照数据（`probes/expect.tsv`、
`probes/device-config.gz`、活体设备树、反汇编清单）。

**不入库**：设备分区原始导出（`*-part-full-*.bin`、`*.img`）、构建与运行产物
（`.bin/.elf/.ko/.o/.out/.tar/.dump`）、一次性实验代码、作废的读数日志。

这些文件没有删除，统一平移到 `~/Debian/m7642-attic/<原相对路径>`，
清单是 `~/Debian/m7642-attic/ATTIC.md`。文档里对它们的引用（例如
`artifacts/probe-out/…`、`probes/ladder/blue.bin`）都按原相对路径去那里找。

目标：仓库只留"能重跑出结论的东西"，体积从 56 MB 降到个位数，
并且**不把厂商二进制和本机 dump 发到公网**。

"""
    if "## 1 代码仓库" in s and "## 0 仓库收什么" not in s:
        s = s.replace("## 1 代码仓库", section + "## 1 代码仓库", 1)
    return s

edit("Documentation/mstar/m7642/paths.md", f_paths)

# ---------- discipline.md: dangling boot-test.md reference ----------
def f_disc(s):
    return s.replace("见 `boot-test.md` §三 更正块。", "见 [display.md](display.md) §九。")

edit("Documentation/mstar/m7642/discipline.md", f_disc)

# ---------- README.md ----------
def f_readme(s):
    old_struct = """```
Documentation/mstar/m7642/     研究文档（按子系统一份，结论 + 证据 + 待办）
arch/arm64/boot/dts/mstar/     板级 DTS
drivers/                       计划中的移植代码（当前只有占位说明）
patches/                       git format-patch 序列
probes/                        内核探针模块源码 + 构建输入
tools/host/                    开发机上跑的脚本
tools/device/                  推到电视上跑的脚本
artifacts/                     取证产物：反汇编、寄存器基线、活体 DTS、探针输出
fw/                            固件（.bin）分析脚本
```"""
    new_struct = """```
Documentation/mstar/m7642/     研究文档（按子系统一份，结论 + 证据 + 待办）
arch/arm64/boot/dts/mstar/     板级 DTS
drivers/                       计划中的移植代码（当前只有占位说明）
patches/                       git format-patch 序列
probes/                        探针与注入器的源码（.c/.S），不带构建产物
tools/host/                    开发机上跑的脚本
tools/device/                  推到电视上跑的脚本
artifacts/                     少量参照物：反汇编清单、活体设备树、GOP 基线
fw/                            固件（.bin）分析脚本
```

### 这个仓库收什么、不收什么

- **收**：结论与方法论、可复用源码、脚本、补丁、DTS，以及少量必需的参照数据。
- **不收**：设备分区导出的 `.bin`/`.img`、构建产物（`.elf`/`.ko`/`.o`/`.out`）、
  一次性实验代码、作废的读数日志。
- 不收的东西**没有删**，平移到仓库外的 `~/Debian/m7642-attic/<原路径>`，
  清单在 `~/Debian/m7642-attic/ATTIC.md`。文档里的这类引用按原相对路径去那里找。

理由：仓库要能公开推送到 `github.com/emfox/m7642`，既不该带厂商二进制和本机 dump，
也该保持"能重跑出结论"的最小集合。规则细节见
`Documentation/mstar/m7642/paths.md` §0。"""
    s = s.replace(old_struct, new_struct)
    s = s.replace("本仓库存放移植过程的研究结论、可复现的取证工具和图树就绪的产物（DTS / 文档 / 补丁）。",
                  "本仓库存放移植过程的研究结论、可复现的取证工具和图树就绪的产物（DTS / 文档 / 补丁）。\n"
                  "远端：`git@github.com:emfox/m7642.git`（`master`）。")
    return s

edit("README.md", f_readme)

# ---------- .gitignore ----------
def f_ignore(s):
    add = """
# ---- 2026-11-22: 产物与原始数据不入库（见 Documentation/mstar/m7642/paths.md §0）
*.elf
*.img
*.bin
*.dump
*.tar
*.out
*.bak-*
*.old
artifacts/probe-out/
!probes/device-config.gz
"""
    if "2026-11-22: 产物与原始数据不入库" not in s:
        s = s.rstrip("\n") + "\n" + add
    return s

edit(".gitignore", f_ignore)
