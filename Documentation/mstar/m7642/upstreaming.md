# 主线怎么组织驱动：按子系统，不按设备

结论先说：**内核从不给某块板子/某个 SoC 开一个"驱动目录"**。层次是

```
drivers/<子系统>/            先按功能分：usb、gpu/drm、mmc、net/wireless、pinctrl…
        └─ <vendor>/         厂商的一族驱动才合并成子目录（mediatek/、qcom/、mstar/…）
           └─ xxx-<soc>.c    单个控制器一个文件
arch/arm64/boot/dts/<vendor>/ 板级差异只放这里（按 vendor 分，不是按 SoC）
```

几条硬事实（都可在 mainline 里直接验证）：

- **arm64 没有 `mach-*`**：`arch/arm64/` 下只有 `boot crypto hyperv include kernel kvm lib mm net tools xen`。
  板级代码在 arm64 上是**不存在的**，全部靠 DT + 通用驱动。arm32 时期那套 `arch/arm/mach-xxx/` 已经不再接受新平台。
- **DTS 目录按 vendor 分**：`arch/arm64/boot/dts/{mediatek,rockchip,amlogic,…}`，里面一个 SoC 一个 `.dtsi`、
  一块板一个 `.dts`。
- **厂商前缀已注册**：`Documentation/devicetree/bindings/vendor-prefixes.yaml` 里
  `^mstar,.*` → "MStar Semiconductor, Inc. (acquired by MediaTek Inc.)"。
- **MStar 在主线本来就有先例**，而且是标准的分法：

  | 组件 | 主线位置 |
  |---|---|
  | 时钟 | `drivers/clk/mstar/clk-msc313-{cpupll,mpll}.c` |
  | GPIO | `drivers/gpio/gpio-msc313.c` |
  | RTC | `drivers/rtc/rtc-msc313.c` |
  | 看门狗 | `drivers/watchdog/msc313e_wdt.c` |
  | 定时器 | `drivers/clocksource/timer-msc313e.c` |
  | SMP（arm32） | `arch/arm/mach-mstar/mstarv7.c` |
  | 绑定 | `Documentation/devicetree/bindings/{clock,rtc,gpio,arm/mstar}/mstar,*` |

  注意看：**同一颗 MStar SoC 的代码散在 6 个不同子系统目录里**，没有一个 `mstar-msc313/` 大目录。

## 本项目的落点

每一块最后应该变成哪个文件（这也是本仓 `drivers/**/README.md` 占位目录存在的意义）：

| 功能 | 目标路径 | 形态 |
|---|---|---|
| 板级 | `arch/arm64/boot/dts/mstar/m7642-tcl-65s535d.dts` | 一块板一个 dts |
| SoC 公共部分 | `arch/arm64/boot/dts/mstar/m7642.dtsi` | 一个 SoC 一个 dtsi |
| USB EHCI 胶水 | `drivers/usb/host/ehci-mstar.c` | 单文件，照 `ehci-platform.c` 的骨架 |
| USB PHY（UTMI 序列） | `drivers/phy/mstar/phy-mstar-usb.c` | 走 PHY 框架，别塞进 ehci |
| 显示（gflip/gop） | `drivers/gpu/drm/mstar/` | 厂商一族 → 目录 |
| 面板时序 | `drivers/gpu/drm/panel/panel-*.c` | 面板单列成驱动 |
| eMMC | `drivers/mmc/host/mstar-mci.c` | 单文件（如果不是 sdhci 兼容） |
| I2C | `drivers/i2c/busses/i2c-mstar.c` | 单文件 |
| GPIO / pinctrl | `drivers/pinctrl/mstar/` | 厂商一族 → 目录 |
| 时钟 | `drivers/clk/mstar/clk-m7642-*.c` | 复用已有目录 |
| 红外遥控 | `drivers/media/rc/mstar-ir.c` | 单文件 |
| **WiFi / BT** | **不需要新驱动** | `mt76/mt7615/usb.c` + `btmtk`，只加 DT 节点和固件 |
| Binding | `Documentation/devicetree/bindings/<subsys>/mstar,m7642-*.yaml` | 每个新 compatible 一份 |
| SMP（arm64） | `arch/arm64/kernel/smp_mstar.c` | 主线无 arm64 先例，见 `smp.md` |

## 对本仓结构的含义

本仓**不**是内核树，但故意镜像了上面这些路径（`Documentation/`、`arch/.../dts/`、`drivers/**`），
好处是：一篇文档/一个文件放在哪、补丁最终落到哪，一眼能对上，`git format-patch` 出来就能直接送。

规矩：

1. **代码在真实内核树里写**（`linux-main` 或 clone 一份 `-next`），写完 `format-patch` 丢进 `patches/`；
   本仓 `drivers/**` 长期只放 README 与"这块要做什么"。
2. 新增 `compatible` 必须同时给 binding yaml，并且过 `make dt_binding_check`。
3. 不要把厂商的 `drivers/mstar2/` 整棵搬进来——那是"一个 SoC 一个大目录"的反面教材，
   上游一定会要求按子系统拆开。
