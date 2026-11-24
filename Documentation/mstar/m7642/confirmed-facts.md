# 确证事实

> **本文件是必读**（尤其 §A / §B / §C / §H）。
> 每条都带标记：**【实测】** = 本机复现过；**【对照】** = 有独立对照推出的结论；**【推测】** = 未验证。
> 纪律在 [discipline.md](discipline.md)，路径在 [paths.md](paths.md)。
> 数字都应能在本机复算——文档里给的是结果，命令见对应专题文档。

---

## A 设备身份

| 事实 | 标记 | 证据 |
|---|---|---|
| SoC 是 **M7642**（＝ MT9652 / 9669 一系），MStar 血统，**GIC-400** | 实测 | `/proc/cpuinfo`、`/proc/interrupts` |
| GIC distributor / CPU interface = **`0x16001000` / `0x16002000`** | 实测 | 厂值 dtb + 活体 iomem |
| timer 频率 **12 MHz** | 实测 | 厂值 dtb |
| UART0 **`0x1F201300`**，寄存器步距 **8 字节**（`reg-shift = <3>`），SPI，**123 MHz** | 实测 | 厂值 dtb；厂商把 8250 偏移翻倍再 `<<2`，净值就是标准 8250 |
| `ro.build.fingerprint` = `tcl/tcl_m7642/…:PPR2.180905.006.A1/…:user/dev-keys` | 实测 | `getprop` |
| `verifiedbootstate=orange`、`SECURITY=OFF` ⟹ **分区镜像无签名** | 实测 | 厂值 cmdline |
| 谱系 `m5621 → m7332 → m7632 → m7642 → mt5862` | 对照 | 同型号相邻**不可复用**：TCLOpenSource 17 个仓库全是 MTK 血统（`mt58xx-intc`、IO 基址 `0x1C`），不合用 |

## B 启动链与交接

**mboot 的交接状态（全部实测）**

- 进入内核时 **`CurrentEL = EL2`**、**`SCTLR_EL2.M = 0`**，A/C/I 全 0 ⟹ **MMU 是关的**。
  探针 `m7642-boot-s1.img`：144 B rung 写 FDT `/model` 后读回 `20000`。
- `x0` **被内核自己覆盖**成 `0x23000000`（FDT 地址，env `bootcmd` 背书）；`w2` = cmdline 指针；
  `w3`/`w4` = ramdisk 起 / 长。触发条件是 `CONFIG_MP_PLATFORM_ARM_64bit_PORTING=y` 与
  `..._BOOTARGS_NODTB=y` ⟹ **7.3 必须内建 dts**，不能指望 mboot 传。
- `preserve_boot_args` 写 `.data` **成功** ⟹ 「镜像内不可写」已被否掉。
- **`CONFIG_MP_PLATFORM_3G_MIU0` 未开** ⟹ `b stext`、不走 MIU 偏移 ⟹ **物理地址 = MIU 地址**，
  `create_init_idmap` 的纯身份映射是对的。
- 厂商用 **PSCI**（`psci{method="smc"; cpu_on=<0x84000003>}`）⟹ 本地 dtsi 里「no PSCI / 只能
  maxcpus=1」作废，与 `EL2` 自洽。4 核行为仍【推测】。

**入口 = `Image_base`，`code1` 是 PC 相对跳转**

| | `code1` | 目标 |
|---|---|---|
| 原厂 4.9 `prebuilt/kernel` | `0x143e7fff` | `base + 0xFA0000`（`VENDOR_ENTRY`，`FA_AT = 0xF9FE00`） |
| 7.3 `Image` | `0x1411540d` | `base + 0x455038`（`primary_entry`） |

两边都是 EFI-stub 的 `MZ` 头 + 相对跳转 ⟹ mboot 只要跳 `Image_base+0` 就进得去，
**这解释了「绿检查点总能出来」**。⚠️ `code1` 在偏移 4，**算目标时 PC = base+4**。

**原厂 4.9 的启动流程**（`+0xFA0000`，实测反汇编）

```
查 0x1F001CE0 → el2_setup → record_mmu_state → __create_page_tables(MStar 版)
→ __cpu_setup → __primary_switch
```

MStar 版 `__create_page_tables` 先 `__inval_dcache_area(0x217CD000, 0x217D2000)` → 清 16 KB
→ 属性 `0x701`、**物理起点 `0x1F200000`** 建 block。细节见 [factory49-entry.md](factory49-entry.md)。

## C 内存与地址

**`/proc/iomem` 实测的四段**

| 段 | 范围 | 大小 |
|---|---|---|
| 1 | `0x20200000 + 0x21600000` | 534 MiB（内核 `0x20280000` 在其中） |
| 2 | `0x54400000 + 0x49600000` | 1174 MiB |
| 3 | `0x180000000 + 0x40000000` | 1024 MiB |
| 4 | `0x41900000 - 0x419fffff` | persistent_ram ×4 |

- 合计 **2732 MiB**；`MemTotal` 报 3072 ⟹ 厂值 `total_memory=3145728` **虚报**。
- **`LX_MEM=0x21600000` 是第一段的「大小」不是起点**；`LX_MEM2/3` 是 (起点, 长度)。
- 本地 dts 三段 memory 节点与 iomem **逐字节吻合，别再改**。
- 「7.3 只有 128 MB」是只看厂值 dtb 单节点的**错读**。

**关键地址**

| 项 | 值 | 标记 |
|---|---|---|
| `Image` 物理基址 | **`0x20280000`** | 实测（厂值 recovery 头 offset 12 的 `kernel_addr`；另有 OPPO dump `ARM\x64` @ `0x20280038`、TWRP `BOARD_KERNEL_BASE 0x20278000`+0x8000 佐证） |
| `TEXT_OFFSET` | `0x80000`（`CONFIG_MEMORY_START_ADDRESS 0x20200000` + 它 = 基址） | 实测 |
| `ZRELADDR` | arm64 上**是死字段**，不影响 `Image` 内容 | 对照（全树只有 `arch/arm/Makefile` 消费它） |
| framebuffer | **`0x2D100000`**，由 mboot 经 `recovery_fbaddr=` 传 | 实测 |
| ramoops | `0x42300000`，落在内存洞里（无 `struct page`） | 实测 |

**7.3 镜像结构**

- `_edata = 0x5F3200`（Image 实体到此为止）；`image_size` 实测 `0xFA0100`（16.4 MB）。
- ⟹ `0x600000` 起是厂家 blob 拼接区；`0xF9F000` 会被加载但**是零填充空洞**（放代码 = `udf #0`）。
- **安全探针落点 `0x4A7000`**（`__alt_instructions_end`+0x14），备用 `0x499178`。
- `__pi_create_init_idmap = 0x465E5C`、`primary_entry = 0x455038`。
- ⚠️ `+0x600000` 是镜像内偏移，文件里 `+0x600800`；无 header 的 `arch/arm64/boot/Image` 两者相等。

**7.3 早期布局**（`System.map` + `vmlinux.lds.S`，2026-11-20 核对）

| 符号 | VA 偏移 | 物理 |
|---|---|---|
| `_text` | `ffffffc080000000` | `0x20280000` |
| `__pi_init_idmap_pg_dir` | `+0x4B0000` | `0x20730000` |
| `early_init_stack` | `+0x66D000` | **`0x208ED000`** |
| `_end` | `+0x670000` | `0x208F0000` |

- **`early_init_stack` 指向栈顶，不是栈底。** `vmlinux.lds.S:367` 是
  `. += SZ_4K;` 之后才 `early_init_stack = .` ⟹ `head.S:130` 的 `mov sp, x1` 正确，
  栈区 = `0x208EC000..0x208ED000`（4 KB）。
- ⟹ **「`create_init_idmap` 里栈不可写」这条作废**，改判「待确认」。三条依据：
  ① 该记号是栈顶，设置没 bug；② `head.S:132` 注释记着「A store to `[sp]` succeeded on
  2026-11-19」；③ 挂点 `+0x465EB8` 反汇编是 `mov x2, x14`——**准备第一次 `bl __pi_map_range`，
  这条指令本身不访存** ⟹「4 次栈写之后挂」≠「栈写失败」。
- **7.3 建表用栈，4.19 不用**：`__pi_create_init_idmap` 有 `sub sp,#0x30` + 4 次 `stp` +
  2 次 `bl`；4.19 的 `__create_page_tables` 整函数纯寄存器、无一条 `str [sp]`。
  ⟹ 7.3 多一个「栈可用且 4 KB 够用」的依赖，但这**不是**死因证据。
- ⚠️ `ladder.S` 注释称「bits[7:4]：1=RGB565，5=ARGB8888，per `E_GOP_COLOR_*` in `apiGOP.h`」——
  **本机全盘没有 `apiGOP.h`**，此映射是反推的推测，不可当事实引用。

**★★ `create_init_idmap` 静态可证不会 fault（2026-11-20 计算 + 反汇编）**

`map_range` 覆盖 `_stext.._end` = 物理 `0x20290000..0x208F0000`。它需要访问的东西全在范围内：

| 访问对象 | 物理 | 在 `_edata`(0x20873200) 之前？ | 含义 |
|---|---|---|---|
| 页表池 `__pi_init_idmap_pg_dir.._pg_end` | `0x20730000..0x20738000` | **是** | **镜像数据已写进去 ⟹ 这片 DDR 必然可写** |
| `ldrb` 目标（`.data`，`+0x557820`） | `0x207D7820` | 是 | 已加载，可读 |
| 早期栈 `early_init_stack` 之下 4 KB | `0x208EC000..0x208ED000` | **否**（在 `.bss`） | 不被加载，但 11-19 实测 `[sp]` 可写 |

- 页表池 **32 KB = 8 页**（`INIT_IDMAP_DIR_PAGES=5` + `EARLY_IDMAP_EXTRA_PAGES=3`）。
  实需 **7 页**：1 PGD + 1 L1 + 1 L2 + 4 L3（text 两段非 2 MB 对齐各一张、data 同样），
  中间 `0x20400000..0x20600000`/`0x20800000..0x208A0000` 段用 2 MB block 不占表页。
  ⟹ **7 ≤ 8，不越界**（余 1 页）。
- 栈用量：`create_init_idmap` 0x30 B + `map_range` 递归 4 层 ≈ 600 B ⟹ 4 KB 够。
- **`map_range` 内一条 MMIO 都没有**：只读写页表池、参数与局部变量（栈）、`pte_none(*tbl)` 读刚写的项。
  `create_init_idmap` 里唯一的外部读是 `+0x465E78` 那个 `ldrb`，落 `.data`。

⟹ **只要检查点 A（`0x4210`，函数体开头）能执行，B（`0x8410`）必然能执行。**
"卡在 `map_range` 里"在静态上不成立——见 §H。

**`_text.._stext` 这 64 KB 不在 idmap 内**（`0x20280000..0x20290000`，`.head.text` 前段）。
`code1` 直接跳 `+0x455038`，不经过它，所以无害；但**任何把探针放到 `Image+0` 又指望 MMU 开着还能跑的方案都会挂**。

**4.19 镜像结构**（`Image` 13,892,096 B）

| 符号 | 链接地址 | 物理 |
|---|---|---|
| `_text` | `ffffff8008080000` | `0x20280000` |
| `stext` | `ffffff8008bf0000` | `0x20DF0000` |
| `__primary_switch` | `ffffff80089952b0` | `0x20B95000` |
| `__primary_switched` | `ffffff8008bf02a8` | `0x20DF02A8` |
| `start_kernel` | `ffffff8008bf0b90` | `0x20DF0B90` |
| `idmap_pg_dir` | `ffffff8008e3d000` | **`0x2103C000`** |
| `swapper_pg_dir` | `ffffff8008e40000` | **`0x21040000`** |
| `_end` | `ffffff8008e42000` | `0x21042000` |

`.bss` **不被 mboot 加载**：`kernel_size = 0xd3fd60` ⟹ 只加载到 `0x20FBFD60`，
而 `_end = 0x21042000`，中间 `0x824A0`（约 522 KB）由内核自己清。
`__create_page_tables` 第一件事就是 `__inval_dcache_area(idmap_pg_dir, _end-idmap_pg_dir)` 再清 20 KB 零
（属性 `x7 = 0x711` = AF|SH_inner|AttrIndx=4|block）⟹ **它过橙检查点就等于证明 `0x2103C000` 这片 DDR 可写**。

## D 刷机 / 恢复 / 槽

| 事实 | 标记 |
|---|---|
| `boot` = `mmcblk0p8`、`recovery` = `mmcblk0p7`，**都是 32 MB**（65536 扇区） | 实测 |
| 厂值 recovery 镜像 **27,471,872 B**；槽内前 21,618,688 B 的 md5 = **`0f6e1705f077935e1c3018973e658bfa`** | 实测 |
| 厂值 recovery 头：`ANDROID!`、`kernel_addr=0x20280000`、`ramdisk_addr=0x21280000`、`tags_addr=0x20280100`、`page_size=2048` | 实测 |
| boot / recovery **都是单向车道**，刷坏后按电源键只是重播，adb 不回来，唯一出路 U 盘救砖 | 实测 |
| **`boot-recovery` BCB 是非消费式**：写过之后每次开机都进 recovery | 实测（已踩过锁死） |
| `install-recovery.sh` 实际在 **`/system/bin/`**（731 B、`-rwxr-x---`、`class main`+`oneshot`，`init.rc:801` 是 `service flash_recovery`），每次 Android 启动都跑 `applypatch -c EMMC:…recovery:27471872:1ef69168…` | 实测 2026-11-21 |
| `/system/etc/recovery.img` **存在**（27,471,872 B，sha1 `1ef69168…` = applypatch 的目标）⟹ 槽内容 ≠ 厂值时必被整段覆写回厂值 | 实测 |
| 每次 Android 正常启动后 recovery 槽**自动回到厂值** `7c2f467b…`（3 次观察，无需人工） | 实测 |
| mboot env：`mmcblk0` `bs=4096` `skip=2528` / `skip=2544`，各 64 KB、两份相同；前 4 B = CRC32(其余 65532 B) 小端，之后 `key=value\0`；`MstarUpgrade_complete` 值字节在 **`0x8E1`** | 实测 |
| env 若 `MstarUpgrade_complete=0` + U 盘有包 ⟹ 每次启动都想强制升级、重写 recovery 槽 | 实测（`ForceUpgradePath=/v8-t652t03-lf1v147.bin`） |
| `rescue-fast.bin` **不设** `MstarUpgrade_complete` ⟹ 每次救砖后要手工重置成 1 | 实测 |
| 刷机包改内容可等长替换 ⟹ 前 16 KiB 不变 ⟹ 只重算 trailer 136 的 `crc32` | 实测 |
| 本机 toybox **禁用 `conv=notrunc`** | 实测 |

## E 显示与输出通道

- **显示不用重做时序**：面板与 tcon 都是 bootloader 做完的，`grep -i tcon /proc/kallsyms` 零命中。
- **7.3 有文字通道**：`SIMPLEDRM` / `FB` / `FRAMEBUFFER_CONSOLE` / `VT_CONSOLE` 全开、
  dts 的 `/chosen/framebuffer@2d100000`（2026-11-20 从根节点移入）、bootargs 带
  `console=tty0 … fbcon=nodefer` ⟹ **活过 `create_init_idmap` 就会有字**。
- **4.19 树没有文字通道，而且开 `FB_SIMPLE` 也救不了**：`FB_SIMPLE` 未开、MStar FB 在被剥掉的
  `mstar2/` 里、`SERIAL_8250` 已关；更关键是 4.19 只吃 mboot/ATF 交来的**厂值 DTB**
  （`setup_machine_fdt(__fdt_pointer)`，无 appended-DTB 分支），厂值 DTB 里没有
  `simple-framebuffer` 节点 ⟹ 无节点可匹配。
- `simpledrm` / `earlycon` 都在 `setup_arch` **之后** ⟹ `primary_entry` 头几行永远是黑盒。
- **UART 通道被"拆不了机"挡死**（用户：「我有 usb ttl 我也拆不了机器啊」）。

**刷屏 blob 的行为契约**（`probes/ladder/ladder.S`，已验证可用）

1. `0x1F240600`（GOP gop0/bank1/win0 CTRL）bits[7:4] = RGB565、bit0 = enable
2. 8 个窗口的 `STR_L/H/EX` steer 到 `0x2D100000`
3. pulse `0x1F2407FC` 的 bit9 提交
4. 用 `movz/movk w15,#COLOUR`（32 位一次写两个像素）填 `0x2D100000..0x2D8E9000`
   （`0x7E9000` = 8,294,400 B = 1920×1080×4）
5. 哨兵 `"M764"` @ `0x43300000` + STEP + 反码
6. 尾部 `.word <b>` 回跳 + `.word 0x4D373645`（`"M76E"`）结束标记

**只碰 `x7..x19`，绝不碰 `x0..x5` / `x21` / `x23`。**

## F 内核构建

**7.3**（`~/Debian/m7642-build/kernel/linux-main`，仓库 `~/Debian/m7642`）

- 只走 `tools/build-mstar-kernel.sh`；梯级独立汇编 ⟹ 改梯级零内核重编。
- 卡点：`0x455038` 之后、`__primary_switch` 之前，绿 → 暗紫蓝 `0x4210`
  = 死在 `create_init_idmap` 体内（`0x465eb8`，**4 次栈写之后**）⟹ **栈真的不可写**；
  另一个检查点 `0x465ef0` 打 `0x8410`，在 text 段 `map_range` **之后**，从未到达。

**4.19**（原 `~/kbuild/tcl-419`，源自 `Thedemon007/realme_Smart_TV_4K-kernel-source`；**2026-11-22 已随 kbuild 清理删除**——post-MMU 检查点仪器与 eMMC 读通道打通后，4.19 这条绕行路线不再需要；本节保留作为历史结论）

- **⚠️ 没有 `mstar2/`**（HAL 被 `mstarKernelRelease.sh` 剥掉，gitlink 且无 `.gitmodules`），
  需自行补齐约 63 个文件。
- `Image` 目标曾经失败的**真因是 `MACHINE` 为空**：`arch/arm64/Makefile:107` 从 `machine-y` 推导
  `MACHINE`，14 条 `machine-*` 全被注释 ⟹ `arch/arm64/arm-boards///Makefile.boot` 不存在。
  **修法**：建 `arch/arm64/arm-boards/m7642/{Makefile,Makefile.boot}` + `machine-$(CONFIG_MSTAR_M7642) += m7642`。
  ⚠️ **不能**指回 `drivers/mstar2/hal/…`，那会让同一目录进 `core-y` 两次。
- `Image` 已编成：13,892,096 B、`make rc=0`、`image_size = 0xDC2000`、`text_offset = 0x80000`。
- 真配置下曾有 14 个 `undefined reference`，**逐个查证全部来自过期 `.o`**（`nm` 与 `.cmd` 的
  `CONFIG_*` 计数矛盾 + 源码本身有 `#ifdef` 守卫）⟹ 删净重编即消失，**没写任何 stub**。
- **`ZRELADDR` 在 arm64 无效**；`Image` 落点由 `TEXT_OFFSET` + `CONFIG_MEMORY_START_ADDRESS` 决定。

**QEMU 只是改动预检工具，不是诊断工具。** 它能证明"内存给对 + MMU 正常"下内核跑完，
**不能**解释真机为什么卡住 ⟹ 别用它找真机死因。要真跑须 `MSTAR_M7642_BUILTIN_DTB=n` +
`MSTAR_M7642_BEACON=n`（必须一起关）。串口零输出的真因：cmdline 取自**内建 dts 的
`chosen/bootargs`**，`-append` 被忽略、`CONFIG_CMDLINE` 空。

## G 待机与电源

- **插电 = 直接进待机、不显示 logo**；真正启动只在「按电源键」那一下。
- **待机 → 按电源键 = 内核完整重启**：`uptime` 从 0 起、`btime` +392 s ⟹ 待机**不是** Android suspend，
  mboot 每次重载内核。
- 待机是 **PM51 硬件状态机**：关机 = 交权给 MCU，红外电源键由 MCU 解码。
- 「回待机」= PM51 **直接切电** = 硬断电 ⟹ `/data` 有损坏风险（见 discipline §2）。
- **两条重启路径**：`adb reboot` → 进待机、**必须按电源键**；`adb reboot recovery` → 直接起
  （mboot 认 `misc` 的 `boot-recovery`）。屏上会先出现 mboot 自己的画面
  （**不是** `boot_recovery.jpg`——该文件全盘不存在，见 §H），所以屏幕底色永远不能当判据。
  **试机一律用后者**（`tools/host/boottest.sh reboot`）。「3 秒后重启」= 「3 秒后回待机」。
- ★ **`adb reboot recovery` 之后会不会自己回来，取决于镜像行为**【2026-11-21 观察 + 2026-11-22 用户实测】：
  - 镜像 `bootm` 后**返回**（没卡死）⟹ mboot 交权 PM51 ⟹ **停在待机，要按电源键**；
  - 镜像**卡死**（带电）⟹ **停在 logo、无人处理电源键** ⟹ **只能拔电**
    （用户实测：屏幕停 logo、红外与实体遥控都无反应、`ping` 不通）；
  - ⟹ 判据是**屏幕**：黑屏 = 进过待机（切过电、DDR 全丢）；停 logo = AP 仍带电（同样拿不到 DDR）；
  - 正常启动耗时 **35–40 s**（含人按电源键的反应时间），所以**启动时长不能当判据**；
  - **`recoverycmd` 里加 `wdt_enable` 不会让卡死的镜像自动复位**（四次实验见 §34.13）。
- ⚠️ **DDR 能否保留，取决于复位方式，两者必须分清**【实测 + 早期记录】：
  - **soft reset（WDT / panic）⟹ DDR 保留**。依据：§五十二 `ramoops/pstore | 只在 soft reset
    下保留`；§3 实测 `echo c > /proc/sysrq-trigger` 后设备自恢复，且
    `/sys/fs/pstore/console-ramoops` 拿到 panic 前的 576 行日志 —— 内容只可能来自保留的 DDR。
  - **`adb reboot` ⟹ 进待机 = PM51 切电 = 硬断电 ⟹ DDR 全丢**。
    `flash-and-recovery.md` §44 实测："`adb reboot` 之后设备停在待机、网络与 adb 都不通"。
  - ⟹ **任何"DDR 是否保留"的实验，绝不能用 `adb reboot` 做复位**（2026-11-20 犯过这个错，
    见 `wdt-beacon.md` §二）。
- **ramoops 区 `0x42300000` 有签名校验**（`fs/pstore/ram_core.c`，`PERSISTENT_RAM_SIG=0x43474244`）：
  sig 不符 ⟹ `persistent_ram_zap()` 清零；**sig 写对 ⟹ `persistent_ram_save_old()` 把内容拷进
  kmalloc，之后原厂内核再写日志也覆盖不掉**，pstore 导出成 `/sys/fs/pstore/console-ramoops`。
  这是现成的"跨 soft reset 传信息"通道，且**不需要 probeRW**，adb 直接读文件。
  详见 `wdt-beacon.md` §三。
- 🔴 **`0x20100000` 是 mboot 的活动代码区**：写进去的字节重启后变成 ARM 指令（`e59fc078…`）。
  **绝对不要在那里做任何读写实验**。

## H 已否定 / 已结案的假设（不要重走）

| 曾经的假设 | 结论 | 依据 |
|---|---|---|
| **DDR 内容能跨一次启动保留（标记 / pstore 通道）** | **否，彻底作废** | 原厂 4.9 kernel + 44 B blob（只写 `0x419A0000` 后 `b .`）执行成功（`/data` 未被格式化、`last_log` 未更新 ⟹ recovery init 被拦住），但 adb 读回仍是全 `ff` ⟹ **mboot 每次启动都重新初始化 DDR**。这同时解释 pstore 永远空、11-20 probeRW 写值全丢。见 `wdt-beacon.md` §三 |
| **4.19 ladder 没被执行（镜像被 mboot 拒绝 / 跳到错误地址）** | **否** | 同一机制的原厂内核探针能拦住 recovery init ⟹ 机制通；00:25 那次之后 `/data` 也没被格式化 ⟹ 4.19 的 ladder 同样执行了。看不到涂色的嫌疑改为"ladder 自己关了显示"（控制字 `0x1f240600`） |
| mboot 开着 MMU 交接 ⟹ 写页表 fault | **否** | 交接时 `SCTLR_EL2.M=0`、A/C/I 全 0 |
| 镜像内不可写 | **否** | `preserve_boot_args` 写 `.data` 成功 |
| **7.3 死在 `create_init_idmap` 体内 / 卡在 `map_range`** | **否，自相矛盾** | 该函数与 `map_range` 的访存**全部落在 DDR 内的页表池与栈**，无一条 MMIO；页表池 7/8 页不越界、栈 ~600 B/4 KB 不溢出（§C）。页表池 `0x20730000` 在 `_edata` 之前 ⟹ 镜像数据已写入 ⟹ 必然可写 ⟹ **检查点 A 能涂则 B 必能涂**。看到 A 没见 B 只能是颜色通道吞了 B。见 §C 末段 |
| 物理地址有 MIU 偏移 | **否** | `CONFIG_MP_PLATFORM_3G_MIU0` 未开，物理地址 = MIU 地址 |
| 存在 STR / `sleep_wakeup_first` 分支 | **否，死代码** | 三次启动 `WakeupSource=1`/`WakeupKey=0xd5`/`STR_Cnt=0` 完全相同 |
| 「结果不可复现」是 STR 造成的 | **否** | 与启动路径无关，那个谜还在 |
| `adb reboot recovery` 不启动槽内内核 | **否** | `ladder9.img` → 亮绿 `0x07E0` |
| 「没 TCL logo 直接洋红」能判断 | **否** | 洋红**没有唯一含义**：面板只读每 32 位字的**低 16 位**（§四十六补实测），所以 `0x07FF07FF` 是**青**不是洋红；洋红只能来自 mboot 内容或「涂了一半」。`boot_recovery.jpg` 经实测全盘不存在。见 `display.md` §八/§九 |
| 不能有 PSCI（只能单核） | **否** | 厂商 dts 用 PSCI，`cpu_on=0x84000003`，与 EL2 自洽 |
| PSCI 在 ⟹ 可用 `SYSTEM_RESET` 当执行信标 | **否，两者要分开看** | PSCI 本体在（`cpu_on` 有效），但 `smc #0` 带 `0x84000009` **返回了**、`brk #0` 也不重启 ⟹ 这颗 ATF 不实现复位。见 `prior-art.md` §2.2 |
| 看门狗超时复位可当执行信标 | **否** | boot 路径无布防的狗（5 秒狗只在 CMD25 写 eMMC）；`HAL_WDT_Start` 是空实现；出厂 env `WDT_ENABLE 0` |
| 「7.3 只有 128 MB 内存」 | **否** | 内建 dts 拿到全部 2732 MB，只读厂值 dtb 单节点会误读 |
| `loglevel=3` 挡住了早期 dmesg | **否** | 只约束控制台、不约束环缓冲；真因是 audit 洪水 |
| 只要打出颜色就说明代码路径正确 | **否** | 四版逐字节相同的 rung 结果一次绿三次花屏 |
| arm64 的 `ZRELADDR` 决定 Image 落点 | **否** | 全树只有 `arch/arm/Makefile` 消费它 |
| 缺 `mstar2/` 就编不出 arm64 内核 | **否** | 缺口只需约 63 个文件，且 `Image` 已编成 |
| 那 14 个未定义符号要写 stub | **否** | 全是过期 `.o`，删净重编即消失 |
| 「挂了就 `adb reboot`」能回 Android | **否** | 单向车道，挂了就没 adb |
| **「recovery 槽 + 探针挂住 + `wdt_enable` 兜底」能拿到读数** | **否** | 10 s 狗咬在「mboot 等内核」的窗口里，pstore 导出（kmalloc 在 DDR）与证据一起被抹；换 120 s 则 mboot 先超时进待机、设备不再自己回来。见 §I.3 与 `wdt-beacon.md` §四 |
| **「改过的 recovery 镜像没有被 mboot 执行」**（`wdt-beacon.md` §一） | **否，作废** | ① `misc` 第 2 页的标记被 `mmc erase.p misc` 擦掉 ⟹ `recoverycmd` 执行到了；② 去掉 `wdt_enable` 后 `b .` 探针把设备挂在 logo 上 4 min+ 不恢复 ⟹ 控制权已在我们代码里 |
| **「厂值 boot 镜像放 recovery 槽能起 Android」** | **否** | 零改动 `6272b10d…` 写进 recovery 槽 → `adb reboot recovery` → 90 s 无 Android ⟹ 是这个场地不行，不是探针不行 |
| **「`0x419c0000` 与普通 DDR 同类，可被 EL2 直接写」** | **否（强证据）** | 两次写它的探针（`handoff.S` 192 B / `handoff1` 100 B）都挂；改写到普通 DDR 的 `handoff2` 一次成功返回。且该 zone 数据区始终是 `ff`（`persistent_ram_zap` 用 `memset 0`，被写过会留字节）⟹ 那个地址**从来没被写成过** |
| **「`wdt_enable 120` 拉长超时当安全网」** | **否** | mboot 先自己超时进待机，狗响不响都看不见，要人按电源 |
| **「WDT 能兜底自动复位」** | **否（强证据）** | mboot `wdt_enable 10/120`、`HAL_WDT_Start`、`MDrv_WDT_*`、直写寄存器，**四条都不咬**；此前「自己回来」是 BCB 没写、走了 `bootcmd`（`misc` 标记法证明）。见 §34.13 |

## I 探针读数通道（2026-11-21 下午，boot 槽，实测可用）

**结论：boot 槽 `code1` 的探针只要能「写普通 DDR + 返回 `0xFA0000`」，同一次启动里就能被
Android 用 probeRW 读回来。** 这是屏幕涂色、`0x43300000` 标记、pstore 三条通道之后，第一条
端到端成功**且**不依赖复位、不依赖屏幕、不依赖内核导出的通道。

### 1. 通道形状

| 项 | 值 |
|---|---|
| 落点 | `0x23080000`–`0x230F0000`，8 个 64 KB 间隔的页（dtb 装载区 `0x23000000`+1 MB 的上半个） |
| 记录 | 每页 64 B：`+0x00 u32 "M764"`、`+0x04 u32 step`、`+0x08..+0x38` 七个 u64（`x0..x5`、`sp`） |
| 读法 | `probeRW.ko addr=0x23080000 len=64 op=r`，8 次 |
| 存活 | Android 起来 32 s 后读回：8 页**全部完好、内容一致** |

为什么不写 `0x419c0000`：见 §H —— 写它的两次探针都挂，而且那块从没被写成过。写 dtb 区普通
DDR 则已被 §B 的 `m7642-boot-s1.img` 证明能返回。

### 2. 交接状态实测（`handoff2.bin`，360 B，boot 槽）

| 寄存器 | 值 |
|---|---|
| `x0` | `0x0` |
| `x1` | `0x1c` |
| `x2` | `0x20200100` |
| `x3` | `0x0` |
| `x4` | `0x0` |
| `x5` | `0x9dcc10d4` |
| `sp` | `0x0` |

- 值【实测】；含义【待确认】。**这不是 arm64 boot 参数**，是 mboot 留下的原样（参数由 vendor
  stub 在 `+0xFA0000` 重设）。
- `sp = 0` ⟹ stub 必须自己建栈；与 §C 关于 `early_init_stack` 的分析不冲突。
- `x2 = 0x20200100` 与厂值 kernel header 的 `tags_addr = 0x20280100` 不同，未解释。

### 3. `wdt_enable` 的真实语义（实测）

| 值 | 探针挂住时 |
|---|---|
| `wdt_enable 10` | **没有证据表明它会复位**。唯一有硬证据进过 recovery 的两次（`misc` 标记被 `mmc erase.p misc` 擦掉）都以「探针挂住、设备不恢复」收场。详见 §I.6 |
| `wdt_enable 120` | mboot 先超时**进待机**，要人按电源 |
| 无 | 停在 logo 不动（`b .` 实测 4 min+） |

⟹ **「狗会咬回来」这条前提没有一次可复现的实验支持**，而 `wdt-beacon.md` §二 本来就写着「是否真布防仍未证明」。见 §I.6 的寄存器证据：mboot 调的那条 `HAL_WDT_Start` 在厂 HAL 里是**空桩**。
  而且「回待机」是 PM51 切电，**DDR 会全丢**——任何「跨复位存活」的实验，碰上待机就等于没测。

### 4. 判据盲区（必须记住）

**adb 走 WiFi ⟹ 它只等于「Android 完整起来了」。** 探针挂住 / 内核只跑到 recovery / 落回
待机，在 remote 侧完全同形。⟹「没有 adb」「多久回来」只能区分「Android 起没起」，不能
区分原因。2026-11-21 据此连推三轮，得出过「探针没返回」「镜像没被执行」两个错误结论。

### 5. 待确认

- **探针的 stash 能否跨一次 10 s WDT 复位存活**——这是主线内核调试的门（4.19/7.3 不起
  Android，读数必须跨复位）。测法：`recovery 槽 + stash 写 + b . + wdt_enable 10`，狗咬回来读。
- pstore/pmsg 在**同一次启动内**到底导出过没有：现在判不了，因为写 `0x419c0000` 的那一档
  可能从未成功写入。

### 6. `wdt_enable` 为什么不咬：厂 HAL 反汇编（2026-11-21 下午，实测 + 反汇编）

**结论：mboot `wdt_enable` 走的那条链路在这台机器上是空的。** 两条独立证据：

1. `misc` 第 2 页标记被擦 ⟹ `recoverycmd` 确实执行到了（探针确实被 `bootm` 交出去）；同一轮
   设备挂住 **130 s 不恢复**、需人按电源。11:56 那次同样的组合挂了 **4 分钟**。
2. 把厂 HAL 的函数机器码 dump 出来反汇编（`kallsyms_lookup_name` 取址 + `kernel_write` 落盘，
   工具 `probes/wdtdump/`）：

| 符号 | 实际内容 |
|---|---|
| `HAL_WDT_Start` | **`mov w0,#1; ret`** —— 空桩，永远返回 1（这就是我调它时 rc=1 的原因，不是签名错） |
| `MDrv_SYS_WDTEnable(arg)` | 只 `strb` 到一个全局字节，**不碰寄存器** |
| `MDrv_SYS_WDTSetTime(idx,*out)` | 11..22 的**时间索引**翻译成码值，不碰寄存器 |
| `HAL_WDT_SetTimer(secs)` | `ticks = secs × 12,000,000`（12 MHz 时基），再调 `f(0x3008, ticks)` |
| 同族第二个实现 | `base = *(u64*)0xffffff800232d628`；`strh (ticks>>16) → [base+0x600C]` |

3. 用**厂商自己的高层 API** 也不行：`MDrv_WDT_Init(ch)` + `MDrv_WDT_SetTimer(ch, 20)`
   （模块 `probes/wdtarm/wdtarm5.c`）**120 s 内没有复位**。直接写寄存器
   （`[base+0x600C]=ticks>>16`、`[base+0x6000]=1`，`base=0xffffff800a000000`）同样不复位。
   期间出现的三次「复位」经查全部是我那段诊断代码自己 oops 引发的 **panic**（`dmesg-ramoops`
   里有 `Kernel panic - not syncing: Fatal exception`），不是狗。

⟹ **WDT 在这台机器上目前无法布防**（mboot 的 `wdt_enable`、`HAL_WDT_Start`、`MDrv_WDT_*`
   三条路都不行）。主线内核挂住时**没有自动复位**，只能人按电源（=切电=丢 DRAM）。

### 7. ★ 但 warm reset 本身找到了：panic（实测，2026-11-21 14:12）

**结论：kernel panic 是一次可靠的 warm reset，DRAM 会保留，复位前写的 pmsg 记录会在下次启动
被导出成 pstore 文件；连复位前的整份内核日志（`dmesg-ramoops-*`）都能读回。**

证据（一次完整闭环）：

```
写 /dev/pmsg0 "M7642WDT2\n" + "M7642WDT3\n"
→ 模块在 module_exit 里触发 oops（panic_on_oops=1 ⟹ panic）
→ 设备自己复位、起 Android
→ /sys/fs/pstore/pmsg-ramoops-0 = "M7642WDT2\nM7642WDT3\n"
   另有 console-ramoops 60 KB、dmesg-ramoops-0 127 KB（复位前的完整内核日志）
```

⟹ 对**Android 侧**实验，"写记录 → 制造 panic → 复位后读" 这条链现在可用（等价于以前用 sysrq，
但不需要 sysrq、也不用碰 sysrq 开关）。
⟹ 对**主线内核**仍然不够：4.19/7.3 自己挂住时，要么它自己 panic（`panic=1` + 可用的 restart
路径），要么仍需人按电源（丢 DRAM）。这是下一步要解决的点。

`/dev/watchdog` 也不存在（`/proc/devices` 无 watchdog），dmesg 只有一句
`_MI_WDT_GetHandle: Handle is Not open`。

### 8. 复位寄存器的定位进度（2026-11-21 14:5x，未完成）

**目标**：找一个「从任意上下文（含 EL2 预内核探针）都能触发 warm reset」的写操作。现有能力见 §I.7（panic 可以，但主线内核没有可用的 restart 路径）。

已确定的事实：

| 项 | 值 | 依据 |
|---|---|---|
| PM 寄存器块 VA | `0xffffff800a000000`，与 WDT 块**同一片映射** | 模块 `probes/pmbase` 读 `*(u64*)0xffffff8009358000+72` |
| PM 块物理基址 | **`0x1F000000`**（`/proc/vmallocinfo` 里有 `phys=1f000000 size=0xA01000 start_kernel+0x248`） | read-only |
| 复位候选寄存器 | **`0x1F201FCC`**（`0x1F201FCC` 可读，`0x1FA01FCC` 是 `deadbeef`） | probeRW 只读对比 |
| `MDrv_SYS_ResetAeon` 的序列 | `strh 1 → [PM+0x201FCC]`；然后 `[PM+0x20210C]` 的 bit0 先清后置 | 反汇编 `hal/dumps` |

**但按这个序列从 Android 写过去没有复位**（uptime 313→379 连续）。⟹ 要么还缺前置条件（例如先交给 PM51，相邻函数里有一句 `strb 0 → 0xA01FE000`），要么 `MDrv_SYS_ResetAeon` 不是 `machine_restart` 实际走的那条。

**这条暂时不影响主线实验**：现在「挂住 → 红外按电源 → 起来读」已经能自动跑（见 `paths.md` §6），只是挂死时按电源**会切电丢 DRAM**，所以「跨复位的检查点读数」仍然需要这条寄存器路径或主线内核自己的 restart。

### 9. ★★ 复位方式定型（2026-11-21 14:53，实测）

**结论：`panic` 是 warm reset，`machine_restart(cmd)` 是待机（切电）。两者不同，厂商 handler 按原因分派。**

| 触发 | 现象 | DRAM |
|---|---|---|
| 模块里 `panic("…")`（无任何 WDT、无其他动作） | **5 s 内自己复位**，Android 25 s 后可用 | **保留**：pmsg 记录 `M7642PANC` 出现在 `pmsg-ramoops-0` |
| 模块里 `machine_restart("m7642test")` | 4 s 内失联，40 s 仍 ping 不通，**要按电源** | 丢（PM51 切电） |
| `MDrv_WDT_Init/SetTimer`（ch0，20 s） | 120 s 内无复位 | — |
| 写 `0x1F201FCC` + `0x1F20210C`（`MDrv_SYS_ResetAeon` 的序列） | 无复位 | — |

⟹ **Android 侧已经有可靠的「写记录 → 复位 → 起来读」闭环**：写 `/dev/pmsg0`（或任意预留内存）→ 主动 `panic()` → 复位后读 `/sys/fs/pstore/pmsg-ramoops-0` 与 `dmesg-ramoops-*`（复位前的完整内核日志）。
模块：`probes/panicmod`（故意 panic）、`probes/rstcall`（调 machine_restart 做对照）。

⟹ **对主线内核的影响**：4.19/7.3 只要能跑到 `panic()`，理论上就能自己复位；但主线树里的 `machine_restart` 是 arm64 通用实现（PSCI，这颗 ATF 不实现），所以要么把厂内核这套按原因分派的 restart 移植进主线（bring-up 本来就要做的事），要么靠外部手段。

### 10. 为什么 panic 会 5 s 复位（2026-11-21 15:0x，机制已定位一半）

`panic_timeout=0`、`panic_on_oops=1`、cmdline 无 `panic=` ⟹ 复位**不是** `panic_timeout`。
真正的线索在运行时：

```
/dev/mik!wdt          ← 有一个 WDT 设备节点（mik 模块建的，名字带感叹号）
[WdtHeartBeatTas]     ← 内核里有一个喂狗线程（PID 3462）
```

⟹ **WDT 一直被内核的 heartbeat 线程喂着**，所以：

- 从模块/用户态「布防」超时 10 s、20 s 都不会咬（**被喂活了**）；
- panic 时所有 CPU 停摆、heartbeat 线程也停 ⟹ 没人喂 ⟹ ~5 s 后 warm reset（DRAM 保留）。

配套实测：把超时寄存器（phys `0x1F00600C`）改成 1 tick（~5.5 ms）**仍不咬**，说明真正在喂狗的不是这个超时寄存器，
或使能位在别处（phys `0x1F006000` 写不进去）。寄存器现状：`+0x08=0x900 +0x0C=0xFFFF +0x10=0xE00`。

**对主线的意义**：这条「死手」依赖厂商内核里的 heartbeat 线程，主线内核不会有 ⟹ **主线挂住时没有自动复位**。
所以主线调试不能依赖复位，改用下面的单步方案。

### 11. ★ 主线调试的替代方案：**「检查点 → 跳回厂内核」单步阶梯**（待实现）

思路：不追求「挂住后再复位」，而是让**每次启动只验证一个检查点**：

```
在 4.19/7.3 镜像的第 k 个检查点插桩：
    写记录到 0x23080000 那 8 页（已验证可用）
    b 0xFA0000        ← 不回主线，直接交给厂内核
⟹ 厂内核正常起 Android ⟹ 同一趟启动就能读回「检查点 k 到达过」
```

- **不需要任何复位、不需要 WDT、不需要 DDR 跨复位**——用的全是已验证的机制（`probes/handoff2` 的写入通道 + boot 槽返回 `0xFA0000`）。
- 依据：`code1` 处的探针「写记录 → 返回 `0xFA0000`」已实测成功（Android 正常起来、8 页读回）。
- 风险：检查点如果在 head.S 深处（已经改过 SP/MMU 位），跳回厂内核时状态不再干净。**必须先验证「在 4.19 head.S 的前 N 条指令后跳回 `0xFA0000` 仍能起 Android」**，再逐段推进。
- 退化情形：如果某一档跳回厂内核起不来，那一档就说明主线已经改了不可回退的状态 —— 本身也是有用的信息。

⚠️ **上面这条经复核有致命缺陷（2026-11-21 15:1x）**：跳回 `0xFA0000` 要求**厂内核同时驻留在内存里**，
而厂内核 19.7 MB + 4.19 Image 13.9 MB = 33.6 MB > 一个槽 32 MB ⟹ 一个分区装不下两个内核，
mboot 也不会同时加载两个槽。**所以「跳回厂内核」对主线探针不可行**，此方案作废。

### 12. ★★ 屏幕通道复核：物理上就是同一块 fb（2026-11-21 15:1x）

**结论：Android 的 `/dev/graphics/fb0` 就是 mboot 的 `0x2D100000` 那块缓冲，所以「boot 路径探针填色」和
「Android 侧看屏」指向同一片内存；而这块内存与主线内核无关，主线挂住也不影响它。**

```
/dev/graphics/fb0: id=MStar FB smem_start=0x2d100000 smem_len=8294400 line_length=7680 bpp=32
```

⟹ 屏幕是**唯一**满足「主线内核挂住后仍可读」的通道。上一轮判它不可靠，症结应在 ladder 去写 GOP 窗口
寄存器（`0x1f240600` 等）把显示搞乱，而不在「填色」本身。

**下一步（待实测）**：boot 路径探针只做「整屏填一个纯色」（不碰任何 GOP 寄存器），然后返回/或挂住，
人眼确认。若成立，主线检查点就可以用「每级一种纯色」的阶梯读出，**完全不需要复位**。

### 13. 屏幕通道：为什么「填 0x2D100000」看不见（2026-11-21 15:4x，实测）

**结论：面板在 boot 阶段扫的不是 `0x2D100000`（那是内核 fb 的地址），所以往那儿填色看不见；
要看见必须填「GOP 窗口当前指向的缓冲」，而那个地址必须在 boot 时刻读。**

实测证据（boot 槽 + `paint-solid` 探针，填满 8 MiB 后挂住/或返回）：

| 观测 | 结果 |
|---|---|
| 探针确实执行了（`paint-hold` 版因空转常量写错而挂死，设备卡 30 s 回待机） | ✓ 执行了 |
| 屏幕 | **始终是 logo，没有变绿** ⟹ `0x2D100000` 不在扫描路径上 |

GOP 窗口寄存器（probeRW 只读，Android 运行态）：

- 布局确认：`gop0/bank0 CTRL = 0x1F240400`、`bank1 CTRL = 0x1F240600`，bank 步距 `0x200`，
  窗口步距 `0x40`，地址三件套在 CTRL `+4/+8/+12`（STR_L=低 16 位、STR_H=高 16 位）。
- **bank1/win0 的地址逐帧变化**：两次读分别得到 `0x2F100000` 和 `0x30244000`，**都不是 `0x2D100000`**
  ⟹ Android 态的 GOP 值不能当 boot 态用。

**下一步（就绪，未做）**：boot 路径探针只做「读 8 个 bank 的 CTRL + 地址三件套 → 写进
`0x23080000` 那 8 页 → 返回 `0xFA0000`」（写入通道已验证），Android 起来后读回 ⟹ 得到 **boot 时刻**
面板真正扫描的地址，再填它。

### 14. 屏幕通道三条路都试过了：暂时无解（2026-11-21 15:47）

boot 时刻的 GOP dump（探针 `gopstash` 读寄存器 → 写 stash → 返回，已成功）：

| bank | CTRL | STR_L | STR_H | 推得地址 |
|---|---|---|---|---|
| 0 | `0x4009` | 0 | 0 | 0 |
| 1 | 0 | 0 | 0 | 关 |
| 2 / 5 | `0x0019` | 0x4e | 0x0a | 测试图案寄存器 |
| 3 | `0x4009` | 0x4200 | 0x15 | `0x?54200` |
| 6 | `0xc018` | 2 | 0 | 关（bit0=0）|
| **7** | `0x0091` | 0 | `0x24e0` | **`0x24E00000`** |

然后分别在 boot 阶段整屏填纯色（只 store，不碰任何 GOP 寄存器）：

| 填哪里 | 人的观察 |
|---|---|
| `0x2D100000`（内核 fb 地址） | **logo → Android，没有变色** |
| `0x24E00000`（boot 态 bank7 窗口地址） | **logo 7 s → Android，没有变色**（而且耗时正常） |

⟹ **整个 boot 阶段往内存里填色都看不见。** 最可能的解释：logo 是 **mboot 画好后由 tcon 保持的一帧静态画面**，GOP 在这段时间并没有在扫描 DRAM；只有内核把显示重新初始化（fb 驱动）之后，0x2D100000 才真正上屏。
⟹ 要让挂住的主线内核「说话」，必须**自己重新初始化显示流水线**（ladder 当年做过，结果是条纹/花屏，见 §H）——难度和当年一样，没有变简单。

**因此今天的净结论：主线内核的检查点目前没有任何可用的读出通道**——
1. warm reset 只能由厂内核的喂狗线程提供（§I.10），挂住的主线内核拿不到；
2. 屏幕在 boot 阶段不扫描 DRAM（本节实测）；
3. 预内核阶段没有可写的持久介质（eMMC 驱动不在）。

### 15. ★★★ 单步追踪通道打通（2026-11-21 16:18，四档全实测）

**结论：主线内核的检查点现在有可用的读出通道了——不需要复位、不需要 WDT、不需要屏幕、不需要人。**
机制是「检查点 → 把预读的厂内核拷回运行地址 → 跳进厂入口」，厂内核照常起 Android，
**记录在同一次启动里读回**。

四档实测（每档都验证了 Android 能否起来 + stash 内容）：

| 档 | stub 做的事 | 结果 |
|---|---|---|
| `abort1` | 写 stash + 清 x3/x4 + 跳 `0xFA0000`（recovery/boot 两个槽的内核**是同一个二进制**，md5 `6c650b9c…`） | **Android 起来**，stash = `M764/STEP/02` ✓ |
| `abort1c` | 同上 + 读暂存区并记录 | Android 起来；stash 记录到 `"ANDR"`(ANDROID!)、`ksize=0x12d4a00`、`code0=0x91005a4d`、`code1=0x143e7fff` ⟹ **预读成功** |
| `abort3` | 写 stash + **拷贝** `0x30000800 → 0x20280000`（19,745,280 B）+ 清 x3/x4 + 跳厂入口 | **Android 起来**，stash = `M764/STEP/03` ✓ |
| `abort2` | 同 abort3 但暂存地址用 `0x28000000` | 失败（见下） |

**两个关键坑（都付过代价）：**

1. **`recoverycmd` 有命令长度上限**：原厂 117 字符正常；直接加一条 `mmc read.p … boot …` 变 157 字符 ⟹
   **启动直接挂掉**（不是地址问题，`0x28000000`/`0x30000000` 都一样）。解法：把预读放进单独的
   env `stagecmd`，主串里用 **`run stagecmd`** 间接执行（主串 126 字符）。
2. **必须清 `x3/x4`（ramdisk 起/长）**：不清就会拿到 recovery 的 7.7 MB ramdisk ⟹ 厂内核起 recovery
   而不是 Android（`abort0` 就栽在这里）。

当前设备 env（已验证可用）：

```
recoverycmd = mmc erase.p misc; mmc read.p 0x23000000 dtb 0x100000; mmc read.p 0x25000000 recovery 0x2000000; run stagecmd; bootm 0x25000000
stagecmd    = mmc read.p 0x30000000 boot 0x2000000
```

⟹ **下一步（真正的主线工作）**：把 `abort3` 的那段 stub 插进 4.19/7.3 镜像的早期代码（第 k 条检查点），
逐档读出主线到底走到哪一步。工具链齐全（`mk-boot-beacon` 注入 + `probeRW` 读 stash）。

### 16. ★★★ 7.3 的动态追踪第一批：两个卡点，第一个已定位并绕过（2026-11-21 17:1x）

**方法**：`recoverycmd` 预读厂内核到 `0x30000000`（`run stagecmd`），被追踪镜像里在指定
`Image` 偏移打 `bl <stub>`；stub 把 `x30`（档位地址）和 `x0..x5` 写进 `0x23080000`，
把预读的厂内核拷回 `0x20280000`、清 `x3/x4`、跳 `0x21220000`；Android 照常起来，
**同一次启动**用 `probeRW` 读回。stub 放在 `Image+0x1400000`（在拷贝区之外，否则会被自己拷掉）。

**结果（7.3，先无修复）**

| 档 | 偏移 | 结果 |
|---|---|---|
| A | `code1` `0x4` | ✅ 到达（`x30=0x20280008`） |
| B | `primary_entry` `0x455038` | ✅ 到达（`x30=0x206D503C`） |
| C | `0x465E5C` | ❌ |
| F | `init_kernel_el` `0x4550A4` | ❌ |
| K | `0x455048`（建栈之后） | ❌ |
| **cache 修复后** | `0x46803C` 改 `nop`，检查点 `0x455048` | ✅ **到达**（`x30=0x206D504C`） |

**卡点一（真 bug，已绕过）**：`preserve_boot_args` 在 **MMU 关着**（`x19=0`）时尾调
`dcache_inval_poc`（`Image+0x21DE8`），里面是 `dc ivac`。按 VA 的 cache 维护在 MMU 关时是
实现定义行为，这颗 SoC 上会抛 data abort ⟹ 卡死。把 `Image+0x46803C` 的 `b dcache_inval_poc`
改成 `nop` 后，内核顺利走过这一段（同时也跳过 0x468040 那句 `str x19,[x0,#896]` 之前的分支，
实测无害）。

> 这一条修正了文档 §五十二「7.3 `code0` 是 `nop`、`CONFIG_EFI=n`」那批实验没覆盖到的点：
> 真正的第一现场不在 `primary_entry` 的 `mrs`，而在它调用的 `preserve_boot_args` 里。

**卡点二（带修复后）**

| 档 | 偏移 | 结果 |
|---|---|---|
| N1 | `__pi_create_init_idmap` 入口 `0x465E4C` | ✅ |
| Q1 | `0x465E50`（`sub sp` 之后） | ✅ |
| Q2 | `0x465E78`（参数准备前） | ✅ |
| **Q3** | `0x465ECC`（**`bl map_range` 返回处**） | ❌ |
| P2 | `0x455058`（`create_init_idmap` 返回后） | ❌ |

⟹ **死亡在 `0x465E78..0x465ECC` 之间：`ldrb` 取全局 + `map_range` 递归建表这一段**。
页表池 `0x20730000`、栈 `0x206ED000` 都在 DDR 段 `0x20200000-0x41800000` 内，
「地址不可写」这条路解释不通；下一步应查 `map_range` 的递归深度/参数（`w5` 层级、
`x26` 页大小掩码、递归里的 `bl 0x206e5cb8`）。

**工具**：`tools/host/mk-mainline-abort.py --at <偏移> [--nop <偏移>]`、
`tools/host/rung73.sh A..L`、`probes/handoff/abort-rung.S`。

### 17. 卡点二的进一步夹逼（2026-11-21 17:36）

带 cache 修复后，`create_init_idmap` 体内继续二分：

| 档 | 偏移 | 指令 | 结果 |
|---|---|---|---|
| Q2 | `0x465E78` | 参数前的 `adrp` | ✅ 到达 |
| T1 | **`0x465CB8`** | **`map_range` 第一条指令 `sub sp,#0x90`** | ❌ **未到达** |
| S1 | `0x465CBC` | `map_range` 第二条 `cmp w5,#3` | ❌ 未到达 |

⟹ **`0x465E78` 到 `0x465CB8` 之间就死了**：这段只有一次 `ldrb w2,[0x207D7820]`（读镜像内已加载的
`.data`）+ 几条纯寄存器运算（`mov/movk/csel/bic`）+ `bl __pi_map_range`。
**纯运算不可能 fault，所以下一发打 `0x465E80`（`ldrb` 之后）即可判定是「那条读」还是「那次调用」。**

**操作要点（重要，省时间）**：
- 挂死态下**红外按不动**（SoC 不处理 IR），只有**物理拔插电源**有效；物理拔插 → 按一次电源即可。
- 「没回来」的档位 = 需要一次物理断电；「回来了」的档位不需要人工介入，可以连着跑。

### 18. 卡点二的最新边界（2026-11-21 17:41，实测两轮）

带 cache 修复（`nop @0x46803C`）之后：

| 档 | 偏移 | 结果 | 说明 |
|---|---|---|---|
| Q2 | `0x465E78` | ✅ | `create_init_idmap` 参数准备前 |
| **U1** | **`0x465E80`** | ✅ | 那条 `ldrb` 之后（⟹ `ldrb` 无害） |
| **T1** | **`0x465CB8`** | ❌（两轮都失败） | `__pi_map_range` 第一条 `sub sp,#0x90` |
| S1 | `0x465CBC` | ❌ | `map_range` 第二条 |

⟹ **死亡窗口 = `0x465E80` … `0x465EC8`（12 条指令）**：全部是纯寄存器运算
（`mov/movk/add/ands/csel/bic`）加一次 `str xzr, [sp]`（写 init 栈），最后是 `bl 0x465CB8`。
纯运算不可能 fault ⟹ **下一发 U2（打桩在 `0x465EC8` 那条 `bl` 上）即可定性**：

- U2 **回来** ⟹ `bl` 指令执行到了，问题在**它跳去的 `0x465CB8`**（即 `map_range` 第一条之前/之后）
- U2 **不回来** ⟹ 问题在 `str xzr, [sp]`（写 init 栈 `0x206ECFD0`）——那就指向**栈所在那页不可写**，
  与「DDR 内、必然可写」的推断冲突，需要重新审视 `sp` 的来源（`primary_entry` 的
  `mov sp, x1 = 0x206ED000`）

**镜像已备**：`~/Debian/m7642-build/out/m7642-rec-73-fixU-0x465ec8.img`
（`md5 830f37c49668d3a3541ac24d203913cd`，跑法见 `tools/host/run-u2.sh`）。

### 19. 交接时刻的真实 CPU 状态（2026-11-21 19:08，实测三次一致）

探针 `state-probe.S` 放在镜像入口，记录：

| 寄存器 | 值 | 含义 |
|---|---|---|
| `CurrentEL` | `0x8` | **EL2** |
| `SCTLR_EL2` | `0x30C50830` | **M=0 MMU 关、C=0 D-cache 关、I=0 I-cache 关** |
| `SCTLR_EL1` | `0x30C00800` | M=0、C=0 |
| `MIDR_EL1` | `0x411FD090` | **Cortex-A55** |
| `MPIDR_EL1` | `0x80000000` | CPU0 |
| `0x30000000` | `0x21444E41` / `0x012D4A00` | 预读的厂内核 magic/ksize 正确 |

⟹ **「cache 没关」这个假设被排除**：交接时 cache 全关，`dc ivac` 在架构上是合法的。
所以 §I.16 里把 `nop @0x46803C` 称为「修复」**是不严谨的**——实测它确实改变行为（让内核走过那段），
但根因不能确认是那条 cache 维护。

### 20. 方法论缺陷：判定窗口太短导致「假阴性」（2026-11-21 19:0x）

同一镜像 `U1 (0x465E80)` 在 17:40 返回、18:23 与 18:35 不返回。已排除：U 盘、暂存区
（magic 每次都正确）、cache 状态（上节）。

**最可能的原因**：判定脚本只等 **120 s** 的 `sys.boot_completed`。多次非正常掉电后 Android
可能先修 `/data`，启动时间被拉长 ⟹ **慢启动被误判成「检查点没到」**。

⟹ **以后所有「到达/没到达」判定必须：① 等待窗口 ≥ 300 s；② 记录实际到达时的 uptime；
③ 关键结论至少重复 2 次一致。** 这条写进 `discipline.md`。

### 21. ★★ 「同一镜像时好时坏」的根因假设：页表池是未清零的 .bss（2026-11-21 19:2x）

**对照实验（关键）**：纯交接装置 `abort1` 连跑 3 次 —— **3/3 全部 RETURNED，每次 36 s**，
stash 内容一致。⟹ **交接装置本身是确定性的**，不是它在抖动。

**⟹ 抖动来自 7.3 内核自身。** 看 `map_range` 建表逻辑（`Image+0x465D7C`）：

```
ldr  x0, [x22]      ; 读页表项
cbnz x0, 0x465DA4   ; 非零 -> 当成"已存在的表"，跳过分配
ldr  x0, [x24]      ; 否则取下一个空闲页
str  x0, [x22]      ; 写入表描述符
```

这段**假设页表池初始为 0**。池在 `0x20730000`，属 `.bss`，而 **mboot 不加载也不清零 `.bss`**
⟹ 池里是**上一次开机残留**：

- 残留恰为 0 ⟹ 正常，检查点可达 ✅
- 残留非零垃圾 ⟹ 被当成已存在的表，顺着垃圾指针走 ⟹ 死 ❌

**这一条同时解释了「同镜像时好时坏」和「为什么 17:40 那次过了」。**
也吻合用户早先的判断：「不是随机，是状态/参数不同」「初始化不到位」。

**待验证（下一发）**：`code1` 处放一个「清零 `0x20730000` 起 32 KB 然后跳回 `primary_entry`」的桩，
检查点仍在 `0x465E80`。若变成稳定 3/3 到达 ⟹ 假设成立，这就是 7.3 在该 SoC 上的第二个真 bug
（缺 `.bss` 清零），修复只需一条清零循环。

### 22. 修正：页表池不需要运行时清零；信标未启用（2026-11-21 19:4x）

**§I.21 那个「页表池是未清零 .bss」的假设不成立，原因在 `head.S` 源码里：**

```c
	adrp	x0, __pi_init_idmap_pg_dir
	mov	x1, xzr
	bl	__pi_create_init_idmap
	cbnz	x19, 0f
	dmb sy
	adrp    x0, __pi_init_idmap_pg_dir
	adr_l	x2, dcache_inval_poc
	blr	x2                  // 建完表后必须再做一次 cache 维护
```

- `__pi_init_idmap_pg_dir` 放在**会被镜像加载的段**（`.pi.data`/`.init.data`，文件内容为 0），
  所以「不清理直接用」是**标准内核的有意设计**——早期汇编跑在 `.bss` 清零之前，凡早期要用的
  缓冲区都必须落在已加载段里。**这也解释了「清零 0x20730000」实验为何无用：它本来就干净。**
- 建表后的 `dcache_inval_poc` 同样是上游必需（清掉可能被投机读入的 cache line）；
  被 `nop` 掉的 `preserve_boot_args` 那次也是上游代码。

**造色信标假设也排除**：`.config` 里 `# CONFIG_MSTAR_M7642_BEACON is not set`，
`System.map` 里没有 `m7642_beacon` ⟹ 追踪的镜像是干净的。

**当前唯一未排除项**：同一份标准代码 + 同一入口寄存器状态（§I.19 实测）却行为不同
⟹ 差异只能在**入口内存内容或时序**上。下一步应当做「入口内存快照」仪器：
在 `code1` 记录 dtb 前若干字节、`__pi_init_idmap_pg_dir` 前 64 B、栈顶若干字，然后继续跑；
在 `0x465E80` 保留交接桩；连跑 N 次对比。**不要再用二分去逼近一个不稳定的现象。**

### 23. 仪器极限与策略转向：改为「让它不死」（2026-11-21 20:0x）

**W1 实测**：三处 MMU 关时的 cache 维护全部 `nop`（`0x46803C`、`0x455070`、`0x45508C`），
检查点在 `init_kernel_el`（`0x4550A4`）—— **仍然 NO RETURN**。

**仪器极限（必须记住）**：
- 检查点 `0x465E80`（`create_init_idmap` 体内）偶尔能到
- 其后所有点（`0x465EC8`、`0x465CB8`、`0x465ECC`、`0x455058`、`0x4550A4`）从未到达
- **「没到」的运行读不回来**：待机 DDR 不保留（实测：写 `0xdeadbeef`，待机唤醒后变 `0xf1b80e0f`）
  ⟹ 每次失败只给一个比特，且要一次人工拔插

⟹ 用这种仪器做精细二分，效率和可信度都不够（那些互相矛盾的边界就是这么来的）。

**转向：不再追「死在哪条指令」，改为「让它不死」。** 可疑面已经很窄（MMU 关时的 cache 维护 +
`create_init_idmap`/`map_range` 建表路径），直接逐个安全化，看内核能否自己走过这一带：

1. 跳过全部 MMU 关时的 cache 维护（已做：三处 `nop`）——W1 实测仍不够
2. `primary_entry` 里**显式清零 init 栈与页表池**，不依赖镜像内容
3. `map_range` 的「已有表」判断改成只认显式标记过的表（杜绝任何残留值被误认为表）
4. 关 `CONFIG_ARM64_PAN/UAO` 等影响早期访问的选项做对照

判据：哪一步之后 `init_kernel_el` 检查点能**稳定**到达（连续 2 次），那一步就是真修复。

### 24. 仪器重大缺陷：多数「到达」未经验证（2026-11-21 20:1x）

复盘中发现的**方法论错误**（比任何技术结论都重要）：

- 今天大部分 rung 判定只等 `sys.boot_completed=1` 就宣布"检查点到达"，
  **没有核对 stash**。
- 若 `adb reboot recovery` 未生效、mboot 改走 `bootcmd` 直接起 Android，设备同样"回来"
  ⟹ **假阳性**。这能一次解释 `0x465E80` 一会儿过一会儿不过的矛盾。
- 因此**「卡点二 = create_init_idmap」这条链上的多数数据点（Q1/Q2/N1 等）都不牢**。
  真正**有 stash 验证**的只有：`A (code1)`、`B (primary_entry)`、`fixcacheK (0x455048)`。

**新工具**：`tools/host/run-verified.sh` —— 判定必须满足
`stash.magic == "M764"` 且 `stash.x30 == 0x20280000 + off + 4`，否则记 `INCONCLUSIVE`。

⟹ **下一步就是用它把整条阶梯重跑一遍**（先 A/B 校准，再从早到晚），
在拿到**已验证**的边界之前，所有「卡点」结论都应视为待复核。

### 25. stash 验证后的真实边界（2026-11-21 20:1x–22:4x）

用 `run-verified.sh` 重跑（判定必须满足 `stash.magic=="M764"` **且** `x30==0x20280000+off+4`）：

| 偏移 | 含义 | stash 验证 | 结论 |
|---|---|---|---|
| `0x4` | `code1` | ✅ | 到达 |
| `0x455038` | `primary_entry` | ✅ `x30=0x206D503C` | **到达** |
| `0x455048` | 建栈后 | ✅ `x30=0x206D504C` | **到达** |
| `0x465E4C` | `__pi_create_init_idmap` 入口 | ✅ `x30=0x206E5E50` | **到达** |
| `0x465E78` | 函数内 `adrp` | ✅ `x30=0x206E5E7C` | **到达** |
| **`0x465E80`** | `mov x0,#0x783` | ❌ 无 | **从未到达** |

**判决性实验**：把两者之间唯一的那条 `ldrb w2,[x0,#2080]`（读 `arm64_use_ng_mappings`）换成
`mov w2, wzr`，检查点仍在 `0x465E80` —— **仍然不到**。

⟹ **执行到了 `0x465E78`，却走不到 8 字节之后的 `0x465E80`，即使中间的读已去掉。**
这不能再用「读内存 fault」解释。两种可能：
1. 内核在 `0x465E78` 与 `0x465E80` 之间跳走了（但那里没有分支指令）
2. **本仪器的交接在「内核已执行过若干指令」后不再可靠**（而 Q2 的成功只证明"到了 adrp"，
   因为桩在该点就中止了，后面的代码没跑）——这一条目前**无法证伪**，因为失败运行读不回 stash

⟹ 下一步必须换仪器：把检查点改成**只记录、不交接**（`bl recorder; ret`，只用 x16/x17 并在栈上保存
恢复），然后在**最晚的 pre-MMU 点**（`__primary_switch` `0x455580`）放交接桩。
这样一次成功启动就能读出「一路记到了哪些点」。

### 26. 纠正：静态反汇编基址错误；两条 cache `nop` 的结论不成立（2026-11-21 23:3x）

**我的错误**：`primary_entry` 那段用 `--adjust-vma=0x204D5038` 反汇编，正确值是
`0x206D5038`（`0x20280000 + 0x455038`），**差了 32 MB**。因此 §I.16/§I.17 里
「`blr x2` 跳到镜像外 `0x200A1DE8`」的判断是**假的**——按正确基址它是
`0x202A1DE8 = dcache_inval_poc`，完全正确。**静态上内核地址引用无异常**：

| 符号 | Image 偏移 | 运行时 | 与 `adrp` 是否一致 |
|---|---|---|---|
| `early_init_stack` | `0x66D000` | `0x208ED000` | ✓ |
| `dcache_inval_poc` | `0x21DE8` | `0x202A1DE8` | ✓ |
| `__pi_init_idmap_pg_dir` | `0x4B0000` | `0x20730000` | ✓ |
| `_text` | `0x0`（`text_offset=0`） | `0x20280000` | ✓ |

**两条被 `nop` 的 cache 指令的真实影响**：

| 站点 | 指令 | 作用 | `nop` 的依据 |
|---|---|---|---|
| `0x46803C` | `b dcache_inval_poc` | 失效 `boot_args` 32 B 的 cache 行 | K 档不回来（**未验证**） |
| `0x455070` | `blr x2` | 失效刚建页表的 cache 行 | P2 不回来（**未验证**） |

交接时刻实测 `SCTLR_EL2.C = 0`（cache 关）⟹ 这两条在架构上是**空操作**，`nop` 它们**不应有影响**。
其"修复"依据全部是**未经 stash 验证的失败** ⟹ **「`dc ivac` 是卡点一」不成立，需重测**。
已验证的只有：有 `nop` 时 `0x455048` / `0x465E4C` / `0x465E78` **可达**。

**静态分析结论**：`create_init_idmap` 的访存全部安全（页表池在加载段且实测 0、栈在 `.bss` 且加载 0、
`arm64_use_ng_mappings` 在加载段）⟹ **代码本身没有任何会 fault 的地方**。

⟹ 剩余唯一未排除的类别：**异常**。内核跑到这里时尚未设置异常向量，任何异常都会跳到 mboot 留下的
`VBAR_EL2` 而飞掉，表现为静默挂死。

**下一步（决定性）**：在入口桩里安装自己的异常向量表，处理器记录
`ESR_EL2 / ELR_EL2 / FAR_EL2 / SPSR_EL2` 到 stash 后交接。若内核真是被异常打死的，
就能拿到**精确故障地址与 syndrome**，把静默挂死变成有记录的崩溃。

### 27. ★★★ 决定性结论：7.3 不是异常挂死，是**空转**（2026-11-21 23:4x）

**向量表自检（`brk #0x1234`，实测）**——证明我们的异常探针完全有效：

| 字段 | 值 | 含义 |
|---|---|---|
| 记录 | `M764` `EXCP` `04` | 处理程序执行，向量号 4（当前 EL/SPx 同步） |
| `ESR_EL2` | `0xF2001234` | **EC=0x3C（BRK），ISS=0x1234** ✓ 与 `brk` 参数一致 |
| `ELR_EL2` | `0x21680018` | `brk` 之后的下一条指令 ✓ |
| `SPSR_EL2` | `0x600003C9` | EL2h ✓ |
| 交接 | Android 34 s 起来 | 处理程序里的交接也正常 ✓ |

**对照组（vec2）**：同样的向量表，让**未打补丁的 7.3 从 `primary_entry` 真跑** →
**挂住，但一个异常都没有触发**。

⟹ **7.3 的卡死是「空转/等待」，不是异常。**

**这一条推翻了此前所有「fault」类假设**（`dc ivac` 的 data abort、`ldrb` 的读 fault、
`map_range` 的写 fault）——根本没有异常发生。真实故障类别是：**进入了一个永不退出的循环或等待**
（死循环、`wfe/wfi` 等待、或忙等某个寄存器）。

**附：今天我自己犯并已纠正的两个错**
1. 反汇编基址写错 32 MB，误判「`blr` 跳到镜像外」（§I.26 已纠正）
2. 异常探针第一版把 7.3 的 `code1` 目标写成了 4.19 的 `0xb70000`（正确是 `0x206D5038`），
   于是抓到的是自己的取指异常（ELR=`0x20DF0000`）——这次纠正后才发现"无异常"

**下一步方向**：既然不是异常，就要找**循环/等待**。候选：
- `map_range` 的递归/循环条件（`Image+0x465CB8` 起）
- 早期代码里任何 `wfe/wfi` 或忙等
- 静态扫描 `0x455000`–`0x466000` 区间的回边（backward branch）

### 28. 空转的最强候选：**等从核的 `wfe` 循环**（2026-11-21 23:5x，静态扫描）

静态扫描 `0x455000`–`0x466000`（`.idmap.text` 区）：

- **没有任何回边（backward branch）** ⟹ 该区间内没有显式死循环
- **5 处 `wfe`/`wfi`**：

| 地址 | 附近符号 | 含义 |
|---|---|---|
| `0x4554D8` | `pen`（`secondary_holding_pen`） | 从核停泊循环 |
| `0x455574` / `0x455578` | `__no_granule_support` | 异常兜底死等 |
| `0x45560C` | `idmap_kpti_install_ng_mappings` | KPTI 映射切换 |
| **`0x4557F0`** | **`wait_linear_map_split_to_ptes` / `scondary_cpu_wait`** | **等其它 CPU** |

**最强假设**：7.3 在 `wait_linear_map_split_to_ptes` 里等**从核**同步；而从核是 mboot/厂商内核
停泊的（停在厂商内核的地址上），**永远到不了 7.3 的同步点** ⟹ 主核在 `wfe` 里无限等待，
**不产生任何异常** —— 与 §I.27「挂住但零异常」完全吻合。

**验证/修复方向**（下次）：
1. 把 `0x455574`/`0x455578` 附近（`__no_granule_support` 死等）与 `0x4557F0` 的 `wfe` 改 `nop`
   （或直接 `b` 到返回），看内核能否走过这一带
2. 或在入口桩里把从核**重新停泊到 7.3 的 `secondary_holding_pen`（`0x206D54A4`）**
3. 检查 dtb 的 `enable-method`（`psci` / `spin-table`）与 `cpu-release-addr` 是否与 7.3 期望一致
   —— 这是最可能的**真正的**根因

### 29. 交接桩的适用边界：MMU 关 vs MMU 开（2026-11-22 00:0x）

**实测**：`__no_granule_support`（`Image+0x455558`，`__enable_mmu` 里颗粒度检查的失败分支）**未到达**
⟹ 颗粒度检查**通过**，`msr sctlr_el1` 执行 ⟹ **内核已打开 MMU**。

**由此暴露交接桩的局限**：桩用**物理地址**（staged `0x30000800`、runtime `0x20280000`、
stash `0x23080000`）。这在 MMU 关时成立；**MMU 打开后这些地址是未映射的 VA**，桩自己就会 fault
⟹ 对 `start_kernel`(`Image+0x46091C`)、`panic`(`Image+0x29FF0`)、`setup_arch`(`Image+0x463830`)
这类**MMU 后**的点，桩无效，"没回来"**不能**解释为"没到达"。

| 类型 | 代表点 | 桩有效性 |
|---|---|---|
| MMU 前 | `primary_entry` / `create_init_idmap` / `__enable_mmu` 入口 / `__no_granule_support` | ✅ |
| MMU 后 | `start_kernel` / `panic` / `setup_arch` | ❌ 需新桩 |

**MMU 后桩的做法**：先 `msr sctlr_el1`（清 M）+ `isb` 关 MMU，再按物理地址走交接流程
（桩代码本身位于物理地址 `0x21680000`，关 MMU 后仍可继续执行）。

**当前边界（全部 MMU 前、已验证）**：`primary_entry` ✓ → `create_init_idmap` ✓ → `0x465E78` ✓ →
`__enable_mmu` 颗粒度检查通过 ✓ → 挂在 MMU 之后（`start_kernel` 一带，具体未定位）。

### 30. 「关 MMU 交接」被否决；WDT 自动复位确认不可用；dtb compatible 无问题（2026-11-22 00:2x）

1. **否决「先关 MMU 再交接」**：`start_kernel` 之后的代码处处依赖 MMU，关掉等于制造新故障。
   （此路作废，不再尝试。）
2. **WDT 自动复位确认不可用**：文档 §I.6/§七 已记录三条布防路径（mboot `wdt_enable`、
   `HAL_WDT_Start` = 空桩、`MDrv_WDT_*` + 直接写寄存器）全部无效。挂住的主线内核**没有**自动复位。
3. **dtb compatible 无问题**：厂 dtb 根节点
   `compatible = "arm,foundation-aarch64", "arm,m7642"`、`model = "M7642"`；
   arm64 的 `of_flat_dt_match_machine` 无匹配时回退默认，不 panic。

**⟹ 结论：MMU 之后的检查点目前没有读出手段**（交接需 MMU 关、复位需 WDT、两者都不可得）。
能测的边界止于 `__enable_mmu`（已验证颗粒度检查通过、MMU 已打开）。

**剩余可行方向（纯静态/纯逻辑）**：
- 静态审阅 7.3 早期 `start_kernel` 前置步骤中**会在控制台起来之前 panic** 的点
  （`early_init_dt_verify`、`parse_early_param`、内存/时钟初始化）
- 或在**厂内核**里复现 7.3 的那几步（用厂内核可用的观测手段），而不是在 7.3 里观测

### 31. eMMC 持久化路线：逆向进展与 MMU 后交接桩（2026-11-22 01:0x–01:4x）

**目标**：让检查点把记录**写进 eMMC**，从而彻底摆脱「必须交接/必须 warm reset 才能读出」的限制
（对 MMU 前后都有效，失败运行也能读回）。评估结论：**值得做，约 1 天，写路径有变砖风险**。

**控制器 = MStar FCIE**，厂商内核把每条命令都暴露成独立函数：
`eMMC_CMD17` / `eMMC_CMD24`、`*_MIU`（MIU = DMA 走物理地址）、`eMMC_DMA_MAP_address`、
`eMMC_FCIE_*` 一族。**卡初始化由 mboot 完成** ⟹ 我们只需 CMD17/CMD24。

**已拿到的反汇编事实**（`wdtdump` 转储，运行时地址来自 dmesg）：

| 函数 | 运行时地址 | 关键片段 |
|---|---|---|
| `eMMC_PlatformInit` | `0xffffff8008ca6264` | `adrp x1,0xffffff8009358000; ldr x0,[x1,#72]; add x0,x0,#0x247,lsl #12; ldrh/strh [x0,#3688]` |
| `eMMC_CMD17_MIU` | `0xffffff8008c993fc` | 大量 `adrp`+偏移访问全局结构 |

⟹ **FCIE 寄存器基址 = `[0xffffff8009358048] + 0x247000`**，寄存器在基址的小偏移上
（例如 `+0xE68`）。**注意**：实测该全局读出的值 `0xffffff800000000a` 不像上下文指针，
说明这条链还要再追一层（该地址可能先指向别的结构）——**下次从 `eMMC_Init_Device` 往下追**。

> ✅ **本节这条结论已被 §32 推翻（2026-11-22）**：`0xffffff800000000a` 是我把 8 字节当两个
> 32 位字、按大端拼回去的读数错误；原始字节 `00 00 00 0a 80 ff ff ff` 按小端 u64 读是
> `0xffffff800a000000` = `mstar_pm_base`。**这条链没有缺环**，FCIE0 = `0x1F222600`。
> 以 §32 为准。

**同时修好了一个判断**：所谓「不能关 MMU」只适用于**运行中的内核**；检查点桩本身就是要
**中止**内核，关 MMU 是交接前的最后一幕，**之后 7.3 不再执行任何代码**。据此写了

`probes/handoff/abort-postmmu.S`（MMU 后交接桩）：
1. 用**线性映射**（`0xffffffc0004d5000`，可写）把一小段 routine 拷到物理页 `0x206d5000`
2. `dc civac` + `ic iallu` 刷到 PoC
3. 跳到 **idmap 地址 `0x206d5000`**（VA == PA、可执行；`.idmap.text` 只读所以必须走线性映射写）
4. routine 里清 `SCTLR_EL1` 的 M/C/I ⟹ 回到物理寻址、无 cache
5. 写记录 → 拷贝预读厂内核 → 清 `x3/x4` → 跳 `0x21220000`

已生成 `start_kernel`（`Image+0x46091C`）检查点镜像 `m7642-rec-73-skmain.img`
（`md5 b7970b310cb472f6374c94ac9d793aa8`）。**若这一发能回来，仪器就对 MMU 前后都可用，
且不再需要人工拔插电源。**

### 32. FCIE 寄存器映射逆向（2026-11-22）

**一句话**：上一轮缺的那一环**不存在**——`[0xffffff8009358048]` 就是 `mstar_pm_base`，
真值是 **`0xffffff800a000000`**（= `ioremap(0x1F000000, 0xA00000)`）。上一轮读到的
`0xffffff800000000a` 是**把 8 字节当成两个 32 位字、按大端拼回去**造成的读数字节序错误。
FCIE0 = `mstar_pm_base + 0x222600` = **物理 `0x1F222600` / 内核 VA `0xffffff800a222600`**。

| 结论 | 标记 | 证据 |
|---|---|---|
| `mstar_pm_base` = `0xffffff800a000000`，ioremap 了物理 `0x1F000000`、长 `0xA01000` | 实测 | §32.1 的四条证据，含 4 组 VA/PA 对拍 |
| FCIE0 = 物理 `0x1F222600` = VA `0xffffff800a222600` | 实测 | 同上；VA 读出值与 `mioreg` 物理读值 4/4 相同 |
| EMMC_PLL = 物理 `0x1F247E00`；`reg_emmc_test` = +0x68 | 实测 | `0x1F247E68` 与 VA 对拍相等 |
| FCIE0 有**空洞**：idx `0x19–0x28`、`0x2A–0x33`、`0x3A–0x3E`、`0x40–0x62` 未实现 | 对照 | 源码寄存器表跳号 + 厂商 `DumpRegisters` 只逐字读 0x00–0x7F 的注释；**不要连读** |
| 厂商 `eMMC_PlatformInit` 的 1.8V 分支与源码逐条一致 ⟹ 跑着的二进制 = `kernel_mstar-main` 这一版源码 | 实测 | §32.1 第 1 条 |
| CMD17 = 一次 512 B DMA，数据落在 MIU 地址（不是 ARM 物理地址） | 实测 | §32.4，`DMA_ADDR` 静止值 `0x01639680` |
| 只读探针（我们自己写的 C）能覆盖 CMD17 全部寄存器动作 | 未验证 | 代码在 `probes/fcie/`，**没有在设备上执行过** |

---

#### 32.1 基址链：四条证据

**① 反汇编（实锤这条链就是 FCIE）** `eMMC_PlatformInit` @ `0xffffff8008ca6264`
（`probes/fcie/dumps/` 里有原始字节）：

```
d0003581  adrp x1, 0xffffff8009358000
f9402420  ldr  x0, [x1, #72]          ; x0 = 全局
91491c00  add  x0, x0, #0x247, lsl #12 ; +0x247000
795cd002  ldrh w2, [x0, #3688]         ; +0xE68  → 0x247E68 = EMMC_PLL+0x1a = reg_emmc_test
...
795e2802  ldrh w2, [x0, #3860]         ; +0xF14  → 0x247F14 = EMMC_PLL+0x45
```

`0x1F000000 + 0x247E68 = 0x1F247E68`，正是 `reg_emmc_test`；`+0xF14 = 0x1F247F14` 正是
`reg_emmcpll_0x45`（`eMMC_linux.h`: `EMMC_PLL_BASE = RIU_BASE + (0x11F80<<2) = 0x1F247E00`）。
**偏移只对得上的前提是：这个全局的物理含义 = `0x1F000000` 的映射基址。**
同一段还逐条复现了源码 `eMMC_PlatformInit` 的 1.8V 分支（读 bit0 → 置 bit0/bit2 →
`0x0fff` 清 → `0x0f` 置），所以「跑着的二进制 = `kernel_mstar-main` 源码」也一起成立。

**② 直接读这 8 个字节（读数本身）** `0xffffff8009358040` 起 16 字节，`od -t x1`：

```
000000 80 0c 60 aa c0 ff ff ff  00 00 00 0a 80 ff ff ff
```

按小端 64 位读 `0x48` 处 = **`0xffffff800a000000`**。上一轮的 `0xffffff800000000a`
与「把 `od -t x4` 打印的 `0a000000 ffffff80` 按大端拼装」完全吻合（推测是拼装错误，
不是硬件/工具读错）。

**③ 谁写进去的（源码 + 活体 vmallocinfo）** `init/main.c:547`：

```c
mstar_pm_base = (ptrdiff_t)ioremap(IO_PHYS, 0xA00000);   /* IO_PHYS = 0x1F000000 */
```

设备上 `/proc/vmallocinfo`（地址列被 kptr_restrict 抹成 0，但 phys 与长度还在）：

```
10489856 start_kernel+0x248/0x2200 phys=1f000000 ioremap
```

`10489856 = 0xA01000 > 0xA00000`，是 `ioremap(0x1F000000, 0xA00000)` 的取整结果，
调用者正是 `start_kernel`。**全内核只有这一条 `phys=1f000000` 的 ioremap。**

**④ VA/PA 对拍（决定性）** 同一寄存器，一次用 `mioreg` 读物理地址（32 位，P0 已验证安全），
一次用 `wdtdump vaddr=` 读内核 VA（**len=2，正好是 `ldrh`，和驱动同宽**）：

| 寄存器 | 物理地址 | `mioreg`（PA） | `wdtdump`（VA） |
|---|---|---|---|
| `RESERVED_FOR_SW` | `0x1F222640` | `0x00000003` | `03 00` |
| `SD_MODE` | `0x1F22262C` | `0x00000004` | `04 00` |
| `SD_STATUS` | `0x1F222634` | `0x0000ff00` | `00 ff` |
| `reg_emmc_test` | `0x1F247E68` | `0x00000035` | `35 00` |

四对全部相等 ⟹ `mstar_pm_base + 0x222640 ≡ 0x1F222640`，即
**`mstar_pm_base = 0xffffff800a000000` 映射 `0x1F000000`**。

> 方法学备注：这四对是本轮唯一「VA 与 PA 两路独立读数」的验证。VA 侧必须用 **2 字节**
> 读（`wdtdump len=2`）——FCIE 是 16 位寄存器、4 字节步进，用 `kernel_write` 一次搬
> 8/16 字节会变成设备不支持的宽访问。`mioreg` 是 32 位读，P0 已证明安全。

---

#### 32.2 寄存器表（FCIE0，基址 `0x1F222600`）

「实测值」是 2026-11-22 00:30（uptime ≈ 1300 s，Android 正常、eMMC 空闲）用
`probes/fcie/fcie.c` 这个**只读模块**读的（16 位、4 字节步进）。
「作用」一栏里带「源码」的是从 `eMMC_reg_v5.h` / `eMMC_hal_v5.c` 读出来的语义，
带「推测」的是没有独立验证的。

| idx | 名称 | 物理地址 | 实测值 | 作用 / 证据 |
|---|---|---|---|---|
| 0x00 | `MIE_EVENT` | `0x1F222600` | `0x0000` | 事件标志，写 1 清除。bit0 DMA_END / bit1 CMD_END / bit2 ERR_STS。源码 |
| 0x01 | `MIE_INT_EN` | `0x1F222604` | `0x0000` | 中断使能；探针全程保持 0（轮询）。实测：驱动空闲时也是 0 |
| 0x02 | `MMA_PRI_REG` | `0x1F222608` | `0x0000` | bit[3:2] 选 MIU（0=MIU0）；bit0/1 读写优先级、bit[5:4] 突发长度。源码 |
| 0x03 | `MIU_DMA_ADDR_15_0` | `0x1F22260C` | `0x9680` | DMA 地址低 16 位（**MIU 地址**，见 §32.4） |
| 0x04 | `MIU_DMA_ADDR_31_16` | `0x1F222610` | `0x0163` | DMA 地址 [31:16] |
| 0x05 | `MIU_DMA_LEN_15_0` | `0x1F222614` | `0x0010` | DMA 字节数低 16 位 |
| 0x06 | `MIU_DMA_LEN_31_16` | `0x1F222618` | `0x0000` | DMA 字节数 [31:16] |
| 0x07 | `MIE_FUNC_CTL` | `0x1F22261C` | `0x0002` | bit1 SD_EN、bit12 EMMC_ACTIVE。实测空闲 = `0x0002`（ACTIVE 由 `eMMC_LockFCIE` 每次置/清） |
| 0x08 | `JOB_BL_CNT` | `0x1F222620` | `0x0001` | 本次 job 的块数；CMD17 写 1 |
| 0x09 | `BLK_SIZE` | `0x1F222624` | `0x0200` | 块大小 = 512 |
| 0x0A | `CMD_RSP_SIZE` | `0x1F222628` | `0x0505` | bits[5:0] 响应字节数 = 5；bits[13:8] 命令字节数 = 5（mboot 已设） |
| 0x0B | `SD_MODE` | `0x1F22262C` | `0x0004` | bit0 时钟输出（空闲时驱动清零）、bit[2:1] 位宽（4=8 bit）、bit4 CIFD/R2N。实测停止态 = 8 bit、时钟关 |
| 0x0C | `SD_CTRL` | `0x1F222630` | `0x0006` | bit1 RSP_EN、bit2 CMD_EN、bit3 DAT_EN、bit4 写方向、bit6 JOB_START、bit9 ERR_DET_ON。实测是上一条命令的残留 |
| 0x0D | `SD_STATUS` | `0x1F222634` | `0xff00` | bits[5:0] 错误（W1C：CRC/超时/无响应/busy/数据错）、bit6 卡 busy、bits[15:8] DAT0–7 电平。`0xff00` = 8 条数据线全高、无错误 |
| 0x0E | `BOOT_CONFIG` | `0x1F222638` | `0x0003` | eMMC RSTZ 控制（bit0 RSTZ、bit1 RSTZ_EN、bit2 boot mode） |
| 0x0F | `DDR_MODE` | `0x1F22263C` | `0x1100` | bit7 8bit macro、bit8 DDR_EN、bit12 32bit macro、bit13 pad_in_sel。**实测 `0x1100`：当前总线上 DDR 是开的**——探针必须继承、不能假设 SDR |
| 0x10 | `RESERVED_FOR_SW` | `0x1F222640` | `0x0003` | mboot↔驱动版本号握手（`eMMC_DRIVER_VERSION == 3`）。P0 已实测 |
| 0x11 | `SDIO_MOD` | `0x1F222644` | `0x0000` | SDIO 模式，eMMC 不用 |
| 0x12 | `RSP_SHIFT_CNT` | `0x1F222648` | `0x0000` | 响应采样移位，`FCIE_Init` 清零 |
| 0x13 | `RX_SHIFT_CNT` | `0x1F22264C` | `0x0000` | 接收采样移位 |
| 0x14 | `ZDEC_CTL0` | `0x1F222650` | `0x0000` | 未用（NAND 旁路） |
| 0x15 | `TEST_MODE` | `0x1F222654` | `0x0000` | 调试模式选择 |
| 0x16 | `MMA_BANK_SIZE` | `0x1F222658` | `0x03ff` | MMA 窗口大小，未改 |
| 0x17 | `WR_SBIT_TIMER` | `0x1F22265C` | `0x82fb` | 写超时计数，未改 |
| 0x18 | `RD_SBIT_TIMER` | `0x1F222660` | `0x82fb` | 读超时计数，未改 |
| 0x29 | `MIU_DMA_ADDR_47_32` | `0x1F2226A4` | `0x0000` | DMA 地址 [47:32]；MIU0 恒 0 |
| 0x34 | `PWR_RD_MASK` | `0x1F2226D0` | `0xffff` | 省电模式，未改 |
| 0x35 | `PWR_SAVE_CTL` | `0x1F2226D4` | `0x020d` | 省电模式，未改 |
| 0x36 | `BIST` | `0x1F2226D8` | `0x0000` | 内建自测 |
| 0x37 | `BOOT` | `0x1F2226DC` | `0x8a00` | 作用未确认（名字像 boot 分区控制，但 eMMC 不通过它） |
| 0x38 | `EMMC_DEBUG_BUS0` | `0x1F2226E0` | `0x0000` | 调试总线 |
| 0x39 | `EMMC_DEBUG_BUS1` | `0x1F2226E4` | `0x3000` | 调试总线选择 |
| 0x3F | `RST` | `0x1F2226FC` | `0x0001` | bit0 `SOFT_RST_n`（低有效），bit[3:1] 复位完成状态。**探针绝不碰它** |
| 0x63 | `NC_FUN_CTL` | `0x1F22278C` | `0x0000` | bit0 `nc_en`：为 1 时 FCIE 归 NAND 路径，驱动的 `init` 会静默 `return 0`。探针的第一道检查 |

EMMC_PLL（`0x1F247E00`）只碰两个：

| idx | 名称 | 物理地址 | 实测值 | 作用 |
|---|---|---|---|---|
| 0x1A | `reg_emmc_test` | `0x1F247E68` | `0x0035` | bit0 = 1.8 V IO 已使能（`eMMC_PlatformInit` 只读 bit0）；bit2 = atop patch |
| 0x45 | `reg_emmcpll_0x45` | `0x1F247F14` | `0x00ff` | 1.8 V 必须置 `0x0f` / 清 `0x0fff` |

**命令 FIFO**：`0x1F222680` 起 9 个 16 位字（`0x20<<2`），一条命令 3 个字、一条 R1 响应 3 个字。
**CIFD（NAND/R2N 数据 FIFO）**：`0x1F222800`（FCIE1）。本轮探针**不用**它
（`ENABLE_eMMC_RIU_MODE = 0`，跑着的驱动只走 MIU/DMA）。

---

#### 32.3 CMD17 的寄存器级序列

下表的「反汇编证据」是最关键的：它证明**这些写操作在跑着的二进制里就是这个顺序和这个值**
（`eMMC_CMD17_MIU` @ `0xffffff8008c993fc`、`eMMC_FCIE_SendCmd` @ `0xffffff8008c95c00`）。
寄存器地址一律写成 `FCIE0 + idx`，实际指令里是 `mstar_pm_base + 0x222000 + 0x600 + idx*4`。

| # | 动作 | 寄存器 | 值 | 反汇编证据 |
|---|---|---|---|---|
| 1 | 打开 EMMC_ACTIVE / SD_EN | `MIE_FUNC_CTL` (0x07) | `|= 0x1002` | `eMMC_LockFCIE` 置 BIT_EMMC_ACTIVE；`FCIE_Init` 写 `0x1002` |
| 2 | 输出时钟 | `SD_MODE` (0x0B) | `|= 0x1` | `SendCmd`: `strh w22,[x1,#1580]`（0x62C） |
| 3 | 开时钟后等 DAT0 高 | `SD_STATUS` (0x0D) | 轮询 bit6 == 0，超时 10 s | `WaitD0High` 先置 bit0，再两次 ldrh 比对 bit6。驱动是在写完 FIFO 之后才等；探针在写 FIFO 前也等一次——FIFO 写入本身不启动传输，两者等价 |
| 4 | 清事件 | `MIE_EVENT` (0x00) | 写 `0x3F` 直到读回 0 | `ClearEvents` @ `0xffffff8008c95950` |
| 5 | 清错误 | `SD_STATUS` (0x0D) | 写 `0x3F`（W1C） | 同上，`W1C BIT_SD_FCIE_ERR_FLAGS` |
| 6 | 1 块 | `JOB_BL_CNT` (0x08) | `1` | `c99498: strh w4,[x3,#1568]`（w4=1） |
| 7 | DMA 目的地址 | `MIU_DMA_ADDR_15_0/31_16/47_32` (0x03/0x04/0x29) | MIU 地址（§32.4） | `c994d4..c994f0` |
| 8 | DMA 长度 / 块大小 | `MIU_DMA_LEN_*` (0x05/0x06)、`BLK_SIZE` (0x09) | 512 / 0 | `c994fc`、`c99514` |
| 9 | 响应 5 字节 | `CMD_RSP_SIZE` (0x0A) | `(x & ~0x3F) \| 5` | `c95c58..c95c88` |
| 10 | 写 SD_MODE | `SD_MODE` (0x0B) | `mode`（测到 `0x0005`：8 bit + CLK_EN） | `c95c94: strh w22,[x1,#1580]` |
| 11 | 写命令 FIFO | `CMDFIFO[0..2]` (0x20/0x21/0x22) | 见下 | `c95ca0/c95cac/c95cb8` |
| 12 | 再等 DAT0 高 | `SD_STATUS` | bit6 == 0 | `c95cc8: bl WaitD0High`（w0 = 0x989680 = 10 s） |
| 13 | 启动 | `SD_CTRL` (0x0C) | 先 `0x020E`，再 `\|= 0x40` | `c95d18` / `c95d2c-d30` |
| 14 | 等 CMD_END | `MIE_EVENT` | bit1 或 bit2，1 s | `c95d40: blr` → `WaitEvents(EVENT, 2, 1000000)` |
| 15 | 读 R1 | `CMDFIFO[0..2]` | 3 个字 | `CheckR1Error` @ `0xffffff8008c964d8` |
| 16 | 等 DMA_END | `MIE_EVENT` | bit0 或 bit2，5 s | `c994a0` 之后 `WaitEvents(EVENT, 5, TIME_WAIT_1_BLK_END)` |
| 17 | 查错误 | `SD_STATUS` | `& 0x3F == 0` | 同上 |
| 18 | 收尾 | `MIE_EVENT`、`SD_MODE` | 清事件、`&= ~1`（关时钟） | `eMMC_FCIE_CLK_DIS()` |

命令 FIFO 的打包（源码 `eMMC_FCIE_SendCmd`，反汇编逐条对上）：

```
FIFO0 = ((arg >> 24) << 8) | (0x40 | cmd)      ; 0x51 for CMD17
FIFO1 = (arg & 0xFF00) | ((arg >> 16) & 0xFF)
FIFO2 =  arg & 0xFF
```

R1 的取法（`eMMC_CheckR1Error`）：`GetCMDFIFO(0,3)` 读 6 字节到 `au8_Rsp[0..5]`，
**`R1 = Rsp[1..4]`（大端）**，`Rsp[0]` 是 `0x40|cmd`、`Rsp[5]` 是 CRC7/end bit。

**LBA 要不要左移 9？不用。** 实测 `g_eMMCDrv.u8_IfSectorMode = 1`
（`0xffffff800943db19`，由 `eMMC_CMD17_MIU` 的 `c99458/c9946c` 两条指令读出：
`csel w19, wzr, 9, ne` 后 `lsl w19, w26, w19`），所以 `arg = LBA`。

> 顺带实测到的驱动上下文（`g_eMMCDrv` = `0xffffff800943d000`，
> `u16_Reg10_Mode` @ +0x8C6 = **`0x0005`**、`u8_BUS_WIDTH` @ +0xB2C = **`4`**、
> `u8_IfSectorMode` @ +0xB19 = **`1`**）。`0x0005` 与寄存器里静止态的 `0x0004`
> 恰好差 bit0（时钟），互相印证。

---

#### 32.4 DMA 地址规则：寄存器里装的是 **MIU 地址**

`eMMC_DMA_MAP_address` 在跑着的内核里就是 `dma_map_single` 被内联后的完整
swiotlb/dma-direct 路径（`0xffffff8008ca22e0`），返回 ARM 侧物理地址；紧接着
`eMMC_translate_DMA_address_Ex`（`0xffffff8008ca2254`）把 `MIU_SELECT` 清成 MIU0，然后：

```
0x22a0:  mov x0, #0xffffffffe0000000   ; = -0x20000000
0x22a4:  add x0, x19, x0              ; return dma_addr - 0x20000000
```

阈值判断用的常数是 `0xFFFFFFFE` / `0xFFFFFFFF`（`0x22ec`/`0x2314`），**不是**源码里的
`MSTAR_MIU1_BUS_BASE_H = 0x300000000` —— 这一点见 §32.6 未解决。对我们的用途
（目标地址 `0x23080000` < 4 GB）走的就是上面这一支：

```
MIU 地址 = ARM 物理地址 − 0x20000000        (MSTAR_MIU0_BUS_BASE)
0x23080000 → 0x03080000
```

**活体证据（实测）**：eMMC 空闲时 `MIU_DMA_ADDR_15_0/31_16/47_32 = 0x9680/0x0163/0x0000`
⟹ 寄存器里是 `0x01639680`。这个值**不可能是 ARM 物理地址**——`/proc/iomem` 里所有
System RAM 都 ≥ `0x20200000`；而 `0x01639680 + 0x20000000 = 0x21639680` 正好落在
内核 RAM 里。所以「DMA 寄存器装 MIU 地址」是**实测**，不是推测。

不用 DMA 的 `ENABLE_eMMC_RIU_MODE`（CIFD/PIO）路径在源码里存在，但
`ENABLE_eMMC_RIU_MODE = 0`，**没被这版内核使用，本轮也未考察**。

---

#### 32.5 只读探针设计（`probes/fcie/`）

**目标**：从 mboot 已初始化好的状态出发，把任意一个 LBA 的 512 字节读进物理
`0x23080000`，全程不写 eMMC。

| 项 | 值 | 说明 |
|---|---|---|
| 代码体积 | `fcie_read.o` **848 B** text，0 data / 0 bss / **0 重定位**、0 未定义符号 | `-O2 -march=armv8-a -mgeneral-regs-only -ffreestanding -fno-pic` |
| 入口 | `unsigned long fcie_probe_once(unsigned int lba)` | 88 B；内部调 `fcie_read_block(0x1F222600, lba, 0x23080000, diag)` |
| 心跳 | `0x23080FE0`: `"FCIE1"`, 返回码, R1, `SD_STATUS` | 512 B 数据之后、同一页内 |
| 超时 | `CNTPCT_EL0` + `CNTFRQ_EL0`（12 MHz） | 不用空转常数，避免 discipline §2 那种「量级算错就变砖」 |
| 缓存 | 不需要维护 | 探针在 MMU/Cache 关掉的上下文里跑（交接桩已经负责关） |
| 失败码 | `0xE1` 目标不在 MIU0 / `0xE2` FCIE 归 NAND / `0xE3` DAT0 超时 / `0xE4` CMD_END 超时 / `0xE5` 命令后状态错 / `0xE6` DMA_END 超时 / `0xE7` DMA 后状态错 / `0xE8` R1 报错 | |

**它假设/继承的东西**（很重要，别当成已验证）：

1. 卡已被 mboot 识别完、处在 TRAN 状态（CMD17 的 R1 里 CURRENT_STATE 应 ≥ 4）。
2. 时钟源、分频、pad、DDR/位宽、时序表**全部继承**，探针一个都不重配。实测该机
   `DDR_MODE = 0x1100`（DDR 使能）、`SD_MODE` 停止态 `0x0004`（8 bit、时钟关），
   所以探针只做 `SD_MODE |= 1`。
3. 不碰 `RST`、不碰 `EMMC_PLL`、不碰 `PAD_CHIPTOP`——这些是全芯片级配置。
4. 第一道检查是 `NC_FUN_CTL.bit0 == 0`；为 1 说明 FCIE 归 NAND 路径，直接返回 `0xE2`。

**接线方式**：把 `fcie_read.o` 的 `.text` 拷到一个可执行的物理页（同
`abort-postmmu.S` 的做法），设 `x0 = FCIE0 物理基址 0x1F222600`、`x1 = LBA`、
`x2 = 0x23080000`、`x3 = 0`（diag 可空），`blr` 进去；返回后把 `x0` 存进 stash。
**不要**传 VA：这套代码按「MMU 关、物理寻址」写。

**安全边界（必须遵守）**：

- `probes/fcie/fcie.c` 这个内核模块是**只读**的（只做 16 位寄存器读），
  已在设备上跑过，安全；它是本轮所有实测值的来源。
- **`fcie_read_block` 从未在设备上执行过。** 在 Android 运行中直接跑它，等于绕过
  mmc 块层去动一个正在被挂载的控制器；一次读通常没事，但**没有证据**，所以不做。
  要真跑，顺序应该是：先在 recovery/停掉 `/data` 的场合试 → 再在运行中的 Android 试，
  并且只读 LBA 0（user 区第一个扇区，读它不会改变任何东西）。
- **写路径（CMD24/CMD25）本轮完全没做**，代码里也没有。

**构建/运行**：

```sh
cd ~/Debian/m7642/probes/fcie
./build.sh bare     # 交叉编译两个 freestanding 目标文件，打印 size
./build.sh ko       # 走 ~/Debian/m7642-build/scripts/build-probe.sh（厂商树不能正常 make modules）
adb push ~/Debian/m7642-build/build/fcie-build/fcie.ko /data/local/tmp/
adb shell su -c '/vendor/bin/busybox insmod /data/local/tmp/fcie.ko; rmmod fcie; cat /data/local/tmp/fcie.out'
```

---

#### 32.6 未解决 / 未验证

1. **CMD17 没有真正执行过。** 寄存器序列是从「跑着的二进制」逐条抄的，但没有一次
   上机跑通记录。这是下一步唯一还缺的证据。
   2026-11-22 早上做出了 **boot-path 探针**：`probes/fcie/emmc_read.S` 钉在 `code1`
   （mboot 刚用完 eMMC、控制器空闲、卡在 TRAN），设栈后调 `fcie_probe_once(0)`，
   数据落 `0x23080000`、心跳 `0x23080FE0`、记录 `0x23090000`，然后交接厂内核。
   镜像 `m7642-rec-73-emmc.img` md5 `34de6ec5cf68799ae41f0d85b598f004`；
   `probes/fcie/run-cmd17.sh` 会把读到的 512 B 与内核 `dd` 的 LBA 0 逐字节对比。
   **2026-11-22 07:43 第一次上机：NO_RETURN**（489 s 无 Android，设备挂死、需物理断电）。
   失败是盲的，因此把探针里所有等待改成**双上限**（CNTPCT 截止 + 2e9 次迭代 `SPIN_CAP`），
   这样即使系统计数器停走也只是返回错误码而不是静默死等；全量镜像 md5 改为
   `a4479e336f3b4b4ac7fa5ca1aad46887`。另做两张更小的诊断镜像：
   `ctl`（code1 只写记录+交接，完全不碰 eMMC）md5 `097140f576ef6e34b467b66ced09ab59`、
   `regs`（code1 只读 34 个 FCIE + 2 个 PLL 寄存器，不写不发命令）md5
   `a2e76b787061b803c56bccc96686c973`。顺序：ctl → regs → 全量 CMD17。
   → **已上机，结论见 §32.8**（读安全、写就挂）。
2. `eMMC_translate_DMA_address_Ex` 的 >4 GB 分支：反汇编里的阈值常数是 `0xFFFFFFFE`，
   而源码是 `dma > MSTAR_MIU1_BUS_BASE_H`（`0x300000000`），两者对不上；那一支的加法
   常数也看不出自洽的物理含义。说明**跑着的二进制与本地源码在这一段不一致**（其余函数
   逐条一致）。MIU1/高地址怎么映射：**未确认**，本轮只覆盖 MIU0。
3. `dma_map_single` 返回的到底是纯物理地址还是有 `dma-ranges` 偏移：**对照**（驱动减去
   `0x20000000` 后能正常工作 + 静止值 `0x01639680`），没有单独测量。
4. `BOOT` (0x37) = `0x8a00`、`PWR_SAVE_CTL` = `0x020d` 的语义未确认。
5. `eMMC_FCIE_ErrHandler_RestoreClk` 在什么情况下会重配时钟/pad（探针跳过了它）——
   如果探针跑在一个刚出过错的控制器上，可能不成立。
6. CIFD/PIO 路径（不碰 DMA 的读法）在 m7642 上是否可用：未考察。它对「探针」其实
   更友好（不用管 MIU 地址、不用管 cache），值得以后试。
7. `SD_MODE` 的 bit5 `DATA_SYNC`、bit7 `DMA_R_CLK_STOP`、bit8 `DIS_WR_BUSY_CHK`
   在 CMD17 里是否必须——实测值 0，没验证过置 1 的后果。

#### 32.7 本轮作废的假设（留原文，别重走）

  **作废**：环不存在，是读数的字节序错。真值 `0xffffff800a000000`。
  `eMMC_PlatformInit` 的第一条 `ldr` 就是最终基址。
- 顺带记一条**别踩的坑**：`mstar_pm_base + 0x22600`（= `0xffffff800a022600`）**不是**
  FCIE。FCIE 是 `+0x222600`，中间的 `0x200000` 是 `RIU_BASE`。这类「少一位/少一个 2」
  正是 `discipline.md` 说的「地址算术错一位不会报错，只会读到平静的一整片 0」。

### 33. ★★★ post-MMU 检查点仪器：原设计不可达 + DTB 配置漂移（2026-11-22 01:0x–01:4x）

**结论（三档）**

| 结论 | 档 | 证据 |
|---|---|---|
| §I.31/§I.32 的三张 post-MMU 镜像**按原样不可能回来** | 实测/静态 | 桩追加在 Image+0x1400000（PA 0x21680000），而 MMU 开后的两套映射都止于 `_end`（VA `0xffffffc080670000` / Image+0x670000）：`map_kernel()` 只映射 `_text.._end`，`create_init_idmap()` 只映射 `_stext.._end`。`bl` 落在未映射 VA 上。 |
| 那版 routine 里的「线性映射」地址 `0xffffffc0004d5000` 是**模块区**，不是线性映射 | 实测 | VA_BITS=39 ⟹ `PAGE_OFFSET = -(1<<39) = 0xffffff8000000000`，`KIMAGE_VADDR = MODULES_VADDR + 2G = 0xffffffc080000000`（System.map `_text`）。桩里 `movk #0xffc0, lsl#32` 少了一个半字节（应为 0xff80）。 |
| 即使地址写对，`start_kernel` 时**线性映射还不存在** | 对照 | `map_kernel()` 只建内核镜像映射；线性映射在 `paging_init()/map_mem()` 才建，而 `start_kernel/setup_arch` 早于它。所以「经线性映射写可执行页」这条路对这三个检查点都不成立。 |
| 11-20 编出的 7.3 Image 是 **`CONFIG_MSTAR_M7642_BUILTIN_DTB=n`**，而文档的前提是 `=y` | 实测 | `.config`、`include/generated/autoconf.h`（无该符号）、Image 里搜索 `TCL 65S535D Pro` 为 -1。11-18 那份 5,834,760 B 的 Image 才有内嵌树（boot-test §二十五）。 |
| 主线内核因此拿不到 DT：mboot 交的 `x0 = 0` | 实测 + 对照 | §I.2 handoff2 实测 `x0=0`；`setup_arch()` 无内嵌树时执行 `setup_machine_fdt(__fdt_pointer=0)` ⟹ memblock 为空、`earlycon` 之前就挂（boot-test §二十五 早已预警）。**这是「MMU 之后挂住」的必然结果，不是推测。** |
| 已重编 Image：`BUILTIN_DTB=y`，板级 DTB 在 Image+0x4C9858 | 实测 | `System.map: __m7642_dtb = 0xffffffc0804c9858`，`__m7642_dtb_end = 0xffffffc0804ca80d`；Image 仍 6,238,720 B，`_end` 仍 0x670000，但 `__pi_early_map_kernel`/`__primary_switched` 各 **+0x10**（0x4659e0 / 0x46805c）。 |
| code1 shim 必须在 `early_map_kernel` 之前给出有效 x0 | 对照 | `early_map_kernel()` 先 `map_fdt(x0)` + 解析 `/chosen`（CPU feature override），`setup_arch()` 才换成内嵌树。x0=0 会把 PA 0..2MB 当 DT 读，进不了 setup_arch。 |
| 新仪器（tramp）成立 | 待验证 | tramp 注入 `.text` 尾部填充 Image+0x36C000（PA 0x205EC000），内核 VA 与 idmap **都是 ROX**；PA 入口/内核 VA 入口两种；`dc civac` 清 `_stext.._end` 的脏行（clean+invalidate 保页表写回），清 M/C/I 后跳物理交接 0x21680200。 |
| 第一发 `prsw`（`__primary_switched`）**NO_RETURN** | 实测 | 505 s 无 Android，之后 ping 不通（需物理断电）。此时镜像**没有** `nop @0x46804C`，而此前所有「深」检查点（0x455048 / 0x465E4C / 0x465E78）都是在**带该 nop** 的镜像上测到的。 |
| 已重建四张镜像（含 `nop @0x46804C`） | 实测 | emap `f0ca4aa2…` / prsw `b8651fd2…` / skmain `2eac39d1…` / mmuon `7f309a47…`；都已核对 `nop=0xD503201F`、code1=`bl 0x36c0c0`、检查点 `bl` 目标。 |

**新仪器的结构（`probes/handoff/`）**

- `tramp-postmmu.S` → 注入 Image+0x36C000（`.text` 尾部 16 KB 填充区，`_etext=0x370000` 之内）
  - `_start`（offset 0）：PA 入口，用于 `__pi_early_map_kernel` 或更早（此时 PC 已是 PA）
  - `_start_kva`（offset 4）：内核 VA 入口，先 `adr` 求自身 VA、减 `KIMAGE_OFFSET` 得 PA，再 `br` 过去
  - 共同体内：x0..x2 ← `boot_args[]`（7.3 自己保存的入口寄存器），x3/x4=0；`dc civac` 扫 `_stext.._end`；`msr sctlr_el1` 清 M/C/I；`br 0x21680200`
  - `_start_fdt`（offset 0xC0）：code1 shim，先把 mboot 入口寄存器写到 `0x23090000`（`M764`/`FDT `），再 `x0=0x23000000`、跳 `primary_entry`
- `abort-postmmu.S` → 追加在 Image+0x1400000（handover 在 +0x200 = PA 0x21680200，**在拷贝区 0x20280000..0x21554a00 之外**）：记录 `M764`/`MMMU` + x30 + x0..x4 到 `0x23080000`，拷 `0x30000800→0x20280000`（0x12d4a00 B），清 x3/x4，跳厂入口 `0x21220000`
- 构建：`probes/handoff/build-postmmu.sh`（从 System.map 取 boot_args/_stext/_end/primary_entry 的 PA 和 KIMAGE_OFFSET，`-D` 给汇编）、`mk-postmmu-images.sh`（含 code1 shim 与 `nop @preserve_boot_args+0x20`）
- 运行：`probes/handoff/run-postmmu.sh <img> <md5> <tag>`（300 s 判定窗、槽 md5 校验、读 `0x23080000` 与 `0x23090000` 并解码）

**四张镜像（2026-11-22 01:4x，均含 nop + shim）**

| 镜像 | 检查点 | 入口 | md5 |
|---|---|---|---|
| `m7642-rec-73-mmuon.img` | `__enable_mmu+0x38` = 0x455548（MMU 刚开、仍在 PA） | `_start` | `7f309a473a77abafe894a0636c91b1c2` |
| `m7642-rec-73-emap.img` | `__pi_early_map_kernel` 0x4659e0 | `_start` | `f0ca4aa27051e9cafff4e289adf5193f` |
| `m7642-rec-73-prsw.img` | `__primary_switched` 0x46805c | `_start_kva` | `b8651fd2121089cb69e8385234fc58a9` |
| `m7642-rec-73-skmain.img` | `start_kernel` 0x46091c | `_start_kva` | `2eac39d1515761d31ce65dd7a5b9b33e` |

**对主线的意义**

1. 之前「MMU 之后的检查点没有读出手段」的三轮尝试（§I.29–§I.31）里，桩从一开始就够不到；这些结论里的**否定项**（比如「__no_granule_support 未到达 ⟹ MMU 已开」）也因此不可靠——它们可能只是「内核根本没跑到那里」。
2. 真正需要先回答的是：**7.3 到底走到哪一步**。仪器链条现在是：`mmuon`（一定到达，验证仪器）→ `emap` → `prsw` → `skmain`，每档回来才算「到达」。
3. DTB 这一环已按 11-18 的结论补齐（`BUILTIN_DTB=y` + 入口 x0 shim），但它只影响 `early_map_kernel` 之后；若内核在 `create_init_idmap` 里就挂住，DTB 修了也看不到。

**待办（下一发，按顺序）**

1. 物理断电恢复设备 → 核对 boot 槽仍是厂值 `6272b10d…`、`misc` 前 32 B 全 0（`recoverycmd` 里的 `mmc erase.p misc` 已擦）。
2. `run-postmmu.sh …/m7642-rec-73-mmuon.img 7f309a47… mmuon`：回来 ⟹ 仪器在 MMU 后可用；不回来 ⟹ 仪器本体有问题，先查 tramp（不要继续往后打）。
3. 再跑 `emap`、`prsw`、`skmain`，把「到达」推进到 `start_kernel`；每一步失败只置信一个 bit。
4. 若 `prsw`/`skmain` 到达而 `start_kernel` 之后仍挂，再按 `setup_arch`（0x463830）→ `early_init_dt_verify` → `parse_early_param` 二分。
5. eMMC(FCIE) 那条线不变（§32），`probes/fcie/fcie_read.c` 仍未上机。

#### 32.8 code1 实测：能读、不能写（2026-11-22 08:0x–08:2x）

用「code1 + 交接」的四级探针在设备上实测（每级都先用 misc 末尾标记确认真的进了 recovery）：

| 级别 | 做什么 | 结果 |
|---|---|---|
| ctl `097140f5…` | 只写记录 + 交接，**完全不碰 eMMC** | **REACHED**：stash `M764`/`STEP`、x30=`0x20280008`，Android 正常起 |
| regs `a2e76b78…` | **只读** 34 个 FCIE + 2 个 PLL | **RETURNED**：34+2 值全部读出（见下表） |
| setup `32897a40…`（旧版，未还原） | 写 `FUNC_CTL`/`SD_MODE`/清事件/DMA 设置，**不发命令** | **NO_RETURN**（507 s，设备挂死） |
| emmc `34de6ec5…`（旧版，未还原） | 全量 CMD17 | **NO_RETURN**（489 s，设备挂死） |

⟹ **读安全，写就挂**。要么写本身把 CPU 卡住，要么写后的状态让厂内核起不来。

**code1 寄存器实测**（regs 镜像读回；mboot 刚用完 eMMC、还没交权的状态）：

| idx | 名称 | code1 值 | Android 空闲（§32.2） |
|---|---|---|---|
| 00 | `MIE_EVENT` | **`0003`** | `0000`（DMA_END\|CMD_END 残留） |
| 03/04 | `MIU_DMA_ADDR` | `4ac0`/`094b`（MIU `0x094b4ac0`） | `0x01639680` |
| 05 | `MIU_DMA_LEN_15_0` | `0200` | `0010` |
| 07 | `MIE_FUNC_CTL` | **`0001`** | `0002` |
| 0b | `SD_MODE` | `0004` | `0004`（8 bit、时钟关） |
| 0c | `SD_CTRL` | `000e` | `0006` |
| 0d | `SD_STATUS` | **`ff00`** | `ff00`（DAT0..7 全高、无错误） |
| 17/18 | `WR/RD_SBIT_TIMER` | `0000` | `82fb`（驱动 init 才写） |
| 37 | `BOOT` | `0a00` | `8a00` |
| 39 | `EMMC_DEBUG_BUS1` | `1000` | `3000` |
| 其余 24 个 | — | 与 Android 空闲相同（含 PLL `0035`/`00ff`） | — |

⟹ code1 时**卡是 idle/ready**（DAT0 高、无错误）、控制器 8 bit、时钟关、块 512 —— 环境没问题。

**一次假阳性（08:03，记下来）**：同一发 ctl 报「Android 起来了但 stash 是 dtb 残渣」。
事后查：`adb reboot recovery` **没生效**（走了 `bootcmd`），而 `ro.boot.bootreason` 仍显示
`recovery`（reason 串会被下一次启动继承）。⟹ **bootreason 不能当「进了 recovery」的证据**；
用 **misc 末尾标记法**：往 misc 末尾写 4 KB `0xA5`，`recoverycmd` 的第一条
`mmc erase.p misc` 会擦掉它 —— 标记消失才算真进了 recovery。四张探针镜像都用它验过。

**下一发（已就绪，等断电）**：`setup` 与 `emmc` 都加了「进出原样保存/还原
`FUNC_CTL` / `SD_MODE` / `SD_CTRL` / `DMA_ADDR`」。厂内核靠 `RESERVED_FOR_SW=3`
**信任 mboot 的控制器状态、不重做 init**；探针留在置位的 `EMMC_ACTIVE`/`SD_EN` 和改过的
DMA 目标地址很可能是挂因。新 md5：setup `d2d5fcf9263704acda1deae8a9f15a00`、
emmc `8d5dd03356029548c6aba05f62514d64`。先跑 emmc；若仍挂，再用 setup 二分。

**2026-11-22 10:00 突破：CMD17 读通道成立。**

**根因（实测 + 对照）**：**C 代码把 `x0..x5` 冲掉了**，而厂内核入口（`+0xFA0000`）会把它
拿到的 **`w2` 存进自己的 `boot_args[2]`**（`str w2, [0x20281010]`）。纯汇编桩从不碰
`x0..x5`，所以所有汇编诊断（ctl / regs / wr1 / wt1–5 / clk / cpa / cpb）**全部回来**；
凡是经过 C 代码的镜像（setup / 全量 / cpath）**全部挂死** —— 正是这条相关性把根因指出来。

修法：`emmc_read.S` 入口先把 `x0..x5` 存到 `0x230aff00`，交接前恢复 `x0/x1/x2/x5`，
`x3/x4` 仍清 0（ramdisk），`sp` 回 0。

实测（`~/Debian/m7642-build/out/m7642-rec-73-emmc.img`，md5 `9f071ae8ff512a1843396e8849633531`）：

| 项 | 读数 |
|---|---|
| 心跳 rc | `0` |
| R1 | `0x00000900` ⟹ CURRENT_STATE=4（TRAN）、READY_FOR_DATA=1、错误位 0 |
| SD_STATUS | `0xff00`（DAT0..7 全高、无错误） |
| 读到的 512 B | 与内核 `dd if=/dev/block/mmcblk0 bs=512 count=1` **逐字节相同**（两边 md5 `ce6a9730267a632b99ef9f16ee532031`） |

注：LBA 0 的内容不是 MBR/GPT（510 处不是 `0xaa55`），内核读出来也是同一份 —— 不影响
「读通道成立」这个结论；它只说明这块 eMMC 的分区表不在用户区 LBA 0（待查，与主线无关）。

**⟹ 只读 LBA 0 的 CMD17 在 code1（mboot 交接态、MMU/Cache 关）按 18 步序列跑通了。**
写路径（CMD24/CMD25）仍未做，继续冻结。

### 34. ★★★ post-MMU 仪器成立；7.3 的卡点收窄到 `__pi_early_map_kernel` 体内（2026-11-22 10:05）

**一句话：新 tramp/handover 在 MMU 开之后可用；7.3 进得了 `__pi_early_map_kernel`，但到不了
`__primary_switched` ⟹ 卡点在这个函数体里，不在 `start_kernel` 之后。**

三发实测（每发都用 misc 末尾 `0xA5` 标记确认进了 recovery）：

| 检查点 | 镜像 md5 | 结果 | 记录里的 x30 |
|---|---|---|---|
| `__enable_mmu+0x38` (`0x455548`，`msr sctlr_el1` 之后) | `7f309a47…` | **回来**（Android 34 s） | `0x206D554C` = PA(`0x45554C`) ✓ |
| `__pi_early_map_kernel` 入口 `0x4659e0` | `f0ca4aa2…` | **回来**（35 s） | `0x206E59E4` = PA(`0x4659E4`) ✓ |
| `__primary_switched` `0x46805c` | `b8651fd2…` | **不回来**（488 s） | — |

⟹ **`mmuon` 与 `emap` 都是 stash 验证过的「到达」**，所以：
1. tramp 的两条入口（PA / 内核 VA）、cache 清理、关 M/C/I、物理 handover 全部成立；
2. 内核确实打开了 MMU 并进入了 `__pi_early_map_kernel`；
3. `__primary_switched` 之前的某个环卡住。

**顺带坐实一条旧假设**：code1 shim 记录的 mboot 入口寄存器是
`x0=0, x1=0x1c, x2=0x20200100, x3=0, x4=0, x5=0x9dcc10d4` ⟹ **mboot 交的 x0 真的是 0**
（§I.33 的 DTB 判断成立；也解释了厂内核为什么要自己硬编码 DTB 地址）。

**`__pi_early_map_kernel` 的结构（新编译，System.map + 反汇编）**：

| 偏移 | 动作 |
|---|---|
| `0x465a74` | `bl __pi_map_range`（`map_fdt` 内联体，把 FDT 映射进去） |
| `0x465a94` | `bl __memset`（清 BSS，`__bss_start..init_pg_end`） |
| `0x465aa8` | `bl __pi_fdt_path_offset`（找 `/chosen`） |
| `0x465ab8` | `bl __pi_init_feature_override`（解析 CPU 特性覆盖） |
| `0x465b54..0x465c04` | 6 × `bl __pi_map_segment`（`map_kernel` 的各段） |
| `0x465c14` | `bl idmap_cpu_replace_ttbr1`（切到 `init_pg_dir`） |
| `0x465c1c` | `bl __pi_relocate_kernel` |
| `0x465c38..0x465c88` | 再 3 × `map_segment`（两遍映射的第二遍） |
| `0x465c98` | `bl __memcpy`（`swapper_pg_dir` 拷根表） |
| `0x465ca4` | `bl idmap_cpu_replace_ttbr1`（切到 `swapper_pg_dir`） |
| `0x465cbc` | 尾声 `ldp x27,x28`，随后返回 `__primary_switch` → `br x8` |

**下一批检查点（已构建，都是 PA 段，用 tramp 的 `_start` 入口）**：

| 镜像 | 偏移 | 含义 | md5 |
|---|---|---|---|
| `m7642-rec-73-mk1.img` | `0x465a94` | `map_fdt` 之后、清 BSS 之前 | `371627c1fd729baa16723a3912bcbe1a` |
| `m7642-rec-73-mk2.img` | `0x465ab8` | `fdt_path_offset` 之后 | `50a5f07f5f37e0aa5f3320c880fcaa70` |
| `m7642-rec-73-mk3.img` | `0x465c14` | 6 段映射之后、第一次切 TTBR1 之前 | `3b7dac457072a6c815f9c82a3d08c0f2` |
| `m7642-rec-73-mk4.img` | `0x465c1c` | 第一次切 TTBR1 之后、`relocate_kernel` 之前 | `83cb6f291c5cf838be34301d6c4bc910` |
| `m7642-rec-73-mk5.img` | `0x465ca4` | `memcpy(swapper_pg_dir)` 之后 | `5d567f3a45998c9af33aff9a1bc8fb6e` |
| `m7642-rec-73-mk6.img` | `0x465cbc` | 函数尾声（即将返回） | `893a2274b321cab41137b4b57008cc13` |

构建：`probes/handoff/mk-emap-images.sh`。运行：`probes/handoff/run-postmmu.sh <img> <md5> <tag>`。
顺序 mk1 → mk6：第一个「不回来」的档就是卡点；它前一档（回来的）是最后确认的边界。

**2026-11-22 10:2x 续（mk / ps 阶梯）**：

| 检查点 | 偏移 | 结果 | 记录 x30 |
|---|---|---|---|
| mk1 | `0x465a94`（`bl __memset`） | 回来 | `0x206e5a98` |
| mk2 | `0x465ab8`（`bl __pi_init_feature_override`） | 回来 | `0x206e5abc` |
| mk3 | `0x465c14`（`bl idmap_cpu_replace_ttbr1`） | 回来 | `0x206e5c18` |
| mk4 | `0x465c1c`（`bl __pi_relocate_kernel`） | 回来 | `0x206e5c20` |
| mk5 | `0x465ca4`（第二次 `bl idmap_cpu_replace_ttbr1`） | 回来 | `0x206e5ca8` |
| mk6 | `0x465cbc`（尾声 `ldp x27,x28`） | 回来 | `0x206e5cc0` |
| ps0 | `0x4555b0`（`__primary_switch` 的 `br x8`） | 回来 | `0x206d55b4` |
| ps1 | `0x468060`（`__primary_switched+4`，`bti c` 之后） | **不回来**（533 s） | — |

⟹ `__pi_early_map_kernel` **从头到尾都执行完了**（连尾声都到了），`__primary_switch` 也执行到
`br x8`；卡点在**「`br x8` 跳进内核 VA → 执行 `__primary_switched` 第一条」**这一小段。

**已排除/待判**：
- `ldr x8` 的字面量（`0x4555c0`）在镜像里是 **0**，靠 `R_AARCH64_RELATIVE`
  （addend `-0x3f7fb97fa4` ⟹ `0xffffffc08046805c`）在 `relocate_kernel` 里填 —— 即
  `br x8` 的目标就是 `__primary_switched` 的内核 VA。
- 所有**成功**的检查点走的都是 tramp 的 **PA 入口**；两个失败的（prsw/ps1）走的是
  **内核 VA 入口**。所以嫌疑只剩两类：(a) 该时刻内核 VA 的页表/权限不可用；(b) tramp 的
  KVA 入口路径本身有问题。
- 判别镜像 **`m7642-rec-73-kva.img`**（md5 `3b220ef4e31cc357c65f08a547021732`）：在
  `0x4555b0` 处用自定义桩记录 `x8`，并**用内核 VA 读** `_text`、目标页、tramp 页
  （`0x23090000[0..3]`）。它挂 ⟹ 内核 VA 读不了（(a)）；它回来 ⟹ 看读到什么再定 (b)。

### 34.1 构建环境迁移与镜像可重建性（2026-11-22 11:0x）

`~/kbuild/`（16 GB）清理后迁到 `~/Debian/m7642-build/`（6.6 GB），布局见该目录的 `README.md`
与 `paths.md` §1。**4.19 退役**：`tcl-419/`（2.8 GB）与 `tcl-src/` 已删除——post-MMU 检查点
仪器与 eMMC 读通道打通后，那条绕行路线不再需要。

清理过程中 `out/`（原 `m7642-out/`，5.1 GB 历史镜像）被连带清空，**用源码全量重建后逐张比 md5**：

| 组 | 结果 |
|---|---|
| `mmuon` `emap` `prsw` `skmain` | `7f309a47` / `f0ca4aa2` / `b8651fd2` / `2eac39d1` **全部一致** |
| `mk1`–`mk6`、`ps0`、`ps1`、`kva` | `371627c1`…`893a2274` / `f6dd1e79` / `e4f36379` / `3b220ef4` **全部一致** |
| `emmc` `setup` `cpath` `ctl` | `9f071ae8` / `2c1d230a` / `484e1a01` / `097140f5` **全部一致** |
| `regs` `wr1` `wt1`–`wt5` `clk` `cpa` `cpb` | `a2e76b78` / `c9698a39` / `bfe218f8`…`6b0b33ee` / `466d5d61` / `2c24eada` / `62026122` **全部一致** |

⟹ **镜像确实只是源码 + Image 的确定性函数**，删掉不损失信息；有 md5 就能判定重建是否等价。

**可复验性锚点**（有了这三项，任何一张镜像都能重算出文档里的 md5）：

| 锚点 | 值 |
|---|---|
| `kernel/linux-main/arch/arm64/boot/Image` | 6,238,720 B · md5 **`18f7ed3c290050be3102d8665636ea27`** |
| 工具链 | `toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-*`（buildroot GCC 13.3） |
| 构建入口 | `probes/handoff/{build-postmmu,mk-postmmu-images,mk-emap-images,mk-kva-images}.sh`、`probes/fcie/{build-extra,build-stage,build-boot}.sh` |
| 容器来源 | `backups/partitions/rec/recovery_full.bin`（厂值 recovery 全槽） |

**所以 `out/` 只留在办的那几张**（2026-11-22 12:0x 起）：`kva4`/`kva5`/`kva6`。
其余 31 张（含 4 张作废的 `kva`/`kva1`/`kva2`/`kva3`）全部删除——它们对应的
问题都已经回答过，md5 留在本文件里，需要时一条命令重建。
换内核后 Image 的 md5 会变，那时重建出来的镜像 md5 也会变，**这是预期行为**。

附带两张补记：
- `m7642-rec-73-cmin.img`（md5 `b84c7384a4899bd6eb16cb62def6f719`）：C 路径的最小对照
  （只调一个返回 `0x42` 的 C 函数），用来把「C 代码本身能不能在 code1 跑」和
  「C 代码踩了 x0..x5」分开；已有结论见 §32.8。
- `probes/handoff/build-postmmu.sh` 现在也产出 `abort-rung.bin`（md5
  `4960cf196c358b408633541291d131a4`），`ctl`/`paint` 系列镜像不再依赖手工编的 stub。

### 34.2 追 `br x8`：两次作废的探针与真正的约束（2026-11-22 11:1x）

`prsw`/`ps1` 都不回来、`ps0`（`br x8` 本身）回来 ⟹ 失败点在**「跳进内核 VA」这一步**。
设计判别探针时连踩两个坑，两次都花掉一次物理断电：

**坑一：blob 盖掉了 code1 shim。** 第一版 `kvacheck` 有 280 B，放在 `Image+0x36c000`，
而 code1 的 FDT shim 固定在 `Image+0x36c0c0`。结果 `bl 0x36c0c0` 落进 kvacheck 中间——
挂死与「VA 能不能读」毫无关系。离线复验方法：读镜像 `+0x36c0c0` 的 8 字节，
应等于 shim 的 `movz x6,#0 / movk x6,#0x2309,lsl16`（`060080d2 2661a4f2`）。
现在探针一律放 `Image+0x36d000`。

**坑二：MMU 开着的时候写 stash 会挂。** 第二版把 `x8` 先写进 `0x23090000` 再读 VA，
又挂。原因：**MMU 打开时 stash 页不保证可达**——正常 tramp 之所以没事，是因为它
先读 `boot_args`（能读）、**关掉 MMU 之后才写 stash**；而 `0x23090000` 这类 DDR 页不在
idmap 里，MMU 一开就不一定能访问。这一发同样不能证明任何关于 VA 的事。

**由此定下的探针写法**：MMU 开着时只做**那一个**要测的访存，答案留在**寄存器**里；
`msr sctlr_el1` 关掉 M/C/I，之后再把答案写进 stash、再交接。判据标记（`0x600d`）
也只在访存返回后才写，这样「挂」就只能归因于那次访存本身。

已建（`probes/handoff/mk-kva-images.sh`，探针都在 `+0x36d000`）：

| 镜像 | md5 | 问的问题 |
|---|---|---|
| `m7642-rec-73-kva4.img` | `aaba715835b10bb1b4570964fb24beb9` | MMU 开着时读 `_text` 的**内核 VA**（唯一一次访存） |
| `m7642-rec-73-kva5.img` | `bdcc99927d97ca42e45b9cb910c0ffd0` | MMU 开着时**写** DDR `0x23090020` 是否生效 |
| `m7642-rec-73-kva6.img` | `70d57d95221a0786dc5ec2233456e4a0` | **零次访存**：只用 `mrs` 抓 `x8`/SCTLR/TTBR1/TCR/VBAR/ESR/FAR |

**实测到这里**：`kva1`（旧版，MMU 开着写 stash）挂、`kva4`（MMU 开着读 `_text` 内核 VA）
挂（500 s，11:35）。两次都还不能当结论——`kva6` 是零访存对照，先确认「那一刻 MMU 是否
真的开着、`x8` 是否是 `__primary_switched` 的内核 VA」，再谈 VA 能不能读。
`kva6` 的记录：`0x23090000` = [x8, SCTLR, TTBR1, TCR]、
`0x23090020` = [VBAR, ESR, FAR]，标记 `M764`/`KVA6`。

记录格式：`0x23090000` = [x8, 读到的值, `0x600d`|`0xbad`, kva5 的回读]，
标记 `0x23090800` = `M764`/`KVA4`|`KVA5`。

### 34.3 stash 的有效范围（2026-11-22 12:0x）

stash 页 `0x23080000`（交接记录）/`0x23090000`（code1 shim）**只在同一次启动内有效**：

- 两个地址都落在 mboot 每次启动执行 `mmc read.p 0x23000000 dtb 0x100000` 覆盖的
  `0x23000000–0x230FFFFF` 窗口内 ⟹ **跨启动必被覆盖**；
- 挪到窗口外的普通 DDR（试过 `0x23100000`）也没用：内核分配该页时会清零；
- 复位/待机后 DRAM 本身不保（`wdt-beacon.md` §二）。

⟹ 这条通道的用法只有一个：**探针写记录 → 同一次启动内交接厂内核 → Android 起来 → `probeRW` 读**。
只要检查点会返回，它就是可靠的（今天 `ps0z`/`ps1z`/`skmainz`/`setuparchz` 全部验证过）。


### 34.4 ★★★ `wdt_enable 10` 与我们的交接路径冲突（2026-11-22 13:3x 实测）

**这一条推翻了 §34.3 的乐观读法，也是今天下午连续"挂死"的真凶。**

12:00 把 `wdt_enable 10` 写进 `recoverycmd` 之后，**12:00 以后的每一发都挂**——
包括几张此前明确能回来的镜像。因果是用"同一张镜像"钉死的：

| 时刻 | 镜像 | env | 结果 |
|---|---|---|---|
| 10:24 | `ps0` = `f6dd1e7952547bfed276143b99994d83` | 无 WDT | **回来**（Android 26 s） |
| 13:14 | 同一张 `f6dd1e79`（重建后 md5 相同） | `wdt_enable 10` | **挂死**（501 s） |
| 13:24 | 同一张 `f6dd1e79` | `wdt_enable 10` | **挂死**（505 s） |
| 13:36 | 同一张 `f6dd1e79` | 已回滚 | **回来**（35 s） |

机理：`wdt_enable 10` 在 `bootm` 之前布防，10 秒后无喂狗就咬。而我们的交接路径是
「探针 → 拷 19.7 MB 厂内核 → 从厂入口重新起 → 厂内核的喂狗线程起来」——**实测整条链要
30–35 秒**，狗在中间就咬了 ⟹ 复位到待机 ⟹ 表现与"探针挂死"完全一样。

**所以**：这台机器上**不要**用 10 秒 WDT 兜底跑探针。env 已回滚到救砖前的原始值
（`acd4fe25888b886c4343a8e8612d73df`，主备各 64 KiB）。挂死后的恢复靠**红外电源键**
（`tools/host/tvpower.sh on`，实测 25 s 起来），不需要人。
若将来要重新引入 WDT，超时必须 **≥ 60 s**，并且要先用零风险镜像量出"厂内核开始喂狗"的时刻。

**顺带纠正 §34.3 的两条**：其一，"WDT 复位落到待机"是真的，但那是**狗准时咬**的结果，
不是"WDT 失效"；其二，"DDR 不保"是因为待机切电，与我们自己的写入无关。

### 34.5 探针工程的四个坑（都是我自己踩的，都有离线检查了）

| # | 坑 | 后果 | 现在的防线 |
|---|---|---|---|
| 1 | 探针 blob 放在 `Image+0x36c000`，盖掉 `0x36c0c0` 的 code1 shim | code1 跳进 blob 中间 | 探针一律放 `+0x36d000`；离线比对 shim 签名 |
| 2 | MMU 开着时写 stash | 写就挂 | `probes/handoff/check-probe.py` 静态检查 |
| 3 | 用 `b 2f` 跳过"关 MMU"那段 | 又变成"MMU 开着写 stash" | 同上（检查前向分支不得越过 `msr sctlr_el1`） |
| 4 | `--stub` 传了探针本身，而交接跳转目标固定在 `Image+0x1400200`（应为 `abort-postmmu.bin` 的 `.org 0x200`） | 交接跳进零字节，`udf` | 构建脚本加断言：该处 16 字节必须等于 `abort-postmmu.bin[0x200:0x210]` |

`check-probe.py` 用法：

```sh
python3 probes/handoff/check-probe.py /tmp/probe.bin --tramp-at 0x36d000
```

### 34.6 kva6 现在能回，但记录还没读到（下一步）

env 回滚后 `kva6`（`e7cd16b2…`，零访存、只 `mrs`）**两次都正常回来（34 s）**，
说明探针脚手架可用。但记录没落在我读的地址：

- `0x23090000` 读回的是 code1 shim 的 `M764/FDT` 记录（说明我们的写**没有覆盖**它）；
- 改到 `0x23080100` 后，读回的字节与 `0x23090000` 那次**完全相同**（`5c 80 4e 80 …`），
  而这串字节不是我们写的。

⟹ 待查：探针的 `str` 在"关 MMU 之后、`dc civac` 之前"这个窗口里是否真的落盘
（对照组：同一张镜像里 `abort-postmmu` 的写在同一个窗口之后，是**落盘成功**的，
`M764/MMMU` 读得出来）。下一步应该让探针把记录写到 `abort-postmmu` 用的**同一个页**
（`0x23080000`）并在**同一个位置之后**写，再看是否可见；或者干脆让探针把值放进寄存器、
由 `abort-postmmu` 统一写盘。

### 34.7 ★★★ 找到 `br x8` 的去向了：它跳进**数据区**（2026-11-22 14:0x 实测）

把已证明能用的 tramp 扩展两条指令（`mov x21,x8` / `mrs x22,sctlr_el1`），由
`abort-postmmu` 统一写盘（单一写者、已验证的写窗口），`ps0` 一发拿到：

| 字段 | 值 | 判读 |
|---|---|---|
| `x8`（`br x8` 的目标） | **`0xffffffc0804e805c`** | 见下 |
| `SCTLR_EL1` | **`0x34d4d91d`** | M=1（MMU 开）、C=1（D-cache 开）、I=1 |
| `x30` | `0x206d55b4` | checkpoint 返回地址，⟹ `_text` 运行在 PA `0x20280000` ✓ |

**关键**：`System.map` 里 `__primary_switched = 0xffffffc08046805c`，镜像 `0x46805c` 处是
`d503245f`（`bti c`）✓；而 `x8` 指向的 `0x4e805c` 处是 **`00000000 8062e354`**——那是
`.rodata/data` 区，**不是代码**。

⟹ **`br x8` 一跳过去就执行数据，必然挂死。** 这就是 `prsw`/`ps1`（以及未打补丁的 7.3
真跑）在 `br x8` 之后没有下文的直接原因，而且**与我们的 tramp 无关**。

**差值 +0x80000（512 KB）**。已排除的：
- 不是 KASLR：`CONFIG_RANDOMIZE_BASE` **未开**（`CONFIG_RELOCATABLE=y`）；
- 不是装错地址：`x30` 与 shim 都指向 `_text` PA `0x20280000`；
- 不是我们改坏的：`0x4555c0` 的 `R_AARCH64_RELATIVE` addend 仍是
  `-0x3f7fb97fa4` ⟹ 未重定位时应为 `0xffffffc08046805c` ✓。

⟹ **是内核自己的 `relocate_kernel` 加了 +0x80000**，即它认为自己比链接地址高了 512 KB。
下一步该查的是 `__pi_relocate_kernel` 的 offset 从哪来（`kimage_voffset` 的计算），
以及为什么恰好是 0x80000（注意我们的 `--stub` 把 kernel 补齐到 `0x1400000`、
`kernel_size` 变成 `0x1400800`，这是个高度可疑的候选）。

**判据**：这一条一旦坐实，就能解释"7.3 跑到 `br x8` 就空转"的全部现象，
不需要 `wfe` 假设，也不需要从核假设。

### 34.8 ★★★★★ 7.3 到达 `start_kernel` —— 根因是「2 MB 对齐修正」（2026-11-22 14:4x）

**一句话：`br x8` 之所以跳到数据区，是因为内核按「镜像不在 2 MB 对齐地址」给自己加了
`+0x80000` 的重定位偏移；把这个修正强制为 0，7.3 就从 `br x8` 一路跑到 `start_kernel`。**

#### 证据链（全部实测）

| 步骤 | 手段 | 结果 |
|---|---|---|
| 1 | 把已证明能用的 tramp 多存几个寄存器（`x8` 与 entry `x0..x4`），由 `abort-postmmu` 统一写盘 | 拿到 `x8 = 0xffffffc0804e805c`、`SCTLR_EL1 = 0x34d4d91d`（MMU/cache 都开） |
| 2 | 对照 `System.map`：`__primary_switched = 0xffffffc08046805c`；镜像 `0x46805c` 处是 `d503245f`（`bti c`），而 `0x4e805c` 处是 `00000000 8062e354` | **`br x8` 跳进了数据区** |
| 3 | 在 `__pi_relocate_kernel`（`Image+0x4679bc`）入口打点，采 `x0..x4` | **`x0 = 0x80000`**（就是重定位偏移）；`x1 = 0x206d8000`（rela 表） |
| 4 | 反汇编调用点与 `__pi_early_map_kernel` 开头 | `0x465a1c: and x25, x19, #0x1fffff`，而 `x19 = adrp _text`；**MMU 关着时 `adrp` 给的是物理地址** ⟹ `0x20280000 & 0x1fffff = 0x80000` |
| 5 | 把 `0x465a1c` 强制成 `mov x25, xzr`（`0xaa1f03f9`），检查点仍在 `0x4555b0` | `x8` 变成 **`0xffffffc08046805c`** ✓ |
| 6 | 检查点后移一位到 `0x468060`（`__primary_switched+4`，走 **KVA 入口**） | **回来**，`x30 = 0xffffffc080468064`（内核 VA） |
| 7 | 检查点放到 `start_kernel`（`Image+0x46091c`） | **回来**，`x30 = 0xffffffc080460920` |

⟹ **7.3 现在能到 `start_kernel`。** 之前所有「`br x8` 之后空转」的现象，根因是
**跳进了数据区**，与 `wfe`/从核/异常都无关（§27 的"零异常"也因此得到解释：
它根本没执行到会空转的代码，而是把数据当指令跑了）。

#### 为什么会这样

arm64 的启动协议要求 **Image 放在 2 MB 对齐的物理地址**上。mboot 把内核装在
`0x20280000`（**不是** 2 MB 对齐：`0x20280000 mod 0x200000 = 0x80000`）。厂内核是为这个
地址编的、自己处理得过来；主线按协议假设对齐，于是自己算出一个 512 KB 的修正量，
把**所有重定位指针**连同 `br x8` 的目标一起推高了 512 KB。

#### 尝试过的两条路

| 做法 | 结果 |
|---|---|
| 改容器头里的 `kernel_addr` 为 2 MB 对齐的 `0x20400000`（`--kernel-addr`） | **硬挂**，红外救不回，需物理拔插 ⟹ mboot 不认这个字段（或仍按 `0x20280000` 装），shim 跳到了错地址 |
| **把对齐修正强制为 0**（`--word 0x465a1c=0xaa1f03f9`） | **成功**（见上表 5–7） |

#### 复现方式

```sh
cd ~/Debian/m7642/probes/handoff
./mk-zfix.sh 0x46091c skmainz kva     # start_kernel 检查点，带对齐修正
./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-skmainz.img <md5> skmainz
```

`mk-zfix.sh <image-offset> <tag> [pa|kva]` 把 `0x465a1c` 的修正清零并打检查点；
`kva` 用于 `br x8` 之后的点（内核 VA 段），`pa` 用于之前的点。

#### 镜像

| 镜像 | md5 | 含义 |
|---|---|---|
| `m7642-rec-73-ps0z.img` | `5e2fbf177c892bd2fe5f8f9fe390eaf6` | 对齐修正 + 检查点 `0x4555b0`，`x8` 已正确 |
| `m7642-rec-73-ps1z.img` | `1a09faa129eddc70289db21a318ae871` | 检查点 `0x468060`（`__primary_switched+4`），回来 |
| `m7642-rec-73-skmainz.img` | `787821010db807f9aef183b633f879b5` | 检查点 `start_kernel`（`0x46091c`），回来 |

#### 下一步

卡点已从「`br x8`」推进到「`start_kernel` 之后」。继续用同一套 `mk-zfix.sh` 把检查点往
`setup_arch` / `mm_init` / `rest_init` 推进，第一个不回来的档就是新的卡点。
注意：**所有后续镜像都必须带这个对齐修正**，否则又会在 `br x8` 处跳飞。

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

### 34.10 红外为什么救不回某些挂死（2026-11-22 15:2x，静态 + 用户实测）

**用户实测**：救不回来的挂死，屏幕**停在 logo**（不是黑屏），红外与**实体遥控都没有反应**，
`ping` 不通。

**静态机制**（厂内核 `drivers/mstar2/drv/pm/mdrv_pm.c`）：

| 事件 | 代码 | 效果 |
|---|---|---|
| 挂起前 | `MDrv_PM_Suspend(SUSPEND_PREPARE)`：`CopyBin2Sram()` → **`gRTPM_Live = 0`** | 把 `PM.bin` + 唤醒键表交给 MCU，宣告"AP 走了" |
| 恢复时 | `MDrv_PM_Resume(POWER_ON_DC)`：`MHal_PM_Disable_8051()` → 拷 RTPM bin → `SetDRAMOffsetForMCU()` → **`gRTPM_Live = 1`** | 关 8051、切到 RTPM 代码，宣告"AP 接管" |

AP 与 MCU 还共享一块运行期 PM 区（cmdline `RTPM_INFO=1,0x43FF0000`）。

⟹ **只有 MCU 处于"唤醒键模式"（待机/关机）时，红外 POWER 才由 MCU 自己断电重启。**
AP 一旦接管，POWER 走的是"AP 输入子系统 → Android 关机流程 → 内核把电源交给 MCU"——
AP 挂了就没人做这一步，所以按键无反应。

**与"能救回"的那些次的差别不是挂得多深，而是有没有回到待机**：

| 状态 | 屏幕 | 谁处理 POWER | 结果 |
|---|---|---|---|
| 待机 | **黑屏** | PM51 自己断电重启 | 红外一次，约 25 s 回来 |
| AP 带电但内核已死 | **停在 logo** | 没人 | 只能拔电 |


### 34.11 ★★★ 用户实测更正：救不回的挂死 = **AP 还活着且画面停在 logo**（2026-11-22 15:4x）

用户三条观察（比任何静态推理都硬）：

1. **拿原版实体遥控按也没反应** ⟹ 与"云红外没送到"无关，**排除**了 §34.10 里的伪因；
2. **凡是救不回来的挂死，屏幕都停在 logo，不是黑屏**；
3. 按红外遥控**屏幕毫无变化**，并且 **ping 不通**。

#### 这组事实说明什么

- 屏幕还在显示 logo、面板还在扫描 ⟹ **DC 没断、AP 还带电**，PM51 **没有**执行断电；
- 按电源键毫无变化 ⟹ 按键**要么没被解码，要么被交给了 AP**（而 AP 已经死了，没人处理）；
- 于是"救不回"不是硬件坏了，而是**系统停在了一个没有任何人或 MCU 会去断它的状态**。

#### 与"早期挂死能救回"的差别 = 有没有回过待机

对照此前成功的那些次：那些次红外一次、25 s 就回来——**待机态是 MCU 处理电源键的状态**。
所以真正的分界线不是"挂得多深"，而是：

| 状态 | 屏幕 | 谁处理 POWER | 结果 |
|---|---|---|---|
| 待机（PM51 唤醒键模式） | **黑屏** | PM51 自己断电重启 | 一次红外 25 s 回来 |
| AP 带电但内核已死 | **停在 logo** | 没人（POWER 被交给 AP） | 按什么都没用，**只能拔电** |

⟹ **晚期挂死之所以回不来，是因为它没有进入待机**：AP 已经把 MMU/时钟/定时器都跑起来了，
从 PM51 的角度"系统是活的"，于是 POWER 被路由给 AP、而 AP 死在某处。

（另一种可能是 MCU 自己被共享总线拖住，见 §34.10 的备选；但"屏幕停 logo + 无变化"
已经足以用上面这个更简单的模型解释，且它不需要额外假设。）

#### 对实验设计的直接影响

1. **待机是唯一可自动化的救援态** ⟹ 任何"带电挂死"都要人工拔电。
2. 所以晚期检查点必须**少而准**：`su1..su5` 已覆盖 `setup_arch` 内部，三分即可定位
   （先 `su3`，再 `su1` 或 `su5`），不要一次连打多档。
3. `wdt_enable >60` 仍然值得试一次：它的复位**会落到待机**（§34.3 实测），
   等于把"带电挂死"转成"待机"⟹ 若成立，晚期挂死就重新变回可自动救援。
   **这是目前唯一可能把晚期挂死变回无人值守的路径，值得单独一发来验证。**


### 34.13 WDT 自动复位：四次实验，都不成立（2026-11-21 实测）

| # | 做法 | 结果 |
|---|---|---|
| 1 | mboot env `recoverycmd` 加 `wdt_enable 10` | **两次"确认进入 recovery"的挂死都没有复位**（`misc` 尾部 4 KiB `0xA5` 标记法判定） |
| 2 | 同上 `wdt_enable 120` | 设备在 mboot ~40 s 超时后进待机，狗有没有咬无从观察 |
| 3 | 厂 `HAL_WDT_Start(3,10)` | `rc=1` 失败（缺 `MI_WDT_Open` 前置）；`/dev/watchdog` 不存在 |
| 4 | `MDrv_WDT_Init(0)+MDrv_WDT_SetTimer(0,20)` 干净版 | 120 s 不复位（更早三次"复位"是模块诊断代码自己 oops/panic） |
| 5 | 直接写 `pm+0x6000`/`pm+0x600C` | 超时 5.5 ms 仍不复位；`+0x0C` 读回 `0xFFFF` |
| 6 | `machine_restart()` | 落待机（切电） |

早期几次"设备自己回 Android"的真正原因：**BCB 没写进 `misc` ⟹ mboot 走了 `bootcmd`**，
与看门狗无关。

**唯一会 warm reset 的是 `panic()`**：厂内核 `[WdtHeartBeatTas]` 线程喂一颗 5 s 的狗，
panic 停掉所有 CPU ⟹ 没人喂 ⟹ 狗咬 ⟹ 复位且 **DRAM 保留**。普通挂死不会触发。

### 34.14 卡点二：`setup_arch` 内部，窗口已收到 ~0xCC 字节（2026-11-22 15:5x–16:1x）

带 §34.8 的 2 MB 对齐修正后逐发推进（每发 `kva` 入口）：

| 档 | Image 偏移 | 位置 | 结果 |
|---|---|---|---|
| `su3` | `0x4638fc` | `early_init_dt_scan` 返回后 | ✅ 回来（`x30=…463900`） |
| `su4` | `0x463940` | `of_flat_dt_get_machine_name`+`_printk` 之后 | ✅ 回来（`x30=…463944`） |
| `su5` | `0x463954` | `bl parse_early_param` 处 | ✅ 回来（`x30=…463958`） |
| **`b1`** | `0x463b98` | `smp_init_cpus` | ❌ **不回**（记录全零） |
| **`c2`** | `0x463a24` | `paging_init` 返回后 | ❌ **不回** |

⟹ **上界从 `0x463b98` 收窄到 `0x463a24`**，下界 `0x463954`。窗口内只有这几次调用：

```
0x463954  bl parse_early_param
0x4639fc  bl cpu_do_switch_mm
0x463a00  bl efi_init
0x463a14  bl arm64_memblock_init
0x463a20  bl paging_init
```

已建好、待打的三个点（每一发都是 ~35 s 判定 + 挂死则拔电）：

| 档 | 偏移 | 含义 | md5 |
|---|---|---|---|
| `d0` | `0x463958` | `parse_early_param` 返回后（即 `bl` 的下一条） | `ea3cb11c…` |
| `c1` | `0x463a04` | `efi_init` 返回后 | `8ce80b0f…` |
| `d1` | `0x463a18` | `arm64_memblock_init` 返回后 | `521244a9…` |

**读法**：先 `d0`，回来就打 `c1`，再回来打 `d1`；第一个不回的就是新上界。
如果 `d0` 就不回，那卡点在 **`parse_early_param` 内部**（`0x463954`→`0x463958` 之间）。

**注意**：`paging_init` 是强嫌疑——它会重建页表并切换 `TTBR`。如果卡在它里面，
要考虑"tramp 所在页在切换后是否仍可执行/可写 stash"这个问题（`0x36c000` 在 `.text`
范围内，理应可执行，但 `rodata` 全保护下我们只读不写，问题不大）。

### 34.15 卡点三：`0x463958` 之后紧跟一段「关中断 + 换 TTBR0 + TLBI」的代码（2026-11-22 16:2x）

`su5`/`d0` 都回来了（`d0 = 0x463958`，实测 **10 s 就回来**——新快路径生效），
而 `c1 = 0x463a04` 不回**且记录为空** ⟹ 那个点根本没执行到。

把 `0x463958` 起 0xAC 字节摊开后，看到 `d0` 后面立刻是这样的序列：

```
0x463958  mov  x0, #0xc0
0x46395c  msr  daif, x0          ← I/F 全屏蔽（中断关闭）
0x463964  adrp x0, reserved_pg_dir
0x463974  sub  x0, x0, x2
0x463978  msr  ttbr0_el1, x0     ← 换 TTBR0
0x463984  tlbi vmalle1
0x463990  mrs  x0, tcr_el1
0x463994  and  x2, x0, #0x3f ; cmp x2, #0x19
0x46399c  b.eq 0x4639b4          ← T0SZ 已经是 25 就跳过改写
0x4639a8  msr  tcr_el1, x0       ← 否则把 T0SZ 改成 25
0x4639b4  adrp x0, …+0xa80       ← init_thread_union 附近
0x4639c0  b.eq 0x463a00          ← x1 == 该地址则直接跳到 bl efi_init
0x4639d4  b.eq 0x463d98          ← 否则另有支路
0x4639e8  b.hi 0x463d78          ← 再一支路
0x4639fc  bl   cpu_do_switch_mm
0x463a00  bl   efi_init
0x463a04  ← c1 的检查点（从未执行到）
```

**两条推论**：

1. 这一段**关着中断**。里面任何异常（比如 `ttbr0_el1` 指向的 `reserved_pg_dir` 不可用导致的
   取指/取数中止）都会变成**关中断的死循环**——外部表现正是"停 logo、ping 不通、按键无效"。
2. `c1` 没到，有两种可能：**(a) 死在这段里**，或 **(b) 从 `0x4639d4`/`0x4639e8` 分支走了别的路**
   （那两条 `b.eq`/`b.hi` 的目标 `0x463d98`/`0x463d78` 都在 `0x463a04` 之后，
   所以**即使内核健康，`0x463a04` 也可能永远不执行**）。⟹ "c1 不回"不能直接判成"efi_init 挂了"。

**为此建的下一批点**（主路径必经，且能顺便把分支条件读出来）：

| 档 | 偏移 | 含义 | md5 |
|---|---|---|---|
| `e0` | `0x4639b4` | TTBR0/TLBI/TCR 那段**之后**第一条：过了就说明这段没杀我们 | `e761d7d4…` |
| `e1` | `0x4639c0` | `b.eq` 本身；tramp 的 entry 寄存器里有 `x1`，正好是被比较的值 | `9ce33859…` |

`e1` 回来之后，把记录的 `x1` 与 `0xffffffc0805d9a80` 比一下就知道走没走 `0x463a00` 那条直路。

**代价说明**：这一发 `c1` 挂死后**红外两次都没救回**（`d1` 连推都推不上），又只能拔电。
所以后续每发都要挑"最可能在健康路径上"的点，并尽量用 `merge` 把多个点串在一次上电里。

### 34.16 ★★★ 卡点四：凶手在 `cpu_uninstall_idmap()` 里（2026-11-22 16:3x）

`e0 = 0x4639b4` 也不回（记录为空），所以卡点被夹进 `0x463958`–`0x4639b4` 这 **0x5C 字节**。
对着源码认出这两行就是它：

```c
local_daif_restore(DAIF_PROCCTX_NOIRQ);   /* 0x463958 mov x0,#0xc0 ; msr daif */
cpu_uninstall_idmap();                    /* 0x463960–0x4639b0 */
```

`cpu_uninstall_idmap()` 的汇编展开（逐条）是：

```
0x463960  ldr  x2, [x20]          ← x20 = &init_mm.pgd（0x46387c 刚往这里存过）
0x463964  adrp x0, reserved_pg_dir
0x46396c  mrs  x1, sp_el0         ← current
0x463970  ldr  x1, [x1, #976]     ← current->active_mm
0x463974  sub  x0, x0, x2         ← phys_to_ttbr()：把 kimage 偏移减掉
0x463978  msr  ttbr0_el1, x0
0x463984  tlbi vmalle1
0x463990  mrs  x0, tcr_el1 ; …    ← T0SZ 不是 25 就改成 25
0x4639b4  cmp  x1, &init_mm ; b.eq 0x463a00   ← active_mm == init_mm 则跳过 cpu_switch_mm
```

**意义**：这是 7.3 **第一次切回它自己的页表映射并刷 TLB**。两个后果：

1. **`phys_to_ttbr()` 依赖 `kimage_voffset`**——而 §34.8 的对齐修正（`mov x25, xzr`）恰好动过这个偏移。
   所以这个卡点**可能是我们那个补丁的副作用**，而不是独立的平台问题；
2. `x1` / `x2` 两个值（`active_mm`、`init_mm.pgd`）都在我们的 tramp 记录范围内，
   一发 `f1`（`0x463978`）就能把 `x0`（要写进 TTBR0 的值）和 `x2`（被减掉的偏移）读出来。

待打的三个点：

| 档 | 偏移 | 位置 | md5 |
|---|---|---|---|
| `f0` | `0x463968` | 两次 `ldr` 之后（0x463960/0x46396c–0x463970 都过了） | `78a79871…` |
| `f1` | `0x463978` | `msr ttbr0_el1` 之前，记录里有 x0/x2 | `b658b732…` |
| `f2` | `0x463984` | `tlbi vmalle1` 处（TTBR0 已写） | `dfd7e21c…` |
| `e1` | `0x4639c0` | 整段之后、`b.eq` 处；`x1` 即 active_mm | `9ce33859…` |

**判读**：`f1` 回来 + `e1` 不回 ⟹ 凶手在 `msr ttbr0_el1`/`tlbi`/TCR 那几条里，且 `x0` 的值是否合理
直接决定"是我们补丁的副作用"还是"平台拒绝这个 TLBI"。

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

### 34.18 仪器改造：三条路试过两条，仍卡在“0x463978 之后不能打点”（2026-11-22 22:0x）

#### 已排除的路线

| 路线 | 做法 | 结果 |
|---|---|---|
| **1** | 保持 MMU 开、全程用线性映射 VA 交接（含跳厂内核入口） | **`g2` @0x463978 不回** ⟹ 厂内核不接受"带 MMU 进入" |
| **2** | 自己装一张 1 GB 恒等块表（`T0SZ=25` 下 L1 单条表项足够盖住 `0x20280000`~`0x30000800`）→ 跳到桩的物理地址 → 在桩里关 M/C/I | **`g5` @0x463978 仍不回**（该点在旧仪器下 `f1` 是能回来的） |

#### 改造过程中修掉的两个真 bug（都值得记）

1. **双重加偏移**：`arm64` 永远把内核映射在 `KIMAGE_VADDR`，所以**符号的运行时 VA 就是它的链接 VA**，
   与装载地址无关。我一开始又加了一次 `kimage`（实测到的 `VA-PA`），
   于是 `memstart_addr` 的地址跑到 `0xffffffc0e01c1dd8`（野指针）——
   读它得到垃圾、`lin` 变成垃圾、后面一条 `str` 写到野地址 ⟹ 取数中止。
2. **VA 模式仍跳 PA 别名**：校准之后代码仍走“跳到 `PA = VA - KIMAGE_OFFSET`”，
   而那个别名正是 idmap 拆掉后**不存在**的东西。VA 模式必须留在 VA 空间。

#### 现在的判据困境

`g5` 失败发生在**旧仪器能回来的点**上，所以问题一定还在新代码里，但**挂了就读不到记录**
（DDR 随拔电丢失），只能靠二分试错——而每次试错要一次人工拔插，成本已经不可接受。

#### 下一步（明确的两步，第一步很便宜）

**A. 只做校准、沿用旧交接**（即"stage A"）：校准代码 + 记录 + **老的 PA 跳转/关 MMU**，
   完全不碰 idmap。若这一发回来 ⟹ 校准本身是安全的，问题在装表那段；
   与此同时记录里会带上 `kimage` / `memstart_addr` / `lin` 三个实测值（正好验证数值）。
   这一发在 `0x463978` 上做，风险等于 `f1`。

**B. 若 A 回来，再单独验证"装表"**：把它们拆成两个独立改动，逐条上机，
   而不是像今天这样一次改三处（校准 + VA 访存 + 装表）。

**重要**：用户已下单智能插座（两天到）。到货后每次"拔插"变成脚本可控，
这一天里剩下的试错就不再消耗人的耐心——**在那之前应避免高频上机**。

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

### 34.20 ★★★★★ 连挂三发的真凶：检查点补丁打在了**错误的入口偏移**上（2026-11-22 23:3x）

#### 现象

`n1`（v3）与 `p1`（v4）都在 `0x463978` 挂死、记录为空——而这个偏移上**旧的 `f1` 是能回来的**。
QEMU 测试台对 v2/v3/v4 两个世界全 PASS，**与真机矛盾**。

#### 真因

v2 重写把 `_start` 变成了两条指令：

```
0x00  mov x5, xzr        <- _start
0x04  b   0x110          <- _start 第二条
0x08  ...                <- _start_kva 被推到这里（原先是 0x04）
```

而 `mk-zfix.sh` 里 `kva) TGT=0x36c004` 是**写死的**。于是从 v2 起，每一发
检查点的 `bl` 都落在 `Image+0x36c004`＝`_start` 的第二条指令，**直接 `b 0x110` 进公共路径，
绕过整个 AT 探测、也没有初始化 x5**。带着内核现场的 `x5`（非零）：

| 版本 | 走到的分支 | 死法 |
|---|---|---|
| v2 / v3 | `x5≠0` → VA 分支 | 用垃圾 `x5` 当偏移写表 → 取数中止 |
| v4 | 绕过探测 → `cbz x5` 不成立 | 又去建表 → 中止 |

#### 为什么测试台没抓到（**夹具盲区**）

QEMU bench 是**按符号**跳到 `_start_kva` 的（日志里写 `entering tramp _start_kva at VA=…`），
**从不经过 `bl Image+0x36c004` 这条真实的补丁路径**。所以"入口偏移漂移"这类 bug
在夹具里天然不可见。

#### 结构性修复（不再依赖人记）

1. `tramp-postmmu.S` 里用 `.org 0x10` **钉死** `_start_kva`；
2. `build-postmmu.sh` 用 `nm` **断言** `_start==0x0`、`_start_kva==0x10`、`_start_fdt==0xc0`，
   不符即退出；并把结果写进 `tramp-entries.env`（`TRAMP_PA_ENTRY/TRAMP_KVA_ENTRY/TRAMP_FDT_ENTRY`）；
3. `mk-zfix.sh`、`mk-aligned.sh` **读这份文件**，不再写死 `0x36c004/0x36c000`；
4. 镜像构建后离线核对：`patch@0x463978 -> 0x36c010` ✓、`code1 -> 0x36c0c0` ✓。

#### 教训（已进 discipline）

**"按符号调用"的测试台，必须再加一条"按补丁入口调用"的场景**，否则它证明不了真实镜像的行为。
凡是"偏移量"这种手工同步的东西，都要变成"由构建生成 + 断言"。

镜像：`q1` = `042bb24c…`（`0x463978`）、`q2` = `b8ca5721…`（`0x4639c0`），tramp blob `3f2a9fcf…`。

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

### 34.22 厂内核设备树与厂 cmdline（2026-11-17 采集，2026-11-23 入库）

来源：厂内核运行时 `/proc/device-tree` 的整棵 dump（212 个节点），以及 `dtc -I fs` 的反编译。

| 项 | 值 |
|---|---|
| `compatible` | `"arm,foundation-aarch64"`, `"arm,m7642"` |
| `model` | `M7642` |
| **`chosen/bootargs`** | **`root=/dev/ram0 rw init=/sbin/init ip=dhcp console=ttyS0,38400,LX_MEM=0x03000000`** |
| 内存节点 | `memory@20200000` |
| 中断节点 | 212 个里有大量具名中断：`acpu_int`、`AUDMA_V2_INTR`、`AU_SPDIF_TX_CS_INT0/1`、`aia_*`、`aesdma_s_int` …… |

**归档位置**：

- 文本：`Documentation/mstar/m7642/reference/m7642-factory.dts`（26 KB，machine 输出，未改动）
- 原始 fs dump：`~/Debian/m7642-build/diag/factory-devtree-fs.tar.gz`
- 二进制 DTB：`~/Debian/m7642-build/diag/live.dtb`（64 KB，反编译结果与上面同树）

**为什么记**：厂 cmdline 之前没有任何文档记录，而它含 `LX_MEM=0x03000000` 与
`console=ttyS0,38400`——后者说明厂内核**打开了串口控制台**（我们这个板子上是否有可用焊点另说，
但至少说明这条通路在厂方案里是被使用的）。中断节点表是写我们自己的 DTS 时的直接参考。

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

### 34.25 新仪器：world B 内「读内核变量」的 readout 入口（零断电风险）

`combo` 证明卡在 `kmem_cache_init` 的分配循环里"既不返回也不失败"。为了**不靠断电试探**，
新增了一个**必定返回**的探针：在任意 world-B 检查点上先把 `TCR_EL1`/`TTBR0_EL1` 还回去
（复刻 `_start_restore` 的动作），再**通过内核 VA 读若干个变量**，存进镜像 `.bss` 的 SAVE 页；
交接桩在 32 MB 拷贝**之前**把这 8 个 qword 抄进记录（记录由 `0xB0` 扩到 **`0xF0`**）。

| 项 | 值 |
|---|---|
| 入口 | `_start_readout` = blob `0x600`（`Image+0x36c600`） |
| 符号传法 | 构建期 `-DSYM0_VA..SYM7_VA`（链接 VA = 运行时 VA） |
| 落位 | SAVE 页 +0x40…+0x78（PA = `SAVE_VA - KIMAGE_OFFSET` = `0x20883000`） |
| 记录槽 | `+0xB0..+0xEF`，`+0x08` 的 size 写 `0xF0` |
| 构建 | `WORLD_VA=0 READOUT_SYMS="memblock+16 memblock+32 ..." ./mk-multi.sh <tag> d0=save mm4=readout` |
| 解码 | `tools/host/decode-record.py` 会自动打印这 8 个槽 |

**默认符号集**（`struct memblock` 布局已核对：`memory` 在 +16、`reserved` 在 +56；
`memblock_type` 内 `cnt`=+0、`total_size`=+16）：

| 槽 | 符号 | 含义 |
|---|---|---|
| 0 | `memblock+16` | `memory.cnt`（内核认到几段 RAM） |
| 1 | `memblock+32` | `memory.total_size`（认到多少字节） |
| 2 | `memblock+56` | `reserved.cnt`（保留了几段） |
| 3 | `memblock+72` | `reserved.total_size`（保留多少字节） |
| 4 | `max_pfn` | 最高页号 |
| 5 | `min_low_pfn` | 最低页号 |

（`totalram_pages` 在 7.x 已不是普通符号，故不用。）

#### 明天第一发（零风险，会返回）

```
镜像：m7642-ro2.img  md5 e5eb8c14f8582eebfb079c6baff0387e
配置：d0=save  +  mm4(0x473448, bl kmem_cache_init)=readout
```

**为什么是这一点**：`mm4` 在 `mem_init` 之后、`kmem_cache_init` 之前，**已验证会返回**；
它给出"内核在进入 slab init 之前到底有多少可用内存"。

**判读**：

| `memblock.memory.total_size` | 结论 | 下一步 |
|---|---|---|
| ≈ 2.7 GB 且 `reserved` 很小 | 内存充足 ⟹ **不是内存耗尽**，卡点是锁/自旋/数据结构问题 | 转向 `__alloc_pages_noprof` 内部分档（静态先选出 1 个点） |
| 只有几百 MB 或 `reserved` ≈ `memory` | 内存被大量保留 ⟹ 分配进 direct reclaim，而**调度器尚未初始化**（`mm_core_init` 在 `init/main.c:1049`，`sched_init` 在 1062） | 直接查是谁保留了内存（memblock 各段的来源） |

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
pr_info("SLUB: HWalign=%d, ..., CPUs=%u, Nodes=%u\n", ...);               // 0x477548
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
