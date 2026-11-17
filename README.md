# m7642 — MStar m7642 / MT9652 主线内核移植

目标设备：**TCL 雷鸟鹤6（`tcl_m7642`，MT9652，4×Cortex-A73，Android 9 / 内核 4.9.118）**。

目标：在最新主线上跑起这台机器 —— 面板显示、HDMI、蓝牙遥控、WiFi 可用，并能承载 Android TV。

本仓库存放移植过程的研究结论、可复现的取证工具和图树就绪的产物（DTS / 文档 / 补丁）。
**不是内核源码树**：这里只放"会被提交到上游的那部分"，以及支撑结论的证据。

## 结构

```
Documentation/mstar/m7642/     研究文档（按子系统一份，结论 + 证据 + 待办）
arch/arm64/boot/dts/mstar/     板级 DTS
drivers/                       计划中的移植代码（当前只有占位说明）
patches/                       git format-patch 序列
probes/                        内核探针模块源码 + 构建输入
tools/host/                    开发机上跑的脚本
tools/device/                  推到电视上跑的脚本
artifacts/                     取证产物：反汇编、寄存器基线、活体 DTS、探针输出
fw/                            固件（.bin）分析脚本
```

命名与分层尽量对齐内核树（`Documentation/<vendor>/<soc>/`、`arch/arm64/boot/dts/<vendor>/`、
`drivers/<子系统>/`、`tools/`、`patches/`），这样将来 `git format-patch` 出来的东西可以直接往上游送。

## 现在到哪一步了

| 功能 | 状态 | 关键结论 |
|---|---|---|
| 面板显示 | 路径已定 | bootloader 已完成 tcon/面板时序，内核走 `simplefb`（`recovery_fbaddr=0x2D100000`） |
| WiFi / BT | 路径已定 | USB 是标准 EHCI 逻辑，但寄存器为 16 位拼接访问；MT7663 在 `pm+0x2600` 那一路 |
| 多核启动 | 协议已反推 | 非标准 spin-table（PM 窗口 3 字邮箱）；P0 单核即可 |
| HDMI | **零源码** | RX/TX 两条链路都只有二进制；HDCP 为硬件引擎 + OTP 密钥 |
| Android TV | 用户态问题 | 32 位用户态、非 Treble、HIDL |

详细路线见 `Documentation/mstar/m7642/roadmap.md`。

## 从哪里读起

1. `Documentation/mstar/m7642/index.md` — 全仓索引与"可背下来的几条"
2. `Documentation/mstar/m7642/hardware.md` — 这台机器上到底有什么
3. `Documentation/mstar/m7642/usb.md` — 想动手的话从这一块开始最划算

## 约定

- 文档一律写**结论 + 证据 + 待办**，拿不到证据的写成"待确认"，不要写推测当结论。
- 任何在线实验必须可复现：脚本进 `tools/`，产物进 `artifacts/`，结论里给文件名。
- 触碰 MMIO 前先读 `Documentation/mstar/m7642/index.md` 的"在线实验纪律"一节。

## 维护

```
Emfox Zhou <emfox@debian.org>
```
