#!/usr/bin/env python3
"""Document the relocation, the rebuild verification, and the lessons."""
import os

REPO = os.path.expanduser("~/Debian/m7642")
BUILD = os.path.expanduser("~/Debian/m7642-build")
D = os.path.join(REPO, "Documentation/mstar/m7642")

# ---------- 1. 构建树 README（仓库外，给未来的自己看）
open(os.path.join(BUILD, "README.md"), "w").write("""# m7642-build —— 构建与备份根目录

原 `~/kbuild/`。2026-11-22 清理：16 GB → 6.6 GB，只留还在用的，按用途分七个子目录。

| 子目录 | 内容 |
|---|---|
| `kernel/linux-main/` | 7.3 编译树（Linux 7.3.0）。DTS 权威副本在这里。 |
| `kernel/mstar-4.9/` | 厂内核 4.9.118 源码（`drivers/mstar2/`）。探针模块靠它编：它自带 `scripts/mod/modpost` 和 `Module.symvers`，所以标准 `make M=... modules` 就能用。 |
| `toolchain/gcc13/` | 交叉工具链 `aarch64-buildroot-linux-gnu-*`。 |
| `out/` | 上机镜像 `m7642-rec-73-*.img`（28 张，897 MB）。全部可由 `probes/*/build-*.sh` 重建。 |
| `build/fcie-build/` | FCIE 裸机 blob 中间产物；`build/modules/` 放编出来的 .ko。 |
| `backups/` | **救砖与回滚，只读勿删**：`fix/V8-T652T03-LF1V147.bin`（3.0 GB 原厂包）、`fix/rescue-fast.bin`（唯一能修 boot 的 47 MB 包）、`rescue/`、`partitions/`（boot/recovery/misc/dtb/tvconfig）。 |
| `diag/` | env 快照、dmesg、厂内核 config、`live.dtb`、`mboot-guide.pdf`。 |
| `ref/` | `m7642-dt/`（TWRP 设备树）、`emmcboot/`、`hal-dumps/`、`mboot-src/`。 |
| `scripts/` | `tvrun.sh`、`precheck.sh`、`scan5555.sh`、`wait-dmesg.sh`、`build-probe.sh`、`score-drivers.sh`、`scan_pkgs.py`、`mark.bin`。 |

删掉的东西（历史镜像、4.19 树、老工具链、一次性脚本与 dump）在
`~/Debian/m7642-deleted-manifest.txt` 里有完整名单。

## 重建上机镜像

```sh
cd ~/Debian/m7642/probes/handoff && ./build-postmmu.sh && ./mk-postmmu-images.sh && ./mk-emap-images.sh
cd ~/Debian/m7642/probes/fcie && ./build-extra.sh && ./build-stage.sh && ./build-boot.sh
```

2026-11-22 迁移后按上面跑过一遍，27 张已记录的镜像 md5 **逐一对上**
（`mmuon 7f309a47 / emap f0ca4aa2 / prsw b8651fd2 / skmain 2eac39d1 /
mk1 371627c1 … mk6 893a2274 / ps0 f6dd1e79 / ps1 e4f36379 / kva 3b220ef4 /
emmc 9f071ae8 / setup 2c1d230a / cpath 484e1a01 / ctl 097140f5 / regs a2e76b78 /
wr1 c9698a39 / wt1 bfe218f8 … wt5 6b0b33ee / clk 466d5d61 / cpa 2c24eada / cpb 62026122）。
""")

# ---------- 2. confirmed-facts: cmin 与迁移记录
p = os.path.join(D, "confirmed-facts.md")
s = open(p).read()
if "m7642-rec-73-cmin.img" not in s:
    s = s.rstrip("\n") + """

### 34.1 构建环境迁移与镜像可重建性（2026-11-22 11:0x）

`~/kbuild/`（16 GB）清理后迁到 `~/Debian/m7642-build/`（6.6 GB），布局见该目录的 `README.md`
与 `paths.md` §1。**4.19 退役**：`tcl-419/`（2.8 GB）与 `tcl-src/` 已删除——post-MMU 检查点
仪器与 eMMC 读通道打通后，那条绕行路线不再需要。

清理过程中 `out/`（原 `m7642-out/`，5.1 GB 历史镜像）被连带清空，**用源码全量重建后逐张比 md5**：

| 组 | 结果 |
|---|---|
| `mmuon` `emap` `prsw` `skmain` | `7f309a47` / `f0ca4aa2` / `b8651fd2` / `2eac39d1` **全部一致** |
| `mk1`–`mk6`、`ps0`、`ps1`、`kva` | `371627c1`…`893a2274` / `f6dd1e79` / `e4f36379` / `3b220ef4` **全部一致** |
| `emmc` `setup` `cpath` `ctl` | `9f071ae8` / `2c1d230a` / `484e1a01` / `097140f5` **全部一致** |
| `regs` `wr1` `wt1`–`wt5` `clk` `cpa` `cpb` | `a2e76b78` / `c9698a39` / `bfe218f8`…`6b0b33ee` / `466d5d61` / `2c24eada` / `62026122` **全部一致** |

⟹ **镜像确实只是源码 + Image 的确定性函数**，删掉不损失信息；有 md5 就能判定重建是否等价。

附带两张补记：
- `m7642-rec-73-cmin.img`（md5 `b84c7384a4899bd6eb16cb62def6f719`）：C 路径的最小对照
  （只调一个返回 `0x42` 的 C 函数），用来把「C 代码本身能不能在 code1 跑」和
  「C 代码踩了 x0..x5」分开；已有结论见 §32.8。
- `probes/handoff/build-postmmu.sh` 现在也产出 `abort-rung.bin`（md5
  `4960cf196c358b408633541291d131a4`），`ctl`/`paint` 系列镜像不再依赖手工编的 stub。
"""
    open(p, "w").write(s)
    print("confirmed-facts: 34.1 已加")

# ---------- 3. discipline: 两条教训
p = os.path.join(D, "discipline.md")
s = open(p).read()
anchor = "**跳厂内核之前必须把 `x0..x5` 还给 mboot 的值（尤其 `x2`）。**"
if anchor in s and "构建目录的移动/清理必须做「重建 + md5 对账」" not in s:
    add = """**构建目录的移动/清理必须做「重建 + md5 对账」。**

代价：2026-11-22 清理 `~/kbuild` 时，一条 glob 映射写反（`add "out/$c"` 把源写成裸文件名），
phase A 把 `m7642-out/` 整个删空——5.1 GB、175 张历史镜像没了重建脚本之外的副本。
补救办法正是纪律本身：源码在、工具链在，跑一遍 `build-*.sh` 再逐张比文档里的 md5，
27 张全部一致，等于没有损失。**推论：上机镜像永远是"可重建产物"，不是资产**；
真正要保住的是源码、脚本、md5 记录，以及 `backups/` 里的救砖包。

**删任何东西之前，先确认它不在"救砖路径"上。**

同一天的清单里差点有 `backup/fix/rescue-fast.bin`（47 MB，**唯一能修 boot 的包**，
`tools/host/boottest.sh` 的默认值）。判据不是"名字像不像历史产物"，而是**谁在引用它**：
`git grep` 一遍仓库里的路径引用，比看文件名可靠。

"""
    s = s.replace(anchor, add + anchor, 1)
    open(p, "w").write(s)
    print("discipline: 两条教训已加")

# ---------- 4. NEXT-SESSION: 顶部加状态
p = os.path.join(D, "NEXT-SESSION.md")
s = open(p).read()
if "构建树已迁到" not in s:
    i = s.index("\n## ")
    head = ("""
> **2026-11-22 11:0x 环境变更**：`~/kbuild/` 已清理并迁到 `~/Debian/m7642-build/`
> （16 GB → 6.6 GB，布局见该目录 `README.md` 与 `paths.md` §1）。4.19 树已删除。
> `out/` 里的 27 张上机镜像已按源码重建并逐一比过 md5，全部一致。
> 设备当前是活的（adb 可达），上一发 `ps1` 的挂死已由拔插恢复。
""")
    s = s[:i] + head + s[i:]
    open(p, "w").write(s)
    print("NEXT-SESSION: 顶部状态已加")
