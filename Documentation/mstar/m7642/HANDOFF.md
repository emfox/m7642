# 交接单 — m7642（TCL / 雷鸟 65S535D，MStar M7642）

> **写给接手的新对话。** 日期 2026-11-21 11:41，交接人：小布。
> 本地目录和文件全部不变，新对话直接在 `/home/emfox/Debian/m7642/` 和
> `~/Debian/m7642-build/` 上继续（原 `~/kbuild/`，2026-11-22 迁移，布局见 paths.md §1）。本文只交接**脑子里的东西**：项目在哪、什么被证过、什么被否过、
> 什么绝对不能做、下一步第一个动作是什么。
>
> **读完本文，再按 §2 的顺序读那 5 份。** 不要跳过 §5「已否定」。

---

> **判据速查（2026-11-22 定）**：
> - **WDT 不可用**：`wdt_enable`/`HAL_WDT_Start`/`MDrv_WDT_*`/直写寄存器全部实测不咬
>   （`confirmed-facts.md` §34.13）。唯一会 warm reset 的是 `panic()`（厂内核 5 s 心跳狗）。
> - **stash 可用，但只在同一次启动内有效**：`0x23080000`（交接记录）/`0x23090000`（code1 shim），
>   探针"写记录 → 交接厂内核 → Android 起来 → `probeRW` 读"这条链是好的（今天多次验证）。
> - **待机 = 切电 = DRAM 全丢**（`M7642SURV1` 记录实测），所以挂了之后靠复位/待机都留不下数据。
> - **挂了之后能不能自动回来**：不能。屏幕停 logo（AP 带电）= 只能人工拔电；
>   屏幕黑（进了待机）= 红外一次可救。

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

## 0 一分钟摘要

**在干什么**：让主线内核（先 4.19，后 7.3）在这台 M7642 电视上跑起来。当前卡在
「mboot 把控制权交出去之后，内核/探针死在哪一级」，而**没有任何串口可用、不能拆机**。

**为什么难**：判据全灭过一轮。屏幕涂色（三次全废）、DDR 标记（读法错过一次）、
颜色通道（面板只读低 16 位）都不可靠。现在**唯一可信的通道是 pstore/pmsg**，
已端到端打通（§4.1）。

**现在到哪**：pmsg 通道 ✅ 打通；第一批 handoff 探针把 boot 槽跑挂了（§4.4），
刚用 U 盘救回（§3 是救回后的实测状态）。**下一发还没打。**

**下一步第一个动作**：不是刷探针。是把场地从 boot 槽挪到 recovery 槽
（因为只有 recovery 路径有验证过的 WDT 兜底），见 §8。

---

## 1 项目与硬约束

| 项 | 值 |
|---|---|
| 机器 | TCL / 雷鸟 **65S535D**，SoC MStar **M7642**，arm64，Android 9（`PPR2.180905.006.A1`，`verifiedbootstate=orange`） |
| 目标 | 主线内核 bring-up（4.19 先通，再 7.3） |
| **无串口** | 不接 UART、不拆机 —— 这是用户定的，不是能力不足 |
| 原厂内核 | 4.9，入口 `+0xFA0000`（MStar vendor stub），不是标准 `primary_entry` |
| 唯一救砖手段 | U 盘 `rescue-fast.bin`，约 10 分钟人工 |
| 仓库 | `~/Debian/m7642`（git，`master`，**无远端**，注意没有异地备份） |

---

## 2 必读顺序（都在 `~/Debian/m7642/Documentation/mstar/m7642/`）

| 顺序 | 文件 | 为什么 |
|---|---|---|
| 1 | **`HANDOFF.md`（本文）** | 交接上下文 |
| 2 | `discipline.md` | **纪律**，每条都付过代价。不读必重犯 |
| 3 | `confirmed-facts.md` | 实测事实 + **§H 已否定的假设**，不读会重走死路 |
| 4 | `paths.md` | 路径清单（代码树 / 产物 / 脚本 / 备份 / 设备地址） |
| 5 | `wdt-beacon.md` **§十三 / §十四 / §十五** | 最新三节：pmsg 打通、探针跑挂、救砖核对 |
| 6 | `index.md` | 文档总索引 + 「可背下来的几条」 |

其余按需，`index.md` 里有全表。

---

## 3 设备当前状态（2026-11-21 11:27 实测，逐条可复核）

| 项 | 实测值 | 判读 |
|---|---|---|
| adb | `192.168.10.60:5555` → `device` | 通，`su -c id` 返回 root |
| boot 槽 `mmcblk0p8` | md5 `6272b10dcaf5e9efa40491d87f2c1289` | **与 `~/Debian/m7642-build/backups/partitions/boot-stock-backup.bin` 逐字节相同**，探针已清 |
| `bootcmd` | `mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 boot 0x02000000; bootm 0x25000000` | 厂方原文，**不带 `wdt_enable`** |
| `recoverycmd` | 同上，把 `boot` 换成 `recovery` | 厂方原文，**不带 `mmc erase.p misc`、不带 `wdt_enable`** |
| `WDT_ENABLE` | `1` | 前置条件在（`wdt_enable` 命令本体要求它非空） |
| `MstarUpgrade_complete` | **已手工改回 `1`** | 救砖包不设它；不改的话下次插 U 盘会被强制升级 |
| env 块 | 单份（64 KiB）md5 `8111a0f4…`；改 `MstarUpgrade_complete` 后 `30b6cf8d…`；整块 128 KiB（主备）`b6dee2da…` | 被救砖**整个重置**过 |
| `misc` 前 32 B | 全 `00` | BCB 干净，不锁 recovery |
| `/data` | 25 G 用 1.3 G（6%） | **保住了**（`/data/local/tmp` 里我们 30+ 个脚本全在） |
| `install-recovery.sh` | **`/system/bin/`**（不是 `/system/etc/`）731 B、`-rwxr-x---`、可执行 | 每次 Android 启动都跑 `applypatch`。⚠️ 槽 ≠ 厂值必被覆写成厂值（反过来也是自愈） |
| `/system/etc/recovery.img` | **存在**，27,471,872 B，sha1 `1ef69168…`（= applypatch 目标） | 所以覆写**会成功**，不是空跑 |

---

## 4 已确证（实测，可以直接当前提用）

### 4.1 ★ pstore / pmsg 通道端到端可用

- 写 `/dev/pmsg0` → 内容进 ramoops pmsg zone → **同一次启动内**就被
  `persistent_ram_save_old()` 拷进 kmalloc → 导出成 `/sys/fs/pstore/pmsg-ramoops-0`，
  之后谁也覆盖不掉，`od` 一个文件就能读。
- **探针不需要崩溃、不需要复位、不需要等下一轮**（原厂内核自己这趟启动就做 init）。
- 记录头部语义：`+0x00 u32 sig=0x43474244 "DBGC"`、`+0x04 u32 start=写指针`、
  `+0x08 u32 size=有效字节`、`+0x0c` 起是数据。空环手写记录用 `start=0, size=N`（无回绕）。
- **基址是 `0x41900000`，不是 DT 里写的 `0x42300000`**（后者读回全 `00`）。pmsg zone 在
  **`0x419c0000`**。DT 与运行的矛盾**未解**，但操作上一律用实测值。
- zone 布局：`0x41900000`/`0x41940000` = dmesg 两笔，`0x41980000` = console，`0x419c0000` = pmsg。

### 4.2 mboot 不校验内核内容

往 boot 镜像尾部追加代码、改 `code1` 都被接受。这是所有注入手法的前提。

### 4.3 `wdt_enable 10` 放在 `recoverycmd` 里真的布防 WDT【实测 2026-11-20】

镜像卡死 → 约 10 s 后 warm reset → 回 `bootcmd` → Android 起来。
前提：env `WDT_ENABLE` 非空；`wdt_enable` 必须写在两条 `mmc read.p` **之后**。
**`bootcmd` 里加 `wdt_enable` 没有验过**（见 §5）。

### 4.4 boot 路径没有失败回退

探针在 boot 槽挂掉 = mboot 等内核超时（约 40 s）→ 回待机 → adb 完全不通 → U 盘救砖。
2026-11-21 10:37 就是这么挂的。

---

## 5 ★ 已否定 / 已作废（**不要重走**）

| 已否定 | 为什么 |
|---|---|
| **屏幕涂色当判据** | 三种写法（`0x2d100000` / win0 控制字 / `0x24e00000`）全无效。面板**只读每 32 位字的低 16 位** ⟹ `0x07FF07FF` 显示成青色；涂一半必出条纹；屏幕与 mboot 竞争谁写赢随机。**别再拿颜色定等级** |
| 「7.3 死在 `create_init_idmap` 体内」 | 自相矛盾：该函数与 `map_range` 的访存全落在 DDR 内的页表池和栈，无一条 MMIO；页表池 7/8 页、栈 ~600 B/4 KB 都不越界 |
| 「栈真的不可写」 | `early_init_stack` = 物理 `0x208ED000`，但它是**栈顶**，向下增长到 `0x208EC000`，`mov sp, x1` 是**正确**的；`head.S` 第 132 行注释写明 11-19 实测过 `[sp]` 可写 |
| 「`adb reboot` 之后 DDR 还留着」 | `adb reboot` = 进待机 = PM51 切电 = **硬断电**。只有 **soft reset（WDT / panic）保 DDR** |
| 「`/proc/sys/kernel/sysrq` = 0 所以 `echo c` 没用」 | 错。往 `/proc/sysrq-trigger` 写是**独立入口**，照样生效 |
| 「`MstarUpgrade_complete` absent 就一定保住 `/data`」 | 本次侥幸保住了，但 `flash-and-recovery.md` §十二 补记里有反例：mboot 在升级模式下**自己**格式化了 `/data`，不是脚本擦的。**别当必然** |
| 「Projectivy 还在 ⟹ `/data` 没被清」 | Projectivy 实际在 **`/system/product/app/TCL_ALL_T2GameCenter/`**，是 system 侧。要判断 `/data` 就用「脚本文件在 + `su` 在 + `df` 用量」三条一起看 |
| 「`rescue-norecovery.bin` 能救 boot」 | 与 `rescue-fast.bin` **同名同尺寸同 CRC**，但 recovery 段被整段注释。11-20 救砖失败就是放了它。**按 md5 区分：`7e8ef7a7…` 才是对的** |
| 「Android 侧能涂色验证」 | fb 驱动无 `write()`（ENODEV）、`shell` 域无权、停 `surfaceflinger` 会让整机重启。路已封死 |
| 「`0x20100000` 可以当标记区」 | 那是 **mboot 活动代码区**，绝对不要碰 |
| 「recovery 槽 + 挂住 + WDT 兜底能拿读数」 | 10 s 狗把 pstore 导出一起抹掉；120 s 则落待机 |
| 「改过的 recovery 镜像没被执行」 | 否。`misc` 标记被擦 + 无 WDT 时 `b .` 挂死 4 min ⟹ 执行了 |
| 「厂值 boot 镜像能放 recovery 槽起 Android」 | 否。零改动镜像 90 s 无 Android |
| 「`0x419c0000` 可从 EL2 直接写」 | 否。写它的探针两次都挂；该 zone 始终 `ff`（从没写成过） |

---

## 6 铁律（每条都付过代价）

1. **一次试验 = 一次赌注。** boot / recovery 都是单向车道，挂了就没 adb，只能搬 U 盘。
2. **`boottest.sh arm` 只许执行一次。** 第二次会把自己写的镜像当厂值备份，永久失去回滚能力。
3. **未验证过的新指令类别，不许直接进 boot 槽。** 每加一类都先问「挂了我能不能便宜地知道原因」。
4. **禁止 MMIO 盲扫。** 厂商块里有空洞，读到就 external abort → arm64 panic。
5. **不许用 sysrq。** `panic=0` ⟹ 不重启只挂住 ⟹ `wdt_enable` 硬复位 ⟹ 又给 `/data` 补一次非正常断电。
6. **只有整屏纯色算数** —— 但现在连这条也废了，见 §5。
7. **结论分三档**：实测 / 有对照的推论 / 推测。拿不到证据就写「待确认」，不许把推测写成结论。
8. **要动系统、写工作区外、碰块设备，先 `ssh emfox@localhost` 出沙箱。**
9. **工作产物只落在 `~/Debian/<项目>/`**，不在外面新开目录。
10. **改外部状态（env / 分区 / 刷机）前，先只读核对一遍再动手，动完立刻回读校验。**

---

## 7 环境速记（照抄就能用）

```bash
# adb：必须 connect 与后续命令放在同一次调用里（daemon 每条命令都会重启）
ADB=~/Debian/tv/adb/platform-tools/adb
$ADB connect 192.168.10.60:5555; sleep 1; $ADB devices

# 拿 root 读 600 文件（adb pull 会 Permission denied）
$ADB -s 192.168.10.60:5555 exec-out su -c "cat /path/to/file" > local.bin

# 裸读 eMMC（env 在 0x9E0000，主备各 64 KiB）
dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32          # 读
dd if=env-write.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32   # 写
# ⚠️ toybox dd 不支持 conv=notrunc（报 "conv option disabled"），去掉即可

# env 工具（CRC 自动重算，主备两份要写一样）
envtool.py list/get/set/verify <block>（env 快照在 ~/Debian/m7642-build/diag/）

# 交叉工具链前缀是 aarch64-buildroot-linux-gnu-（不是 aarch64-linux-gnu-）
export PATH=~/Debian/m7642-build/toolchain/gcc13/bin:$PATH

# 构建 boot 槽探针镜像（把 blob 接到原厂内核尾部，code1 跳过去，尾字跳回 0xfa0000）
python3 tools/host/mk-boot-beacon.py --src ~/Debian/m7642-build/backups/partitions/boot-stock-backup.bin \
    --blob probes/handoff/handoff1.bin --out ~/Debian/m7642-build/out/xxx.img

# 编译裸探针
aarch64-buildroot-linux-gnu-gcc -c x.S -o x.o
aarch64-buildroot-linux-gnu-objcopy -O binary --only-section=.text x.o x.bin
```

**踩过的坑**：

- 沙箱 `/tmp` 是 **10 M tmpfs、每条命令开始时清空** ⟹ 不能当备份。
- 沙箱里 `ls -l` 的 `root:root` 是 userns 映射假象，别去 `chown`。
- 沙箱多行命令会被压成单行 ⟹ 用 `;` 分隔，或先写脚本再 `bash 脚本`。
- GNU as 里 **`#define X 136` 不能当立即数**（报 `undefined symbol ... used as an immediate value`），用 `.equ`。
- `su -c "printf \"...\n\""` 双引号嵌套会**吞掉 `\n`**（变成字面 `n`），不是数据损坏。
- `mstar_mci` 分区节点在 `/dev/block/by-name/{boot,recovery,misc,dtb}`。

---

## 8 下一步（按顺序，前三步都不刷任何东西）

> ⚠️ **2026-11-21 下午更新：本节 §8.0–§8.4 的场地选择（recovery 槽）已作废**，recovery 路径经零改动对照证明起不来 Android。见 **§12**（本文末尾），那里是当前有效的下一步。


### 8.0 一个待用户拍板的决策

下一发打 **recovery 槽**还是继续 **boot 槽**？**建议 recovery 槽**，理由是：

- `recoverycmd` 的 `wdt_enable 10` 是**实测能布防**的；`bootcmd` 的没验过，而且一旦内核不起来
  就是每 10 s 复位一次、adb 根本连不上，比现在还惨。
- recovery 槽的 `recoverycmd` 也是 `mmc read.p …; bootm 0x25000000` ⟹ **探针在 recovery 槽
  `code1` 处执行时的状态与 boot 槽完全同类**（都是 `bootm` 之后、内核 entry 之前，`x0..x5`
  都是 mboot 留下的）。信息一模一样，但有狗兜底。

### 8.1 三个准备动作（不刷机、不改内核、设备照常开机）

1. **`install-recovery.sh` 改回 `.disabled`** —— 否则它会把我们写进 recovery 槽的探针冲掉。
   （它现在可执行；内容里 `applypatch -c …recovery:27471872:1ef69168…`，SHA1 不符就覆写。）
2. **改 `recoverycmd`**（env 裸写 + 回读校验）：
   ```
   recoverycmd = mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000;
                 mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 10; bootm 0x25000000
   ```
   `mmc erase.p misc` **必须最前**，否则 WDT 复位后 BCB 还在、又进 recovery、锁死循环。
3. **确认原厂 recovery 镜像的 `code1` 是否也指向 `0xfa0000`**（决定 `mk-boot-beacon.py`
   能不能直接复用，还是要把 resume 目标写成别的）。

### 8.2 第一档探针（已就绪，未刷）

`~/Debian/m7642/probes/handoff/handoff1.S` → `handoff1.bin`，**100 B / 25 条指令**：

```
  0: movz x6,#0x419c ; lsl #16     ← 8: sig/start/size 三个 str
 20: add  x6,x6,#0xc               ← "M764" "2H1 " 两个 str
 3c: str  x0..x5,sp                ← 7 × str [x6],#8
 5c: dsb  sy                       ← 60: .word 0x14000000（由注入器 patch 成 b）
```

**里面没有任何 `mrs`、没有任何 `dc cvac`。** 剩下的指令类别与 `paint3` 相同（那个实测能返回）。
记录 `size=72`（8 B 标记 + 7 × 8 B）。

现成的 boot 槽版镜像（**已作废，只作参考**）：
`~/Debian/m7642-build/out/m7642-boot-handoff1.img`，33,554,432 B，
md5 `3a950d5064b4569f47df1d4337faa2f6`，`code1 144b527f`，尾字 `17f32d68`。

### 8.3 上一发为什么挂（嫌疑清单，**没有逐条二分，别当已知**）

上一版 `handoff.S`（192 B）比 `paint3` 多做了：`dc cvac` ×3、8 条 `mrs`
（SCTLR/TTBR0/TCR/MAIR/CurrentEL/MPIDR/ID_AA64MMFR0/CNTFRQ）、写 `0x419c0000`、`mov sp`。
最可疑是 **`dc cvac`**（MMU 关时 by-VA 维护行为依赖实现，可能 data abort）。
第一档把 `mrs` 和 `dc cvac` 全删掉了。

### 8.4 之后逐档加回去

`mrs CurrentEL` 一条 → 再加 `SCTLR_EL1/TTBR0_EL1/TCR_EL1/MAIR_EL1`。
每档只加一类，挂了好归因。

---

## 9 协作约定（**行为层面的交接，同等重要**）

### 对用户

- 用户是 **emfox**，Debian Developer，技术很硬，会**当场纠正**错误。
  被纠正时：立刻查证 → 认账 → **把教训写进 `discipline.md`**，不要辩解、不要含糊带过。
- 用户回话极短（「刷吧」「刷回了」）。不要因此认为他不需要细节 —— 恰恰相反，
  关键结论要给全，只是不要注水。
- 用户明确要求过：**不要为了「多看一眼」浪费一次赌注**。
- **不擅自扩大改动范围**：只改被要求的那几行，不顺手加注释、不顺手"加固"。
- 对外发邮件（上游 / 维护者 / BTS）**必须先贴全文等他说「发」**，不许先发后解释。

### 汇报格式

- **结论分三档**：实测 / 有对照的推论 / 推测。拿不到证据写「待确认」。
- 最终回复控制在 **50–70 行**以内，给最高信号量的东西；中间过程不用复述。
- 表格用于对比；纯说明用短句。
- 中文回复，**thinking 也用中文**。
- 代码注释**一律英文**，能不用就不用；要用以一行为主，确需解释不超过三行。

### 工程习惯

- 改任何外部状态之前：先只读核对 → 说明打算怎么做 → 做完**立刻回读校验并报 md5**。
- 每次实验完更新三处：`confirmed-facts.md`（新事实）、`index.md`（若新增文档）、
  工作区 `.workbuddy/memory/MEMORY.md`（只动"下一步"那部分）。
- 文档体例固定：**结论 → 证据 → 对主线的意义 → 待办**。

---

## 10 产物与备份（都在，路径不变）

| 路径 | 是什么 | 校验 |
|---|---|---|
| `~/Debian/m7642-build/backups/partitions/boot-stock-backup.bin` | **厂值 boot，救砖/回滚的基准** | 33,554,432 B · md5 `6272b10dcaf5e9efa40491d87f2c1289` |
| `~/Debian/m7642-build/backups/partitions/rec/recovery_full.bin` | 厂值 recovery 全槽 32 MB | 33,554,432 B |
| `~/Debian/m7642-build/backups/partitions/rec/rec.head.factory.bin` | 厂值 recovery 槽前 21,618,688 B | md5 `0f6e1705f077935e1c3018973e658bfa` |
| `~/Debian/m7642-build/backups/fix/rescue-fast.bin` | **救砖包（唯一能修 boot 的 47 MB 包）** | md5 `7e8ef7a725e163672af7fb824b066abc` |
| `~/Debian/m7642-build/backups/fix/rescue-norecovery.bin` | ⚠️ **同名同尺寸，但修不了 boot** | md5 `326132c7…` |
| `~/Debian/m7642-build/diag/env-after-rescue.bin` | 救砖后 env 快照（主备两份，131072 B；单份 md5 `8111a0f4…`） | 只读存档 |
| `~/Debian/m7642-build/diag/env-write.bin` | **当前设备上那份**（含 `MstarUpgrade_complete=1`，主备两份） | 131072 B · md5 `b6dee2daaa9019f6c9d6596692005620` |
| `~/Debian/m7642-build/ref/emmcboot/now/env-wdt.bin` | 旧 WDT 配置快照 —— ⚠️ **已被救砖重置，仅存档，不要直接写回** | 64 KiB |
| `~/Debian/m7642-build/out/m7642-419-pstore.img` | 4.19 镜像，ladder 已改成写 ramoops 签名 | 21,618,688 B · md5 `7047387799c19444798060782d1ae4ca` |
| `~/Debian/m7642-build/out/m7642-boot-handoff1.img` | 第一档探针的 boot 槽版（**作废，只作参考**） | md5 `3a950d5064b4569f47df1d4337faa2f6` |
| `~/Debian/m7642/probes/handoff/handoff1.{S,bin}` | 第一档探针源码 + 100 B blob | — |
| `~/Debian/m7642/tools/host/mk-boot-beacon.py` | 注入器（把 blob 接到内核尾部 + patch code1 + 尾字） | — |
| `~/Debian/m7642/tools/host/envtool.py` | env 解析 / 改 / CRC 重算 | — |
| `~/Debian/m7642/tools/host/pkgcheck.py` | 刷机包脚本段核对（`RESULT: PASS`） | — |

---

## 11 未解 / 待办

- ❓ **ramoops 基址矛盾**：DT 写 `0x42300000`，运行在 `0x41900000`，DT 那边读回全 `00`。未解。
- ❓ **handoff 探针挂在哪条指令**：只有嫌疑清单，没二分。
- ❓ **`bootcmd` 里 `wdt_enable` 是否生效**：未验。这决定 boot 槽能不能变成可回滚。
- ❓ **`/data` 到底是被谁清的**（历史遗留）：脚本没擦，怀疑 mboot 在升级模式自己格式化。
- 待办：`~/Debian/m7642` **没有远端**，所有文档只在本机 —— 要异地备份得先决定放哪。
- 待办：`m7642-bringup` 分支未提交；`drivers/.marker_test` 待删。

---

## 附：一份最小可执行的开工检查

新对话接手后，建议先跑这三条确认设备还活着、状态没漂：

```bash
ADB=~/Debian/tv/adb/platform-tools/adb
$ADB connect 192.168.10.60:5555; sleep 1; $ADB devices
$ADB -s 192.168.10.60:5555 exec-out su -c \
  "dd if=/dev/block/mmcblk0p8 bs=1048576 count=32 2>/dev/null" | md5sum
# 期望 6272b10dcaf5e9efa40491d87f2c1289（厂值 boot）

$ADB -s 192.168.10.60:5555 exec-out su -c \
  "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" | md5sum
# 期望 b6dee2daaa9019f6c9d6596692005620（整块 128 KiB = 主备两份）
# 单份 64 KiB 是 30b6cf8d416c2924a7d8a94a7a90a293；若对不上，先 envtool list 看差异
```

如果第一条就对不上，说明设备被人动过，**先别刷任何东西**，按 §3 重新核一遍。

---

## 12 2026-11-21 下午：本对话的产出（**取代 §8**）

### 12.1 一句话现状

**有了一条可用的探针读数通道**：boot 槽 `code1` 的探针「写普通 DDR + 返回 `0xFA0000`」→
Android 正常起来 → probeRW 直读那几页。第一次拿到交接状态，零 U 盘、零复位。

### 12.2 场地判据（今天逐条判死，别再试）

| 场地 / 做法 | 结果 |
|---|---|
| recovery 槽 + 挂住 + `wdt_enable 10` | 自己回 Android，**读不到**（记录被同一次复位抹掉） |
| recovery 槽 + 返回版 + `wdt_enable 120` | 落**待机**，要人按键；狗不再是兜底 |
| recovery 槽 + 零改动厂值 boot 镜像 | **90 s 无 Android** ⟹ 场地不行（对照实验） |
| **boot 槽 + 返回版 + 写普通 DDR** | **成功**（`handoff2`，md5 `eed03941…`） |

⟹ 只有 **boot 槽**能承载「探针返回 → Android → 读数」。挂了就是 U 盘（`rescue-fast.bin`
md5 `7e8ef7a7…`），但这一类指令（`movz/movk/str/dsb`）实测能返回。

### 12.3 通道与交接状态

- 落点：`0x23080000`–`0x230F0000` 八页（每页 64 B 记录），读法 `probeRW op=r`。
- `x0=0` `x1=0x1c` `x2=0x20200100` `x3=0` `x4=0` `x5=0x9dcc10d4` `sp=0`（实测；含义待确认）。
- 详见 `confirmed-facts.md` §I、`wdt-beacon.md` §四。

### 12.4 下一步（唯一关键门）

**主线内核不起 Android ⟹ 读数必须跨一次复位存活。** 测法（自恢复，10 s 狗）：

```
recovery 槽 + stash 写 + b . + wdt_enable 10   → 狗咬回来 → 读 8 页
```

- 存活 ⟹ bring-up 调试通道成立：把 4.19/7.3 每级检查点写进 stash，狗咬回来读最后一级。
- 不存活 ⟹ 只剩屏幕或持久介质，要重新设计信标。

### 12.5 今天被证明无效的文档结论（已就地标注）

- `wdt-beacon.md` §一「改过的 recovery 镜像没有被 mboot 执行」——**作废**。
- `wdt-beacon.md` §四.6 的标记 `M764`——实际是 `M746`。
- §8.1 的「必须先 disable `/system/etc/install-recovery.sh`」——路径是 `/system/bin/`；
  且不动它反而更好：每次 Android 启动自动把槽还原厂值。
