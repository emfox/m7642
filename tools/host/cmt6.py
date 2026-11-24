import os
D=os.path.expanduser("~/Debian/m7642")
p=os.path.join(D,"Documentation/mstar/m7642/confirmed-facts.md"); s=open(p).read()
if "34.21" not in s:
    s=s.rstrip("\n")+"""

### 34.21 世界改为**编译期**选择；运行时 AT 探测作废（2026-11-22 23:5x）

`q1`（入口已修正、带 `AT S1E1R` 探测）在 `0x463978` **仍然挂**。而这个点上 `f1` 是能回来的，
`f1` 与 `q1` 的差别只剩入口那几条 `AT/mrs/tbnz`。

⟹ **取消运行时探测**：检查点属于哪个世界，构建期就知道（`cpu_uninstall_idmap()` 的位置是固定的）。

| 构建 | 入口行为 | 用途 |
|---|---|---|
| `WORLD_VA=0`（默认） | `adr` → `sub KIMAGE_OFFSET` → `br`（跳到 PA 别名），`x5=0` | `cpu_uninstall_idmap()` **之前**的检查点（与 `f1`/`ps1z`/`skmainz` 同一路径） |
| `WORLD_VA=1` | `x5 = KIMAGE_OFFSET`，留在内核 VA，末尾自建 1 GB 恒等表 | **之后**的检查点 |

`make` 侧：`build-postmmu.sh` 接受 `WORLD_VA`，并把三个入口偏移写进 `tramp-entries.env`；
`mk-zfix.sh`、`mk-postmmu-images.sh`、`mk-emap-images.sh` 全部改读该文件（此前有两个脚本
仍在写死 `TRAMP_AT + 4`，是子代理的 `check-entries.sh` 静态检查点出来的）。

#### 子代理新增的两道**上机前静态检查**（已入库）

| 工具 | 作用 |
|---|---|
| `qemu/check-images.py` | 不需要启动 QEMU：在镜像里按 `_start` 的指令签名找到内嵌 tramp blob，读出 `_start_kva` 真实偏移，再检查镜像里的那条 `bl` 落在 blob 的哪个偏移；不一致就判 `POISONED` |
| `qemu/check-entries.sh` | 扫所有构建脚本，找出仍硬编码旧入口偏移、不读 `tramp-entries.env` 的 |

它的首次运行就点名了 **`p1`/`p2` 是毒发的**（内嵌 v4 的 `_start_kva@0x8`，而 `bl` 指向 `blob+0x4`）——
**那两个 md5 正是我准备上机的**。这条检查以后必须放在每次上机之前。

镜像：`u1` = `d7fdf887…`（`0x463978`，world A，入口与 `f1` 逐条相同）、
`u2` = `f55c5439…`（`0x4639c0`，world B）。
"""
    open(p,"w").write(s); print("§34.21 已加")
