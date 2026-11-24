import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.10" not in s:
    s=s.rstrip("\n")+"""

### 34.10 静态调查：为什么晚期的挂死红外救不回（2026-11-22 15:2x）

#### 已确认的机制（源码 + 文档）

1. **红外电源键由 PM51（常电 8051）解码**，按一次 = MCU 自己把 DC 断掉再送上
   （`pm51-standby.md` §三、§五.1）。所以"断电重启"本身不依赖 AP 是否活着。
2. **但 AP 活着的时候，PM51 不是那个处理按键的人。** 厂商 PM 驱动的状态机：

   | 事件 | 源码（`drivers/mstar2/drv/pm/mdrv_pm.c`） | 效果 |
   |---|---|---|
   | 挂起前 | `MDrv_PM_Suspend(E_PM_STATE_SUSPEND_PREPARE)`: `MDrv_PM_CopyBin2Sram()` 然后 **`gRTPM_Live = 0`** | 把 PM.bin 与唤醒键表交给 MCU，宣告"AP 走了" |
   | 恢复时 | `MDrv_PM_Resume(E_PM_STATE_POWER_ON_DC)`: `MHal_PM_Disable_8051()` → 拷 RTPM bin → `MHal_PM_SetDRAMOffsetForMCU()` → **`gRTPM_Live = 1`** | 关掉 8051、把 MCU 切到跑 RTPM 代码，宣告"AP 接管" |

3. 内核与 MCU 共享一块运行期 PM 区：cmdline `RTPM_INFO=1,0x43FF0000`
   （`early_param("RTPM_INFO", MDrv_PM_Set_RTPM_Info)`），落在 RAM 空洞里。

⟹ **判据**：只有 MCU 处于"唤醒键模式"（`gRTPM_Live == 0` 之后、AP 还没接管）时，
红外 POWER 才会被 MCU 自己执行。**一旦 AP 接管（`Live == 1`），POWER 走的是
"AP 的输入子系统 → Android 关机流程 → 内核把电源交给 MCU"，AP 一挂就没人做这一步。**

#### 对本次现象的解释力与缺口

- **解释力**：晚期挂死时 AP 已经跑到 `setup_arch`（内存/页表/早期 ioremap 都动过），
  如果这一刻 MCU 处于 RTPM/8051 关闭状态，红外按键就**没有任何人处理** ⟹ 只有拔电。
- **缺口（必须说清）**：按上面的模型，"早期挂死"和"晚期挂死"的 MCU 状态**应该是一样的**
  （两者都在 recovery 启动里、都没走到交接），所以**深度与可恢复性之间的相关性，静态推不出来**。

#### 因此还有第二个同样可能的解释：红外根本没送到

`tools/host/tvpower.sh` 走的是**米家云 → 小爱音箱**。返回 `✅ Sent` 只代表云端接受了请求，
不代表电视收到。今天下午连续发了十几次，完全可能被限流/丢包。**这条与硬件无关，必须排除。**

#### 静态能给出的最实用结论：用 ≥60 s 的 WDT 把"硬挂"变成"待机"

- 已知：`wdt_enable n` 能让设备自己 warm reset，且复位后停在**待机**（§34.3 实测）；
- 已知：**待机态下红外一次 25 s 就起来**（今天多次实测）；
- 已知：10 s 的狗会打断交接链（链要 30–35 s，§34.4），所以要用 **≥60 s**；
- 厂商内核有自己的喂狗线程（`[WdtHeartBeatTas]`），所以正常跑完的那一发不会被狗打断。

⟹ **晚期检查点（`sched_init` 及之后）建议一律带 `wdt_enable 60`**：
挂了就是"60 s 后自己回待机"，然后红外一次即可 —— 把"必须拔电"降级成"多等 60 s"。

#### 待验证（下次一并做，代价小）

| 问题 | 判法 |
|---|---|
| 挂死时屏幕是黑屏还是停在 logo？ | 黑屏 ⟹ MCU 已切断面板（它在动手）；停在 logo ⟹ AP 仍持电、MCU 没动 |
| 挂死后发 POWER，屏幕有没有任何变化？ | 有变化但没启动 ⟹ MCU 收到了、只是没走完；完全无变化 ⟹ 要么没收到、要么 MCU 认为 AP 活着 |
| 挂死时能否 ping 通？ | 通 ⟹ AP 还活着（只是内核死在某处）；不通 ⟹ 电断了或 AP 死透 |
| 同一张晚期镜像，换 `wdt_enable 60` 再跑一次 | 自己回待机 ⟹ 上面那条缓解成立，且证明"拔电"其实只需要"一次冷复位" |
"""
    open(p,"w").write(s); print("34.10 已加")

p=os.path.join(D,"discipline.md"); s=open(p).read()
a="**挂死后自动救回已经脚本化，不需要人拔插。**"
if a in s and "晚期检查点带 wdt_enable 60" not in s:
    add="""**晚期检查点（`start_kernel` 之后）带 `wdt_enable 60`；红外只对"待机"有效。**

红外 POWER 在 AP 活着时由软件处理（厂商 PM 驱动的状态机 `gRTPM_Live`），AP 一挂就没人
做那一步；只有 MCU 处于唤醒键模式（待机/关机）时它才自己断电重启。所以"红外救不回"
不等于硬件坏了。可行做法：`wdt_enable 60` 让设备自己复位回待机，再红外一次
（10 s 的狗不行——交接链要 30–35 s，§34.4）。

"""
    s=s.replace(a,add+a,1); open(p,"w").write(s); print("discipline 已加")
