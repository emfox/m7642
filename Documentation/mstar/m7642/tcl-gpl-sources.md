# 网上借鉴：TCL 官方 GPL 源码与同平台资料

日期：2026-11-18 凌晨
背景：主线内核在 mboot 交接处卡住（详见 `boot-test.md` 第二十二～二十四节），
按「先找前人工作、别埋头硬试」的原则做的一轮外部调研。

## 一、★ TCL 官方 GPL 内核源码（github.com/TCLOpenSource）

TCL 遵守 GPL 公开了 TV 内核源码，**17 个仓库，全部是 arm64 TV SoC 内核**：

| 仓库 | 对应机型/芯片 | Android | Kernel |
|---|---|---|---|
| `mt9653` | C11G/C78G/C12G/X11G/Q10G… | R | **5.4.190** |
| `mt9653ftv` | 55QM64L 等 | U | 5.15.167 |
| `mt9655` | Q9L/T7L/Q10L… | U | 5.15.148 |
| `mt9618` | 65QM851G 等 | U | 5.15.180 |
| `mt9221` / `mt9221U` | S65A/S615/S5205… | R / U | 4.19.116 / 5.15.144 |
| `tc8000` | P12G 系列 | R | 5.15.78 |
| `T982` | 商显 | T | 5.15.78 |
| `rt2881` / `rt2875p` / `rt2851a` / `rt2851mr` / `rtk2841` | 各低端 | — | 4.4 ~ 5.15 |
| `a311d2` | 商显 V60Pro | R | 5.4.125 |

**注意：没有 mt9652 / mt5888。** 但这台机器的板级串是
`Board=MT167B_10AT_MT5888_M7642_CUS19`，与 `mt9653`（MStar 代号 **M7332**）
同属 MTK TV 平台（MStar 血统），可直接借鉴。

### 1. mt5870_defconfig（对应 MT9653）的关键项

```
CONFIG_ARCH_MSTAR=y
CONFIG_MSTAR_M7332=y            ← MStar 芯片代号
CONFIG_MSTAR_CHIP_TYPE=0
CONFIG_ARM64_VA_BITS=39          ← 与我们改后一致
CONFIG_ARM64_PA_BITS=48
CONFIG_ARM64_4K_PAGES=y
CONFIG_ARM64_PAN=y
CONFIG_ARM64_VHE=y               ← A73 不支持，但也没坏处
CONFIG_ARM_PSCI_FW=y             ← TCL 用 PSCI！不是 DTB 里的 mstar-spin-table
CONFIG_ARM_GIC=y / ARM_GIC_V3=y / ARM_GIC_V3_ITS=y
CONFIG_NR_CPUS=4
CONFIG_SERIAL_8250=y / SERIAL_8250_CONSOLE=y / SERIAL_8250_MTK_TV=y
CONFIG_MTK_TV_IR_IN=m / MTK_TV_IR_DYNAMIC_CONFIG=m
CONFIG_MTK_TV_IR_CONFIG_PATH="/config/ir_config.ini"
CONFIG_ARM64_ERRATUM_843419=y / 1024718=y
CONFIG_EFI=y / EFI_STUB=y
```

**整份 config 里没有 `CONFIG_RELOCATABLE`** —— TCL 的 TV 内核是**非重定位**的。

### 2. ★ `arch/arm64/Makefile` 第 119 行

```
TEXT_OFFSET := 0x00080000
```

TCL 的 5.4 内核**硬编码 TEXT_OFFSET = 0x80000**，与原厂 4.9 内核的
boot image 头 `text_offset = 0x80000` 完全对应。

而我们的主线 7.3 是 5.8+，`TEXT_OFFSET` 已被上游**彻底移除**，固定为 0，
链接在 `PHYS_OFFSET + 0`。**这是两类完全不同的内核布局。**

### 3. UART 地址（与我们的记录吻合）

`mt5870.dtsi`：

```dts
uart0: serial@1f201300 {
    compatible = "mediatek_tv,ns16550";
    reg = <0x0 0x1f201300 0 0x20>;
    current-speed = <115200>;
    clock-frequency = <123000000>;
    reg-shift = <3>;
    interrupts = <0x0 0x0 0x4>;
};
uart1: serial@1f220C00 { ... interrupts = <0x0 0x27 0x4>; };
```

`0x1f201300` 与本地文档里记录的 UART0 基址**完全一致** —— 说明两个 SoC 的
串口 IP 相同，接串口的话参数是确定的：

```
基址 0x1f201300  115200 8N1  reg-shift=3（每次访问 8 字节步进）  clk 123 MHz
```

### 4. 内存布局（mt5870_mmap.dtsi）

```dts
MI_MBOOT_MEM_USAGE: reg = <0x0 0x27400000 0x0 0x02400000>;   ← mboot 自查保留 36MB
MI_DISP_PHOTO_BUF:  reg = <0x0 0x27400000 0x0 0x04000000>;
EMAC_MEM:           reg = <0x0 0x3DF00000 0x0 0x00100000>;
MI_CACHED_POOL:     reg = <0x0 0x3E000000 0x0 0x00080000>;
```

`MI_MBOOT_MEM_USAGE` 从 `0x27400000` 起 36 MB —— 正是 mboot 自己的加载地址
（与本机 `mboot.raw` 头部的 `0x27400000` 一致）。**内核加载地址 0x20280000
在那之下，不冲突。**

### 5. 驱动目录

`drivers/gpu/drm/mediatek/` 里有 `MTK_TV/` 子目录和完整的
`mtk_hdmi*.c`、`mtk_dsi.c`、`mtk_mipi_tx.c`、`mtk_drm_*`，
`drivers/misc/mediatek/` 有 46 个子系统。

`drivers/mstar/` 和 `drivers/mtk_tv/` **不存在**（404），说明 MStar 的 TV 应用层
驱动放在了别处（`CONFIG_MTK_TV_IR_*` 对应的源码位置待查）。

## 二、MBoot 官方用户手册（2011 年版 PDF，36 页）

来源：`https://cdn.hackaday.io/files/1929198253846496/Introduction-to-MBoot.pdf`
（MStar 的 MBoot User Guide，讲的是 u-boot-1.1.6 / 2011.06 的 MIPS 平台，
但架构和命令体系与 ARM 版一致）

### 启动链（4.3 Auto boot sequence）

```
bootcmd = nand read.e 81000000 KL 300000; bootm 81000000;
  1. 从 flash 读内核镜像
  2. do_bootm():
       从 0x81000000 读 image header
       算出数据真实地址（entry - header offset）
       解压到 hdr->ih_load
       （MIPS 版还会 "Read MStar bin via cpmsbin"）
  3. do_bootm_linux():
       取入口点 hdr->ih_ep
       初始化 linux 参数（bootargs 放进 boot parameters section）
       初始化内存大小 / initrd / flash 参数
       跳到入口点
```

### 三个可注入点（5.2）

```
MstarDrvInit → MstarProcess → Detect "enter" key
                                 ├─ 有 enter 键 → U-Boot console
                                 └─ 无 → MstarToKernel → Jump to kernel
```

注册命令用 `Add_Command_Table(name, maxargs, STAGE_xxx)`，
注册点分 `Core_` / `App_` / `Customer_` 三类。

### 环境变量（4.5）

```
bootcmd        最后执行的命令，通常 bring up 内核
bootargs       传给内核的参数，格式 e.g.
               console=ttyS0,115200 ... LX_MEM=0x2000000 EMAC_MEM=0x100000
               DRAM_LEN=0x10000000 LX_MEM2=0x66381000,0x1C00000
bootdelay      等几秒再执行 bootcmd
UARTOnOff      ★ UART 开关，默认 on。被关掉的话串口也不会有输出
```

**`LX_MEM=基址` 就是 `E_LX_MEM_ADR` 那个变量的来源**（SigmaStar/MStar 的
MMAP 机制：Linux 可用内存区叫 LX_MEM，可以有多块 LX_MEM2/3）。

## 三、linux-chenxing（MStar/SigmaStar mainline 社区）

`https://linux-chenxing.org/` —— 目前**唯一**在做 MStar mainline 的社区，
但专注 IP camera SoC：

```
infinity1 / infinity2m / infinity3 / infinity5 / infinity6 / infinity6b0
mercury5 / mercury6 / pioneer3
MIPS 时代: Titania4 / Milan / Marlon / Kronus / Kappa / Kirin / K5AP
32 位 ARM: Messi(MSD6A338S) / Nike / Madison / Edison / Napoli / Cedric
MediaTek 血统条目: MT53xx / MSD6886 / MT9255(MSD368)
```

**没有 MT9652 / MT5888 / m7642 / 任何 TV SoC。**
⟹ **这台机器的主线移植没有前人做过**，我们是在无人区。

不过它的方法论可以照抄（记录 SoC、BROM 签名、UART 探测、SDK 提取）。

## 四、★ mboot 命令表 131 条（本次新解析）

命令表项 0x1c 字节。除已知的 `bootm`/`filepartload` 外，本次新发现：

### 与「内核/分区保护」直接相关

```
kernelProtect       - Protect kernel
kernelProtectBist   - Protect kernel bist
dont_overwrite_init / do_dont_overwrite / do_dont_overwrite_free
dont_overwrite_switch  "This cmd is used to disable dont_overwrite function."
force_overwrite / force_overwrite_init / get_force_overwrite_flag
「dont_overwrite force disable」/「dont_overwrite force enable」
「force_overwrite_count %d」
「This serial apis are for protecting the specific partitions are overwrited. ex: customer」
```

⟹ **mboot 有一套分区写保护名单**，`dont_overwrite force disable` 是关掉它的开关。
这**很可能就是自建升级包「进度条走完但 recovery 一个字节没变」的原因**。

### 与内存映射相关

```
get_mmap -l                 列出 mmap 里所有 ID
get_mmap E_MMAP_ID_COMPROCESSOR
sync_mmap                   do_sync_mmap_to_env
「setenv sync_mmap 1;saveenv」
「no env 'sync_mmap'」
_get_mmap / get_mmap_range_by_id
```

### 与刷机/交互模式相关

```
fastboot                    enter fastboot mode
usbboot / usb / spi2usb
update_mode
checkUsbModeSwitch
checkVersion / checktee / qhb_check
cleanallenv
```

## 五、bootm 失败后的行为（反汇编确认）

`bootm` → `0x27497de4 (bootm_load_os)` → `0x2741c470` 判返回值 →
非零则调 `0x27474880`：

```asm
0x274748c4  bl  0x2743e8fc          ; 取某个时间戳/计数
0x274748c8  mov r6, #0x50           ; 80
0x274748d8  bl  printf(...)         ; 打印一条消息
0x274748dc  mov r0, #9  / #0x12 / #0x72('r') / #0x65('e')
0x274748e8  mov r0, #0x3e8 (1000)
0x274748ec  bl  0x274b9cb0          ; mdelay
0x274748f0  subs r6, r6, #1
0x274748f4  bhs 0x274748e8          ; 循环 80 次 = 80 秒
...        然后继续走一段 GPIO/电源序列
```

⟹ **`bootm` 失败后 mboot 会先等 80 秒，再走关机/待机流程。**
所以「卡在 logo」这个观察里，前 80 秒设备其实还在 mboot 里，
之后可能自己黑屏关机 —— 这一点此前每次实验都因等待时间不足而没有观察到。

## 五之二、★ 新发现：boot check、WDT 重启、eMMC 校验

第二轮挖字符串，得到一组此前完全没注意的机制：

### boot check 与看门狗

```
0x2861b2  do_bootcheck
0x285e6b  do_qhb_check          /  set_qhb_flag
0x2887bc  do_wdt_enable
0x2924f9  "Boot Check: Reboot by WDT --------"
0x292aaa  "MBoot will reset within 10s, if you don't want to reset,
           please run wdt_enable 0!!"
0x292afe  "wdt_enable 10"   /  0x292b0c "wdt_enable 0"
0x299cd5  "wdt_enable n - set Watchdog timer to n secs"
0x2a2ea3  "[QHB] prepare to CLEAR QHB" / "[QHB] prepare to ENTER QHB"
0x2a2e66  "[QHB] PowerOnMode = %d, u4BootCtrl = 0x%08x, fgStateOn = %d"
```

⟹ **mboot 在若干失败点会启用 WDT 并在 10 秒（或 80 秒）后复位。**

**这直接影响对「卡 logo」的判读**：如果 boot check 失败走了 WDT 路径，设备其实在
**反复重启**，屏幕每次重新画出同一个 logo，看起来就像"卡死"。

判据（不需要刷机）：

- 设备"卡 logo"时，**每隔 10～80 秒**重新闪一次 logo / HDMI 短暂断一下 / U 盘灯闪
  ⟹ 是 WDT 循环；
- 彻底静止、毫无周期 ⟹ mboot 停在了更早的某个死循环（例如 `lx address` 那个 `b .`）。

### eMMC boot 分区校验

```
0x2a03e0  "eMMC Rom boot checksum:%xh misatch read boot partition checksum:%xh !!"
```

⟹ mboot 会比对 **eMMC ROM boot 记录的 checksum** 与 **实际读到的 boot 分区 checksum**。
这解释了为什么 `mmcblk0boot0/1` 在 Android 里读出来全 0（加密/受保护），
也说明**boot area 不能随便写** —— 写了可能触发这条不匹配。

### 启动模式分支

```
0x292452  "usb upgrade fail , go to recovery"
0x292476  "boot to recovery mode"
0x29248d  "boot to normal mode"
0x2924a2  "disable dont overwrite function"  /  "setenv dont_overwrite"
0x2924d9  "enable dont overwrite function"
0x292539  "recovery_wipe_partition cache"
0x292578  "setenv UARTOnOff on"  /  0x29258c "Opening UART now"
0x2925a8  "setenv BootlogoFile /cache/boot0.jpg"
0x2925dc  "mmc erase.p misc"
```

这几条是同一个函数里的连续字符串，说明 **"USB 升级失败 → 转 recovery" 是一个
明确的代码分支**，`dont_overwrite` 也用 env 开关控制，`UARTOnOff on` 会被显式设置。

### 写保护的初始化方式

```
0x289b80  "artitionname] ([empty_skip]<0/1>)"
0x289ba2  "ex. auto_flash mmc write.p MBOOT"
0x289bc4  "dont_overwrite_init"
0x289bd8  "This serial apis are for protecting the specific partitions are
           overwrited. ex: customer"
0x289c31  "This cmd is used to init this function"
0x291700  "function of 'dont overwrite' is not enable"
```

⟹ `dont_overwrite_init <分区名> [<empty_skip>]` 需要**显式注册**才生效，
默认是 **not enable**。所以"自建包写不进 recovery"**不能**用写保护解释，
这条假设排除。

## 六、本轮的结论与优先级

### 已经能确定的事

1. **内核二进制本身健康**（QEMU 完整启动，见 boot-test.md 第二十四节）。
2. **mboot 不校验内核签名、不校验内容**（改 1 字节照样进 recovery）。
3. **这台机器的 mainline 没有任何前人工作**，只能自己啃。
4. **TCL 的 TV 内核是「非重定位 + TEXT_OFFSET=0x80000」**，
   而主线 5.8+ 移除了 TEXT_OFFSET、默认 RELOCATABLE —— 两类布局不同。

### 三条候选路径（按代价排序）

| 路径 | 代价 | 成功概率 |
|---|---|---|
| **0. 先判定「卡 logo」到底是静止还是 WDT 重启循环** | **零**（只需观察设备，不刷机） | 高（直接决定后面往哪查） |
| A. 升级脚本加 `wdt_enable 0` + `setenv no_compare_kernel_lx 1` | 一次 U 盘刷机 | 中 |
| B. 接 UART（`0x1f201300`，115200 8N1，reg-shift 3，clk 123 MHz） | 要拆机 | 高 |

**A 路径已降级**：原计划的「关掉 `RELOCATABLE`」被否掉了 ——
arm64 在 5.8 之后移除了 `TEXT_OFFSET`，非重定位内核的 `__pa_symbol` 恒等于
「相对镜像起点的偏移」，等价于要求镜像加载到**物理 0**。而本机 DRAM 从
`0x20200000` 起，物理 0 不存在，所以主线内核**必须**保持 `RELOCATABLE=y`。
（TCL 的 5.4 能不用它，是因为那时候 `TEXT_OFFSET` + `PAGE_OFFSET` 机制还在。）

### 下一步建议

先做 **0**（纯观察），再决定 A 还是 B。C 只剩串口。
