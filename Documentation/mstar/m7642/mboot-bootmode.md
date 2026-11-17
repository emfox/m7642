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

## 七、待办

- [ ] 验证 U 盘自动刷机（官方 BIN 放 U 盘根目录，断电重上电，看是否自动进入升级）
- [ ] 确认 "Env Partition" 的具体分区名（`_write_env failed : can not find Env Partition(%s)` 里的 `%s`）
- [ ] 反汇编 `get_boot_status_from_mtd0` 拿到 mtd0 偏移（需要先重建 ARM 符号表，成本较高，优先级低）
- [ ] 把 `mboot-part-full-2026-11-17.bin`（5 MB）留档，将来恢复时作对照
