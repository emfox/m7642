import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

p = os.path.join(D, "confirmed-facts.md"); s = open(p).read()
if "34.23" not in s:
    s = s.rstrip("\n") + """

### 34.23 ★★★★★ world B 解锁 + 7.3.5 上机 + 卡点收敛到 `kmem_cache_init()`（2026-11-23 晚）

#### 7.3.5 通过真机验证

`f1`（`setup_arch+0x148` = `cpu_uninstall_idmap` 的 `msr ttbr0_el1`）在 7.3.5 镜像上 **11 s 回来**，
记录与 7.3 逐字段一致，只有 `x30 = 0xffffffc080463984`（7.3.5 的 `0x463980+4`，即 +8 位移）。
`MIDR=0x411fd090`（A73）、`TCR T0SZ=16`、`MAIR=0x40044ffff`、`CTR=0x84448004` 全部与 7.3 那次相同。

#### world B 解锁：把内核自己的 TCR/TTBR0 **存下来再还回去**

之前"自建 1 GB 恒等表"的路在真机上一直挂。换了个更小的做法，**不自己造页表**：

| 探针 | 位置 | 动作 |
|---|---|---|
| `_start_save`（blob+0x400） | `d0`（`setup_arch+0x128`，拆 idmap **之前**） | 存 `TCR_EL1`/`TTBR0_EL1` 到 `SAVE_VA`，写 "M764"/"SAVE" 标记，**模拟被替换的指令（`mov x0,#0xc0`）后 `ret` 返回内核** |
| `_start_restore`（blob+0x500） | 目标检查点（拆 idmap **之后**） | 把存下的 TCR/TTBR0 写回，`tlbi vmalle1`，然后走**已验证的 PA 别名路径**交接 |

⟹ `sr2 = [d0=save] + [e1=restore]` **11 s 回来**，`x30=0xffffffc0804639cc`，
`TCR_EL1=0x32b5593510`（T0SZ=16）⟹ 归还成功。**拆 idmap 之后的区域从此可观测。**

**两个坑（都踩过）**：

1. **`SAVE_VA` 的物理地址要减 `KIMAGE_OFFSET`**：`0xffffffc080603000` → PA **`0x20883000`**，
   不是 `0x20603000`（镜像装在 `0x20280000`）。
2. **交接桩的 32 MB 拷贝会覆盖整个镜像**（`0x20280000..0x21554A00`），所以**存进镜像里的东西
   在交接之后就读不到了**——它只活到 "restore 探针读到它" 为止，这对功能足够，但别指望事后回读。

镜像构建：`probes/handoff/mk-multi.sh <tag> d0=save <ckpt>=restore`（入口名 `pa|kva|save|restore`）。

#### 阶梯结果（全部真机实测，7.3.5）

| 检查点 | 结果 |
|---|---|
| `c1`（`efi_init` 之后）/ `c2`（`paging_init` 之后） | ✅ ✅ |
| `b1`（`bl smp_init_cpus`）/ `b1b`（`smp_init_cpus` 返回后） | ✅ ✅ |
| `trap_init`（= `start_kernel` 入口前 4 B）/ `zonelists`（`build_all_zonelists`） | ✅ ✅ |
| `pre_mmcore`（`bl mm_core_init`） | ✅ |
| `post_mmcore`（`mm_core_init` 返回后） | ❌ **挂** |
| `mm1`（`build_all_zonelists` 之后）/ `mm2`（`bl memblock_free_all`） | ✅ ✅ |
| `mm3`（`bl mem_init`）/ `mm4`（`bl kmem_cache_init`） | ✅ ✅ |
| `mm5`（`kmem_cache_init` 返回后） | ❌ **挂** |

⟹ **`paging_init`/`smp_init_cpus`/`sched_init` 是卡点** 这三条旧结论**正式作废**（都是仪器问题）。
⟹ **当前卡点在 `kmem_cache_init()` 内部**。里面有个 **`panic()` 调用（`0x4774c4`，分配失败路径）**——
无控制台的 panic 就是静默挂死，是首要嫌疑之一；另一个是 `__cpuhp_setup_state`。

#### 明天从这里继续

镜像已建好（`~/Debian/m7642-build/out/m7642-wb6-*.img`）：

| 档 | 位置 | md5 |
|---|---|---|
| `kc1` | `kmem_cache_init+0xc8`（`bl bootstrap`） | `cfd90b42f8b48c3de3a01089d913b96c` |
| `kc2` | `+0xe4`（`bl create_kmalloc_caches`） | `822290ccad2763d27cd00d2be214a154` |
| `kc3` | `+0xe8`（`create_kmalloc_caches` 之后） | `465cdbcf72c09f97856f8bc329c2d47b` |
| `kc4` | `+0x298`（`bl __cpuhp_setup_state`） | `cca141bc8b80037336ac1758a992cd99` |

设备当前**挂死**（`mm5` 那发），需物理拔插一次。

#### 工具

- `tools/host/ckpt.py` 已加：`b1b`、`trap_init`、`zonelists`、`sort_extable`、`pre_logbuf`、
  `pre_vfsearly`、`pre_sortext`、`pre_mmcore`、`post_mmcore`、`pre_sched`、`mm1..mm8`、`kc1..kc4`。
- `probes/handoff/mk-multi.sh`：多入口补丁构建器（名字而非偏移）。
- **已知 bug**：`qemu/check-images.py` 把 `adrp`（`0x90001f80`）误判成 `bl` 并报 `POISONED` 假阳性，待修。
"""
    open(p, "w").write(s); print("§34.23 已写入")

p = os.path.join(D, "NEXT-SESSION.md"); s = open(p).read()
block = """**2026-11-23 晚 ★★★★★ world B 解锁；卡点 = `kmem_cache_init()` 内部**

- 基线已升到 **Linux 7.3.5**（内核 git 分支 `m7642-7.3.5`，构建树 `linux-735-out`）；
  `f1` 真机验证通过（+8 位移，其余记录字段与 7.3 完全一致）。
- **world B（拆 idmap 之后）现在可观测**：`mk-multi.sh <tag> d0=save <ckpt>=restore`
  —— d0 处存 `TCR_EL1`/`TTBR0_EL1` 并返回内核，目标检查点处还回去再走老路。
- 已确认通过：`c1` `c2` `b1` `b1b` `start_kernel` `build_all_zonelists` `pre_mmcore`
  `mm1..mm4`（`build_all_zonelists`/`memblock_free_all`/`mem_init` 全部 OK）。
- **卡点：`kmem_cache_init()` 内部**（`mm5` 挂）。四档 `kc1..kc4` 镜像已建好，见 §34.23。
- 设备当前挂死，**需物理拔插**后继续。

"""
if "world B 解锁" not in s:
    i = s.index("\n## ")
    s = s[:i] + "\n" + block + s[i:]
    open(p, "w").write(s); print("NEXT-SESSION 顶部已更新")
