import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.17" not in s:
    s=s.rstrip("\n")+"""

### 34.17 ★★★★★ 更正：`0x463978` 之后的“挂死”极可能是**我们探针自己挂了**（2026-11-22 16:4x）

#### 边界实测

| 档 | 偏移 | 结果 |
|---|---|---|
| `d0` | `0x463958` | ✅ 回来（10 s） |
| **`f1`** | **`0x463978`** | ✅ **回来（10 s）** |
| `e0` / `c1` / `c2` / `b1` / `e1` | `0x4639b4` / `0x463a04` / `0x463a24` / `0x463b98` / `0x4639c0` | ❌ 不回，**记录全空** |

分界精确落在 `cpu_uninstall_idmap()` 里那条 `msr ttbr0_el1, x0`（`0x463978`）上：
**`f1` 在它之前 → 好；`e1` 在它之后 8 条指令 → 坏。**

#### 机制：探针用物理地址写记录，而恒等映射被拆掉了

- `abort-postmmu.S` 把记录写到 **PA `0x23080000`**（`movz x6,#0x2308; lsl 16`），交接时还按 PA
  把厂内核从 `0x30000800` 拷到 `0x20280000`；
- 这些在 **MMU 关**时是物理地址，没问题；在 **MMU 开**时它们是**用户态 VA**，
  必须靠 TTBR0 的**恒等映射**才能落到物理内存；
- `cpu_uninstall_idmap()` 的作用就是**把 TTBR0 换成 `reserved_pg_dir`（零页）**，
  即**拆掉恒等映射**（源码注释写得很明确："No translations will be possible via TTBR0"）。

⟹ **`0x463978` 之后，我们探针的第一条 `str` 就取数中止**；而且此时 `local_daif_restore`
已经屏蔽了 IRQ/FIQ，中止会变成**死循环**，外部表现与"内核挂死"完全一致（停 logo、静默）。

#### 为什么以前从没暴露

`__primary_switched`(0x468060)、`start_kernel`(0x46091c)、`setup_arch`(0x463830)、
`su3`/`su4`/`su5`/`d0`/`f1` —— **全部在 `cpu_uninstall_idmap()` 之前执行**，恒等映射还在。
而 `c2`/`b1`/`sched_init` 都在它之后，所以"一过 `setup_arch` 就挂"其实是同一件事。

⟹ **§34.14 与 §34.9 里“`paging_init`/`smp_init_cpus`/`sched_init` 是卡点”的结论全部作废**：
那几发记录为空，是探针没写进去，不能说明内核状态。

#### 修法（下一步要做的）

让**所有 post-MMU 路径的访存都走 VA**，而不是 PA：

1. tramp 的 KVA 入口已经算过 `PA = VA - KIMAGE_OFFSET`；反过来记一个"MMU 开"标志传给交接桩；
2. 交接桩用 `mrs x, sctlr_el1` 的 `.M` 位判断（更稳，不依赖传参）：
   - MMU 关 → 沿用现在的物理地址；
   - MMU 开 → 记录与厂内核拷贝改用 **VA**：
     * 镜像范围内的地址用 `VA = PA + KIMAGE_OFFSET`（tramp 就在这个映射里，已验证可执行）；
     * 镜像范围外的（`0x30000800` 那块暂存、`0x23080000` 那块记录）需要**线性映射**偏移，
       可用 `memstart_addr` 符号（它的 VA 是构建期常量）算出 `lin = PAGE_OFFSET - memstart_addr`；
3. `dc civac` 也改用对应 VA。

**立即可用的替代**：把记录**放进镜像自己的一页**（比如我们 tramp 所在页的尾部
`PA 0x2036c800` → `VA 0xffffffc08036c800`），这条路径**不需要线性映射**，
只要 `KIMAGE_OFFSET` 正确——那是最小改动，可以先用来验证"恒等映射说"：
若把记录改到 `0xffffffc08036c800` 之后 `e1` 能回来，理论即坐实。
"""
    open(p,"w").write(s); print("§34.17 已加")

p=os.path.join(D,"discipline.md"); s=open(p).read()
if "探针的访存地址必须跟 MMU 状态匹配" not in s:
    s=s.rstrip("\n")+"""

### 探针的访存地址必须跟 MMU 状态匹配（血的教训）

MMU **关**时要用物理地址；MMU **开**时物理地址不是"物理地址"，是**用户态 VA**，
要靠 TTBR0 的恒等映射才落到内存。`setup_arch` 里的 `cpu_uninstall_idmap()`（`0x463978`）
会把恒等映射拆掉 ⟹ 之后任何"按 PA 写"的探针都会**取数中止**，而那一刻 IRQ/FIQ 已被
`local_daif_restore` 屏蔽，中止变成死循环，**外部表现与内核挂死无法区分**。

⟹ 判据：如果某一发"记录为空"，先问**探针在那一点能不能合法访存**，再怀疑内核。
这一条之前害我们误判了 5 发（`c1`/`c2`/`b1`/`e0`/`e1`），每发还花掉一次人工拔电。
"""
    open(p,"w").write(s); print("discipline 已加")
