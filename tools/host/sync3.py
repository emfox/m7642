import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()

old = """- ★ **但 `reboot recovery` 也会回待机，取决于 recovery 镜像的行为**【现场观察 2026-11-21】：
  - 镜像**卡死** ⟹ `wdt_enable` 10 s 后 warm reset ⟹ **十几秒自己回 Android，不用人**；
  - 镜像 `bootm` 后**返回**（没卡死）⟹ mboot 交权 PM51 ⟹ **停在待机，要按电源键**。
  - ⟹ 「要不要人按」是判断"复位是哪一级"的唯一路标：**要人按 = 切过电 = DDR 全丢**。
    任何读 DDR 标记的实验必须落在前一种，否则读到空不说明任何问题（见 `wdt-beacon.md` §十一）。
  - 正常启动耗时 **35–40 s**（含人按电源键的反应时间），所以**启动时长不能当判据**。
- **`recoverycmd` 里 `wdt_enable 10` 真的布防 WDT**【实测 2026-11-20】。env 加这一条后，
  两次"内核卡死"实验（`white-cc` / `wdt` 镜像）**设备都自己回到了 Android**，
  而此前 `white-halt` 卡死后必须拔电。reboot→内核启动的差额 16–23 s，与"进 recovery +
  卡 10 s + 复位"吻合。⟹ **测试失败的恢复不再需要人：不用拔电、不用 U 盘、不用按键。**
  前提见 `mboot-env.md` §七（`WDT_ENABLE=1`、`recoverycmd` 前 4 字节须为 `mmc `）。"""

new = """- ★ **`reboot recovery` 之后会不会自己回来，取决于 recovery 镜像的行为**【现场观察 2026-11-21】：
  - ~~镜像**卡死** ⟹ `wdt_enable` 10 s 后 warm reset ⟹ 十几秒自己回 Android~~
    **——这条是错的，已否证（§34.13）**：`wdt_enable` 不咬。当时那几次"自己回来"其实是
    **BCB 没写进去 ⟹ mboot 走了 `bootcmd`**（`misc` 标记法证明）。
  - 镜像 `bootm` 后**返回**（没卡死）⟹ mboot 交权 PM51 ⟹ **停在待机，要按电源键**。
  - 镜像**卡死**（带电）⟹ **停在 logo、无人处理电源键** ⟹ **只能拔电**（用户 2026-11-22 实测：
    屏幕停 logo、红外与实体遥控都无反应、ping 不通）。
  - ⟹ 判据是**屏幕**：黑屏 = 进过待机（切过电、DDR 全丢）；停 logo = AP 仍带电（同样拿不到 DDR）。
    **两条路都读不到 DDR 标记**，所以"跨复位读 DDR"这个想法本身不成立。
  - 正常启动耗时 **35–40 s**（含人按电源键的反应时间），所以**启动时长不能当判据**。
- ~~**`recoverycmd` 里 `wdt_enable 10` 真的布防 WDT**【实测 2026-11-20】~~
  **——已否证（§34.13）**。2026-11-20 那两次（`white-cc`/`wdt` 镜像）"设备自己回到 Android"
  用的是**没被验证过"确实进了 recovery"**的判据；11-21 用 `misc` 尾部标记法重做后，
  **两次有硬证据进了 recovery 的轮次都挂住不恢复**。另有 `HAL_WDT_Start`（空桩）、
  `MDrv_WDT_*`（不咬）、直写寄存器（不咬）三条独立否证。
  唯一会 warm reset 的是 `panic()`——厂内核 `[WdtHeartBeatTas]` 喂的 5 s 狗在 panic
  停掉所有 CPU 后才咬；7.3 探针没有这个条件。"""

assert old in s, "G 段原文未匹配"
s = s.replace(old, new, 1)
open(p,"w").write(s); print("§G 待机与电源 已更正")
