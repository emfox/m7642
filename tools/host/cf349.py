import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.9" not in s:
    s=s.rstrip("\n")+"""

### 34.9 对齐修正之后：`setup_arch` 到达，`sched_init` 不到（2026-11-22 14:5x）

带 §34.8 的对齐修正后逐级推进（每档 `kva` 入口、`WAITSECS=90`）：

| 检查点 | Image 偏移 | 结果 | 记录 `x30` |
|---|---|---|---|
| `start_kernel` | `0x46091c` | 回来 | `0xffffffc080460920` |
| **`setup_arch`** | `0x463830` | **回来** | `0xffffffc080463834` |
| `sched_init` | `0x46cc14` | **不回来**（≥10 min） | — |

⟹ **新的卡点在 `setup_arch` 与 `sched_init` 之间**（`setup_arch` 已进入）。
`setup_arch` 内部候选点（已建好镜像，`mk-zfix.sh <off> <tag> kva`）：

| tag | Image 偏移 | 位置 |
|---|---|---|
| `su1` | `0x463888` | `early_ioremap_init` 之后 |
| `su2` | `0x4638d4` | `fixmap_remap_fdt` 之后 |
| `su3` | `0x4638fc` | **`early_init_dt_scan` 之后**（§28 点名的 DT 那条线） |
| `su4` | `0x463940` | `of_flat_dt_get_machine_name` + `_printk` 之后 |
| `su5` | `0x463954` | `jump_label_init` 之后、`parse_early_param` 之前 |

镜像 md5：`su1 760ad6bb` / `su2 4d9718fd` / `su3 16e574ed` / `su4 727bb105` / `su5 43038060`。

#### ⚠️ 恢复手段退化了

`sched_init` 这一挂 **红外救不回**（按了两次电源都没起，只能物理拔插）。
对照：`br x8` 之前的挂死，红外按一次 25 s 就回来。
推断：进了 `setup_arch` 之后，硬件状态已被改到 PM51/待机流程回不来的程度
（时钟/定时器/异常向量/中断遮蔽之一）。**结论：越过 `start_kernel` 之后，
每一次失败都要人工拔插**，因此这一段要么先上 ≥60 s 的 WDT（需先量喂狗时刻），
要么严格用最少的发数做二分。
"""
    open(p,"w").write(s); print("34.9 已加")

for f in ("NEXT-SESSION.md","HANDOFF.md"):
    p=os.path.join(D,f); s=open(p).read()
    if "setup_arch 到达" in s: continue
    s=s.replace("**2026-11-22 14:4x ★★★★★ 7.3 到达 `start_kernel`（重大突破）**",
                """**2026-11-22 14:5x 最新卡点：`setup_arch` ✓ / `sched_init` ✗**

新的卡点在 `setup_arch` 内部。五个内部检查点（`su1..su5`）已建好，见
`confirmed-facts.md` §34.9。**注意：越过 `start_kernel` 之后挂死，红外救不回，
只能人工拔插**——所以这一段要省着打。

**2026-11-22 14:4x ★★★★★ 7.3 到达 `start_kernel`（重大突破）**""",1)
    open(p,"w").write(s); print("updated",f)
