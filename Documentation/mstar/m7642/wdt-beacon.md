# pstore / pmsg 通道与 boot 槽读数通道

> 这篇原名「WDT 信标」。那个思路假设 `wdt_enable n` 能让设备自己在 n 秒后复位，
> **该假设实测不成立**（见 §一），所以按它的推论写的内容已全部删除，只留实测事实。

## 一、WDT 自动复位：四次实验，都不成立

| # | 做法 | 实测结果 |
|---|---|---|
| 1 | mboot env `recoverycmd` 里加 `wdt_enable 10` | **两次"确认进入 recovery"的挂死都没有复位**。"确认进入 recovery"用 `misc` 尾部 4 KiB `0xA5` 标记法（`recoverycmd` 第一条 `mmc erase.p misc` 会擦掉它） |
| 2 | 同上但 `wdt_enable 120` | 设备在 mboot 自己 ~40 s 超时后**进待机**；狗有没有咬无从观察 |
| 3 | 厂 HAL `HAL_WDT_Start(3, 10)` | `rc=1` 失败（缺 `MI_WDT_Open` 之类前置）；`/dev/watchdog` 不存在，`/proc/devices` 里没有 watchdog |
| 4 | `MDrv_WDT_Init(0) + MDrv_WDT_SetTimer(0, 20)`（去掉所有解引用的干净版） | **120 s 内没有复位**（更早那三次"复位"是模块里诊断代码自己 oops/panic 造成的） |
| 5 | 直接写 WDT 寄存器（`pm+0x6000` / `pm+0x600C`） | 超时值改到 5.5 ms 仍不复位；`+0x0C` 读回 `0xFFFF` |
| 6 | `machine_restart()` | 落到**待机**（PM51 切电） |

**更正过一次误解**：早期几次"设备自己回到 Android"，实际是 **BCB 没写进 `misc` ⟹ mboot 走了
`bootcmd`**，与看门狗无关。改用 `misc` 标记法（能证明 `recoverycmd` 真的跑了）之后，
结论稳定为"不复位"。

**唯一会 warm reset 的是 `panic()`**，而且不是因为布防了 WDT：厂内核有 `[WdtHeartBeatTas]`
线程在喂一颗 **5 s** 的狗，`panic` 停掉所有 CPU ⟹ 没人喂 ⟹ 狗咬 ⟹ warm reset、**DRAM 保留**。
普通挂死（单线程自旋）不会触发；7.3 探针里也没有这个条件。

## 二、待机 = 切电 = DRAM 全丢（实测）

往 ramoops 数据区（`0x419c0000`，在内存空洞里、内核不分配也不清零）写记录 `M7642SURV1`，
**写入后先读回确认**；然后让设备进待机、再红外开机；读回该区 = **`ff`** ⟹ 记录没了。
载体本身不可能被内核碰，仍然丢失 ⟹ 只能是**切电**。

⟹ **挂在"带电"状态时（屏幕停 logo）只能拔电，拔电后 DRAM 同样丢。**
所以"跨复位/跨断电保留记录"这条路在 DDR 上不存在。

## 三、ramoops 布局（实测）

| 全盘地址 | 用途 |
|---|---|
| `0x41900000` / `0x41940000` | dmesg 两笔 |
| `0x41980000` | console |
| `0x419c0000` | pmsg（/dev/pmsg0） |

一条记录的头部（实测，不是读代码推的）：

```
+0x00  u32 sig   = 0x43474244 "DBGC"
+0x04  u32 start = 写指针（下次写的位置）
+0x08  u32 size  = 有效字节数
+0x0c  data[]
```

- 数据永远从 `+0x0c` 起；`save_old()` 从 `data[start]` 开始读、到末尾回绕到 `data[0]`，总长 `size`；
- 空环 + 手写记录用 `start=0, size=N, data[N]`；
- 复位后再读：`sig` 仍是 `DBGC`，但 `start=size=0` ⟹ `PRZ_FLAG_ZAP_OLD` 生效
  （先 `save_old` 拷进 kmalloc，再清环）。

**导出情况**（2026-11-21 10:15 实测，python 侧用 `/dev/pmsg0` 写、然后 panic 复位）：

```
/sys/fs/pstore/console-ramoops   57554 B   从 [0.000000] SAR5=ON 开始 ⟹ panic 前 DDR 完整跨过复位
/sys/fs/pstore/dmesg-ramoops-0  127434 B
/sys/fs/pstore/pmsg-ramoops-0       35 B   内容 = 之前几轮 /dev/pmsg0 写入的拼接
```

**注意：从 EL2/code1 直接写 `0x419c0000` 会挂**（`handoff.S` 192 B、`handoff1` 100 B 两次都挂，
且该 zone 数据区始终是 `ff` ⟹ 从没被写成过）。能写它的是**内核/用户态**（`/dev/pmsg0`，
`request_mem_region + ioremap_wc`）。所以早期探针用不了 pstore。

## 四、可用的读数通道：boot 槽 code1 探针 + 普通 DDR

这是目前唯一验证过、且不依赖复位/屏幕/人的通道：

```
code1 探针写 0x23080000–0x230F0000 八页（每页 64 B，同一份记录写 8 个落点）
  → 返回 0xFA0000（厂内核入口）
  → Android 正常起来（同一次启动内）
  → probeRW op=r 直读那八页
```

实测 2026-11-21 13:06（boot 槽，8 个落点内容完全一致）：`+0x00 = "M764"`、
`x0..x5` = mboot 交接时的寄存器、`CurrentEL`/`SCTLR` 等。

**边界**：只在**同一次启动内**有效。
- `0x23090000` 落在 mboot 每次 `mmc read.p dtb 0x100000` 覆盖的 `0x23000000–0x230FFFFF` 内；
- 普通 DDR（如 `0x23100000`）会被内核分配时清零；
- 复位/待机后 DRAM 不保（§二）。

⟹ 用它的前提是**检查点会返回**。检查点务必设计成"到达 → 写记录 → 交接 → Android 起来"，
而不是"到达 → 继续跑"。

## 五、与其它文档的关系

- 检查点仪器（pread-MMU / post-MMU tramp、交接桩、2 MB 对齐修正）：`confirmed-facts.md` §34。
- pstore 之外的历史通道（屏幕填色、GOP 寄存器分级）已废，原因见 `display.md` §九。
- 复位/待机的硬件机制（PM51、红外电源键归属）：`pm51-standby.md`。
