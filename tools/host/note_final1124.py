import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p = os.path.join(D, "confirmed-facts.md"); s = open(p).read()
if "34.28" not in s:
    s = s.rstrip("\n") + """

### 34.28 插座/恢复流程修正 + 卡点缩到 `kmem_cache_alloc_node_noprof`（2026-11-24 深夜）

#### 插座：之前控的是**另一个**插座

- 电视用的是 **`did 2188570626` / `xiaomi.plug.mcn004` / 米家名「电视插座」**；
- 我们一直在控的是 **`did 1043054088` / `zimi.plug.zncz01` / 「墙壁插座」**——那是别的插座，
  所以"断电"对电视毫无作用（用户现场盯着插座确认过）。
- 根因：`mihome-ctl` 的设备列表是**缓存**（`~/.local/state/mihome-ctl/mi-tokens.json`，
  当时是 11-21 的快照，新装的插座不在里面）。修法：用云端 `/home/device_list` 重新拉，
  见 `tools/host/refresh_tokens.py`（复用已有会话，不需要扫码）。

#### 控制方式（两个插座都一样）

| 操作 | 结果 |
|---|---|
| `prop-get --siid 2 --piid 1` | ✅ 读开关状态（`True`/`False`） |
| `prop-set --siid 2 --piid 1 --value false` | ❌ 被拒（per-item `code: 1`） |
| `action --siid 2 --aiid 1`（Switch·Toggle） | ✅ 生效，**但有约 1–8 秒延迟** |

⟹ 可靠做法：**读状态 → 只在需要时 toggle → 轮询状态直到翻转**（见 `tools/host/socket.sh`）。
功率读数不可靠：待机时读 0~4，电视亮屏时才 78+。

#### 恢复流程（用户给的时序，不能改）

```
断电 → 等 10 秒 → 上电 → 等 3 秒 → 按一次红外 POWER
```

之前失败的原因有两个，都很致命：

1. **时序自作主张**（30 秒 / 25 秒后再按红外）⟹ 错过窗口，卡在 logo；
2. **一个后台 burst 任务每秒按一次红外**（被遗忘的 job），Android 一起来就被下一发按回待机，
   表现为"设备莫名其妙不可达"。⟹ **跑长任务前先 `job_list` 清残留**。

#### 卡点阶梯（真机实测，7.3.5）

| 检查点 | 结果 |
|---|---|
| `ckB` `0x4772b4`（`hash_pointers_finalize` 之后） | ✅ |
| `p1` `0x47730c`（`create_boot_cache` #1 之后） | ❌ 挂 ⟹ 卡在第一次 `create_boot_cache` 内部 |
| `do_kmem_cache_create+0x40` `d1` `0x1202f4` | ✅ |
| `do_kmem_cache_create+0x94` `d2` `0x120348`（`bl pcpu_alloc_noprof`） | ✅ |
| `do_kmem_cache_create+0xc4` `d3` `0x120378`（`bl kmem_cache_alloc_node_noprof`） | ❌ 挂 |

⟹ **卡在 `kmem_cache_alloc_node_noprof`**：即第一次真正从刚建好的 cache 取对象 →
`new_slab` → `allocate_slab` → `alloc_pages` → **首次 `memset` 那一页**。
这是"首次真正触及新分配物理页"的位置，与"第 6 GB 内存段可能是幽灵区域"的假设一致。

**下一步（零猜测试探）**：把 DTB 里的第三个内存节点 `memory@180000000`（6 GB 处 1 GB）去掉，
重编内建 DTB，再跑一次之前必挂的 `kc4`（`0x477518`）。若返回 ⟹ 该段内存不可用，问题定位。
"""
    open(p, "w").write(s); print("§34.28 已写入")

p = os.path.join(D, "NEXT-SESSION.md"); s = open(p).read()
block = """**2026-11-24 深夜：卡点 = `kmem_cache_alloc_node_noprof`（首次触及新分配页）**

- 阶梯：`ckB`(hash_pointers_finalize 后) ✓ → `p1`(create_boot_cache #1 后) ✗
  → 进入 `do_kmem_cache_create`：`d1`(0x1202f4) ✓、`d2`(bl pcpu_alloc) ✓、`d3`(bl kmem_cache_alloc_node) ✗
- **插座是 `did 2188570626`「电视插座」，不是 `1043054088`「墙壁插座」**（之前控错了）；
  设备列表是缓存，用 `tools/host/refresh_tokens.py` 刷新
- 控制只能用 Toggle action（有 1–8 秒延迟）⟹ 读状态→需要才 toggle→轮询确认
- 恢复时序：**断电 → 10 秒 → 上电 → 3 秒 → 单次红外**（`socket.sh recover` 已实现）
- **跑长任务前先 `job_list` 清残留**（曾有一个每秒按红外的残留 job 把 Android 反复按回待机）
- 下一步：去掉 DTB 里 `memory@180000000` 重编，跑 `kc4`(0x477518) 验证"第 6 GB 段不可用"

"""
if "kmem_cache_alloc_node_noprof" not in s:
    i = s.index("\n## ")
    s = s[:i] + "\n" + block + s[i:]
    open(p, "w").write(s); print("NEXT-SESSION 已更新")
