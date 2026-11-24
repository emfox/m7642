import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

p = os.path.join(D, "confirmed-facts.md"); s = open(p).read()
if "34.26" not in s:
    s = s.rstrip("\n") + """

### 34.26 排除法：内存充足、核数无关、跨 4 GB 无关 —— 卡点在 `bootstrap_kmalloc_sheaves`（2026-11-24）

#### 零风险"读数发"（`ro2`，11 s 返回，未断电）

在 `mm4`（`bl kmem_cache_init`，已验证会返回）用新的 readout 入口读 `memblock`：

| 项 | 实测 | 判读 |
|---|---|---|
| `memblock.memory.cnt` | **3** | 三段内存全被认到 ✓ |
| `memblock.memory.total_size` | **0xaac00000 = 2864 MB (2.67 GB)** | 与 `LX_MEM/LX_MEM2/LX_MEM3` 吻合 ✓ |
| `memblock.reserved.cnt` | 19 | |
| `memblock.reserved.total_size` | **0x88c33dd = 137 MB** | 可用约 2.6 GB |
| `max_pfn` / `min_low_pfn` | `0x1c0000` / `0x20200` | 与 6 GB 顶端、`0x20200000` 起点一致 ✓ |

⟹ **内存完全充足**。"分配器因 OOM 进入 direct reclaim"这个假设**排除**。

#### `kmem_cache_init` 的真实结构（slub.c:8644，不是 slab_common.c）

```c
hash_pointers_finalize(...);            // 0x4772b0
for_each_node_state(node, N_MEMORY) node_set(node, slab_nodes);
for_each_online_node(node)         node_set(node, slab_barn_nodes);
create_boot_cache(kmem_cache_node, ... SLAB_NO_SHEAVES|SLAB_NO_OBJ_EXT);  // 0x477308
slab_state = PARTIAL;
create_boot_cache(kmem_cache, ...);                                       // 0x477340
kmem_cache      = bootstrap(&boot_kmem_cache);                            // 0x477348
kmem_cache_node = bootstrap(&boot_kmem_cache_node);                       // 0x477358
setup_kmalloc_cache_index_table();                                        // 0x477360
create_kmalloc_caches();                                                  // 0x477364
bootstrap_kmalloc_sheaves();     // ★ 内联为 0x477368..0x4774f4（含那个 panic）
init_freelist_randomization();   // ★ 同上（本 config 下是空桩）
cpuhp_setup_state_nocalls(CPUHP_SLUB_DEAD, ...);                          // 0x477518
pr_info("SLUB: HWalign=%d, ..., CPUs=%u, Nodes=%u\\n", ...);               // 0x477548
```

反汇编还原出的循环：遍历 **14 个 kmalloc 尺寸类**（`cmp x19,#0xe`），逐项检查
`cache->flags & 0x2c87`（`SLAB_NO_SHEAVES` 等），然后 `kmalloc_size_roundup`（`0x4773dc`）
→ `__kmalloc_cache_node_noprof`（`0x47740c`）= **`bootstrap_cache_sheaves()` 里的
`kmalloc_node(sizeof(*barn), GFP_KERNEL, node)`**，失败则走 `0x4774b8` 的
`panic("Out of memory when creating kmem_cache %s")`。

#### QEMU 复现尝试（全部零硬件风险，全部失败）

前提：我们的镜像开着 `CONFIG_MSTAR_M7642_BUILTIN_DTB=y`，`setup_arch` 会**无视 QEMU 的树**、
强制用自己的 m7642 DTB ⟹ console 指向不存在的 `ttyS0`、`/memory` 指向电视地址 ⟹ **QEMU 里一个字都不打印**。
为此专门建了 `BUILTIN_DTB=n` 的变体（`~/Debian/m7642-build/kernel/qemu-735`）。

| 配置 | `SLUB: HWalign` 是否打印 | 结论 |
|---|---|---|
| `-smp 1 -m 2G` | ✅ | 基线 |
| `-smp 4 -m 2G` | ✅ | **核数无关** |
| `-smp 4 -m 6G` | ✅ | 跨 4 GB 无关 |
| `-smp 4 -m 8G` | ✅ | 多 zone 无关 |

⟹ **QEMU 复现不了**。TV 与 QEMU 剩下的差别只有 QEMU 不建模的东西：
**带空洞的多段内存**（TV 有 `0x41800000..0x54400000` 空洞 + 第 6 GB 区域）、
MStar 时钟/定时器、以及 `ZONE_NORMAL` 里的实际页分布。

#### 下一步（需上机，1 发，尽量让它返回）

顺序代码没法用"互斥探针"压缩，最有效的仪器是**让挂死也能留下读数**：

1. **优先**：把"计数型返回探针"加到 `bootstrap_kmalloc_sheaves` 的循环头
   （`0x47738c`）——每次迭代把计数写进 SAVE 页并返回内核，**计数到 N 时才交接**。
   N 从 1 开始递增（1 → 8 → 32 → …），每次"能返回"的发数**零断电成本**，
   直到某一发开始挂死，就把死亡点锁在两次 N 之间。
2. 若确认必然要"挂了也能读"，则解冻 **eMMC 写路径**（`emmc.md` §11.3 已离线实现并验证过逻辑），
   让探针把每次迭代 append 到 eMMC——**一次挂死就能拿到精确位置**。
"""
    open(p, "w").write(s); print("§34.26 已写入")

p = os.path.join(D, "NEXT-SESSION.md"); s = open(p).read()
block = """**2026-11-24：排除法收窄到 `bootstrap_kmalloc_sheaves`，下一步用"计数型返回探针"**

- 已排除：内存不足（`ro2` 实测 2.67 GB 认到、仅 137 MB 保留）、核数（QEMU `-smp 4` 正常）、
  跨 4 GB/多 zone（`-m 6G/8G` 正常）。**QEMU 复现不了**。
- 卡点在 `kmem_cache_init` 内联的 `bootstrap_kmalloc_sheaves()`（`0x477368..0x4774f4`）：
  遍历 14 个 kmalloc 尺寸类，逐项 `kmalloc_node(sizeof(*barn))`。
- **下一步（1 发/次，尽量返回）**：在循环头 `0x47738c` 放"计数型返回探针"，
  计数到 N 才交接；N 从 1 递增，能返回的发零断电成本。
- 若必须"挂了也能读"：解冻 eMMC 写路径（见 `emmc.md` §11.3）。
- 设备当前**正常**（Android 在跑），智能插座名字"电视插座"（`zimi.plug.zncz01`，did
  `1043054088`，工具 `tools/host/socket.sh`，**仅在最后手段使用**）。

"""
if "计数型返回探针" not in s:
    i = s.index("\n## ")
    s = s[:i] + "\n" + block + s[i:]
    open(p, "w").write(s); print("NEXT-SESSION 已更新")

# 纪律：插座 = 最后手段
p = os.path.join(D, "discipline.md"); s = open(p).read()
if "电视插座" not in s:
    s = s.rstrip("\n") + """

### 重启手段的优先顺序（2026-11-24，用户重申）

1. **静态分析**（反汇编 / 源码 / 符号与结构体布局）先缩小到 1–2 个候选点；
2. **优先设计会返回的发数**（readout、计数型返回探针、互斥探针），这类发数**零断电成本**；
3. 红外 `tools/host/tvpower.sh`（把断电→上电当作"待机复位"）只在挂死且不得不断电时用；
4. **最后**才用智能插座 `tools/host/socket.sh cycle`（米家"电视插座"，`zimi.plug.zncz01`）。

**每一轮断电重启对电源与存储都是冲击，发数本身就是预算。**
"""
    open(p, "w").write(s); print("discipline: 重启优先级已写入")
