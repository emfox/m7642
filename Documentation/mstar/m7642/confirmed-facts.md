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

**7.3**（`~/kbuild/linux-main`，仓库 `~/Debian/m7642`）

- 只走 `tools/build-mstar-kernel.sh`；梯级独立汇编 ⟹ 改梯级零内核重编。
- 卡点：`0x455038` 之后、`__primary_switch` 之前，绿 → 暗紫蓝 `0x4210`
  = 死在 `create_init_idmap` 体内（`0x465eb8`，**4 次栈写之后**）⟹ **栈真的不可写**；
  另一个检查点 `0x465ef0` 打 `0x8410`，在 text 段 `map_range` **之后**，从未到达。

**4.19**（`~/kbuild/tcl-419`，源自 `Thedemon007/realme_Smart_TV_4K-kernel-source`）

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
- ★ **但 `reboot recovery` 也会回待机，取决于 recovery 镜像的行为**【现场观察 2026-11-21】：
  - 镜像**卡死** ⟹ `wdt_enable` 10 s 后 warm reset ⟹ **十几秒自己回 Android，不用人**；
  - 镜像 `bootm` 后**返回**（没卡死）⟹ mboot 交权 PM51 ⟹ **停在待机，要按电源键**。
  - ⟹ 「要不要人按」是判断"复位是哪一级"的唯一路标：**要人按 = 切过电 = DDR 全丢**。
    任何读 DDR 标记的实验必须落在前一种，否则读到空不说明任何问题（见 `wdt-beacon.md` §十一）。
  - 正常启动耗时 **35–40 s**（含人按电源键的反应时间），所以**启动时长不能当判据**。
- **`recoverycmd` 里 `wdt_enable 10` 真的布防 WDT**【实测 2026-11-20】。env 加这一条后，
  两次"内核卡死"实验（`white-cc` / `wdt` 镜像）**设备都自己回到了 Android**，
  而此前 `white-halt` 卡死后必须拔电。reboot→内核启动的差额 16–23 s，与"进 recovery +
  卡 10 s + 复位"吻合。⟹ **测试失败的恢复不再需要人：不用拔电、不用 U 盘、不用按键。**
  前提见 `mboot-env.md` §七（`WDT_ENABLE=1`、`recoverycmd` 前 4 字节须为 `mmc `）。
- ⚠️ **DDR 能否保留，取决于复位方式，两者必须分清**【实测 + 早期记录】：
  - **soft reset（WDT / panic）⟹ DDR 保留**。依据：§五十二 `ramoops/pstore | 只在 soft reset
    下保留`；§3 实测 `echo c > /proc/sysrq-trigger` 后设备自恢复，且
    `/sys/fs/pstore/console-ramoops` 拿到 panic 前的 576 行日志 —— 内容只可能来自保留的 DDR。
  - **`adb reboot` ⟹ 进待机 = PM51 切电 = 硬断电 ⟹ DDR 全丢**。
    `flash-and-recovery.md` §44 实测："`adb reboot` 之后设备停在待机、网络与 adb 都不通"。
  - ⟹ **任何"DDR 是否保留"的实验，绝不能用 `adb reboot` 做复位**（2026-11-20 犯过这个错，
    见 `wdt-beacon.md` §九末）。
- **ramoops 区 `0x42300000` 有签名校验**（`fs/pstore/ram_core.c`，`PERSISTENT_RAM_SIG=0x43474244`）：
  sig 不符 ⟹ `persistent_ram_zap()` 清零；**sig 写对 ⟹ `persistent_ram_save_old()` 把内容拷进
  kmalloc，之后原厂内核再写日志也覆盖不掉**，pstore 导出成 `/sys/fs/pstore/console-ramoops`。
  这是现成的"跨 soft reset 传信息"通道，且**不需要 probeRW**，adb 直接读文件。
  详见 `wdt-beacon.md` §十。
- 🔴 **`0x20100000` 是 mboot 的活动代码区**：写进去的字节重启后变成 ARM 指令（`e59fc078…`）。
  **绝对不要在那里做任何读写实验**。

## H 已否定 / 已结案的假设（不要重走）

| 曾经的假设 | 结论 | 依据 |
|---|---|---|
| **DDR 内容能跨一次启动保留（标记 / pstore 通道）** | **否，彻底作废** | 原厂 4.9 kernel + 44 B blob（只写 `0x419A0000` 后 `b .`）执行成功（`/data` 未被格式化、`last_log` 未更新 ⟹ recovery init 被拦住），但 adb 读回仍是全 `ff` ⟹ **mboot 每次启动都重新初始化 DDR**。这同时解释 pstore 永远空、11-20 probeRW 写值全丢。见 `wdt-beacon.md` §十二 |
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
| **「recovery 槽 + 探针挂住 + `wdt_enable` 兜底」能拿到读数** | **否** | 10 s 狗咬在「mboot 等内核」的窗口里，pstore 导出（kmalloc 在 DDR）与证据一起被抹；换 120 s 则 mboot 先超时进待机、设备不再自己回来。见 §I.3 与 `wdt-beacon.md` §十六 |
| **「改过的 recovery 镜像没有被 mboot 执行」**（`wdt-beacon.md` §十二.1） | **否，作废** | ① `misc` 第 2 页的标记被 `mmc erase.p misc` 擦掉 ⟹ `recoverycmd` 执行到了；② 去掉 `wdt_enable` 后 `b .` 探针把设备挂在 logo 上 4 min+ 不恢复 ⟹ 控制权已在我们代码里 |
| **「厂值 boot 镜像放 recovery 槽能起 Android」** | **否** | 零改动 `6272b10d…` 写进 recovery 槽 → `adb reboot recovery` → 90 s 无 Android ⟹ 是这个场地不行，不是探针不行 |
| **「`0x419c0000` 与普通 DDR 同类，可被 EL2 直接写」** | **否（强证据）** | 两次写它的探针（`handoff.S` 192 B / `handoff1` 100 B）都挂；改写到普通 DDR 的 `handoff2` 一次成功返回。且该 zone 数据区始终是 `ff`（`persistent_ram_zap` 用 `memset 0`，被写过会留字节）⟹ 那个地址**从来没被写成过** |
| **「`wdt_enable 120` 拉长超时当安全网」** | **否** | mboot 先自己超时进待机，狗响不响都看不见，要人按电源 |

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
