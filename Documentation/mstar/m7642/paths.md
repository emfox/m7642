# 路径清单

> **本文件是必读**（找不到东西时先看这里）。
> 纪律在 [discipline.md](discipline.md)，事实在 [confirmed-facts.md](confirmed-facts.md)。

## 1 代码仓库

| 路径 | 是什么 | 备注 |
|---|---|---|
| `~/Debian/m7642/` | **本项目主仓库**（git，分支 `master`，**无远端**，本地历史） | 文档 / 补丁 / 探针 / 主机侧工具 / 刷机包工具 |
| `~/kbuild/linux-main/` | **7.3 编译树**（Linux 7.3.0） | 只用于编译，不在这里写文档 |
| `~/kbuild/tcl-419/` | **4.19 工作副本**（官方 fork） | 编译入口见 §3 |
| `~/kbuild/tcl-src/` | 4.19 **原树**（未改动，对照用） | 被 `mstarKernelRelease.sh` 剥掉了 `mstar2/` |
| `~/kbuild/toolchain-gcc13/bin/` | 交叉工具链 `aarch64-buildroot-linux-gnu-*` | `objdump` / `gcc` / `ld` |
| `~/Debian/tv/adb/platform-tools/adb` | 专用 adb（**不要用系统的**） | 各脚本里的 `ADB=` 默认值 |

⚠️ **DTS 有三份副本，已经不同步（2026-11-20 发现）**。改之前先确认改的是哪一份：

| 副本 | 状态 | 差异 |
|---|---|---|
| `~/kbuild/linux-main/arch/arm64/boot/dts/mstar/` | **权威**（最新） | 含 `ttyS0` 双控制台、`ramoops.*` 四个参数、reserved-memory **无** `no-map`、`framebuffer@2d100000` 已在 `/chosen` 下 |
| `~/Debian/m7642/arch/arm64/boot/dts/mstar/` | 快照，**落后** | bootargs 缺 `ttyS0`/`ramoops`；节点仍在根下 |
| `~/Debian/m7642/patches/0003-arm64-mstar-platform-and-dts.patch` | 上游化草稿，**最旧** | bootargs 只有 `console=tty0 earlycon ignore_loglevel maxcpus=1`；reserved-memory 仍带 `no-map`；节点在根下 |

**构建只用编译树那份。** 仓库副本与 patch 草稿的差异是有历史的（去掉 `no-map` 是因为
bring-up beacon 要经线性映射写），不要拿它们当构建源。

**上游仓库**

- 4.19 来源：`github.com/Thedemon007/realme_Smart_TV_4K-kernel-source`（fork realme，GPL，`master`）
- 同型号参考：`shenzong168/android_device_tcl_tcl_m7642`（TWRP 仓库同源，`prebuilt/kernel` 同型号）
- TCL 官方开源：TCLOpenSource 17 个仓库**全不合用**（MTK 血统）

## 2 文档地图

全部在 `~/Debian/m7642/Documentation/mstar/m7642/`。

**入口三件（必读，按顺序）**

| 文件 | 内容 |
|---|---|
| [index.md](index.md) | 总索引 + 可背下来的结论 + 阅读顺序 |
| [discipline.md](discipline.md) | **纪律**：判读 / 赌注 / 观测 / 构建 / 环境 |
| [confirmed-facts.md](confirmed-facts.md) | **确证事实**（分 实测/对照/推测）+ 已否定的假设 |

**当前主线（4.19 验证）**

| 文件 | 内容 |
|---|---|
| [rung419-runbook.md](rung419-runbook.md) | **4.19 上机操作卡**：三种颜色判读、刷入、回滚、救砖 |
| [factory49-entry.md](factory49-entry.md) | 原厂 4.9 入口 `+0xFA0000` 判读卡、段界表、厂值 cmdline §9 |

**启动路径与验证读out**

| 文件 | 内容 |
|---|---|
| [ladder6-readout.md](ladder6-readout.md) ~ [ladder9-readout.md](ladder9-readout.md) | 第 6–9 次梯级的实测读out |
| [boot-test.md](boot-test.md) | 启动路径、boot image 参数、分区、可观察性（最大的一份） |
| [online-test-ladder.md](online-test-ladder.md) | 在线验证的阶梯：从空模块到真探针 |
| [remote-testing.md](remote-testing.md) | 不插 U 盘、不按键的远程验证路径 |
| [ramoops.md](ramoops.md) | 跨崩溃日志通道、覆盖范围与盲区 |

**刷机与恢复**（动手前必读）

| 文件 | 内容 |
|---|---|
| [flash-and-recovery.md](flash-and-recovery.md) | 32 字节容器版式、五张盘的分工、刷与退 |
| [mboot-bootmode.md](mboot-bootmode.md) | mboot 镜像结构、内置 env、为什么没有纯软件救砖路径 |
| [mboot-env.md](mboot-env.md) | env 分区改法（偏移、CRC、两份） |
| [misc-bcb-readout.md](misc-bcb-readout.md) | BCB 布局与实测 |
| [recovery-stick.md](recovery-stick.md) | 自建 U 盘升级 BIN |
| [ir-and-recovery.md](ir-and-recovery.md) | 红外救不了砖、远程恢复的边界 |
| [pm51-standby.md](pm51-standby.md) | 待机是 PM51 硬件状态机、硬断电风险 |

**子系统**

`hardware.md`（14 项清单）· `upstreaming.md`（落主线哪个目录）· `portability.md`（离线移植成本评分）·
`roadmap.md`（阶段与估工）· `display.md` + `gop-registers.md`（GOP 寄存器与 simplefb）·
`uart.md`（`0x1F201300`、步距 8）· `usb.md` + `usb-phy.md`（16 位访问器）· `hdmi.md`（零源码）·
`smp.md`（非标准 spin-table）· `emmc.md`（FCIE、94 行改动）· `tcl-gpl-sources.md`（GPL 包盘点）

## 3 脚本

**7.3 构建**

| 路径 | 用途 |
|---|---|
| `~/Debian/m7642/tools/build-mstar-kernel.sh` | **7.3 唯一编译入口**（`KERNEL=~/kbuild/linux-main`） |
| `~/Debian/m7642/probes/ladder/{ladder.S,build.sh}` | 刷屏 blob 源码与构建（`-DCOLOUR= -DSTEP= -DHALT=`） |
| `~/Debian/m7642/probes/ladder/{blue,yellow}.bin` | 已构建的 288 B blob（蓝 `0xcccc` / 黄 `0xffe0`） |

**4.19 构建**

| 路径 | 用途 |
|---|---|
| `~/kbuild/tcl419-build.sh` | 编译（内建执行位修复 + 4 次重试 + `-fcommon`） |
| `~/kbuild/tcl419-clean.sh` | 清成"从未编译"状态（`.o`/`.a`/`.cmd` 一起清） |
| `~/Debian/m7642/tools/host/mk-rung-419.py` | 打三级检查点并包成 recovery 槽镜像 |

**设备操作**

| 路径 | 用途 |
|---|---|
| `~/Debian/m7642/tools/host/boottest.sh` | `show` / `arm` / `disarm` / `reboot`（**arm 只许一次**） |
| `~/kbuild/tvrun.sh <脚本>` | 通过 `tvroot` 服务以 root 跑本地脚本 |
| `~/kbuild/wait-dmesg.sh <tag>` | 抓启动 dmesg（按 `uptime` 归零判断，9 秒内） |
| `~/kbuild/precheck.sh` | 刷前**只读**前置检查 |
| `~/Debian/m7642/tools/host/read-ladder.sh` | 读梯级结果 |
| `~/Debian/m7642/tools/host/{gop-snap,gop-diff,gop-volatile}.sh` | GOP 寄存器快照 / 差分 |
| `~/Debian/m7642/tools/host/{mbdis,mboot-an}.py` | mboot 反汇编 / 分析 |
| `~/Debian/m7642/tools/host/{mk-ladder,mk-entry,mk-tramp,mk-pstub}.py` | 各种注入器（历史） |
| `~/kbuild/scan5555.sh` | 扫本网段哪台机器开着 adb 端口 |
| `tools/host/tvpower.sh` | **红外按电源**（走米家云 → 小爱音箱）：`status` / `on` / `off`。默认拒绝在 Android 运行态按（那是硬断电） |

**刷机包**

`~/Debian/m7642/fw/fix_footer_crc.py`（重算 trailer CRC）· `mstarbin.py` · `kernelver.py` ·
`patch_bin.py` · `ext4write.py` · `make_rescue_norecovery.py`

## 4 产物与备份

| 路径 | 是什么 | 校验 |
|---|---|---|
| `~/kbuild/m7642-out/m7642-419-rung0.img` | **待上机的 4.19 三级检查点镜像** | 21,618,688 B · md5 `c8bca13a1935bbcbd9a45833bda67885` |
| `~/kbuild/tcl-419/arch/arm64/boot/Image` | 4.19 裸内核 | 13,892,096 B · `image_size 0xDC2000` |
| `~/kbuild/rec/recovery_full.bin` | **厂值 recovery 全槽 32 MB 备份** | 前 21,618,688 B 的 md5 = `0f6e1705f077935e1c3018973e658bfa` |
| `~/kbuild/diag/env*.bin` | mboot env 分区备份（两份各 64 KB） | — |
| `~/kbuild/boot-stock-backup.bin` | 厂值 boot 备份 | — |
| `~/kbuild/dmesg-{warm1,cold1,after-boot}.txt` | 启动日志缓存池 | — |
| `~/kbuild/m7642-out/` | 历史实验镜像（`_b.bin` `_f.bin` `_g.bin` 等） | — |

**设备侧**

- `/data/local/tmp/rec.head.bin` — 槽回滚备份（**arm 一次后才有，且只在那时是厂值**）
- `/data/local/tmp/misc.head.bin` — misc 首块备份
- `/data/local/tmp/tvroot.cmd` — 提权命令通道
- `/data/local/tmp/*.out` — `tvrun.sh` 的输出
- `/sys/fs/pstore/console-ramoops` — 崩溃日志（**Android init 启动时清，要快**）

## 5 设备

- 网络 adb：**`192.168.10.60:5555`**（历史值；换网络后必须先确认可达）
- 本机换网段后怎么找：`~/kbuild/scan5555.sh` 扫当前 `/22`，或 `adb mdns services`
- `ro.build.fingerprint` = `tcl/tcl_m7642/…:PPR2.180905.006.A1/…:user/dev-keys`

## 6 红外按键通道（2026-11-21 打通）

设备在米家里是一个**云红外遥控**（卡片叫「电视」），实际发射器是 **小爱音箱**。

| 项 | 值 |
|---|---|
| 遥控 | `电视` · 型号 `miir.tv.ir01` · matchid 10982 · 58 个键 |
| 电源键名 | **`POWER`**（另有 `VOL+/-` `CH+/-` `OK` `MENU` 等） |
| 发射器 | `xiaomi.wifispeaker.oh2p`（另一台 `lx06`） |
| 工具 | `mihome-ctl`（`~/.local/bin`，uv 安装）——扫码登录一次，会话存 `~/.local/state/mihome-ctl/`（0600）|
| 命令 | `mihome-ctl ir-send --remote 电视 --key POWER [--repeat N]` |
| 封装 | `tools/host/tvpower.sh {status|on|off}`，**必须跑在主机侧**（沙箱对状态目录只读） |

实测延迟：按下 → 进待机 ≤10 s；待机中按下 → adb 可用 **24 s**。

⚠️ **纪律**：Android 运行态按电源 = 待机 = PM51 切电 = 硬断电。脚本默认拒绝，必须显式 `--force`。
救砖流程（按住机身键 + 插电 ≤15 s）IR 做不了，仍要人。
