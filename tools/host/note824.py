import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

p = os.path.join(D, "confirmed-facts.md"); s = open(p).read()
if "34.24" not in s:
    s = s.rstrip("\n") + """

### 34.24 卡点在 `kmem_cache_init()` 的分配循环里：**既不返回也不 panic**（2026-11-23 深夜）

#### 静态分析（不用上机）

`kmem_cache_init`（`0x477280`）的调用序列与其中的关键点：

| 地址 | 调用 | 判读 |
|---|---|---|
| `0x4772b0` | `hash_pointers_finalize` | |
| `0x477308/0x477340` | `create_boot_cache` ×2（`kmem_cache_node`、`kmem_cache`） | |
| `0x477348/0x477358` | `bootstrap` ×2 | |
| `0x477360` | `setup_kmalloc_cache_index_table` | |
| `0x477364` | `create_kmalloc_caches` | |
| `0x4773dc` | `kmalloc_size_roundup` | 循环内 |
| `0x47740c` | `__kmalloc_cache_node_noprof` | **循环内的分配 #1** |
| `0x477474` | `_find_next_bit` | |
| `0x4774ac` | `__kmalloc_flags_noprof` | **循环内的分配 #2** |
| `0x4774c4` | `panic` | 格式串实测为 **`"Out of memory when creating kmem_cache %s"`**（slub.c） |
| `0x477518` | `__cpuhp_setup_state(state=10 "slub:dead", start=NULL, teardown=slab_cpu_down)` | **`invoke=0`**，不会对在线 CPU 调回调 ⟹ 不太可能挂 |

顺带澄清：**内存描述没问题**。我们的三个 memory 节点与厂 cmdline 一致
（`LX_MEM=0x21600000 LX_MEM2=0x54400000,0x49600000 LX_MEM3=0x180000000,0x40000000`，见
`factory49-entry.md`）；`reserved-memory` 只有 8 MB framebuffer。

#### 真机实测（一图双探针，`combo` = `d7b98d68…`）

同一张镜像里放两个**互斥**探针：

| 探针 | 位置 | 触发条件 |
|---|---|---|
| `panicpath` | `kmem_cache_init+0x238`（`0x4774b8`） | 只有 `kmalloc(48)` 返回 NULL 才会走到 |
| `kc4` | `kmem_cache_init+0x298`（`0x477518`） | 循环正常结束才到 |

**结果：两条都没触发，设备挂死。**

⟹ **既不是 slub 的 OOM panic，也不是循环走完** ⟹ **卡在循环里的某个分配上，分配器"既不返回也不失败"**
（典型形态：`__alloc_pages_slowpath` 里的 reclaim / compaction / OOM 重试自旋）。

#### 明天第一发（已建好）

`combo2` = `b82ba978fadaea82189a72f0af800f68`：
`d0=save` + `firstalloc`（`0x477410`，循环里第一次 `kmalloc` 返回之后）+ `oom`（`out_of_memory` 入口）。

| 记录 `x30` | 结论 | 下一步 |
|---|---|---|
| `0x…0c4d40` | **确认 OOM** | 一发读内存计数器（`totalram_pages`/`max_pfn`/memblock 计数）后再决定 |
| `0x…477414` | 第一次 `kmalloc` 正常返回 | 卡在循环更后面（分配 #2 或 `_find_next_bit`） |
| 两处都不触发 | 慢路径自旋但没 OOM | 在 `__alloc_pages_noprof`（`0x112070`）内部分档 |

设备当前**挂死**，需物理拔插。
"""
    open(p, "w").write(s); print("§34.24 已写入")

p = os.path.join(D, "NEXT-SESSION.md"); s = open(p).read()
block = """**2026-11-23 深夜：卡点在 `kmem_cache_init()` 的分配循环（既不返回也不 panic）**

- world B 继续可用：`mk-multi.sh <tag> d0=save <ckpt>=restore`。
- 已确认通过：`c1`/`c2`/`b1`/`b1b`/`start_kernel`/`build_all_zonelists`/`pre_mmcore`/`mm1..mm4`。
- **`combo` 镜像（`d7b98d68…`）证明**：既没走 slub 的 OOM panic（`0x4774b8`），也没走完循环
  （`0x477518`）⟹ 卡在循环内的分配上，分配器"既不返回也不失败"。
- **明天第一发**：`combo2` = `b82ba978…`（`d0=save` + `firstalloc 0x477410` + `oom out_of_memory`），
  三态判读见 `confirmed-facts.md` §34.24。
- 设备挂死，**需物理拔插**。

"""
if "combo2" not in s:
    i = s.index("\n## ")
    s = s[:i] + "\n" + block + s[i:]
    open(p, "w").write(s); print("NEXT-SESSION 顶部已更新")
