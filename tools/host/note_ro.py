import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

# 1) discipline：把"静态优先 / 少断电"写成硬规则
p = os.path.join(D, "discipline.md"); s = open(p).read()
if "静态分析优先" not in s:
    s = s.rstrip("\n") + """

### 静态分析优先；每次断电都是硬件损耗（2026-11-23，用户要求）

即使用户已经买了智能插座（可脚本化断电），**仍不允许"先打一发看看"**：

1. **打点前必须先用静态分析缩小范围**（反汇编 + 源码 + 符号/结构体布局），
   把候选点压到 1–2 个再上机；
2. **优先设计"会正常返回"的发数**：能在一个"已知会回来"的检查点上读数据，就不要在
   `可能挂死` 的点上试探。为此新增了 readout 入口（见 `confirmed-facts.md` §34.25）；
3. **一张镜像放多个互斥探针**，用记录里的 `x30` 判断走了哪条路——把 4 发压成 1 发；
4. 每次断电重启对电源/存储都是冲击，**发数本身就是预算**。

反例（当天）：`mm5` 之后直接打了 `combo`，虽然信息量高，但那条路本来就有一半概率挂死；
而 readout 这种"必定返回"的仪器应该先做。
"""
    open(p, "w").write(s); print("discipline: 静态优先规则已写入")

# 2) confirmed-facts：readout 仪器 + 明天的零风险第一发
p = os.path.join(D, "confirmed-facts.md"); s = open(p).read()
if "34.25" not in s:
    s = s.rstrip("\n") + """

### 34.25 新仪器：world B 内「读内核变量」的 readout 入口（零断电风险）

`combo` 证明卡在 `kmem_cache_init` 的分配循环里"既不返回也不失败"。为了**不靠断电试探**，
新增了一个**必定返回**的探针：在任意 world-B 检查点上先把 `TCR_EL1`/`TTBR0_EL1` 还回去
（复刻 `_start_restore` 的动作），再**通过内核 VA 读若干个变量**，存进镜像 `.bss` 的 SAVE 页；
交接桩在 32 MB 拷贝**之前**把这 8 个 qword 抄进记录（记录由 `0xB0` 扩到 **`0xF0`**）。

| 项 | 值 |
|---|---|
| 入口 | `_start_readout` = blob `0x600`（`Image+0x36c600`） |
| 符号传法 | 构建期 `-DSYM0_VA..SYM7_VA`（链接 VA = 运行时 VA） |
| 落位 | SAVE 页 +0x40…+0x78（PA = `SAVE_VA - KIMAGE_OFFSET` = `0x20883000`） |
| 记录槽 | `+0xB0..+0xEF`，`+0x08` 的 size 写 `0xF0` |
| 构建 | `WORLD_VA=0 READOUT_SYMS="memblock+16 memblock+32 ..." ./mk-multi.sh <tag> d0=save mm4=readout` |
| 解码 | `tools/host/decode-record.py` 会自动打印这 8 个槽 |

**默认符号集**（`struct memblock` 布局已核对：`memory` 在 +16、`reserved` 在 +56；
`memblock_type` 内 `cnt`=+0、`total_size`=+16）：

| 槽 | 符号 | 含义 |
|---|---|---|
| 0 | `memblock+16` | `memory.cnt`（内核认到几段 RAM） |
| 1 | `memblock+32` | `memory.total_size`（认到多少字节） |
| 2 | `memblock+56` | `reserved.cnt`（保留了几段） |
| 3 | `memblock+72` | `reserved.total_size`（保留多少字节） |
| 4 | `max_pfn` | 最高页号 |
| 5 | `min_low_pfn` | 最低页号 |

（`totalram_pages` 在 7.x 已不是普通符号，故不用。）

#### 明天第一发（零风险，会返回）

```
镜像：m7642-ro2.img  md5 e5eb8c14f8582eebfb079c6baff0387e
配置：d0=save  +  mm4(0x473448, bl kmem_cache_init)=readout
```

**为什么是这一点**：`mm4` 在 `mem_init` 之后、`kmem_cache_init` 之前，**已验证会返回**；
它给出"内核在进入 slab init 之前到底有多少可用内存"。

**判读**：

| `memblock.memory.total_size` | 结论 | 下一步 |
|---|---|---|
| ≈ 2.7 GB 且 `reserved` 很小 | 内存充足 ⟹ **不是内存耗尽**，卡点是锁/自旋/数据结构问题 | 转向 `__alloc_pages_noprof` 内部分档（静态先选出 1 个点） |
| 只有几百 MB 或 `reserved` ≈ `memory` | 内存被大量保留 ⟹ 分配进 direct reclaim，而**调度器尚未初始化**（`mm_core_init` 在 `init/main.c:1049`，`sched_init` 在 1062） | 直接查是谁保留了内存（memblock 各段的来源） |
"""
    open(p, "w").write(s); print("§34.25 已写入")

# 3) NEXT-SESSION
p = os.path.join(D, "NEXT-SESSION.md"); s = open(p).read()
block = """**2026-11-24 第一发：零风险"读数发"（会正常返回，不用断电报废）**

```
镜像 ~/Debian/m7642-build/out/m7642-ro2.img   md5 e5eb8c14f8582eebfb079c6baff0387e
d0=save + mm4(0x473448)=readout   → 记录 +0xB0..0xEF 给出 memblock 六项
```

判读见 `confirmed-facts.md` §34.25。**纪律**：打点前先静态缩小范围；优先"会返回"的发数。

"""
if "零风险" not in s:
    i = s.index("\n## ")
    s = s[:i] + "\n" + block + s[i:]
    open(p, "w").write(s); print("NEXT-SESSION 已更新")
