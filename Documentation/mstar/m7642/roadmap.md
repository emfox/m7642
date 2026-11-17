# 目标：最新主线内核 + 显示 / HDMI / 蓝牙遥控 / WiFi + 能跑 Android TV

2026-11-17。这份文档只回答一件事：这个目标拆成哪些可交付件，每件的缺口、估工和风险。

## 0. 一句话结论

目标里有 6 个独立的交付件。**4 个主线已有或接近**（WiFi、蓝牙、串口、CPU/中断/定时器）；
**2 个要从零写驱动**（显示、HDMI）；最后那个（Android TV 跑起来）依赖前两者，
并且不只是内核问题——还要重做 HAL 和 64 位用户态。

单人工时量级：**1.5–3 人年**。但每个阶段的可见成果是 2–6 周，不是"做完才知道行不行"。

## 1. 逐件现状

| 功能 | 主线现状 | 厂商素材 | 缺口 | 估工 | 风险 |
|---|---|---|---|---|---|
| CPU / GIC / 定时器 | ✅ `arm,gic-400`、`armv8-timer` | ⚠️ 次核源码缺失 | `mstar-spin-table` 是 PM 窗口里的 3 字邮箱，非标准 spin-table；**P0 单核即可**，见 `smp.md` | P0 不阻塞，P2 后补 1–2 周 | 中 |
| 串口 | ✅ 8250 通用 | ✅ 基址 `0x1F201300`、123 MHz | **已解决**：8 字节步距 = `reg-shift = <3>` + `reg-io-width = <4>`；细节见 `uart.md` | **0**（只需 DT 节点） | 低 |
| **WiFi** | ✅ `mt76` 认 `0e8d:7663` | 闭源 .ko | USB 侧：16 位拼接访问器（~40 行）+ PHY 序列 + DT 节点；基址/中断已实测 | 1–2 周 | 低 |
| **蓝牙** | ✅ `btusb` + `btmtk`（v6.6 有 `FIRMWARE_MT7663`） | 闭源 | 新内核对 MT7663 的路径要实测 | 1–2 周 | 中 |
| 存储 eMMC | ❌ 私有 `mstar_mci` | ✅ `mstar_mci_v5.c` 源码 | 移植进 mmc 框架 | 3–6 周 | 中 |
| I2C | ❌ 私有 `Mstar-iic` | ✅ | 移植，或 `i2c-gpio` 绕过 | 1 周 | 低 |
| GPIO / pinctrl | ❌ `mstar,gpio` | ✅ | gpio-mmio + pinctrl | 1–3 周 | 中 |
| 时钟 | ❌ 私有 `clkm` | ✅ | clk 框架驱动 | 3–6 周 | **高**（一切的前提） |
| 以太网 | ❌ 私有 `mdrv_emac_v3` | ✅ | 新驱动 | 4–8 周 | 中 |
| **显示输出** | ❌ 无 | ⚠️ 只有 m7322 HAL，m7642 缺席 | DRM/KMS + tcon + 面板 | **3–6 月** | **极高** |
| **HDMI 输出** | ❌ 无 | ❌ **零源码**：`drv/hdmitx4vx1/` 只有一个 Kconfig（0 行 C） | DRM bridge + EDID + HDCP | 2–4 月 | 极高 |
| **HDMI 输入** | ❌ 无 | ❌ **零源码**：`MDrv_HDMI_*` 全在核内二进制（见 `hdmi.md`） | V4L2 + EDID + HDCP | 3–6 月 | 极高 |
| 音频 | ❌ 私有 `Mstar-alsa`/`voc` | ✅ | ASoC | 2–4 月 | 高 |
| 遥控（红外） | ❌ 私有 `Mstar-ir` | ✅ | rc-core | 1–2 周 | 低 |
| 面板 / tcon | ❌ 无 | ⚠️ 二进制 `PM.bin`/`gamma.bin` | 反推时序 | 并入显示 | 极高 |
| Tuner / DTV | ❌ 无（Si2151 主线不认） | 私有 demod | DVB 前端 + Android Tuner HAL | 3–6 月 | 极高 |

## 2. 阶段划分（每阶段都有可见成果）

**P0 · 最小可启动（1–2 周）**
`arch/arm64/boot/dts/mstar/` 下的 dtsi + 板级 dts + 主线 arm64 + initramfs + `simplefb` + MT7663。
判据：电视上出现内核日志，WiFi 能起来、能 ping。
产出：证明"主线能在这块板子上跑"，这是后面一切的前提。

**P1 · 可用的 Linux（1–2 月）**
eMMC + I2C + GPIO + 时钟 + USB 完整上电；rootfs 落到 eMMC；能装 Debian armhf。
判据：断电重启后自己进系统，能 `apt update`。

**P2 · 显示（3–6 月，最难）**
把 `graphic`/`gflip`/`mspi`/tcon 移植成 DRM/KMS 驱动，面板时序从 `PM.bin` 反推。
判据：`modetest` 能出图，fbcon 走 KMS 而不是 simplefb。

**P3 · HDMI 输出（2–4 月）**：4K/1080p 复用 P2 的 KMS，加 EDID/热插拔。
**P4 · HDMI 输入（3–6 月）**：V4L2 采集 + 信号源切换。

> P3/P4 都**没有任何可移植源码**（GPL 包里 HDMI 只剩一个 Kconfig），属于纯反推，
> 且 HDCP 是硬件引擎 + OTP 密钥，主线无对应框架 —— 不接 HDCP 只能显示非保护内容。
> 结论：**别排进 P0/P1**，等面板和 WiFi 通了再单独立项。详见 `hdmi.md`。
**P5 · 音频（2–4 月）**：ASoC + HDMI 音频回传。
**P6 · Android TV**：见下。

## 3. Android TV 这一段，和内核是两件事

即使 P2–P5 全做完，Android 还差这些：

1. **HWC2 + gralloc**：Android 14 已经不用 fbdev，必须有 DRM/KMS 后端并实现 HWC；
2. **HAL 全部重写**：audio、tuner、HDMI CEC、keymaster/gatekeeper、power；
3. **64 位用户态**：本机 `abilist64` 是空的，现有 vendor 库全是 32 位。Android 12+ 的系统镜像
   是 arm64 ⟹ 要么自己编一套 64 位 AOSP（HAL 也全 64 位），要么这条路走不通；
4. **认证**：自建 AOSP 过不了 Google 认证 ⟹ 没有 Widevine L1 ⟹ Netflix/Disney+ 降级或无。

其中第 3 条是硬伤：**它不是工作量问题，是"没有可用的 64 位闭源组件"**。

## 4. 三条路的成本对比

| 路线 | 工期 | 结果 | 风险 |
|---|---|---|---|
| 完整 P0–P6 | 1.5–3 人年 | 自建 TV 系统，无 L1、无认证 | 极高 |
| P0–P1 + 外接盒子 | 1–2 月 | 一块能跑 Linux 的电视 + 完整 Android TV 14 | 低 |
| 只做 L1（官方固件 + 补丁） | 已有 | 现状 | 低 |

## 5. 建议

先做 **P0**。它是唯一"不写驱动、1–2 周内能拿到确定答案"的一步，而且它的产物
（DTS、内核构建脚本、initramfs）是后面每一步的地基。

P0 失败的信号很明确：`simplefb` 不出画面，或次核起不来且没有 PSCI 兜底。
那时候再决定要不要继续，比现在争论"能不能做到"有价值。
