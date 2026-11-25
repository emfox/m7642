# 下次开工的第一件事（2026-11-22 01:5x 写）

设备当前状态：**上一发 `prsw` 没回来，设备 ping 不通，需要一次物理断电**
（拔电源线 → 插回 → 按一下电源键）。boot 槽是厂值 `6272b10dcaf5e9efa40491d87f2c1289`，
`misc` 的 BCB 已被 `recoverycmd` 里的 `mmc erase.p misc` 擦掉，断电后不会锁 recovery。

> **2026-11-22 11:0x 环境变更**：`~/kbuild/` 已清理并迁到 `~/Debian/m7642-build/`
> （16 GB → 6.6 GB，布局见该目录 `README.md` 与 `paths.md` §1）。4.19 树已删除。
> `out/` 里的 27 张上机镜像已按源码重建并逐一比过 md5，全部一致。
> 设备当前是活的（adb 可达），上一发 `ps1` 的挂死已由拔插恢复。

> **2026-11-22 11:4x 停在这里（设备挂死，需一次拔插）**：追 `br x8` 的这一轮，`kva1`
> 和 `kva4` 都挂，但两次都**不能当结论**——`kva1` 是 MMU 开着写 stash（探针自己的错），
> `kva4` 是 MMU 开着读内核 VA，挂在它自己那次访存上。零访存对照已建好：
> **`kva6` = `70d57d95221a0786dc5ec2233456e4a0`**（只 `mrs`，安全），恢复设备后先跑它：
>
> ```sh
> cd ~/Debian/m7642/probes/handoff
> ./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-kva6.img 70d57d95221a0786dc5ec2233456e4a0 kva6
> ```
>
> 记录 `0x23090000` = [x8, SCTLR, TTBR1, TCR]、`0x23090020` = [VBAR, ESR, FAR]。
> 判读：SCTLR 的 M 位若为 0 ⟹ 那一刻 MMU 其实没开（VA 访存必挂，`br x8` 也必挂）；
> 若为 1 ⟹ 看 x8 是否等于 `0xffffffc08046805c`（= `__primary_switched` 的内核 VA），
> 不等就是重定位没填字面量（`0x4555c0` 的 R_AARCH64_RELATIVE）。
> 之后才轮到 `kva5`（MMU 开着写 DDR 的对照），再决定 VA 到底能不能读。

> **判据速查（2026-11-22 定）**：
> - **WDT 不可用**：`wdt_enable`/`HAL_WDT_Start`/`MDrv_WDT_*`/直写寄存器全部实测不咬
>   （`confirmed-facts.md` §34.13）。唯一会 warm reset 的是 `panic()`（厂内核 5 s 心跳狗）。
> - **stash 可用，但只在同一次启动内有效**：`0x23080000`（交接记录）/`0x23090000`（code1 shim），
>   探针"写记录 → 交接厂内核 → Android 起来 → `probeRW` 读"这条链是好的（今天多次验证）。
> - **待机 = 切电 = DRAM 全丢**（`M7642SURV1` 记录实测），所以挂了之后靠复位/待机都留不下数据。
> - **挂了之后能不能自动回来**：不能。屏幕停 logo（AP 带电）= 只能人工拔电；
>   屏幕黑（进了待机）= 红外一次可救。

**2026-11-23 晚 ★★★★★ world B 解锁；卡点 = `kmem_cache_init()` 内部**

- 基线已升到 **Linux 7.3.5**（内核 git 分支 `m7642-7.3.5`，构建树 `linux-735-out`）；
  `f1` 真机验证通过（+8 位移，其余记录字段与 7.3 完全一致）。
- **world B（拆 idmap 之后）现在可观测**：`mk-multi.sh <tag> d0=save <ckpt>=restore`
  —— d0 处存 `TCR_EL1`/`TTBR0_EL1` 并返回内核，目标检查点处还回去再走老路。
- 已确认通过：`c1` `c2` `b1` `b1b` `start_kernel` `build_all_zonelists` `pre_mmcore`
  `mm1..mm4`（`build_all_zonelists`/`memblock_free_all`/`mem_init` 全部 OK）。
- **卡点：`kmem_cache_init()` 内部**（`mm5` 挂）。四档 `kc1..kc4` 镜像已建好，见 §34.23。
- 设备当前挂死，**需物理拔插**后继续。


**2026-11-23 深夜：卡点在 `kmem_cache_init()` 的分配循环（既不返回也不 panic）**

- world B 继续可用：`mk-multi.sh <tag> d0=save <ckpt>=restore`。
- 已确认通过：`c1`/`c2`/`b1`/`b1b`/`start_kernel`/`build_all_zonelists`/`pre_mmcore`/`mm1..mm4`。
- **`combo` 镜像（`d7b98d68…`）证明**：既没走 slub 的 OOM panic（`0x4774b8`），也没走完循环
  （`0x477518`）⟹ 卡在循环内的分配上，分配器"既不返回也不失败"。
- **明天第一发**：`combo2` = `b82ba978…`（`d0=save` + `firstalloc 0x477410` + `oom out_of_memory`），
  三态判读见 `confirmed-facts.md` §34.24。
- 设备挂死，**需物理拔插**。


**2026-11-24：排除法收窄到 `bootstrap_kmalloc_sheaves`，下一步用"计数型返回探针"**

- 已排除：内存不足（`ro2` 实测 2.67 GB 认到、仅 137 MB 保留）、核数（QEMU `-smp 4` 正常）、
  跨 4 GB/多 zone（`-m 6G/8G` 正常）。**QEMU 复现不了**。
- 卡点在 `kmem_cache_init` 内联的 `bootstrap_kmalloc_sheaves()`（`0x477368..0x4774f4`）：
  遍历 14 个 kmalloc 尺寸类，逐项 `kmalloc_node(sizeof(*barn))`。
- **下一步（1 发/次，尽量返回）**：在循环头 `0x47738c` 放"计数型返回探针"，
  计数到 N 才交接；N 从 1 递增，能返回的发零断电成本。
- 若必须"挂了也能读"：解冻 eMMC 写路径（见 `emmc.md` §11.3）。
- 设备当前**正常**（Android 在跑），智能插座名字"电视插座"（`zimi.plug.zncz01`，did
  `1043054088`，工具 `tools/host/socket.sh`，**仅在最后手段使用**）。


**2026-11-24 深夜：卡点 = `kmem_cache_alloc_node_noprof`（首次触及新分配页）**

- 阶梯：`ckB`(hash_pointers_finalize 后) ✓ → `p1`(create_boot_cache #1 后) ✗
  → 进入 `do_kmem_cache_create`：`d1`(0x1202f4) ✓、`d2`(bl pcpu_alloc) ✓、`d3`(bl kmem_cache_alloc_node) ✗
- **插座是 `did 2188570626`「电视插座」，不是 `1043054088`「墙壁插座」**（之前控错了）；
  设备列表是缓存，用 `tools/host/refresh_tokens.py` 刷新
- 控制只能用 Toggle action（有 1–8 秒延迟）⟹ 读状态→需要才 toggle→轮询确认
- 恢复时序：**断电 → 10 秒 → 上电 → 3 秒 → 单次红外**（`socket.sh recover` 已实现）
- **跑长任务前先 `job_list` 清残留**（曾有一个每秒按红外的残留 job 把 Android 反复按回待机）
- 下一步：去掉 DTB 里 `memory@180000000` 重编，跑 `kc4`(0x477518) 验证"第 6 GB 段不可用"


**2026-11-24 23:1x 状态（独立审计后更正）**

- **卡点窗口**：`create_boot_cache(kmem_cache_node, …)` 内部，`[pcpu_alloc 开始 … new_slab)`。
  已证实可达：`ckB 0x4772b4`、`d1 0x1202f4`、`d2 0x120348`。
  **已作废**：`d3 0x120378 ❌` 是结构性假阴性（`slab_state==DOWN` 时走 `0x1204e0` 的
  `early_kmem_cache_node_alloc`，那条 `bl` 永不执行）；"卡在 kmem_cache_alloc_node"不成立；
  `0x1203d8` 别打（必然 ❌）。
- **下一发**（镜像已备好 `out/`）：
  - `ctl` = `8b4bcf72d8bd4f95163e2c5d945d1ff6`（`0x4772b4`，对照，必回）
  - `ns1` = `1a0a04e4095f07ed379794a3b4d6bd11`（`0x1204fc` = `bl new_slab`）
  - **先打 ctl 再打 ns1**；ctl ❌ 则整批作废。
- **仪器已修**：`-DSAVE_VA/-DTABLE_PA/-DTABLE_VA` 真正传入 + 构建后自检（防旧 blob）；
  `SAVE_VA=0xffffffc08061a000`；`TABLE_PA` 由 `TABLE_VA-KOFF` 算出（原硬编码差 0x280000）；
  `ckpt.py`(47 条) / `decode-record.py`(readout) 已从 `eb0ff18^` 恢复。
- **已知仪器缺陷（未修）**：blob 0x36c000 覆盖 9 个活符号（含 `queued_spin_lock_slowpath`、
  `queued_read_lock_slowpath`）⟹ 锁竞争会跳进 blob 变成假挂死；记录区 `0x23080000` 未在 DT 保留；
  `restore` 不关中断。
- **构建陷阱**：改 DTS 后要删 `$O/arch/arm64/kernel/m7642-dtb.o`（不是 `dts/mstar/` 那个）再
  `make Image`，否则内嵌 DTB 静默留旧。当前 DTS 已回滚，Image 内嵌 FDT 为 3 段内存。
- **插座**：`did 2188570626`（`xiaomi.plug.mcn004`「电视插座」）；恢复流程
  `tools/host/socket.sh recover` = 断电→10 s→上电→3 s→单次红外。


**2026-11-24 23:3x 状态（带对照探针的一批实测）**

- 卡点：**页分配器快路径** `get_page_from_freelist` 入口→水位检查之间（内联 zone 遍历）。
  已验证可达：`ctl 0x4772b4`、`ns1 0x1204fc`、`na 0x1169a4`、`pa 0x110ddc`。
  挂死：`nb 0x116aa0`、`pb 0x110e54`、`pw 0x10fad8`。
- 已排除：内存不足/回收、`sched_init` 时序（还不到 `preempt_schedule` 0x10fb9c）、第 6 GB 内存段。
- **下一步**：静态还原 `get_page_from_freelist` 前 0x120 字节的 zone 循环，然后在其**循环头**
  用 `_start_count`（N=1）判别"正常迭代"还是"第一项就卡"。
- 纪律：每批先打 `ctl` 对照；对照不回来则整批作废。


**2026-11-25 00:1x 状态：仪器已修，真实阶梯到 `sched_init` 体内部**

- **仪器修复**：探针 blob 从 `Image+0x36c000`（压着 `_raw_spin_trylock` 等 9 个符号）
  移到 `Image+0x36e000`（8 KB 真空闲 `.text` 尾）。修复后 `nb2/t2b/kc4c/sc1` 全部由 ❌ 变 ✅。
- **已到达**：`kmem_cache_init` 结束、页分配完成、`sched_init` 内的
  `__sched_fork` → `init_idle` → `idle_thread_set_boot_cpu` → `init_sched_fair_class`
  的 `alloc_cpumask_var_node` 与 `open_softirq`。
- **未到达**：`console_init`（`0x46e024`）⟹ 真实窗口 = `open_softirq` 之后 → `console_init`，
  含 `sched_init` 剩余、`init_IRQ`、`local_irq_enable`、`time_init`。
- **下一步先静态**：把 `sched_init` 从 `0x46d0e4` 之后到结尾的调用列干净，再列 `start_kernel`
  从 `sched_init` 返回后到 `console_init` 之间的调用（注意 `init_IRQ`/`local_irq_enable` 是重点嫌疑）。
  每个打点地址必须先用 `objdump` 确认**所在函数**与**指令类型**（避开 `brk #0x800`）。
- 纪律：每批先打 `ctl2`（`0x4772b4`）对照；改仪器后**重跑先前 ❌ 的点**验证。


**2026-11-25 00:35 状态：NOP 已判定不需要；对齐问题已开三条线索**

- ✅ **dcache NOP 不需要**（`cchk`/`cnop`/`knop` 三发全返回）⟹ 上线配方只剩对齐修正一个补丁。
- ✅ **mboot 读 `ANDROID!` 头的 `kernel_addr`**（只改它行为就变：`0x20400000` → 挂死）。
- ⚠️ 但"装到 `0x20200000` + 去掉对齐补丁"仍失败（`al4`）。已修两个真 bug：
  `PRIMARY_ENTRY_PA` 必须绑厂地址 `0x20280000`；`HANDOVER_PA` 必须随装载地址推。
  待查：`IDMAP_PROBE_PA` 仍写死 `0x20280000`；mboot 是否有其它隐含约束。
- 构建开关：`NO_NOP` / `NO_ALIGN` / `KADDR` / `KERNEL_ADDR` / `FACTORY_KADDR` / `STUB_AT`。
- **下一步**：先回到第 3 项（找真卡点：`open_softirq` → `console_init`），对齐收口可并行推进。


**2026-11-25 01:35 ★★★★★ 早期启动没有卡点：内核已跑到 init 末尾（VFS panic = 没有根文件系统）**

- 修好两处仪器自伤后，`kmem_cache_init_late` 与 `console_init` 均 **✅ 到达**：
  ① blob 覆盖 `_raw_spin_trylock`（§34.32）；② **开中断后交接桩被定时器中断重入**（终结型入口加 `daifset`）。
- "故障探测器"抓到 `panic`，格式串 = `VFS: Unable to mount root fs on "%s" or %s/dev/root`
  ⟹ 内核跑完 `do_basic_setup`/`prepare_namespace`，只差根文件系统；`panic=0` 表现为挂死。
- **下一步**：内建 initramfs（`linux-735-ir` 已构建），`/init` 把 framebuffer 涂绿 + 尝试 reboot。
  屏幕变绿 = 7.3.5 在这台电视上完整启动到用户态。
- 教训：`❌` 只代表"该地址没被执行"，必须确认该指令在路径上必然执行，并配已知必经点对照。


**2026-11-25 03:40 ★★★★★ 真卡点找到并修复：`free_initmem` 的 init 段毒化**

- 卡点 = `free_initmem` → `__free_reserved_area` 里 `memset(page_address(page), 0xcc, 4096)`。
- **修复（真机验证）**：①`m7642-dtb.S` 从 `.init.rodata` 改到 `.rodata`（真 bug）；②`arm64/mm/init.c`
  的 `free_initmem` 用 `-1` 代替 `POISON_FREE_INITMEM`。验证镜像 `m7642-fixed.img` 的
  `run_init_process` 探针 **触发 ✅** ⟹ 内核到达用户态启动。
- 待办：确认 `CONFIG_MAGIC_SYSRQ`；把 `/init` 改成涂 framebuffer 之类可直接观察的动作；
  继续查毒化为何挂（`.init` 里还有别的东西被后续使用）。
- 仪器经验（必读）：blob 位置 `0x36e000`；终结型入口加 `daifset`；**每次重编必须重取地址**；
  本平台**没有 restart handler**，panic 不会重启（功率通道不能当 panic 证据）。


**2026-11-25 05:15 ★★★★★ 7.3.5 启动到用户态（真机确认）**

- 探针证据：`kernel_execve` ✅ → `begin_new_exec` ✅ → **`ret_to_user` ✅（返回 EL0）**
- 之前"涂绿失败/等不到 panic"的原因是配置：`CONFIG_DEVMEM` 与 `CONFIG_MAGIC_SYSRQ` 都没开，不是 `/init` 没跑。
- 现在 `linux-735-ir` 已开 `DEVMEM/DEVTMPFS/MAGIC_SYSRQ`，`/init` 会**把屏幕涂成纯绿**并常驻。
- 验证镜像：`m7642-green.img`（`3daab60f…`，无探针）。
- 接下来（按优先级）：① 屏幕确认；② 让 `/init` 真正有用（挂 eMMC、起 shell、起网络）；
  ③ 把 `free_initmem` 毒化挂死的原因收口（`.init` 里还有什么被后续使用）；④ 上游化 DTS/驱动。


**2026-11-25 10:30 ★★★★★ 工具链回归已修复，5:24 状态用源码重建复现**

- 两个自伤：①`mkimage.sh` 把 Image 包成容器 ⟹ 与 `mk-mainline-abort.py` 形成嵌套容器；
  ②把对齐点从 `__pi_early_map_kernel+0x3c` 改成字节搜索，匹配到巧合的 `0x465224`，
  真正的 2 MB 对齐修正从未生效。两处都已加硬断言。
- 复现验证：干净构建树 `linux-735-clean` + initramfs 配置 + `d0=save`/`panic` 探针 ⟹
  `android up +22s`、`magic=M764MM`、`x30=panic+4` ✅；随后读到报告页与 **6879 字节内核日志**
  （含 `Run /init as init process`）。
- 镜像（含元数据）：`m7642-fix3.img` md5 `b10d6f18e6f239e187a45b82b2a928f1`。
- 下一步：`FB_SIMPLE`（屏幕控制台）/ `eMMC: no SD 1006`。


## 停下点（2026-11-22 15:1x）

设备**硬挂**，需要一次物理拔插（红外救不回，见 §34.9 的退化说明）。
拔插后按这个顺序做，**每一发都当成有预算的**：

```sh
cd ~/Debian/m7642/probes/handoff

# 0) 复工仪式：确认上次结论、看树里已有什么
../..//tools/host/session-start.sh 2>/dev/null || true

# 1) 先打 setup_arch 里最可疑的那个：early_init_dt_scan 之后
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
$ADB connect 192.168.10.60:5555
$ADB -s 192.168.10.60:5555 exec-out su -c "dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=512 seek=16376 count=8; sync"
WAITSECS=90 ./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-su3.img 16e574ed1de95ea49cdb4485f0114f03 su3

# 2) 判读
#   su3 回来  ⟹ 卡点在 early_init_dt_scan 之后 → 依次打 su4(727bb105) / su5(43038060)
#   su3 不回来 ⟹ 卡点在 early_init_dt_scan 之前或之内 → 先打 su1(760ad6bb) / su2(4d9718fd)
```

**硬约束**：这一段的挂死都要人工拔插，所以**不要一次连打多档**；每发之前先想好
"回来/不回来各自说明什么"。

## ★ 当前最强结论（别再重推一遍）

> 2026-11-21 §27/§28 已用实测**排除了整类「fault」假设**，并给出根因候选。
> 今天（2026-11-22）有会话没读到这条，把 fault 假设又走了一遍，白费三次断电。

1. **7.3 不是异常挂死，是空转/等待。** 异常探针 `probes/handoff/vecprobe.S`（装自建
   VBAR → 记录 ESR/ELR/FAR/SPSR → 交接厂内核，Android 34 s 起来）自检 `brk #0x1234`
   抓到 `ESR_EL2=0xF2001234`（EC=0x3C、ISS 与参数一致）、`ELR_EL2=0x21680018`、
   `SPSR_EL2=0x600003C9` ⟹ 探针有效；对照组让未打补丁的 7.3 真跑 → **挂住，零异常**。
2. **最强根因候选：`wfe` 等从核。** `0x455000–0x466000` 无回边；5 处 `wfe/wfi`，其中
   `0x4557F0`（`wait_linear_map_split_to_ptes`/`scondary_cpu_wait`）与
   `0x4554D8`（`secondary_holding_pen`）最可疑：从核被 mboot 停在**厂内核**地址上，
   永远到不了 7.3 的同步点 ⟹ 主核在 `wfe` 里无限等，**不产生异常**。
3. ~~最可能的真正根因：dtb 的 `enable-method` / `cpu-release-addr` 与 7.3 不一致~~
   **——已排除（2026-11-21 23:43 实测）**：`/cpus` 根本没有 `enable-method`，各 CPU 是
   自旋表式 `cpu-release-addr = <0 0x100510>`；而 **SMP 初始化在 `start_kernel` 之后**，
   与我们这个早期卡点无关。不要再查这一项。
4. 2026-11-22 新增的边界约束：`Image+0x4555b0`（`br x8`）**能回**，
   `Image+0x468060`（`__primary_switched+4`）**不能回** ⟹ 空转点在 `br x8` 之后。
   注意 `ps0`/`mk*` 那类能回的点都走 tramp 的 **PA 入口**，不能回的两个都走**内核 VA 入口**，
   所以"KVA 入口本身是否可用"仍未排除（`kva6` 是为这个建的，零访存，安全）。

**2026-11-22 14:5x 最新卡点：`setup_arch` ✓ / `sched_init` ✗**

新的卡点在 `setup_arch` 内部。五个内部检查点（`su1..su5`）已建好，见
`confirmed-facts.md` §34.9。**注意：越过 `start_kernel` 之后挂死，红外救不回，
只能人工拔插**——所以这一段要省着打。

**2026-11-22 14:4x ★★★★★ 7.3 到达 `start_kernel`（重大突破）**

`br x8` 跳到数据区（`0xffffffc0804e805c`）的根因是：`__pi_early_map_kernel` 用
`and x25, x19, #0x1fffff` 算「镜像与 2 MB 对齐的差」，而 `adrp _text` 在 **MMU 关**时给的是
物理地址 ⟹ `0x20280000 & 0x1fffff = 0x80000`，这个值被当作重定位偏移传给
`__pi_relocate_kernel`（已采到 `x0=0x80000`），把所有重定位指针推高 512 KB。
arm64 要求 Image 放在 2 MB 对齐地址，mboot 偏要放 `0x20280000`。

**修法**：把 `Image+0x465a1c` 强制成 `mov x25, xzr`（`0xaa1f03f9`）。
结果：`x8` 变回 `0xffffffc08046805c`；检查点 `0x468060` 回来（`x30` 是内核 VA）；
**`start_kernel`（`0x46091c`）回来**（`x30 = 0xffffffc080460920`）。

⟹ 后续所有镜像**必须带这个修正**，用 `probes/handoff/mk-zfix.sh <off> <tag> [pa|kva]`。
详见 `confirmed-facts.md` §34.8。

**2026-11-22 14:0x（已被上面这条取代，仅存档）**：`x8`（`br x8` 目标）实测为
`0xffffffc0804e805c`，而 `__primary_switched` 在 `0x8046805c`——**差 +0x80000，落在数据区**，
`br x8` 一跳过去就是执行数据 ⟹ 这一条足以解释"跑到 `br x8` 之后没有下文"。
`SCTLR_EL1=0x34d4d91d` ⟹ MMU/cache 都开着。详见 `confirmed-facts.md` §34.7。
下一步：查 `__pi_relocate_kernel` 的 offset 为什么是 +0x80000（`--stub` 把 kernel
补齐到 `0x1400000` 是首要嫌疑）。

**新会话第 0 步**：跑 `tools/host/session-start.sh`（可选带关键词）。它会打印最近提交、
上面这块结论、树里已有的探针清单，以及**上一个会话最后几条用户消息**——信息全在
`~/.dsh/sessions/` 的原始对话记录里，`zstdcat <dir>/session.v4.jsonl.zstd | less` 可查全文。

**规矩**：设计新探针之前，先 `grep` 一遍 `probes/` 和 `confirmed-facts.md`——
这个仓库里已经躺着 27 个 `.S` 探针，重复造轮子等于重复付代价。

## 0. 必读的上一条结论（§I.33）

NEXT-SESSION 上一版 A 的三张镜像**按原样不可能回来**：桩在 `Image+0x1400000`（PA `0x21680000`），
而 MMU 开后两套映射都止于 `_end`（Image+0x670000）；「线性映射」地址 `0xffffffc0004d5000`
是模块区（`PAGE_OFFSET = 0xffffff8000000000`），且 `start_kernel` 时线性映射还不存在。

同时查出一处**配置漂移**：11-20 的 7.3 Image 是 `CONFIG_MSTAR_M7642_BUILTIN_DTB=n`，
而文档的前提是 `=y`；mboot 交的 `x0=0`，所以 `setup_arch` 拿不到 DT。
已重编 Image（`=y`，DTB 在 Image+0x4C9858），并在 code1 加 shim 把 `x0` 设成 `0x23000000`、
把 mboot 入口寄存器记到 `0x23090000`。详见 confirmed-facts §I.33。

## 0.5 2026-11-22 10:05 更新：post-MMU 仪器成立，卡点在 `__pi_early_map_kernel` 体内

- `mmuon`(`7f309a47…`)、`emap`(`f0ca4aa2…`) 都 **stash 验证通过**（Android 正常起）；
  `prsw`(`b8651fd2…`) **不回来**（488 s）⟹ 卡点在 `__pi_early_map_kernel`
  （`0x4659e0`..`0x46805c`）里，不在 `start_kernel` 之后。
- 顺带实测：mboot 交的 `x0 = 0`（code1 shim 记录），DTB 那环的判断成立。
- 下一批镜像 `mk1`..`mk6`（函数体内 6 个调用点）已构建，md5 与偏移见
  confirmed-facts §34。顺序 mk1→mk6，第一个不回来的就是卡点。
  设备当前挂死（prsw 那一发），**先物理拔插**，再跑：
- **2026-11-22 10:2x 续**：`mk1..mk6`（函数体内 6 个调用点）**全部回来** ⟹
  `__pi_early_map_kernel` 执行完；`ps0`(`0x4555b0`，`br x8`) 回来、`ps1`(`0x468060`) 不回来
  ⟹ 卡点是 **`br x8` 跳内核 VA / `__primary_switched` 第一条**。
  判别镜像 `kva`(`3b220ef4e31cc357c65f08a547021732`) 在 `0x4555b0` 记录 `x8` 并用内核 VA
  读 `_text`/目标页/tramp 页。**设备当前挂死，先拔插**，然后：
  `./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-kva.img 3b220ef4e31cc357c65f08a547021732 kva`


  ```bash
  cd ~/Debian/m7642/probes/handoff
  ./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-mk1.img 371627c1fd729baa16723a3912bcbe1a mk1
  # mk2 50a5f07f / mk3 3b7dac45 / mk4 83cb6f29 / mk5 5d567f3a / mk6 893a2274
  ```

## 1. 恢复设备后先核对（只读，不需要断电磁）

```bash
ADB=~/Debian/tv/adb/platform-tools/adb
$ADB connect 192.168.10.60:5555; sleep 1; $ADB devices
$ADB -s 192.168.10.60:5555 exec-out su -c "dd if=/dev/block/by-name/boot bs=1048576 count=32 2>/dev/null" | md5sum
#   期望 6272b10dcaf5e9efa40491d87f2c1289（厂值 boot）
$ADB -s 192.168.10.60:5555 exec-out su -c "dd if=/dev/block/by-name/misc bs=32 count=1 2>/dev/null" | od -An -tx1
#   期望 32 个 00
```

## 2. 第一发：验证仪器本身（**一定到达**的点）

```bash
cd ~/Debian/m7642/probes/handoff
./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-mmuon.img 7f309a473a77abafe894a0636c91b1c2 mmuon
```

- 检查点 = `__enable_mmu+0x38`（`0x455548`，`msr sctlr_el1` 之后）：MMU 刚开、PC 仍是 PA，
  **不受 `early_map_kernel` 影响**，是仪器的最小可验证点。
- **回来** ⟹ 仪器在 MMU 后可用了 ⟹ 按 §3 的顺序往后推。
- **不回来** ⟹ 先查 `tramp-postmmu.S`，不要继续往后打（每发都要一次人工断电）。

## 3. 之后按这个顺序（每档回来才算「到达」）

| 顺序 | 镜像 | md5 | 检查点 |
|---|---|---|---|
| 2 | `m7642-rec-73-emap.img` | `f0ca4aa27051e9cafff4e289adf5193f` | `__pi_early_map_kernel` 0x4659e0 |
| 3 | `m7642-rec-73-prsw.img` | `b8651fd2121089cb69e8385234fc58a9` | `__primary_switched` 0x46805c |
| 4 | `m7642-rec-73-skmain.img` | `2eac39d1515761d31ce65dd7a5b9b33e` | `start_kernel` 0x46091c |

四张镜像**都带**：`nop @0x46804C`（`preserve_boot_args` 的 `b dcache_inval_poc`，此前所有深检查点
都在带它的镜像上测到）、code1 shim（x0=0x23000000 + 记录到 0x23090000）、tramp、handover。
重建命令：`probes/handoff/build-postmmu.sh && probes/handoff/mk-postmmu-images.sh`（换内核后必须重跑，
脚本从 System.map 复算所有常量）。

`run-postmmu.sh` 会读两个 64 B 记录：

- `0x23090000` = `M764`/`FDT `：mboot 入口的 x0..x5/x30（**x0 是 mboot 真正给的 DTB 指针**）
- `0x23080000` = `M764`/`MMMU`：检查点记录（x30 = 检查点返回地址：内核 VA 或 PA）

## 4. 若 2/3/4 都「不回来」

那说明 7.3 在 `create_init_idmap` 或更早处就挂住（**不是** MMU 之后）：
`0x465E78` 是唯一 stash 验证过的深点，而 `0x465E80` 从未到达过（§I.25，且仪器当时不可靠）。
此时改用 pre-MMU 单步通道（`abort-rung.bin` 的预算交接；**MMU 关时不要用 tramp**——
`dc civac` 在 MMU 关时是另一件事）：

```bash
cd ~/Debian/m7642
python3 tools/host/mk-mainline-abort.py --image ~/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image \
  --at 0x465e80 --stub probes/handoff/abort-rung.bin --nop 0x46804c \
  --out ~/Debian/m7642-build/out/m7642-rec-73-rung-0x465e80.img
# 取输出里的 md5，然后：
probes/handoff/run-rung.sh ~/Debian/m7642-build/out/m7642-rec-73-rung-0x465e80.img <md5> 0x465e80
```

先重跑 `0x465E80`（**带 nop**，与已验证档一致），再往 `map_range` 入口 `0x465CC8` 推。

## 5. 不变的两条线

- **eMMC(FCIE)**：§32 已结案寄存器映射；**boot-path CMD17 探针已就绪、未上机**。
  恢复设备后按顺序：

  ```bash
  # 1) 只读模块复核 34+2 个寄存器（零风险），check-dump 期望 diff 0
  adb push ~/Debian/m7642-build/build/fcie-build/fcie.ko /data/local/tmp/
  adb shell su -c "/vendor/bin/busybox rmmod fcie 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/fcie.ko; rmmod fcie"
  adb exec-out su -c "cat /data/local/tmp/fcie.out" > /tmp/fcie.out
  ~/Debian/m7642/probes/fcie/check-dump.sh /tmp/fcie.out
  # 2) CMD17：code1 处读 LBA 0，与内核 dd 的同一扇区逐字节对比
  cd ~/Debian/m7642/probes/fcie
  ./run-cmd17.sh ~/Debian/m7642-build/out/m7642-rec-73-emmc.img a4479e336f3b4b4ac7fa5ca1aad46887
  ```

  判据：心跳 `rc=0` + `R1` 的 CURRENT_STATE=4/READY_FOR_DATA=1 + 512 B 与 `dd` 一致。
  只读 LBA 0；挂住 = 一次物理断电（boot 槽是厂值，卡只被读过）。

  **2026-11-22 10:00：CMD17 读通道成立**（rc=0、R1=0x900、SD_STATUS=0xff00、
  512 B 与内核 `dd` 的 LBA0 逐字节相同）。之前连续挂死的根因是 **C 代码冲掉了 x0..x5**，
  而厂内核入口要读 `w2`；`emmc_read.S` 已改成入口保存、交接前恢复。
  全量镜像 `9f071ae8ff512a1843396e8849633531`。

- **写路径（CMD24/CMD25）继续冻结**：`probes/fcie` 里没有任何写 eMMC 的代码，也不加。

## 6. 今天（11-22 凌晨）的账

- 发现并修掉上一版 post-MMU 桩的**不可达**（映射范围 + 线性映射地址 + 时机）与
  **BUILTIN_DTB 配置漂移**；重编带内嵌 DTB 的 Image。
- 新仪器：tramp 注入 `.text` 尾部填充（内核 VA 与 idmap 都 ROX），两个入口；handover 仍在 0x21680200。
- 第一发 `prsw` NO_RETURN（505 s）——但那一版漏了 `nop @0x46804C`，已重建四张镜像。
- 机器目前挂死，等一次物理断电。
