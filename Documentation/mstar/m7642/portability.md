# 移植成本评分（L0）：把厂商驱动逐个对主线 7.3 试编译

2026-11-17。目标：不再靠"感觉很难"，而是用编译器的报错把 8 个驱动排出成本顺序。

## 方法

| 项 | 值 |
|---|---|
| 基线 | `torvalds/linux` **v7.3**（最新 release；master 已到 v7.4-rc3） |
| 编译器 | Bootlin aarch64 GCC **13.3.0** |
| 准备 | `make ARCH=arm64 defconfig` + `modules_prepare`（3 秒） |
| 方式 | 每个 `.c` 用 `-fsyntax-only`，旗标对齐 kbuild（`-D__KERNEL__ -DMODULE`、`autoconf.h`、`kconfig.h`、`-nostdinc`） |
| 兼容层 | 把 realme 4.19 树的 `arch/arm/mach-m7642/include/{mach,mstar}` 作为 `-I` 补进去（否则所有驱动都卡在 `mach/*.h`） |
| 分类 | **驱动侧错误**（`drivers/mstar2/...: error`）才算真实成本；**主线头文件里的报错**是这套临时旗标的噪声，不计 |

> 噪声说明：每个文件都会报一条 `static assertion failed: "sizeof(struct filename) % 64 == 0"`，
> 那是旗标不全导致的，不是驱动问题。真实工程里用 kbuild 编译不会有这条。

## 结果

| 驱动 | LOC | 驱动侧错误 | 卡在哪 | 判定 | 估工 |
|---|---|---|---|---|---|
| **mmc**（eMMC） | 14 367 | **2** | 一个调试宏的字符串化写法 | 便宜 | 1–2 周 |
| **gflip**（图形翻转） | 6 211 | **2** | `VERIFY_WRITE/READ` 已被删，改 `access_ok()` | 便宜 | 2–3 天 |
| **iic** | 3 447 | **6** | `i2c_msg`/适配器结构调整 | 便宜 | 2–3 天 |
| **gpio** | 1 078 | **13** | `gpio_chip` 没了 `label`/`to_irq`，要换成 `gpio_generic_chip` 那套 | 便宜 | 3–5 天 |
| **mspi**（SPI） | 1 077 | **35** | `spi_master` 全面改名 `spi_controller`，`spi_device.master` 已删 | 机械，量大 | 2–3 天 |
| **emac**（网口） | 5 012 | **1** | 只缺 `asm/arm-boards/prom.h`（MStar 私有头） | 先补头，之后未知 | 1 周起 |
| **alsa_audio_driver** | 2 547 | **7** | `snd_pcm_ops.copy_user` 早被删、`timer_list.data` 已删 | 中等，要重构回调 | 2–3 周 |
| **graphic**（显示核心） | 1 310 | **8** | **`#error unknown chip!!`** —— 只有 m7322 的 HAL，没有 m7642 | 结构性 | 见下 |

## 三条结论

**1. 存储/GPIO/I2C/SPI 是"机械移植"，不是"研究项目"。**
四个驱动合计约 2 万行，驱动侧错误加起来 56 个，且全是 API 改名/结构体成员搬迁这一类。
合计估工 **3–4 周**（含调试）。这比之前"3–6 周只做 eMMC"的估计乐观，因为报错密度很低。

**2. 显示真正的墙不是 API，是缺 m7642 的 HAL 常量。**
`graphic` 里那句 `#error unknown chip!!` 出在 `mdrv_system.h:1263`——代码里按芯片型号做宏分支，
而公开树里只有 m7322 的分支。这不是"改几个函数名"能解决的，缺的是 m7642 的寄存器基址和序列。
这和之前从目录结构得出的判断一致，现在有编译器背书的证据。

**3. 音频比预想的贵。**
`struct snd_pcm_ops` 的 `copy_user` 回调在主线早就没了（改成 `copy`/`fill_silence` 再配合
`snd_pcm_set_managed_buffer`），`timer_list.data` 也换成了 `from_timer()`。这两处是重写而非改名。

## 复现

```sh
~/Debian/m7642-build/scripts/score-drivers.sh            # 全部
~/Debian/m7642-build/scripts/score-drivers.sh gpio mspi  # 指定驱动
# 日志落在 ~/Debian/m7642-build/diag/score/<driver>.log，统计：
grep "error:" ~/Debian/m7642-build/diag/score/mmc.log | grep -c "drivers/mstar2/"
```

## 下一步建议

按成本顺序推：`gflip`（2 天）→ `mspi`（3 天）→ `iic`（3 天）→ `gpio`（5 天）→ `mmc`（2 周）。
这四个半做完，P1（能挂 rootfs、能跑 Debian）就基本具备条件。
`graphic` 留到最后，因为它缺的不是代码而是数据。
