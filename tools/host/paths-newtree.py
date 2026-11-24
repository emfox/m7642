#!/usr/bin/env python3
"""paths.md: document the relocation + the new build-tree layout."""
import os, subprocess

REPO = os.path.expanduser("~/Debian/m7642")
P = os.path.join(REPO, "Documentation/mstar/m7642/paths.md")
s = open(P).read()

old_head = """| `~/Debian/m7642-build/kernel/linux-main/` | **7.3 编译树**（Linux 7.3.0） | 只用于编译，不在这里写文档 |
| `~/kbuild/tcl-419/` | **4.19 工作副本**（官方 fork） | 编译入口见 §3 |
| `~/kbuild/tcl-src/` | 4.19 **原树**（未改动，对照用） | 被 `mstarKernelRelease.sh` 剥掉了 `mstar2/` |
| `~/Debian/m7642-build/toolchain/gcc13/bin/` | 交叉工具链 `aarch64-buildroot-linux-gnu-*` | `objdump` / `gcc` / `ld` |
| `~/Debian/tv/adb/platform-tools/adb` | 专用 adb（**不要用系统的**） | 各脚本里的 `ADB=` 默认值 |"""

new_head = """| `~/Debian/m7642-build/` | **构建与备份根目录**（原 `~/kbuild/`，2026-11-22 迁移） | 布局见下 |
| `~/Debian/tv/adb/platform-tools/adb` | 专用 adb（**不要用系统的**） | 各脚本里的 `ADB=` 默认值 |

### `~/Debian/m7642-build/` 布局（2026-11-22 定）

原来是 `~/kbuild/` 下 16 GB 的大杂烩（几百个一次性脚本和镜像平铺在一级目录）。
现在只留还在用的，按用途分七个子目录：

| 子目录 | 内容 | 备注 |
|---|---|---|
| `kernel/linux-main/` | **7.3 编译树**（Linux 7.3.0） | 只用于编译，不在这里写文档；DTS 权威副本在它下面 |
| `kernel/mstar-4.9/` | 厂内核 **4.9.118 源码**（`drivers/mstar2/` 在里面） | 驱动移植的参照实现；**探针模块就靠它编**（自带 `scripts/mod/modpost` 与 `Module.symvers`） |
| `toolchain/gcc13/` | 交叉工具链 `aarch64-buildroot-linux-gnu-*` | `objdump` / `gcc` / `ld`；2018.11 那套老工具链已删（只有 4.19 需要它） |
| `out/` | 上机镜像（`m7642-rec-73-*.img`） | 历史镜像已清；用 `probes/*/build-*.sh` 随时重建 |
| `build/fcie-build/` | FCIE 裸机 blob 的中间产物 | |
| `backups/` | **救砖与回滚**：`fix/V8-T652T03-LF1V147.bin`（3.0 GB 原厂包）、`fix/rescue-fast.bin`（唯一能修 boot 的 47 MB 包）、`rescue/`、`partitions/`（boot/recovery/misc/dtb/tvconfig）、`partitions/rec/` | 只读，勿删 |
| `diag/` | env 快照、dmesg、厂内核 config、`live.dtb`、`mboot-guide.pdf` | |
| `ref/` | `m7642-dt/`（TWRP 设备树）、`emmcboot/`、`hal-dumps/`、`mboot-src/` | 只读参考 |
| `scripts/` | 主机侧小工具：`tvrun.sh`、`precheck.sh`、`scan5555.sh`、`wait-dmesg.sh`、`build-probe.sh`、`score-drivers.sh`、`scan_pkgs.py`、`mark.bin` | `build-probe.sh` 已改成标准 kbuild（不再回放 probe8 的命令） |

**4.19 已退役**：`tcl-419/`（2.8 GB 工作副本）与 `tcl-src/` 随这次清理删除。
post-MMU 检查点仪器与 eMMC 读通道打通之后，4.19 这条绕行路线不再需要；
`rung419-runbook.md`、`mk-rung-419.py` 等留作历史，相关工具已移到 attic。"""

assert old_head in s
s = s.replace(old_head, new_head, 1)

# §4 产物与备份表的路径
s = s.replace("| `~/kbuild/m7642-out/m7642-419-rung0.img` |",
              "| `~/Debian/m7642-build/out/m7642-419-rung0.img`（已随 4.19 退役删除） |")
s = s.replace("| `~/kbuild/tcl-419/arch/arm64/boot/Image` | 4.19 裸内核 |",
              "| （已删）`~/kbuild/tcl-419/arch/arm64/boot/Image` | 4.19 裸内核 |")
s = s.replace("| `~/kbuild/rec/recovery_full.bin` |",
              "| `~/Debian/m7642-build/backups/partitions/rec/recovery_full.bin` |")
s = s.replace("| `~/kbuild/diag/env*.bin` |",
              "| `~/Debian/m7642-build/diag/env*.bin` |")
s = s.replace("| `~/kbuild/boot-stock-backup.bin` |",
              "| `~/Debian/m7642-build/backups/partitions/boot-stock-backup.bin` |")
s = s.replace("| `~/kbuild/dmesg-{warm1,cold1,after-boot}.txt` |",
              "| `~/Debian/m7642-build/diag/dmesg-{warm1,cold1,after-boot}.txt` |")
s = s.replace("| `~/kbuild/m7642-out/` | 历史实验镜像（`_b.bin` `_f.bin` `_g.bin` 等） | — |",
              "| `~/Debian/m7642-build/out/` | 上机镜像目录（历史镜像已清，按需重建） | — |")
s = s.replace("| `~/kbuild/rec/recovery_full.bin` |", "| `~/Debian/m7642-build/backups/partitions/rec/recovery_full.bin` |")

# §3 脚本表的 kbuild 行
s = s.replace("| `~/kbuild/tcl419-build.sh` | 编译（内建执行位修复 + 4 次重试 + `-fcommon`） |\n"
              "| `~/kbuild/tcl419-clean.sh` | 清成\"从未编译\"状态（`.o`/`.a`/`.cmd` 一起清） |\n", "")
s = s.replace("| `~/kbuild/tvrun.sh <脚本>` |", "| `~/Debian/m7642-build/scripts/tvrun.sh <脚本>` |")
s = s.replace("| `~/kbuild/wait-dmesg.sh <tag>` |", "| `~/Debian/m7642-build/scripts/wait-dmesg.sh <tag>` |")
s = s.replace("| `~/kbuild/precheck.sh` |", "| `~/Debian/m7642-build/scripts/precheck.sh` |")
s = s.replace("| `~/kbuild/scan5555.sh` |", "| `~/Debian/m7642-build/scripts/scan5555.sh` |")
s = s.replace("| `~/Debian/m7642/tools/build-mstar-kernel.sh` |",
              "| `~/Debian/m7642/tools/build-mstar-kernel.sh`（若不在，见 NEXT-SESSION） |")

open(P, "w").write(s)
print("paths.md updated")

# 剩下的 kbuild 引用
out = subprocess.run(["git", "-C", REPO, "grep", "-n", "kbuild"],
                     capture_output=True, text=True).stdout.splitlines()
left = [l for l in out if "m7642-build" not in l]
print("\n=== 仍提到 kbuild 的 %d 行:" % len(left))
for l in left:
    print("  ", l)
