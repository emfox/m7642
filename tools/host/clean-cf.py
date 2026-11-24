import os, re
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()

# ---------- 1. 删掉所有「本节已被…取代」这类标注 ----------
s = re.sub(r"> ⚠️ \*\*本节[^\n]*\n(?:> [^\n]*\n)*\n?", "", s)

# ---------- 2. §34.3 精简：只留 stash 事实 ----------
m = re.search(r"### 34\.3 挂住后能不能留下读数：WDT 与 stash 的实测[^\n]*\n(.*?)(?=\n### 34\.4)", s, re.S)
if m:
    new = """### 34.3 stash 的有效范围（2026-11-22 12:0x）

stash 页 `0x23080000`（交接记录）/`0x23090000`（code1 shim）**只在同一次启动内有效**：

- 两个地址都落在 mboot 每次启动执行 `mmc read.p 0x23000000 dtb 0x100000` 覆盖的
  `0x23000000–0x230FFFFF` 窗口内 ⟹ **跨启动必被覆盖**；
- 挪到窗口外的普通 DDR（试过 `0x23100000`）也没用：内核分配该页时会清零；
- 复位/待机后 DRAM 本身不保（`wdt-beacon.md` §二）。

⟹ 这条通道的用法只有一个：**探针写记录 → 同一次启动内交接厂内核 → Android 起来 → `probeRW` 读**。
只要检查点会返回，它就是可靠的（今天 `ps0z`/`ps1z`/`skmainz`/`setuparchz` 全部验证过）。

"""
    s = s[:m.start()] + new + s[m.end():]
    print("§34.3 精简")

# ---------- 3. §34.10 精简：留 PM51 机制与用户实测，去掉 WDT 建议 ----------
m = re.search(r"### 34\.10 静态调查：为什么晚期的挂死红外救不回[^\n]*\n(.*?)(?=\n### 34\.1[12])", s, re.S)
if m:
    new = """### 34.10 红外为什么救不回某些挂死（2026-11-22 15:2x，静态 + 用户实测）

**用户实测**：救不回来的挂死，屏幕**停在 logo**（不是黑屏），红外与**实体遥控都没有反应**，
`ping` 不通。

**静态机制**（厂内核 `drivers/mstar2/drv/pm/mdrv_pm.c`）：

| 事件 | 代码 | 效果 |
|---|---|---|
| 挂起前 | `MDrv_PM_Suspend(SUSPEND_PREPARE)`：`CopyBin2Sram()` → **`gRTPM_Live = 0`** | 把 `PM.bin` + 唤醒键表交给 MCU，宣告"AP 走了" |
| 恢复时 | `MDrv_PM_Resume(POWER_ON_DC)`：`MHal_PM_Disable_8051()` → 拷 RTPM bin → `SetDRAMOffsetForMCU()` → **`gRTPM_Live = 1`** | 关 8051、切到 RTPM 代码，宣告"AP 接管" |

AP 与 MCU 还共享一块运行期 PM 区（cmdline `RTPM_INFO=1,0x43FF0000`）。

⟹ **只有 MCU 处于"唤醒键模式"（待机/关机）时，红外 POWER 才由 MCU 自己断电重启。**
AP 一旦接管，POWER 走的是"AP 输入子系统 → Android 关机流程 → 内核把电源交给 MCU"——
AP 挂了就没人做这一步，所以按键无反应。

**与"能救回"的那些次的差别不是挂得多深，而是有没有回到待机**：

| 状态 | 屏幕 | 谁处理 POWER | 结果 |
|---|---|---|---|
| 待机 | **黑屏** | PM51 自己断电重启 | 红外一次，约 25 s 回来 |
| AP 带电但内核已死 | **停在 logo** | 没人 | 只能拔电 |

"""
    s = s[:m.start()] + new + s[m.end():]
    print("§34.10 精简")

# ---------- 4. 删掉 §34.12（分析的是不存在的路径） ----------
m = re.search(r"### 34\.12 .*?(?=\n### 34\.13)", s, re.S)
if m:
    s = s[:m.start()] + s[m.end():]
    print("§34.12 删除")

# ---------- 5. §34.13 改成纯事实条目 ----------
m = re.search(r"### 34\.13 [^\n]*\n.*?(?=\n### |\Z)", s, re.S)
if m:
    new = """### 34.13 WDT 自动复位：四次实验，都不成立（2026-11-21 实测）

| # | 做法 | 结果 |
|---|---|---|
| 1 | mboot env `recoverycmd` 加 `wdt_enable 10` | **两次"确认进入 recovery"的挂死都没有复位**（`misc` 尾部 4 KiB `0xA5` 标记法判定） |
| 2 | 同上 `wdt_enable 120` | 设备在 mboot ~40 s 超时后进待机，狗有没有咬无从观察 |
| 3 | 厂 `HAL_WDT_Start(3,10)` | `rc=1` 失败（缺 `MI_WDT_Open` 前置）；`/dev/watchdog` 不存在 |
| 4 | `MDrv_WDT_Init(0)+MDrv_WDT_SetTimer(0,20)` 干净版 | 120 s 不复位（更早三次"复位"是模块诊断代码自己 oops/panic） |
| 5 | 直接写 `pm+0x6000`/`pm+0x600C` | 超时 5.5 ms 仍不复位；`+0x0C` 读回 `0xFFFF` |
| 6 | `machine_restart()` | 落待机（切电） |

早期几次"设备自己回 Android"的真正原因：**BCB 没写进 `misc` ⟹ mboot 走了 `bootcmd`**，
与看门狗无关。

**唯一会 warm reset 的是 `panic()`**：厂内核 `[WdtHeartBeatTas]` 线程喂一颗 5 s 的狗，
panic 停掉所有 CPU ⟹ 没人喂 ⟹ 狗咬 ⟹ 复位且 **DRAM 保留**。普通挂死不会触发。

"""
    s = s[:m.start()] + new + s[m.end():]
    print("§34.13 改为事实条目")

# ---------- 6. §G 里把划线的旧说法整段删掉 ----------
s = re.sub(r"  - ~~\*\*?镜像[^\n]*\n(?:    [^\n]*\n)*", "", s)
s = "\n".join(l for l in s.split("\n") if "~~" not in l)

open(p,"w").write(s); print("confirmed-facts 清理完成")
