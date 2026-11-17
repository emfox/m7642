# HDMI 子系统盘点：两条链路，都是纯二进制

2026-11-17。结论先说：**HDMI 是四个必需功能里唯一"零源码"的一块**，
上一版路线图里"⚠️ 有 m7322 源码"是错的。

## 一、两条独立链路

| 链路 | 内核符号 | 作用 | 设备节点 |
|---|---|---|---|
| **HDMI RX**（输入） | `MDrv_HDMI_*` / `Hal_HDMI_*` / `HCS_HDMI_*_Rx` | 电视的主功能：接机顶盒/电脑 | 无平台设备节点（板级创建） |
| **HDMI TX**（输出） | `hdmitx4vx1` / `mstar-hdmitx4vx1` | 对外输出（部分板型） | `/sys/devices/hdmitx4vx1` |

DT 里只有 `compatible`，没有 `reg`、没有 `interrupts`：

```
hdmitx4vx1 { compatible = "mstar-hdmitx4vx1"; };
dvi_hdmi_hdcp_int { compatible = "dvi_hdmi_hdcp_int"; interrupts = <0 0x34 4>; };   // irq 52
HDMI_NON_PCM_MODE_INT_OUT { compatible = "..."; interrupts = <0 0x4b 4>; };          // irq 75
```

`hdmitx4vx1` 已绑定驱动 `mstar-hdmitx4vx1`，**内置**（`/proc/modules` 里没有），
`/sys/devices/hdmitx4vx1/` 除 `of_node`/`power` 外没有任何属性 —— 没有 sysfs 接口可调。

## 二、符号规模（721 个含 hdmi 的内核符号）

| 前缀 | 数量 | 层 |
|---|---|---|
| `MDrv_HDMI` | 173 | 驱动层（RX） |
| `mdrv_HDMI` | 67 | 驱动内部 |
| `Hal_HDMI` | 64 | HAL |
| `MTGVDECEX_HDMI` | 43 | 视频解码相关 |
| `MI_DISP` | 31 | 显示模块接口 |
| `KDrv_HDMI` / `MHal_HDMI` / `KHal_HDMI` | 25 / 13 / 5 | 包装层 |
| `HCS_HDMI` | 12 | HDCP 硬件序列（`_Tx` / `_Rx` 都有） |

函数名足以判定方向：`MDrv_HDMI_READ_DDCRAM`、`MDrv_HDMI_Set_EQ_U2`（均衡器）、
`MDrv_HDMI_Set5VDetectGPIOSelect`、`MDrv_HDMI_GetHDCPStatusPort`、`Hal_HDMI_avi_infoframe_info_ver`、
`MDrv_HDMI_EX_Get_4Kx2K_VIC_Code` —— 这套是 **RX**（读 EDID、调均衡、5V 检测、HDCP、AVI infoframe）。
`HCS_HDMI_ComputeH/V/M_Tx`、`HCS_HDMI_EnableEncrypt_Tx` 是 HDCP 加密引擎（硬件算，密钥在 OTP）。

## 三、源码可得性：零

- m7322 GPL drop：`drivers/mstar2/drv/hdmitx4vx1/` **只有一个 Kconfig，0 行 C**；
  `drivers/mstar2/hal/m7322/` 下**没有 hdmi 目录**（对比：usb / gflip / graphic 都有）。
- realme 4.19 树（400 MB）是 **Amlogic** 平台，与 MStar 无关。
- 结论：HDMI RX 与 TX 都只能走"符号 + 反汇编 + 寄存器探测"，工作量与 `graphic` 同级或更高。

## 四、寄存器通路（已部分探到）

反汇编 `Hal_HDMI_init`（0xffffff80013c2238，2048 字节），它是这样取基址的：

```
ldr  x19, <池里的地址>        ; = 0xffffff8002702ee0
ldr  x0, [x19]               ; 读全局指针
add  x0, x0, #0x2e7, lsl #12  ; +0x2E7000
strh wzr, [x0, #520]         ; 16 位写
```

运行时读该全局（`addr=0xffffff8002702ee0`）得到 `0xffffff800a000000` —— **就是 `mstar_pm_base`**。
于是：

| 项 | 值 |
|---|---|
| HDMI RX 寄存器块 | `mstar_pm_base + 0x2E7000` = VA `0xffffff800a2e7000` / 物理 `0xFD2E7000` |
| 另一块（见 `add x1, x1, #0x225, lsl #12`） | `+0x225000`，疑似 PHY/PLL 或 HDCP |
| 访问宽度 | **16 位**（`strh`/`ldrh`），与 USB 块的拼接访问不同 |

## 五、事故：按字节读这块 → 设备重启

用探针按字节读 `0xffffff800a2e7000` 64 字节 → **电视重启**（15:44，uptime 归零，自动恢复，
闸门正常、无残留模块）。

两个可能原因，都还没排除：

1. 该块**要求 16/32 位宽度访问**，逐字节读触发总线错误；
2. 该块**平时不在时钟/电源域**（只在切到 HDMI 源时上电），空访问挂死 XIU 总线 → 看门狗复位。

取证失败：`/sys/fs/pstore/console-ramoops` 里只剩本次启动 0–21 s 的日志，
Android 的 init 在启动时清过 pstore，**panic 日志没保住**。

⟹ 重试前必须先做两件事：
- 给探针加 **按字（`readl`）对齐读**的模式，别再用逐字节 hexdump 去碰新块；
- 先找到该块的时钟/电源开关（大概率在 `clkm` / PM 域里），打开后再访问。

在此之前，`0x2E7000` 与 `0x225000` 两块列入**禁读清单**。

## 六、对主线的意义

1. HDMI 两条链路都没有任何可移植源码，反推需要从 721 个符号里挑出寄存器访问路径，
   再对齐 EDID/HDCP/时序 —— 与写一个 DRM bridge 不是一回事。
2. HDCP 是硬件引擎 + OTP 密钥，主线没有对应框架；**不接 HDCP 就只能显示非保护内容**，
   看机顶盒/蓝光会黑屏，这是硬约束不是工程问题。
3. 因此建议 **P1 不做 HDMI**：先把面板显示（simplefb/GOP）、WiFi/BT、遥控做通，
   HDMI 单独立项评估（预期 3–6 月、极高风险）。

## 七、待办

- [ ] 探针加字宽读模式
- [ ] 找 `0x2E7000` 的时钟/复位开关（从 `clkm` 或 `Hal_HDMI_init` 之前的调用链里找）
- [ ] 打开时钟后再读一次，确认块里是 HDMI 寄存器（找 `MDrv_HDMI_GetStatus_U2` 用到的偏移）
- [ ] 判定"HDMI 可用"到底指 RX 还是 TX（两者都不是小事，方向不同）
