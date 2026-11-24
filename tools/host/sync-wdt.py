import os, re
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

# ---------- 1. wdt-beacon.md 顶部加更正块 ----------
p=os.path.join(D,"wdt-beacon.md"); s=open(p).read()
BLOCK = """
# WDT 信标：看门狗让设备自己重启

> # 🔴 结论更正（2026-11-22）：**WDT 不可用，这一整篇的"自动复位"前提已作废**
>
> 本文 §一~§八 建立在"`wdt_enable n` 能让设备自己在 n 秒后复位"这个前提上。
> 该前提已被 **2026-11-21 的实测全部否证**（证据在 `confirmed-facts.md` §34.13）：
>
> | 路径 | 实测结果 |
> |---|---|
> | mboot `wdt_enable 10` | **两次"有硬证据进了 recovery"的轮次，挂住不恢复**（`misc` 尾部标记法证明 `recoverycmd` 真跑了） |
> | mboot `wdt_enable 120` | mboot 自己 40 s 超时**先进待机**，狗响不响都看不见 |
> | 厂 `HAL_WDT_Start(3,10)` | `rc=1` 失败（需先 `MI_WDT_Open`）；`/dev/watchdog` 不存在 |
> | `MDrv_WDT_Init(0)+MDrv_WDT_SetTimer(0,20)` | 干净版 **120 s 不复位**（更早三次"复位"是诊断代码自己 oops/panic） |
> | 直接写 WDT 寄存器 `pm+0x6000/0x600C` | 超时改到 5.5 ms 仍不咬 |
> | `machine_restart()` | 落到**待机**（切电） |
>
> **为什么"看起来有效过"**：早先几次"设备自己回到 Android"，实际是 **BCB 没写进去 ⟹ mboot 走了
> `bootcmd`**，与狗无关。这条误解直到 11-21 14:20 用 `misc` 标记法才被排除。
>
> **唯一会 warm reset 的是 `panic()`**，而且不是因为 WDT 被我们布防：厂内核有
> `[WdtHeartBeatTas]` 线程在喂一颗 **5 s** 的狗，`panic` 停掉所有 CPU ⟹ 没人喂 ⟹ 狗咬 ⟹
> warm reset、DRAM 保留。**我们的 7.3 探针没有这个条件。**
>
> **另外**：`待机` = PM51 切 DC = **DRAM 必丢**（11-21 13:19 实测：写进 ramoops 区、
> 写前验过的记录 `M7642SURV1`，经"回待机 + 红外开机"后读回 `ff`）。
>
> ⟹ 现在的有效结论：**不存在"挂了还能自动回来且记录还在"的路径**。
> 调试只能"只打会返回的检查点"，用二分夹逼；跨复位/跨断电的记录只有 eMMC 能给。
>
> 本文其余部分仍然有价值，但请当作**历史记录**读：§九~§十六里的
> "pstore/pmsg 通道""handoff 探针""boot 槽 code1 读数通道"这些**结论仍然成立**，
> 只有"用 WDT 兜底"这层壳不成立。
"""
if "结论更正（2026-11-22）" not in s:
    s = BLOCK + "\n" + re.sub(r"^# WDT 信标：看门狗让设备自己重启\n", "", s, count=1)
    open(p,"w").write(s); print("wdt-beacon.md 顶部更正块已加")

# ---------- 2. §34.3 / §34.10 / §34.12 标注被 §34.13 取代 ----------
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
marks = {
 "### 34.3 挂住后能不能留下读数：WDT 与 stash 的实测（2026-11-22 12:0x–12:3x）":
   "> ⚠️ **本节关于 `wdt_enable` 的前提已被 §34.13 推翻**（WDT 根本不咬）。"
   "结论部分（stash 只在同一次启动内有效；待机切电清 DRAM）仍然成立。\n\n",
 "### 34.10 静态调查：为什么晚期的挂死红外救不回（2026-11-22 15:2x）":
   "> ⚠️ **本节第 4 小节建议的「带 `wdt_enable 60`」已作废**（见 §34.13：WDT 不咬）。"
   "前 3 小节的机制分析仍成立。\n\n",
 "### 34.12 「WDT 回待机」这条路，记录还能不能保住？（2026-11-22 15:3x 分析）":
   "> ⚠️ **本节已被 §34.13 取代**：`wdt_enable` 不会复位，所以「WDT 回待机」这个组合不存在；"
   "而「待机清 DRAM」已由 11-21 的 `M7642SURV1` 实测证实。\n\n",
}
for h, note in marks.items():
    if h in s and note not in s:
        s = s.replace(h, note + h, 1); print("标注:", h[:20])

# ---------- 3. §H「已否定」清单里补一条 ----------
if "WDT 能用来兜底自动复位" not in s:
    # 找 §H 里第一个表格行，追加一行
    m = re.search(r"(### .*?已否定.*?\n\n\|[^\n]*\|\n\|[-\s|]*\|\n)", s, re.S)
    if m:
        row = ("| **「WDT 能兜底自动复位」** | **否（强证据）** | mboot `wdt_enable 10/120`、"
               "`HAL_WDT_Start`、`MDrv_WDT_*`、直写寄存器，**四条都不咬**；"
               "此前「自己回来」是 BCB 没写走了 `bootcmd`（`misc` 标记法证明）。见 §34.13 |\n")
        s = s[:m.end(1)] + row + s[m.end(1):]
        print("§H 已否定清单补一条")
open(p,"w").write(s)

# ---------- 4. index.md 的 WDT 信标条目 ----------
p=os.path.join(D,"index.md"); s=open(p).read()
old="| [wdt-beacon.md](wdt-beacon.md) | **★ WDT 信标**：用 mboot 自带的 `wdt_enable` 让设备自己重启，靠 DDR 标记分级 —— 颜色通道废掉之后的替代判据 |"
new="| [wdt-beacon.md](wdt-beacon.md) | ⚠️ **WDT 自动复位已否证（2026-11-21 实测，见 §34.13）**；本文保留作为 pstore/pmsg 通道与 boot 槽读数通道的记录 |"
if old in s:
    s=s.replace(old,new,1); open(p,"w").write(s); print("index.md 条目已改")

# ---------- 5. HANDOFF.md / NEXT-SESSION.md 顶部补一句 ----------
JUDGE = """
> **判据速查（2026-11-22 定）**：
> - **WDT 不可用**：`wdt_enable`/`HAL_WDT_Start`/`MDrv_WDT_*`/直写寄存器全部实测不咬
>   （`confirmed-facts.md` §34.13）。唯一会 warm reset 的是 `panic()`（厂内核 5 s 心跳狗）。
> - **stash 可用，但只在同一次启动内有效**：`0x23080000`（交接记录）/`0x23090000`（code1 shim），
>   探针"写记录 → 交接厂内核 → Android 起来 → `probeRW` 读"这条链是好的（今天多次验证）。
> - **待机 = 切电 = DRAM 全丢**（`M7642SURV1` 记录实测），所以挂了之后靠复位/待机都留不下数据。
> - **挂了之后能不能自动回来**：不能。屏幕停 logo（AP 带电）= 只能人工拔电；
>   屏幕黑（进了待机）= 红外一次可救。
"""
for f in ("HANDOFF.md","NEXT-SESSION.md"):
    p=os.path.join(D,f); s=open(p).read()
    if "判据速查（2026-11-22 定）" not in s:
        i=s.index("\n## ")
        s=s[:i]+JUDGE+s[i:]
        open(p,"w").write(s); print(f,"加判据速查")

# ---------- 6. 脚本注释 ----------
for rel,old,new in [
 ("probes/handoff/halt.S",
  " * Purpose: prove the harness, not the kernel.  If recoverycmd is armed with\n"
  " * `wdt_enable 10`, a hang here must be followed by a watchdog warm reset and an\n"
  " * automatic return to Android in ~20-40 s -- no power key, no unplug.  The\n"
  " * record written *before* the spin must survive in DDR and be readable\n"
  " * afterwards with probeRW.",
  " * Purpose: produce a hang, so the recovery path can be exercised.\n"
  " *\n"
  " * 2026-11-22: `wdt_enable` does NOT bite (see confirmed-facts.md §34.13 -- four\n"
  " * paths measured), so a hang here is NOT recovered automatically: the TV stays\n"
  " * on with the logo up and needs the power plug pulled.  Do not expect the DDR\n"
  " * record to survive either -- standby cuts DC, and an unplug kills DRAM."),
 ("probes/handoff/run-hangtest.sh",
  "# Prove the harness self-recovers from a hang.",
  "# Exercise the hang-recovery path.  NOTE: as of 2026-11-22 the expectation is\n"
  "# the OPPOSITE of what this script was written for -- `wdt_enable` does not\n"
  "# bite (§34.13), so a hang here needs a human unplug.  Kept as a probe of the\n"
  "# recovery behaviour, not as a self-heal test."),
]:
    p=os.path.expanduser("~/Debian/m7642/"+rel)
    if os.path.exists(p):
        s=open(p).read()
        if old in s:
            open(p,"w").write(s.replace(old,new,1)); print("注释更新:",rel)
