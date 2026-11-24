import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md")
s=open(p).read()
if "34.3" not in s:
    s=s.rstrip("\n")+"""

### 34.3 挂住后能不能留下读数：WDT 与 stash 的实测（2026-11-22 12:0x–12:3x）

**目的**：把"一挂就没读数、还要人拔电"这个成本打掉。

**① `wdt_enable 10` 已重新布防。** 设备现行 `recoverycmd` 原本是
`mmc erase.p misc; …; run stagecmd; bootm …`——**不带 `wdt_enable`**（救砖包重写 env 之后
丢的，文档里早有这条警告）。以设备**现有 env 为底**改（不能用 `prep-env-rec.sh` 里那份模板：
模板缺 `run stagecmd`，而整条实验链依赖它把 boot 分区搬到 `0x30000000`）：

| 项 | 值 |
|---|---|
| 新 env 块 | `diag/env-rec.bin`，md5 `74800b24…`，128 KiB，主备逐字节相同，CRC `OK stamp 7512cfa6` |
| 写入 | `busybox dd` → `MPOOL` 偏移 `0x2E0000`(seek=736) 与 `0x2F0000`(seek=752)，读回 md5 一致 |
| 结果 | 重启后 Android 正常起，env 逐字节不变 ⟹ **mboot 接受这份 env** |

**② 但 WDT 复位落到的是"待机"，不是 Android。** 用一张"写记录后死循环"的
`halt` 镜像（md5 `85e36fbad3842a8ba2baa28aac301b07`）实测：卡死后 674 s 内设备**没有**
自己回到 Android；用户观察到它停在待机；红外电源键按一下才起来。
⟹ 在本机当前状态下，WDT 复位 = 回到待机（PM51 那一层），**不是** §九 当时看到的
"16–23 s 自己回 Android"。

**③ 更糟的是 DDR 不保。** 为排除"记录被下一次启动覆盖"，探针把同一条记录写两个地址：
`0x23090000`（dtb 读窗口内，对照）和 `0x23100000`（窗口外）。红外救回后**两个地址都是全零**。
⟹ 待机态本身切断 DDR 电源，记录无从保留。

**④ 顺带确认一条结构性事实**：`bootcmd` / `recoverycmd` 每次启动都执行
`mmc read.p 0x23000000 dtb 0x100000`，覆盖 `0x23000000–0x230FFFFF`。我们两个 stash 页
（`0x23080000`、`0x23090000`）**都在这段里**。stash 之所以一直好用，是因为探针在
**同一次启动内**就交接给厂内核并让 Android 起来；一旦真的要跨复位，它必然失效。

**结论**：`WDT + DDR` 组合**不足以**提供"挂住后的持久记录"——这条先前的推荐被实测推翻。
要这个能力，只能落到**eMMC（持久存储）**，或者干脆**不让探针挂**（装异常向量，把 fault
变成可记录事件后正常交接）。
"""
    open(p,"w").write(s)
    print("confirmed-facts 34.3 已加")

p=os.path.join(D,"discipline.md")
s=open(p).read()
a="**删任何东西之前，先确认它不在\"救砖路径\"上。**"
if a in s and "DDR stash 只在同一次启动内有效" not in s:
    add="""**DDR stash 只在同一次启动内有效；跨复位要用 eMMC。**

代价：2026-11-22 花了三次拔插 + 两次红外才弄明白。`0x23080000`/`0x23090000` 落在
mboot 每次启动 `mmc read.p dtb 0x100000` 覆盖的 `0x23000000–0x230FFFFF` 里，
而待机态还会切断 DDR 电源。所以"探针写了记录"与"复位后还能读到"是两件不同的事，
不要混。另外 `adb reboot` 是硬断电 ⟹ 设备停在待机，得按电源键（`tools/host/tvpower.sh on`
可脚本化，不需要人）。

"""
    s=s.replace(a,add+a,1)
    open(p,"w").write(s)
    print("discipline 已加")
