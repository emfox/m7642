# mboot 的启动模式与「能不能远程救砖」

2026-11-17 对 `fw/mboot/mboot.bin`（2 958 848 字节，2.9 MB）的静态分析。

**结论：不存在纯软件的救砖路径。** 下面把三条独立的证据链摆出来，以及顺带挖到的、对后续真正有用的东西。

## 一、mboot 的镜像结构（实测偏移）

| 分区偏移 | 内容 |
|---|---|
| `0x000` | MStar 头：`0x00002400` 魔数、加载地址 **`0x27400000`**、结束 `0x276D0040`、长度 `0x2D2440` |
| `0x0A0` | `MBOT-1106.0.10.1426731`（版本串） |
| `0x100` | **Board info 块**（早期使用，非 U-Boot env）：`Board=MT167B_10AT_MT5888_M7642_CUS19`、`MBoot_IN=MMC_FLASH`、`Kernel=64BIT`、`Security=OPTEE`、`Load_DTB=True`，共 6 项，之后 `0xFF` 填充 |
| `0x2B8B98` | **内置默认 env**，第一项就是 `mboot_default_env=1` |
| `0x370800` 起 | MBOOT 分区（5 MB）内 mboot.bin 之后的另一段数据，约 1.6 MB |

镜像用**文件偏移寻址**：字面量池里的指针是 `0x00xxxxxx` 形式（例：`0x002869d0` 指向字符串
`do_rw_en_update_mode`），所以静态分析不需要知道运行时基址。字符串表集中在 `0x286000–0x291000`。

### 内置默认 env 的内容（`0x2B8B98` 起）

```
mboot_default_env=1
bootcmd=if mmc rescan ${mmcdev}; then if run loadbootscript; then run bootscript; \
        else if run loaduimage; then run mmcboot; fi; fi; fi
bootdelay=0
baudrate=115200
loadaddr=0x82000000
console=ttyS2,115200n8        <-- 注意，不是 ttyS0
usbtty=cdc_acm
vram=16M
mmcdev=0
mmcroot=/dev/mmcblk0p2 rw
mmcrootfstype=ext3 rootwait
mmcargs=setenv bootargs console=${console} vram=${vram} root=${mmcroot} ...
loadbootscript=...
```

**`mboot_default_env=1` 说明当前跑的就是这份默认值**。真实 env 在 mboot 所谓的 "Env Partition" 里，
读不到/CRC 错时才回落到默认值，并打印 `*** Warning - %s, using default environment`。

相关字符串（都在 `env_mmc.c` 附近）：
```
_write_env failed : can not find Env Partition(%s)
failed to save env
failed to save backup env
!bad CRC
ERROR: Cannot import environment: errno = %d
*** Warning - %s, using default environment
```
⟹ **env 有 CRC32 校验，而且有备份份**。改 env 必须重算 CRC。

## 二、三条证据链，指向同一个结论

### 证据 1：mboot 不解析 Android boot image 的 DTB 字段

搜遍了这些关键字，**全部不存在**：

```
dtb_size       none
dtb_addr       none
header_version none
second_size    none
```

`ANDROID!` 只出现一次（`0x2AF381`），是错误提示用，不是解析器。

⟹ **mboot 只会从独立的 `dtb` 分区加载设备树**，无法把 DTB 塞进 boot.img 躲开这个分区。
这一条直接否掉了"只改 boot 分区、不碰 dtb"的思路。

### 证据 2：没有启动失败自动回退

```
bootcount      none
altbootcmd     none
```

U-Boot 的 bootcount/altbootcmd 机制是 2012 年之后才有的，这颗是 `U-Boot 2011.06-00000-gc44ec26-dirty`。
`do_createMbootBak - create MBOOTBAK partition for mboot backup` 是个**手动命令**，不是自动回退。

⟹ 起不来就是起不来，不会自己退到上一个能用状态。

### 证据 3：dtb 分区是 boot 与 recovery 共用的

分区表里只有一个 `dtb`（p12，1 MB）。boot 与 recovery 都从它取设备树。
⟹ **dtb 坏了，recovery 也起不来**，`adb reboot recovery` 这条后路一并失效。

## 三、启动模式确实有软件接口，但够不到

mboot 里的启动模式有三条来源：

```
get_boot_mode_from_env        <- 读 env 变量 boot_ctrl
get_boot_status_from_mtd0     <- 读 mtd0
get_boot_mode_from_keypad     <- 按键
isBootToRecovery
boot_mode_recovery
```

以及一个 U-Boot 命令：

```
get/set update_mode
<g/s> [EN_UPDATE_MODE]
EN_UPDATE_MODE:
  'EN_UPDATE_MODE_NONE' 'EN_UPDATE_MODE_TFTP' 'EN_UPDATE_MODE_USB' 'EN_UPDATE_MODE_OAD'
  'EN_UPDATE_MODE_NET' 'EN_UPDATE_MODE_USB_WITH_SEG_DECRYPTED' 'EN_UPDATE_MODE_NET_WITH_SEG_DECRYPTED'
```

`do_rw_en_update_mode`（rw = read/write）说明这个值会**持久化到 flash**。运行时的诊断打印给出字段形状：

```
[QHB] PowerOnMode = %d, u4BootCtrl = 0x%08x, fgStateOn = %d
[QHB] get boot_ctrl env failed
[QHB] quite hot boot mode / normal boot mode
set env boot_ctrl to [%s]
```

**`u4BootCtrl` 是个 32 位位域**，与 `EN_UPDATE_MODE_*` 的枚举对应。

**为什么够不到**：

1. 当前 env 是**内置默认值**（`mboot_default_env=1`），里面没有 `boot_ctrl` ⟹ `get_boot_mode_from_env` 返回 NONE；
2. 要设置它，只能改 "Env Partition" 或 mtd0 —— 两者都在 MBOOT 分区内；
3. 而 MBOOT 分区**没有自动回退**（证据 2），改坏了比 dtb 坏更严重：mboot 自己都起不来；
4. 进 `update_mode` 的目的是让 mboot 用 TFTP/U 盘重刷，**但这条路要求 mboot 还能跑**，而它正是不敢动的那部分。

⟹ 用一个更大的风险去换一个更小的风险，不划算。

## 四、意外收获：`console=ttyS2,115200n8`

mboot 的 env 里串口是 **ttyS2**，而厂商 Android 内核的 cmdline 是 `console=ttyS0`。

设备上确实有三个 8250：

```
0: uart:16550 port:FFFFFF800A201300 irq:32     <- Android 内核在这里打日志
1: uart:16550 port:FFFFFF800A220C00 irq:71
2: uart:16550 port:FFFFFF800A220D00 irq:82     <- mboot 在这里打日志
```

⟹ **将来接串口时，两个口都要开**：mboot 阶段只有 ttyS2 有输出，内核接管后才是 ttyS0。
否则会出现"接上串口看不到 mboot 任何东西"的误判。

## 五、那到底怎么恢复

三条现成路径，按省事排序：

| 路径 | 需要人做什么 | 能否救"内核+dtb 都坏" | 备注 |
|---|---|---|---|
| **智能插座** | 一次都不用到场 | 能（断电即可重来） | 几十块钱，但断电后仍需一次好镜像才能恢复系统 |
| **U 盘 + 固件 BIN** | 插一次 U 盘 | 能（mboot 自带刷机） | mboot 里有 `appInitUsbDisk`、`All Upgrade File Had Finished !!`、`AP upgrade OK!`；不需要按键 |
| **串口** | 接一次线 | 能，且能看日志 | mboot 用 ttyS2，内核用 ttyS0 |

注意：智能插座只是**恢复供电**，不能把坏镜像换回去。要真正恢复，必须配合 U 盘固件或串口操作。
所以**最稳的组合是「智能插座 + 一个放好固件 BIN 的 U 盘」**：远程断电重启，mboot 检测到 U 盘固件自动刷回。

## 六、对 R2 的直接影响

R2（写 recovery + dtb）仍然需要一次物理到场，理由没变，但风险等级可以下调：

- 坏的是 **dtb 分区**，不是 MBOOT ⟹ mboot 一定还能跑；
- mboot 能跑 ⟹ U 盘固件刷机这条路永远有效；
- 所以**不是"变砖"，是"必须插 U 盘"**。

前提：**先确认这台机器的 U 盘自动刷机确实工作**（用一个已知好的官方固件试一次）。
这一步可以在动 dtb 之前做，而且完全不改任何东西。

## 七、实测：BCB 可控，但 mboot 不清它

### BCB 完全可控（已验证）

misc 分区的第一个扇区可以被精确改写，逐字节恢复：

```
orig sector md5 = 296862321b339e4dcd271b0936c9ad6e
写入 "boot-poweron" 后 = 3b69d55cadb7a5d79988d3425694d842
从备份恢复后        = 296862321b339e4dcd271b0936c9ad6e   ← 与原始一致
```

**坑**：Android 的 toybox `dd` **禁用了 `conv` 选项**（`dd: conv option disabled`，退出码 1）。
用 `conv=notrunc` 的写操作会**静默失败**（重定向到 `2>/dev/null` 时完全看不出来，连试三次都"成功"）。
正确做法是**整块读-改-写**：读 4K → 改前 13 字节 → 写回整个 4K。

misc 结构（实测）：

```
offset 0:   "boot-adb\0"          8 字符 + NUL
offset 8:   10 个 u32，值形如 0x003be700 / 0x003be7b3 / ...（递增）
offset 51:  全 0 到 4K 结束
```

command 字段不是标准 BCB 的 32 字节——它后面紧跟着一串值。所以**写更长的命令会覆盖它们**，
必须先备份、后校验。

### "mboot 不清理 BCB" —— 这个结论已被推翻（2026-11-17 18:22 复测）

第一次做的对照是"只做普通 `adb reboot`，读回 BCB，发现还是 `boot-adb`"，于是判成"非消费式"。
**这个推理是错的**，因为被测的命令本身是 mboot 不认识的 `boot-adb`。

改用 mboot 认得的 `boot-poweron` 重做，写入后再重启，读回：

```
写入前写入的:  62 6f 6f 74 2d 70 6f 77 65 72 6f 6e 00   ("boot-poweron")
重启后读回:    62 6f 6f 74 2d 61 64 62 00 72 6f 6e 00   ("boot-adb\0" + "ron\0")
                                             ^^^^^^^^^^ 后 3 字节是 "boot-poweron" 的尾巴
```

前 8 字节被改写成 `boot-adb`，偏移 9 起还是我们写的 `...ron`。这说明：

- **Android 每次启动都会把 command 字段重写成 `boot-adb`**（只覆盖 8 字节 + NUL），
- 所以"重启后还是 `boot-adb`"根本不能证明 mboot 清没清——它被覆盖了。

⟹ **mboot 对 `boot-recovery` 到底消费不消费，目前仍是未知**。要判定它，只能拿一个
认识、又能观察到副作用的命令做实验；而唯一有意义的观察量（`boot-recovery` 之后能不能回到
正常启动）正是我们不敢赌的那一步。**在拿到安全网之前，按"非消费式"处理。**

### 补记（2026-11-19 19:2x）：misc 现状与一条坏读数

- misc = `mmcblk0p6`，**8 MiB**，与整盘 LBA `0x19800` 逐字节对得上，映射没问题。
- 18:37 前 4096 B 全零（md5 `620f0b67…`）—— 那是**当天下午多次刷机**（每包第一条
  `mmc erase.p misc`）的结果，**不能用它判断 BCB 归因**。17:2x 的
  「`arm` 写 `boot-recovery` ⟹ 每次开机进 recovery 槽」仍是最简解释。
- 19:19 前 48 B 变成 recovery boot header 的前缀（与 `mmcblk0p7` 前 48 B 逐字节相同），
  来自 `adb reboot recovery`。之后系统正常启动 ⟹ **这 48 B 不是「下次进 recovery」的开关**。
- ★ `dd if=misc bs=1 count=16` 在这个 toybox 上拿到的是 **recovery header**，不是 misc 偏移 0
  ⟹ `boottest.sh show` 打印的「BCB」是假读数，以前据此下的「BCB 已空」结论作废。
  要判 BCB 只用 `bs=512 count=1`。

详见 `misc-bcb-readout.md`。

### 另一条通路阵亡：eMMC 上没有任何 FAT 分区

内置默认 env 里有标准的 `bootcmd`：

```
bootcmd=if mmc rescan 0; then if run loadbootscript; then run bootscript; \
        else if run loaduimage; then run mmcboot; fi; fi; fi
loadbootscript=fatload mmc 0 ${loadaddr} boot.scr
bootscript=echo Running bootscript ...; source ${loadaddr}
```

一度以为可以往 FAT 分区放一个 `boot.scr` 来执行任意 U-Boot 命令（零 flash 写入）。
实测扫描全部 26 个分区的首扇区，**没有一个带 FAT 签名**（`fatstr=0`），也没有 FAT 的 BPB 结构。
⟹ `fatload mmc 0 boot.scr` 必然失败，这段 `bootcmd` 是 U-Boot 的通用默认值、在本机上是死代码。
（这也解释了为什么它指向 `uImage` 而我们这台机器根本没有 uImage。）

### recovery 无法远程控制（实测）

解包原厂 recovery 分区的 ramdisk（7.4 MB，gzip cpio）：

```
sbin/adbd      sbin/recovery   sbin/busybox   sbin/mksh   sbin/charger
```

工具齐全，但是：

```
prop.default:  ro.debuggable=0
               ro.adb.secure=1
init.rc:       service adbd ... (disabled)
               on property:ro.debuggable=1  → start adbd
```

⟹ **adbd 根本不会自动启动**；就算手动拉起，`ro.adb.secure=1` 还需要在屏幕上点授权，
而 recovery 的 UI 只有遥控器能操作。

另一个细节（对将来有用）：

```
init.recovery.m7642.rc:
    # enable ir input for reboot recovery case
    write /sys/module/mdrv_ir/parameters/input_event_en 1
    write /sys/module/mdrv_ir/parameters/input_dev_event_enable 1
```

⟹ **厂商专门为 recovery 场景启用了红外输入**。也就是说"进 recovery 后用遥控器出来"是厂商
设计好的路径——但它要求有人在电视前。

### 内核没有暴露看门狗设备（但 SoC 有看门狗）

```
/dev/watchdog*          不存在
/sys/class/watchdog/    不存在
```

⟹ **内核侧**没有看门狗驱动，所以内核挂死不会自动重启。（之前盲扫 MMIO 导致的自动重启是
SoC 的 external abort 硬件复位，不是看门狗。）

**但不要把这条读成「SoC 没有看门狗」。** 静态分析 `mboot_full.bin` 已经查通：
MStar WDT 在 `0x1F000000 + 0x3000..0x3008`（喂狗 / 复位标志 / 计数值，时钟 12 MHz），
mboot 在**第一次写 eMMC（CMD25）时布防 5 秒**，函数在 `0x60e9c`。
详见 `boot-test.md` 第五十七节。

也就是说：

| 场景 | 会不会被狗咬 |
|---|---|
| mboot 正在写 eMMC（刷机、写 BCB）时卡住 | **会**，5 秒后复位 |
| 纯 `mmc read.p` + `bootm`，不写 eMMC | **不会**（WDT 没布防） |
| 内核已经跑起来之后挂死 | 取决于内核自己有没有布防，mboot 的那次布防早已完成 |

另外，即便被狗咬，**也没有失败回退**：两个消费复位标志的函数
（`do_bootcheck`、`If_Boot_To_PM`）都只打印一行日志，不改变启动哪个内核。

### 顺带确认：fastboot 支持非 USB 传输

```
fastboot_port
fb_udp_our_port=%d
Listening for fastboot transfer on %s
```

⟹ mboot 的 fastboot 可以走网络（UDP）。BCB 白名单里也有 `boot-bootloader`。
但进 fastboot 之后若无可用链路，同样出不来（没有超时回退的证据）。

## 八、结论：唯一可行的路是把"自清 BCB"做进内核

四条硬约束叠加起来，纯软件零风险路径**不存在**：

| 约束 | 证据 |
|---|---|
| 无启动失败回退 | 静态：无 `bootcount` / `altbootcmd` / A-B slot；WDT 复位标志只打印不决策 |
| 内核无看门狗驱动 | 实测：`/dev/watchdog` 不存在（SoC 有 WDT，但只在 mboot 写 eMMC 时布防，且不用于回退） |
| BCB 非消费式 | 实测：重启后原样保留 |
| recovery 无远程入口 | 实测：`ro.debuggable=0`，adbd USB-only |

**所以：任何"改启动路径"的尝试，失败都需要一次物理介入（断电 或 按遥控器）。**

### 真正的出路

让**内核自己在极早期清掉 BCB**。这样即使后续全都挂了，重启也会回到原厂 boot：

```
内核启动 → setup_arch（DTB/memory/timer）→ 【在这里写 misc 清 command】→ 继续启动
                        ↑ 只要走到这里，就已经安全了
```

前置条件是**能在内核里写 eMMC**。而这本来就是主线移植的必做项（`mstar_mci_v5.c`，
14 367 行，驱动侧只有 2 处错误，估工 1–2 周）。

**它不是"额外成本"，而是把"必做项"提前——提前之后，整个测试才变得可反复。**

### 在此之前能做什么（全部零风险）

1. 把 misc / dtb / boot 头 / recovery 头全部备份到本地 —— **已完成**
2. 验证 BCB 写入与恢复 —— **已完成**
3. 离线把 DTB 校到最严（`dtc` + 手工核对 memory/timer/uart）
4. 写 eMMC 最小写路径，**先在厂商内核里用 `insmod` 验证**（厂商内核在跑，出问题重启即可）

## 九、待办

- [ ] 验证 U 盘自动刷机（官方 BIN 放 U 盘根目录，断电重上电，看是否自动进入升级）
- [ ] 确认 "Env Partition" 的具体分区名（`_write_env failed : can not find Env Partition(%s)` 里的 `%s`）
- [ ] 反汇编 `get_boot_status_from_mtd0` 拿到 mtd0 偏移（需要先重建 ARM 符号表，成本较高，优先级低）
- [ ] 把 `mboot-part-full-2026-11-17.bin`（5 MB）与 `misc-part-full-2026-11-17.bin`（8 MB）留档
- [ ] **写 eMMC 最小写路径，先进厂商内核验证，再放进主线 early init**
- [ ] 固化成工具：`tools/device/set-bcb.sh`（整块写 + md5 校验 + 自动恢复）
