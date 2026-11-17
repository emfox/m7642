# M7642 硬件清单与主线内核支持度

2026-11-17，全部数据来自**运行中的这台电视**（`192.168.10.60:5555`），不是查资料推的。
证据文件：`dt/M7642-live.dts`（`/proc/device-tree` 反编译）、`dt/raw-devicetree.tar`、`device-config.gz`。

## 一、先看设备树：它不是硬件描述

| 项 | 值 |
|---|---|
| 根节点 | `compatible = "arm,foundation-aarch64", "arm,m7642"`，`model = "M7642"` |
| 节点总数 | 303 |
| `interrupts` 属性 | **162** |
| `reg` 属性 | **12** |
| `status` 属性 | 5 |

303 个节点里绝大多数只有 `compatible = "int_uart1"`、`interrupts = <0 0 0x4>` 这种内容，
本质是一张**中断号表**。真正带地址的只有：`cpus`(4×A73)、`memory@20200000`、
`interrupt-controller@16001000`、`mdla`、`keypad`、`spi@0x1003`、`ramoops@42300000`。

⟹ 设备**不是**从 DT 实例化的，是 `drivers/mstar2/` + mach 代码硬编码创建的
（这也是 4.9 内核必须有私有平台层的原因）。主线内核拿这棵 DT 什么都发现不了。

## 二、硬件清单（逐个带证据）

| # | 设备 | 设备上的证据 | 厂商驱动 | 主线支持 |
|---|---|---|---|---|
| 1 | CPU 4×Cortex-A73 | `compatible="arm,cortex-a73","arm,armv8"`；`enable-method="mstar-spin-table"` | — | A73 ✓，但 `mstar-spin-table` **非标准**（主线只有 `psci`/`spin-table`） |
| 2 | GIC-400 | `interrupt-controller@16001000`，`reg=0x16001000+0x16002000` | — | ✓ `arm,gic-400`（地址已拿到） |
| 3 | 架构定时器 | `armv8-timer` | — | ✓ |
| 4 | 串口 | `serial8250` + `CONFIG_SERIAL_8250_CONSOLE=y`，`console=ttyS0,115200` | 8250 通用，8 字节步距 | ✓ `8250_of` 直接可用：`0x1F201300` + `reg-shift=<3>`，见 `uart.md` |
| 5 | eMMC (BJTD4R) | `mmc0:0001 MMC_NAME=BJTD4R` | `mstar_mci` / `mstar_mci_v5.c`，`CONFIG_MMC_MSTAR_MMC_EMMC=y` | ✗ **非 sdhci、非 dw_mmc**，私有寄存器 |
| 6 | I2C ×3 | `i2c-0/1/2` → "Mstar I2C adapter" | `Mstar-iic` | ✗ 私有；但 `CONFIG_I2C_ALGOBIT=y`，可用 `i2c-gpio` 绕 |
| 7 | 以太网 | `eth0`，platform driver `Mstar-emac` | `mdrv_emac_v3.c` | ✗ 非 stmmac/dwmac |
| 8 | USB | 4×EHCI，无 xHCI（只有 USB2.0） | `Mstar-ehci-1..4` | ⚠ 逻辑是标准 EHCI，但**寄存器 16 位拼接**（`ehci_readl` 被改），`ehci-platform` 不能直接用；基址/中断已实测（见 `usb.md`） |
| 9 | WiFi/BT | USB `0e8d:7663` MediaTek MT7663，挂在 `Mstar-ehci-3` | 联发科 out-of-tree | ✓ **主线 `mt76/mt7615/usb.c` 里有 `USB_DEVICE…(0x0e8d,0x7663)`**（≥5.12） |
| 10 | GPU | `Mali-G52 1 cores r1p0 0x7402` | `mali` r16p0（Bifrost） | ✓ panfrost `arm,mali-bifrost`（需 clock/power，私有 clkm ✗） |
| 11 | TV 调谐器 | platform driver `Mstar-Si2151` | Si2151 | ✗ 主线 `si2157` 只覆盖 2141/2146/2147/2148/2157/2158/2177，**不含 2151** |
| 12 | 显示链路 | `dc`/`dip`/`mspi`/`gop`/`frc`/`tcon` | `drivers/mstar2/drv/{graphic,gflip,hdmitx4vx1,fusion}` | ✗ 全私有 |
| 13 | 音频 | `MStar-MAD-No_00`、`voc_snd_card` | `Mstar-alsa`、`voc-*` | ✗ |
| 14 | 视频解码 | MAD/voc | `drivers/mstar2/drv/alsa_audio_driver` 等 | ✗ |
| 15 | 遥控/IR | platform driver `Mstar-ir` | `Mstar-ir` | ✗（可用 `gpio-ir` 替代，需 GPIO 与载波信息） |
| 16 | 电源/待机/DVFS | `Mstar-pm`、`Mstar-lp-standby`、`Mstar_DVFS` | — | ✗ |
| 17 | 面板 | cmdline `tcon_type_extend=ST6451D02-5`，`/vendor/tvconfig/config/PM.bin`、gamma.bin | 私有二进制 | ✗ |
| 18 | AI 加速器 | `mdla`，`compatible="mtk,mdla"`，`reg` 在 0x1f3e8000 附近 | `mtk_mdla` | ✗ |
| 19 | 键盘/ADC | `keypad`，`compatible="mtk,hq-keypad"` | `mtk-keypad` | ✗（MTK 私有变体） |

## 三、线上一句话结论

主线内核**能覆盖的恰好是不重要的那部分**：CPU/GIC/定时器/串口，外加两颗外挂芯片
（Mali-G52 走 panfrost、MT7663 走 mt76）和 EHCI。

**完全覆盖不了**的是：eMMC、I2C、以太网、显示、音频、视频解码、IR、电源，
以及所有让这台机器"是台电视"的东西（tcon/面板/DTV 解调）。

最致命的两条叠加：

1. eMMC 没驱动 ⟹ 挂不上根文件系统，只能 initramfs；
2. 显示没驱动 ⟹ 电视屏幕上永远是一片黑，连报错都看不到。

⟹ 想验证"主线能不能起来"，**必须先有串口**（板上有无 debug 排针是唯一未知项，
cmdline 用 `console=ttyS0,115200`，说明固件默认就往串口吐）。

## 四、要试的话，最小实验是这个

1. 手写一份 DTS：`cpus`（4×A73，`enable-method` 改成主线认的 `spin-table`）+ `memory@20200000`
   （size 0x8000000）+ `gic@16001000` + `armv8-timer` + `uart`（地址待查，见下）；
2. 用主线 6.x 编 `Image`，按 Android boot image 格式重打包（boot 分区里是 boot.img，不是裸 Image）；
3. U 盘 mboot 强刷（boot 分区在刷写表内，CRC 只覆盖脚本区，不覆盖镜像）；
4. 成败判据全在串口上：能看到 `Booting Linux` 就是成，能到 `Run /init as init process` 就是大成。

缺的只有一个数：**UART 的物理基址**。设备上 `/proc/tty/driver/serial` 是 `Permission denied`
（需要 root，而现在 `su` 只会返回 shell 身份，说明 `/factory/su` 那条路只在特定调用方式下生效）。
备选来源：`arch/arm/mach-m7642/` 的板级头文件（realme 4.19 树里有，属同一 SoC 家族），
或直接读 `/proc/iomem`（同样被 root 挡住）。

## 五、屏幕能不能不写驱动就亮？——能，捡 bootloader 的现成帧缓冲

用户不能接串口，所以"屏幕"成了唯一可观测通道。查了 cmdline 和厂商源码：

```
cmdline: recovery_fbaddr=0x2D100000
mdrv_graphic_io.c:800   early_param("recovery_fbaddr", MDrv_SYS_SetGraphicAddr);
mdrv_graphic_io.c:776   mstar_fb_fix.smem_start = recovery_addr;
```

意思是：**mboot 已经初始化好 tcon/面板，并把一块 1920×1080×32bpp 的显存固定放在 `0x2D100000`**，
内核只是被告知"别分配，直接用这块"。这正是 `simple-framebuffer` 的标准场景。

设备上实测对得上：

| 项 | 值 |
|---|---|
| `/sys/class/graphics/fb0/name` | MStar FB |
| `virtual_size` | 1920,1080 |
| `stride` | 7680（=1920×4，32bpp） |
| `bits_per_pixel` | 32 |
| 显存大小 | 1920×1080×4 = `0x7E9000` |

⟹ 主线内核只要在 DTS 里放一个 `simple-framebuffer@2d100000`（并把这段标 `no-map`），
**fbcon 就能直接把文字画在电视上**，一行显示驱动都不用写。
唯一前提是 bootloader 的显示初始化不被任何代码重置——而主线根本不会去碰 tcon。

骨架 DTS 见 `arch/arm64/boot/dts/mstar/m7642.dtsi` + `m7642-tcl-65s535d.dts`。

WiFi 这一半没这么幸运：MT7663 走 USB，主线 `mt76` 认这颗芯片，
但 USB 需要 EHCI 节点 + PHY/供电，而 MStar 的 PHY 初始化在私有 PM 块里。
⟹ 屏幕"很可能能亮"，WiFi 是"要先解决 USB 上电"，比屏幕难一档。

## 六、和上一轮结论的关系

上一轮说"L2 不可行"，结论不变，但理由现在更精确了：

- 不是"没有源码"，也不是"没有硬件资料"——**硬件清单我们已经拿到，GIC 地址都有**；
- 卡在**厂商私有控制器的驱动**上：eMMC 和显示这两条一断，即使内核能跑，也是个没有屏幕、没有磁盘的空壳。
- 所以"自编内核"的天花板不是 ABI 匹配，而是**你要自己重写 mstar_mci 和整套显示链路**——
  那是驱动开发项目，不是移植项目。
