#!/usr/bin/env python3
"""Fold the 2026-11-22 code1 eMMC results into the docs."""
import os

D = "/home/emfox/Debian/m7642"

# ---- confirmed-facts: point §32.6 item 1 at §32.8
p = os.path.join(D, "Documentation/mstar/m7642/confirmed-facts.md")
s = open(p).read()
anchor = "   `a2e76b787061b803c56bccc96686c973`。顺序：ctl → regs → 全量 CMD17。\n"
if anchor in s and "§32.8" not in s:
    s = s.replace(anchor, anchor + "   → **已上机，结论见 §32.8**（读安全、写就挂）。\n", 1)
    print("confirmed-facts §32.6 updated")
open(p, "w").write(s)

# ---- README: new md5s + measured results
p = os.path.join(D, "probes/fcie/README.md")
s = open(p).read()
s = s.replace("`32897a40ccf8b08de2e1e2b7a4d02c59`", "`d2d5fcf9263704acda1deae8a9f15a00`")
s = s.replace("`a4479e336f3b4b4ac7fa5ca1aad46887`", "`8d5dd03356029548c6aba05f62514d64`")
old = """| `m7642-rec-73-emmc.img` | `8d5dd03356029548c6aba05f62514d64` | 全量 CMD17 |
"""
new = """| `m7642-rec-73-emmc.img` | `8d5dd03356029548c6aba05f62514d64` | 全量 CMD17 |

2026-11-22 08:0x 的实测结果（详见 confirmed-facts §32.8）：

| 级别 | 结果 |
|---|---|
| ctl | **REACHED**（stash `M764`/`STEP`，x30=`0x20280008`）── code1 的「记录 + 交接」成立 |
| regs | **RETURNED**：34+2 个寄存器全部读出；code1 时 `SD_STATUS=0xff00`（DAT0..7 高、无错误）、`SD_MODE=0x0004`（8 bit、时钟关）、`FUNC_CTL=0x0001` |
| setup | **NO_RETURN**（507 s）── 写就挂 |
| emmc | **NO_RETURN**（489 s）── 写就挂 |

⟹ 读安全、写不安全。已在 `fcie_read.c` 加「进出原样保存/还原
`FUNC_CTL`/`SD_MODE`/`SD_CTRL`/`DMA_ADDR`」（厂内核靠 `RESERVED_FOR_SW=3` 信任 mboot 的
控制器状态、不重做 init），setup/emmc 两张镜像因此重建。先跑 emmc；仍挂再跑 setup 二分。
"""
assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("README updated")

# ---- NEXT-SESSION §5
p = os.path.join(D, "Documentation/mstar/m7642/NEXT-SESSION.md")
s = open(p).read()
old = """  判据：心跳 `rc=0` + `R1` 的 CURRENT_STATE=4/READY_FOR_DATA=1 + 512 B 与 `dd` 一致。
  只读 LBA 0；挂住 = 一次物理断电（boot 槽是厂值，卡只被读过）。
"""
new = """  判据：心跳 `rc=0` + `R1` 的 CURRENT_STATE=4/READY_FOR_DATA=1 + 512 B 与 `dd` 一致。
  只读 LBA 0；挂住 = 一次物理断电（boot 槽是厂值，卡只被读过）。

  **2026-11-22 08:0x 四级实测**：ctl ✅ / regs ✅（34+2 全读出，code1 卡 idle、DAT0 高）/
  setup ✗（507 s）/ 全量 ✗（489 s）⟹ **读安全、写就挂**。已给探针加「进出原样
  保存/还原 `FUNC_CTL`/`SD_MODE`/`SD_CTRL`/`DMA_ADDR`」，新镜像
  emmc `8d5dd03356029548c6aba05f62514d64`、setup `d2d5fcf9263704acda1deae8a9f15a00`。
  恢复设备后先跑 emmc，仍挂再跑 setup 二分。**每发之前往 misc 末尾写 4 KB `0xA5`
  并回读确认**（`recoverycmd` 会擦掉；标记不消失就说明根本没进 recovery）。
"""
assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("NEXT-SESSION updated")

# ---- discipline: bootreason is not proof
p = os.path.join(D, "Documentation/mstar/m7642/discipline.md")
s = open(p).read()
anchor = "**任何「到达」必须由 stash 证明，不能只看「设备回来了」。**"
if "ro.boot.bootreason" not in s:
    add = """**「进了 recovery」只能用 misc 标记证明，`ro.boot.bootreason` 不算。**

代价：2026-11-22 08:03 的一发 ctl 报「Android 起来了」，stash 却是 dtb 残渣——事后查是
`adb reboot recovery` 没生效（走了 `bootcmd`），而 `ro.boot.bootreason` 仍显示 `recovery`
（reason 串会被下一次启动继承）。标记法：往 misc **末尾**写 4 KB `0xA5`，
`recoverycmd` 的第一条 `mmc erase.p misc` 会擦掉它；标记消失才算真进了 recovery。

"""
    assert anchor in s
    s = s.replace(anchor, add + anchor, 1)
    open(p, "w").write(s)
    print("discipline updated")
