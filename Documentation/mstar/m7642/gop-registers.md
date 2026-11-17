# GOP 寄存器快照（运行态，1920×1080）

采集时间 2026-11-17 14:37，系统处于 Android TV 桌面、画面 1920×1080、HDMI 输出正常。
方法：调用厂商自己的访问器 `MHal_GFLIP_ReadGopReg(idx, bank, offset, &u16)`，
扫描 idx 0..2 × bank 0..7 × offset 0..255，共 6144 个 16 位寄存器，记录非零项。

原始数据：`artifacts/probe-out/probeD.out`（864 条非零，格式 `idx bank off value`）。

## 一、覆盖面与分布

| idx | bank0 | bank1 | bank2 | bank3 | bank4 | bank5 | bank6 | bank7 | 合计 |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 56 | 47 | 74 | 49 | 39 | 67 | 39 | 40 | **411** |
| 1 | 49 | 39 | 67 | 39 | 40 | 36 | – | – | **270** |
| 2 | 39 | 40 | 36 | – | – | 14 | 23 | 31 | **183** |

三个 GOP 索引的寄存器足迹明显不同：idx0 覆盖全部 8 个 bank，idx1 只到 bank5，
idx2 缺 bank3/4 但又有 bank6/7。这与「三个显示平面（主视频 / OSD / 光标）」的布局吻合。

## 二、能确认含义的寄存器

idx0 是主力窗口，其 bank0 里能直接对上的值：

| 偏移 | 值 | 含义 |
|---|---|---|
| off 48 | `0x03c0` = 960 | 水平起点（1080p 居中窗口的一半） |
| off 49 | `0x0438` = **1080** | 高度 |
| off 133 | `0x0780` = **1920** | 宽度 |
| off 136 | `0x0438` = **1080** | 高度 |
| off 137 | `0x0780` = **1920** | 行跨距 |
| off 12 / 13 | `0x3fff` / `0x0fff` | 16383 / 4095，坐标或掩码上限 |
| off 67–70 | `3210 7654 ba98 fedc` | 递增图案，典型的**测试图案/默认填充色**寄存器 |

bank1 里同一组几何再出现一次（off 5 = 1920、8 = 1080、9 = 1920），
说明 GOP 对「源窗口」和「目标窗口」各存一份尺寸。

`0x03c0` = 960 这个值很有意思：如果 off48 是水平起点而宽度是 1920，那窗口中心在
960 + 960 = 1920，正好是 1080p 的半宽——说明这组寄存器描述的是一个**居中 1920 宽窗口**，
即全屏。

## 三、没能找到的东西

**帧缓冲物理地址（0x2D100000）不在 GOP 窗口寄存器里。**
按 16 位半字拆（`0x2D10` / `0x0000`）、按 4K 页（`0x2D100`）、按 64K（`0x2D10`）都搜不到。
`MHal_GFLIP_GetGopDst(0)` 和 `(1)` 都返回 `2`，是状态码不是地址；
`MHal_GFLIP_GetFrameIdx(0)` 返回 `0`。

推断：GOP 的目标地址寄存器位于**我们没扫到的 bank**（bank 数可能超过 8），
或者地址不是以「绝对物理地址」形式存储，而是相对某个 MIU 基址的偏移。
这一项不影响 simplefb 方案——`recovery_fbaddr=0x2D100000` 已经在 cmdline 里，
`fb0` 也在正常工作。

**TCON 与 DIP 在核心里几乎没有代码。**

```
$ grep -i tcon /proc/kallsyms    → 没有任何 MDrv_TCON / MHal_TCON 符号
$ grep MHal_DIP /proc/kallsyms   → 只有 _MHal_DIP_Get_EngineClock 一个
```

这是本轮最有价值的结论：**面板时序和 TCON 初始化完全由 bootloader（mboot）完成，
内核不参与。** 与 cmdline 里的 `tcon_type_extend=ST6451D02-5` 一致。

⟹ 主线内核如果只做 `simple-framebuffer`（捡 bootloader 建好的显存），
**根本不需要碰 TCON**——这正好印证了之前 P0 方案的可行性假设。

## 四、这份数据对移植的用处

1. **GOP 寄存器布局的第一手资料**。公开树里只有 m7322 的表，m7642 一直没有；
   现在有了运行态真值，可以反推字段含义（控制位、窗口矩形、格式、色彩键）。
2. **可以作为「黄金状态」对照**：将来自己写 GOP 初始化时，把寄存器调到这张表的样子
   就说明配置正确。这是最实用的用途。
3. **确认 simplefb 的可行性**：TCON 不在内核手里，主线不用重做面板时序。

## 五、复现

```sh
adb push probeD.ko /data/local/tmp/
adb shell 'echo "sh /data/local/tmp/runprobe.sh probeD" > /data/local/tmp/tvroot.cmd'
adb pull /data/local/tmp/probeD.out
```

`probeD.c` 里三个常量控制扫描范围：`MAXIDX=3`、`MAXBANK=8`、`MAXOFF=256`。

## 六、把 bank 扩到 16 之后（14:39 复测）

GOP 寄存器空间比预想的大得多。`MAXBANK` 从 8 调到 16 重跑，bank 8–15 里依然有大量非零寄存器：

| bank | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|
| 非零数 | 71 | 22 | 31 | 35 | 61 | 85 | 37 | 39 |

bank 8 的内容（`0019 004e 000a 004d 002c 00fd 0001 003f` 循环重复）
与 bank 5 的前 16 个寄存器**完全一致**，看起来是同一种「调色板/查找表」结构
被映射在多处，而不是独立的控制寄存器。

**帧缓冲地址仍然找不到。**按 `0x2D10`（高半字）、`0xD100`（addr>>4 低半字）、
`0x002D`（addr>>8 高半字）三种编码在全部 16 个 bank 里搜，**零命中**。

⟹ 结论明确：GOP 的目标地址**不是以绝对物理地址形式存放在这 16 位寄存器空间里**。
它要么由内核在 RAM 里的描述符结构维护、只在 flip 时写进另一个块，
要么放在 16 位访问器够不到的位置。这一项就此打住——`recovery_fbaddr=0x2D100000`
已经在 cmdline 里，`fb0` 正常工作，对 simplefb 方案没有影响。

原始数据两份都留着：`artifacts/probe-out/probeD.out`（8 bank，864 条）和
`artifacts/probe-out/probeD16.out`（16 bank，**1241** 条，更全，建议以它为准）。

## 七、黄金状态对比工具（同日完成）

上面那份快照现在变成了可复用的基线，配套三个脚本在 `tools/`：

| 脚本 | 作用 |
|---|---|
| `tools/host/gop-snap.sh <label>` | 现场采一份快照，存到 `artifacts/snapshots/<label>.txt` |
| `tools/host/gop-diff.sh <基线> <当前>` | 按键 `idx bank off` 对比，输出 added / removed / changed |
| `tools/host/gop-volatile.sh <快照...>` | 从多份快照里算出易变寄存器清单 |

模块侧是 `probes/probeS/`，参数化（`idxmax` / `bankmax` / `offmax` / `out`），
不用为改范围重新编译。

### 易变寄存器：38 个

连采三份（`baseline-2026-11-17`、`t2`、`t3`）后算出 38 个会自己变的寄存器，全部记在
`artifacts/snapshots/volatile.txt`。它们分三类：

- `0x00ba` ↔ `0x40ba`（bit14 翻转）—— 忙/就绪标志，出现在很多 bank；
- `0x2f10` ↔ `0x2f9a` —— 某个计数器或校验值，多个 idx/bank 同步变化；
- idx2 bank13/14 上 `0x07f4 → 0x07e8 → 0x07dc`（每轮减 12）—— 递减计数，像 OSD 动画或时钟。

### 结果

把 38 个易变项排除后，三份快照**完全一致**：

```
baseline: 1205 regs   current: 1205 regs   (ignoring 38 volatile)
added: 0   removed: 0   changed: 0
identical (static registers)
```

⟹ `artifacts/snapshots/baseline-2026-11-17.txt` 可以当作**黄金状态**：以后自己写 GOP 初始化，
刷进去后采一份快照、跑一次 `gop-diff.sh`，就知道配得对不对，不用靠人眼看屏幕。

### 用法

```sh
tools/host/gop-snap.sh my-driver-2026-12-01          # 采一份
tools/host/gop-diff.sh artifacts/snapshots/baseline-2026-11-17.txt \
                  artifacts/snapshots/my-driver-2026-12-01.txt
```

注意：快照依赖厂商的 `MHal_GFLIP_ReadGopReg`，**只在跑厂商内核时有意义**。
主线内核下要采同样的数据，得自己实现读寄存器——那时候比的才是真正的移植成果。
