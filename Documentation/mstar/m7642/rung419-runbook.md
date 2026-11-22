# 4.19 验证镜像：上机操作卡

2026-11-20。目的只有一个：**判断 7.3 的失败是「代码问题」还是「mboot 交接状态问题」**。
做法是拿同一颗芯片、同一份官方 4.19 源码编出的内核去跑同一段低层启动路径，看它能不能过。
**一次试验 = 一次赌注**，不要为了"多看一眼"重复刷。

## 0 装置

| 项 | 值 |
|---|---|
| 镜像 | `~/Debian/m7642-build/out/m7642-419-rung0.img` |
| 大小 | 21,618,688 B（`2048 + kernel 13,893,632 + ramdisk 7,723,008`） |
| md5 | `c8bca13a1935bbcbd9a45833bda67885` |
| 目标槽 | `recovery`（`mmcblk0p7`），32 MB，用掉 21.6 MB |
| 入口 | 头里 `code1 = b +0xd3fa00`（= `stext`，`Image` 内偏移 `0xB70000`） |
| `kernel_addr` | `0x20280000`（与厂值 recovery 逐字节相同） |

镜像头与厂值 recovery 对比：**只有 `kernel_size` 不同**，其余 `magic / kernel_addr /
ramdisk_size / ramdisk_addr / tags_addr / page_size / os_version` 全部一致，ramdisk 段原样搬过来。
所以 mboot 眼里这个包和厂值 recovery 同类。

## 1 三个检查点

`ladder.S` 的 blob 被塞在镜像尾部（`0xD3FA00` 之后），每级只做「steer GOP 窗口 → 关掉其余窗口
组 → 涂满一屏 → 跳回真代码」，不碰 `x0..x5 / x21 / x23`。

**⚠️ 颜色名是错的，看「实际显示」那一列。** 色值原本按 16 位 RGB565 设计，但 GOP 实测是
`a8r8g8b8`（r@16 g@8 b@0 a@24，见 `fbpaint info`），所以 32 位写下去的颜色不是设计意图：

| 级 | 写入值 | **ARGB8888 下实际显示** | 落点 | 证明什么 |
|---|---|---|---|---|
| 1 | `0x07FF07FF` | **洋红**（R=FF G=07 B=FF，alpha 仅 `0x07`）| 入口之后 `+0xD3FA00` | mboot 确实按 `code1` 跳进来了、我们的代码在跑 |
| 2 | `0xFC00FC00` | **绿**（R=00 G=FC B=00，alpha `0xFC`）| `stext+0x44`（`b __primary_switch` 前） | `el2_setup` / `set_cpu_boot_mode_flag` / `__create_page_tables` / `__cpu_setup` 全过 |
| 3 | `0x07E007E0` | **紫红**（R=E0 G=07 B=E0，alpha 仅 `0x07`）| `__primary_switched+0x90`（`b start_kernel` 前） | MMU 已开、idmap 切换完成，即将进 C |

按 RBG 顺序记：**洋红 → 绿 → 紫红**，不是青 → 橙 → 绿。

**判读纪律（血账）**：只看**整屏纯色**。条纹、花屏、渐变都不算数。土黄 `0xCCCC` 是我们 stub
自己的填充色，**不能当读数**。看最后停在那一屏。

## 2 前置检查（只读，零风险）

```bash
adb connect <电视IP>:5555
~/Debian/m7642-build/scripts/tvrun.sh ~/Debian/m7642-build/scripts/precheck.sh
```

必须确认三件事，任何一条不对就**停**：

1. `/system/etc/install-recovery.sh` **absent**、`/system/etc/install-recovery.sh.disabled` **present**。
   反过来 = 每次 Android 启动都会用 `/system/etc/recovery.img` 把槽整段覆盖掉，刷了也白刷。
2. `/data/local/tmp/rec.head.bin` 的 md5 = **`0f6e1705f077935e1c3018973e658bfa`**。
   如果读到 `c8bca13a1935bbcbd9a45833bda67885`，说明**槽被 arm 过两次、厂值回滚文件已经丢了**。
3. BCB（`misc` 前 16 字节）不是 `boot-recovery`。

## 3 刷入（风险从这里开始）

```bash
IMG=~/Debian/m7642-build/out/m7642-419-rung0.img ~/Debian/m7642/tools/host/boottest.sh arm
```

它会：push → **设备上重算 md5 比对** → 备份槽头 21,618,688 B 到 `/data/local/tmp/rec.head.bin`
→ 备份 `misc` 首块 → 写槽 → 写 `BCB=boot-recovery` → 回读槽 md5。
验收：输出里 `slot now md5` 必须等于 `c8bca13a1935bbcbd9a45833bda67885`。

**★ 只 arm 一次。** `boottest.sh arm` 每次都无条件备份「当前槽内容」，第二次 arm 会把我们自己的
镜像当成厂值备份，`rec.head.bin` 就失效了。

备份范围是 `ceil(21618688/4096)=5278` 块 = 21,618,688 B，正好等于我们写进去的长度；
厂值镜像 27,471,872 B 的后 5.8 MB 我们既不写也不备，保持原样 ⟹ **回滚是逐字节精确的**。

## 4 起

```bash
~/Debian/m7642/tools/host/boottest.sh reboot
```

即 `adb reboot recovery`。mboot 认 `misc` 里的 `boot-recovery` 后**直接起，不需要人按电源键**。
屏上先出洋红底 `boot_recovery.jpg`，随后就看颜色。

## 5 判读

| 看到 | 结论 | 下一步 |
|---|---|---|
| 屏幕 | 结论 | 下一步 |
|---|---|---|
| **紫红** | MMU 已开、idmap 已切，即将进 C | 最好情况；往 `start_kernel` 之后补 |
| **绿** | 低层启动全过：`__create_page_tables` / `__cpu_setup` 都返回了 | 7.3 的问题在它自己的新机制上 ⟹ 换 4.19 的 `__create_page_tables` / `__primary_switch` 进 7.3 二分 |
| **洋红** | 只到第 1 级 ⟹ `stext` 之后没走远 | 4.19 和 7.3 死在**同一类**地方 ⟹ 问题在 **mboot 交接状态 / 内存属性**（TZ 保护、PM51 权限、dcache 状态） |
| **纯黑** | 连第 1 级都没到 | mboot 没按 `code1` 跳、或没加载到 `+0xD3FA00` ⟹ 查 `kernel_size`、槽大小、`code1` 编码 |
| **碎花 / 条纹** | **不算数**（判读纪律） | 但能说明有东西写了显存；看整片里有没有可辨认的主色 |

着色参照（**这是 ARGB8888 下的实际颜色，不是设计色**）：

```
洋红  0x07FF07FF → R=FF G=07 B=FF   (alpha 0x07)
绿    0xFC00FC00 → R=00 G=FC B=00   (alpha 0xFC)
紫红  0x07E007E0 → R=E0 G=07 B=E0   (alpha 0x07)
```

**洋红现在是最坏情况之一，不再是"没进来"的同义词** —— 这一点与旧版 runbook 相反，别再按旧结论读。

## 6 回滚

Android 还活着（adb 通）时：

```bash
~/Debian/m7642/tools/host/boottest.sh disarm
```

已锁在 recovery 循环时（`boot-recovery` 是**非消费式**，写过就一直进 recovery）：

1. 拔插头断电，等 15 s，插电（**直接进待机、不显示 logo**），按电源键
2. 仍然进 recovery ⟹ 走 U 盘救砖包 `rescue-fast.bin`（它重写 `misc` / `dtb` / `recovery` / `boot`）
3. 救回后**必须重新置 `MstarUpgrade_complete=1`**（`rescue-fast.bin` 自己不设这个 key），再拔 U 盘

## 7 已知陷阱

- U 盘根目录**只能有一个 `.bin`**，名字必须是 **`V8-T652T03-LF1V147.bin`**（mboot 用
  prefix+postfix 拼名字，TCL 前缀是 `V8-`；只放 `MstarUpgrade.bin` **不会被读**）。
- 强制升级从**关机状态**起步：拔电 → **按住机身实体电源键** → 插电 → 按住 10–15 秒，
  出现进度条才松手。不是"插电进待机再按一下"。
- `boot` 和 `recovery` 都是**单向车道**：刷坏后 logo → 几十秒 → 待机，按电源键只是重播同一段，
  adb 永远不回来。别指望「挂了就 `adb reboot`」。
- 别反复「按一下看看」：回待机 = PM51 直接切电 = **硬断电**，`/data` 会损坏，然后越修越坏。

## 附：这个实验的静态依据

4.19 的 `__create_page_tables` 第一件事是往 `idmap_pg_dir` 写 20 KB 零：

```
ffffff8008bf0068  mov  x28, x30
ffffff8008bf006c  adrp x0, idmap_pg_dir          // 物理 0x2103C000
ffffff8008bf0070  adrp x1, _end                  // 物理 0x21042000
ffffff8008bf0074  sub  x1, x1, x0                // 0x5000 = 20 KB
ffffff8008bf0078  bl   __inval_dcache_area
ffffff8008bf0088  stp  xzr, xzr, [x0], #16  ...  // 清 20 KB
ffffff8008bf00a0  mov  x7, #0x711                // AF|SH_inner|AttrIndx=4|block
```

而 7.3 死在 `create_init_idmap` 体内的**栈写**（`0x208ED000` 一带）。两者同在 `0x20xxxxxx`
这一片 DDR。所以：

- 4.19 过了橙 ⟹ 这一片在内核手里**可写** ⟹ 7.3 的嫌疑从"整片内存不可写"缩小到
  "它自己那套动态建表 / 切栈的用法"。
- 4.19 过不了橙 ⟹ 连"往 `0x2103C000` 写零"都失败 ⟹ 基本可以断定是交接状态而非内核代码。
