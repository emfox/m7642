import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.19" not in s:
    s=s.rstrip("\n")+"""

### 34.19 ★★★★★ 真凶（子代理静态审查）：模式判定用了检查点的 `x5`，且 `memstart_addr` 此刻是毒值

三条独立事实合起来就解释了 `g5` 为什么在"旧仪器能回来"的点上挂：

1. **`memstart_addr` 在此时是 `-1`**：`arch/arm64/mm/init.c` 里
   `s64 memstart_addr __ro_after_init = -1;`（注释明说是"毒值，用来抓早于
   `arm64_memblock_init()` 的误用"）。vmlinux 里 `0xffffffc080441dd8` 处的初值实测就是
   `ff…ff`。而 7.3 要到 **`arm64_memblock_init()`（`0x463a14`）** 才给它赋值，
   **`paging_init()`（`0x463a20`）** 才建线性映射。
2. 所以校准必然走进回退分支，`x29 = 0`。
3. **但模式分叉判的是检查点留下的 `x5`**（内核现场值），不是 `x29` ⟹ 走了 VA 路径；
   接着公共路径又把 `x5` 设成 `x29 = 0` ⟹ 走"关 MMU"分支 ⟹ **在内核 VA 上执行
   `msr sctlr_el1`** ⟹ 下一条取指用 `0xffffffc08036c2e0`（不是 DDR）⟹ 中止；
   而 DAIF 已被 `0x46395c` 屏蔽、SP 已被设成 0 ⟹ 同 EL 二次中止 ⟹ 死循环，
   与"停 logo、ping 不通、无记录"完全一致。

**第二道墙**：此刻 `TCR.T0SZ = 16`（`IDMAP_VA_BITS = 48`，4 级、根在 L0），
不是 25。所以我先前那张"L1[0] = 1 GB block"会被当成 **level-0 表项**，
`[1:0] = 01` 在 L0 是保留编码 ⟹ 翻译失败。

#### 据此重写：不再依赖任何内核变量

| 改动 | 理由 |
|---|---|
| **模式只用 `SCTLR_EL1.M` 判断**（tramp 与交接桩都是） | 用数据值冒充 CPU 状态是这轮两个 bug 的共同根因 |
| **地址一律用 `PA + KIMAGE_OFFSET`**（构建期常量） | `boot_args` 与整个镜像都在镜像映射里；线性映射此时还不存在 |
| **删掉 `AT` 自校准与 `lin`** | 依赖 `memstart_addr` 在这段窗口里必然无效；而镜像映射偏移是常量，不需要测 |
| **表写进镜像内的 `reserved_pg_dir`（PA `0x206d8000`）** | 用**链接 VA** `0xffffffc080458000` 直接写，不需要任何测量；该区此刻仍是 RW（`mark_rodata_ro` 还没跑） |
| **`T0SZ` 一并改成 25**（与 `EPD0=0` 同一次 `msr`） | 让 L1 的 1 GB block 合法 |
| **本地 `tlbi vmalle1`** | 改了 T0SZ，旧条目不再可解释；本地无效化不涉及互联广播 |
| `AttrIndx` 用 **0**（`MT_NORMAL`）、表先清零 | 0 才是各版本内核都保证是 Normal 的索引；垃圾表项可能被推测性走查 |

镜像：`m1` = `c6345815…`（`0x463978`，恒等映射还在）、`m2` = `4366f08f…`（`0x4639c0`，已被拆）。
**这两个点在同一套代码下应当都回来**——因为新设计完全不依赖内核的 idmap。

#### 还未验证的残余风险（上机前要在 QEMU 里过一遍）

- `reserved_pg_dir` 此刻是否真的可写（若已 RO ⟹ 写表时中止）；
- 装表后从 PA 取指是否正常（依赖 `AttrIndx` 与 PXN/UXN）；
- `T0SZ` 从 16 改 25 后，TTBR0 换表 + 本地 TLBI 的时序是否足够。
"""
    open(p,"w").write(s); print("§34.19 已加")
