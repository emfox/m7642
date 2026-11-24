#!/usr/bin/env python3
"""Fold the successful CMD17 result into README / NEXT-SESSION / discipline."""
import os

D = "/home/emfox/Debian/m7642/Documentation/mstar/m7642"

# ---- README: replace the "first attempt / ladder" section with the outcome
p = "/home/emfox/Debian/m7642/probes/fcie/README.md"
s = open(p).read()
start = s.index("### 2026-11-22 07:43 第一次上机：NO_RETURN")
end = s.index("## 不要做的事")
new_section = """### 2026-11-22 10:00 结果：CMD17 读通道成立

四级诊断全部跑过（每发都用 misc 末尾 `0xA5` 标记确认真的进了 recovery）：

| 级别 | 镜像 md5 | 结果 |
|---|---|---|
| ctl（不碰 eMMC，记录+交接） | `097140f5…` | REACHED |
| regs（只读 34+2 个寄存器） | `a2e76b78…` | RETURNED，code1 寄存器全表见 confirmed-facts §32.8 |
| 单写 wr1 / wt1 / wt2 / wt3 / wt4 / wt5 | 见 git 历史 | 全部 RETURNED（JOB_BL_CNT、FUNC_CTL、SD_MODE、SD_STATUS 读、清事件/清错误、DMA 寄存器组） |
| clk（定时器） | `466d5d61…` | RETURNED：CNTFRQ=12 MHz、CNTPCT 在跑、EL2、cache 关 |
| cpa / cpb（C 路径的栈 / 心跳地址） | 见 git 历史 | RETURNED |
| **cpath**（C 路径、零 MMIO） | `484e1a01…` | 修复后 RETURNED |
| **setup**（只写寄存器，不起命令） | `2c1d230a…` | 修复后 RETURNED |
| **全量 CMD17** | `9f071ae8…` | **RETURNED，rc=0，数据与内核 `dd` 逐字节相同** |

**之前连续挂死的根因**：C 代码按 ABI 冲掉了 `x0..x5`，而厂内核入口会把 **`w2`** 存进它的
`boot_args[2]`。纯汇编桩从不碰它们，所以「凡是 C 路径就挂、凡是汇编就过」。修法：
`emmc_read.S` 入口保存 `x0..x5`，交接前恢复（`x3/x4` 清 0、`sp` 回 0）。

成功读数：`rc=0`、`R1=0x900`（CURRENT_STATE=4/READY_FOR_DATA=1）、`SD_STATUS=0xff00`、
512 B 与内核 `dd if=/dev/block/mmcblk0 bs=512 count=1` 完全一致（md5 `ce6a9730…`）。

```sh
cd ~/Debian/m7642/probes/fcie
./build-boot.sh
./run-cmd17.sh ~/kbuild/m7642-out/m7642-rec-73-emmc.img 9f071ae8ff512a1843396e8849633531
```

写路径（CMD24/CMD25）仍未做，继续冻结。

"""
s = s[:start] + new_section + s[end:]
open(p, "w").write(s)
print("README updated")

# ---- NEXT-SESSION §5
p = os.path.join(D, "NEXT-SESSION.md")
s = open(p).read()
old = "  **2026-11-22 08:0x 四级实测**"
if old in s:
    i = s.index(old)
    j = s.index("\n- **写路径（CMD24/CMD25）继续冻结**", i)
    s = s[:i] + """  **2026-11-22 10:00：CMD17 读通道成立**（rc=0、R1=0x900、SD_STATUS=0xff00、
  512 B 与内核 `dd` 的 LBA0 逐字节相同）。之前连续挂死的根因是 **C 代码冲掉了 x0..x5**，
  而厂内核入口要读 `w2`；`emmc_read.S` 已改成入口保存、交接前恢复。
  全量镜像 `9f071ae8ff512a1843396e8849633531`。
""" + s[j:]
    open(p, "w").write(s)
    print("NEXT-SESSION updated")

# ---- discipline
p = os.path.join(D, "discipline.md")
s = open(p).read()
anchor = "**「进了 recovery」只能用 misc 标记证明，`ro.boot.bootreason` 不算。**"
if "跳厂内核之前必须把" not in s:
    add = """**跳厂内核之前必须把 `x0..x5` 还给 mboot 的值（尤其 `x2`）。**

代价：2026-11-22 09:0x，code1 的 eMMC 探针改用 C 之后连续挂死 6 次。根因：C 按 ABI 可以
随意用 `x0..x18`，而厂内核入口会把 **`w2`** 存进 `boot_args[2]`；纯汇编桩恰好没碰。
判据是「凡是 C 路径就挂、凡是汇编就过」。规则：任何要跳厂内核的桩，入口保存
`x0..x5`、交接前恢复（`x3/x4` 清 0、`sp` 回 0）。

"""
    assert anchor in s
    s = s.replace(anchor, add + anchor, 1)
    open(p, "w").write(s)
    print("discipline updated")
