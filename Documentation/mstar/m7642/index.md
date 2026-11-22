# m7642 文档索引

按子系统一篇。每篇的体例固定：**结论 → 证据 → 对主线的意义 → 待办**。
拿不到证据的一律写"待确认"，不写推测当结论。

## 🔴 必读四件（新接手 / 隔了很久回来，按这个顺序）

| 顺序 | 文件 | 为什么必读 |
|---|---|---|
| 0 | [HANDOFF.md](HANDOFF.md) | **交接单**：当前状态、已否定清单、下一步第一个动作、协作约定。换对话/换人从这里开始。 |
| 1 | [discipline.md](discipline.md) | **纪律**。每条都是付过代价换来的：判读 / 赌注 / 观测 / 构建 / 本机环境。不读会重犯。 |
| 2 | [confirmed-facts.md](confirmed-facts.md) | **确证事实**（分 实测 / 对照 / 推测）+ **§H 已否定的假设**。不读会重走死路。 |
| 3 | [paths.md](paths.md) | **路径清单**。代码树、产物、脚本、备份、设备地址各在哪。 |

**当前主线只有一件事**：定位 7.3/4.19 在 mboot 交接之后卡在哪一级。

⚠️ **颜色判据已作废，别再用屏幕定等级。** 面板只读每 32 位字的低 16 位、且屏幕内容与
mboot/GPU 竞争（谁最后写赢随机），项目在 2026-11-18 就把判据改成了"设备是否卡死"。
来龙去脉见 [display.md](display.md) §九。

⟹ 上手前读 [wdt-beacon.md](wdt-beacon.md) **§十三～§十五**：**pstore/pmsg 通道已端到端打通**
（往 `0x419c0000` 写 `sig/start/size + data` 记录头，同一次启动内就被导出成
`/sys/fs/pstore/pmsg-ramoops-0`，`od` 一个文件即可读），它已经取代早先「DDR 标记
`0x43300000` + probeRW」那一套。设备的当前实际状态与下一步第一动作看 [HANDOFF.md](HANDOFF.md)。
刷入 / 回滚 / 救砖仍看 [rung419-runbook.md](rung419-runbook.md)（但其中的颜色判读表已过时）。

**做完任何一次实验都要更新**：`confirmed-facts.md`（新事实）、本文件（新文档）、
工作区 `.workbuddy/memory/MEMORY.md`（只动"下一步该干什么"那部分）。

## 专题文档

| 文档 | 内容 |
|---|---|
| [hardware.md](hardware.md) | 这台机器上有什么硬件、主线认不认（14 项清单） |
| [upstreaming.md](upstreaming.md) | 每一块最后落到主线哪个目录（按子系统，不按设备） |
| [portability.md](portability.md) | 各驱动的离线编译移植成本评分（v7.3 + GCC 13.3） |
| [roadmap.md](roadmap.md) | 阶段划分与估工 |
| [display.md](display.md) | 面板怎么亮：GOP 寄存器探测 + simplefb 路线 |
| [uart.md](uart.md) | 串口：基址、8 字节寄存器步距、中断号（零驱动工作） |
| [gop-registers.md](gop-registers.md) | GOP 全量寄存器图、黄金基线、易变寄存器 |
| [usb.md](usb.md) | USB 寄存器地图（四路基址、16 位拼接访问器） |
| [usb-phy.md](usb-phy.md) | UTMI 上电序列：活体 vs m7322 源码对照 |
| [hdmi.md](hdmi.md) | HDMI RX/TX 盘点（两条链路都零源码） |
| [smp.md](smp.md) | 多核启动协议（非标准 spin-table） |
| [remote-testing.md](remote-testing.md) | 不插 U 盘、不按键的远程验证路径 |
| [ir-and-recovery.md](ir-and-recovery.md) | 红外救不了砖（解码在内核里）、mboot 的启动模式与远程恢复边界 |
| [mboot-bootmode.md](mboot-bootmode.md) | mboot 镜像结构、内置 env、`update_mode` 命令，以及为什么没有纯软件救砖路径 |
| [emmc.md](emmc.md) | eMMC 移植：FCIE 寄存器全表、五个依赖的解法、`while(1)` 版本门槛、P1 已编译通过 |
| [ramoops.md](ramoops.md) | 跨崩溃日志通道：地址落在内存洞反而不用改 DTB、`CON_PRINTBUFFER` 回灌、覆盖范围与盲区 |
| [recovery-stick.md](recovery-stick.md) | 自建 U 盘升级 BIN：格式实测、`mmc write.p`、救援盘与测试盘的脚本路线 |
| [flash-and-recovery.md](flash-and-recovery.md) | 怎么刷、怎么退：官方 32 字节容器版式、五张盘的分工、框架缓冲信标 |
| [pm51-standby.md](pm51-standby.md) | 待机是 PM51 硬件状态机：关机=交权给 MCU、红外电源键由 MCU 解码 |
| [online-test-ladder.md](online-test-ladder.md) | 在线验证的阶梯：从空模块到真探针 |
| [rung419-runbook.md](rung419-runbook.md) | **4.19 上机操作卡**：三级颜色判读、刷入、回滚、救砖 |
| [wdt-beacon.md](wdt-beacon.md) | ⚠️ **WDT 自动复位已否证（2026-11-21 实测，见 §34.13）**；本文保留作为 pstore/pmsg 通道与 boot 槽读数通道的记录 |
| [factory49-entry.md](factory49-entry.md) | 原厂 4.9 入口 `+0xFA0000` 判读卡、段界表、厂值 cmdline |
| [misc-bcb-readout.md](misc-bcb-readout.md) | BCB 布局与实测（`boot-recovery` 非消费式） |

> **早期原始记录不在仓库里**：`boot-test.md`（5600 行的启动路径研究日志）、
> `ladder6`–`ladder9-readout.md`（已作废的颜色判据读out）已移出，见
> [paths.md](paths.md) §0。它们的结论都已并入 `confirmed-facts.md`、
> `factory49-entry.md`、`display.md`。

| [prior-art.md](prior-art.md) | **同类案例与官方契约**：无串口时别人用什么信标（含我们已否证的两条）、ARM 板接屏的接口族、`simple-framebuffer` / `simpledrm` 绑定硬条款 |

## 可背下来的几条

1. **刷机限制在脚本区 CRC**：`.bin` 尾部 24 字节 = `16×0xFF + "12345678" + crc32(前 0x4000)`；
   分区镜像本身无签名（`verifiedbootstate=orange`）。工具 `fw/fix_footer_crc.py`。
2. **显示不用重做时序**：cmdline 有 `recovery_fbaddr=0x2D100000`，面板与 tcon 都是 bootloader 做完了；
   `grep -i tcon /proc/kallsyms` 零命中就是证据。
3. **USB 块是 16 位寄存器**，32 位 EHCI 寄存器由两个半字拼成（低半字 `2*off`、高半字 `2*off+4`）。
   主线 `ehci-platform` 不能直接替换，要补访问器。MT7663 那一路 = `pm+0x2600`。
4. **SMP 不是标准 spin-table**：release 寄存器在 `pm + 2*cpu-release-addr`，是 3 字邮箱 + ack。
   P0 单核即可。
5. **HDMI 零源码**：GPL 包里 `drv/hdmitx4vx1/` 只剩一个 Kconfig；HDCP 是硬件引擎 + OTP 密钥。
6. **串口不用写驱动**：`0x1F201300`，寄存器步距 8 字节（`reg-shift = <3>`），SPI 0，123 MHz。
   厂商把 8250 偏移翻倍再 `<<2`，净值就是标准 8250 —— 见 `uart.md`。
7. **eMMC 不用重写驱动**：`mstar_mci_v5.c` 本来就是 `mmc_host` 框架驱动，只实现 5 个回调。
   中断/时钟/异步 IO 三个私有依赖**在源码里都有「关掉」的编译开关**，关掉就退化成纯寄存器轮询。
   已搬进 7.3 并全内核链接通过，**改动约 94 行** —— 见 `emmc.md`。
8. **ramoops 能抓到早期日志，但抓不到"没进内核"**：`0x42300000` 落在内存洞里，
   没有 `struct page`，于是自动走 `request_mem_region()` + `ioremap_wc()` ——
   **不用改 memory 节点、不用 reserved-memory**。`CON_PRINTBUFFER` 会在
   `postcore_initcall` 时把 128 KB `log_buf` 整体回灌，所以 `setup_arch` 阶段的
   日志也能捞回来。盲区只有"连第 2 级 initcall 都没跑到" —— 见 `ramoops.md`。
9. **文字通道的唯一官方路径是 `simple-framebuffer`**：7.3 用 `CONFIG_DRM_SIMPLEDRM`（已从
   `drm/tiny/` 搬到 `drm/sysfb/`），4.19 用 `CONFIG_FB_SIMPLE`，两者**互斥**、DT 写法**相同**。
   节点必须在 `/chosen` 下（2026-11-20 已从根节点移过去）；`stdout-path` **保持指向串口**
   （`earlycon` 靠它推断），fbcon 靠 bootargs 的 `console=tty0`。
   4.19 当前 `FB_SIMPLE` 未开，**且开了也没用**——4.19 只吃外部厂值 DTB，里面没有该节点。
   见 `prior-art.md` §三、§5.1。

10. **有可用的探针读数通道了**（2026-11-21）：boot 槽 `code1` 探针写普通 DDR
    （`0x23080000`–`0x230F0000` 八页，每条 64 B）然后返回 `0xFA0000`，Android 起来后
    `probeRW op=r` 直读。不依赖屏幕 / pstore / DDR 跨复位。见 `confirmed-facts.md` §I、
    `wdt-beacon.md` §十六。切 `0x419c0000`（ramoops）会挂——那块从没被写成过。

## 在线实验纪律

全部搬到 [discipline.md](discipline.md)，那里按「判读 / 赌注 / 观测 / 构建 / 本机环境」分类并写了代价。
**这里只留最危险的三条**（这三条各自单独造成过一次电视重启或一次救砖）：

1. **禁止 MMIO 盲扫。** 厂商块里有未实现空洞，读到就 external abort，arm64 直接 panic。
2. **「挂了就 `adb reboot`」是错的。** boot / recovery 都是单向车道，挂了就没 adb，只能 U 盘救砖。
3. **`boottest.sh arm` 只许执行一次。** 它会把自己写的镜像当厂值备份，第二次就永久失去回滚能力。
