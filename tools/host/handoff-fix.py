import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

BLOCK = """
## ★ 当前最强结论（别再重推一遍）

> 2026-11-21 §27/§28 已用实测**排除了整类「fault」假设**，并给出根因候选。
> 今天（2026-11-22）有会话没读到这条，把 fault 假设又走了一遍，白费三次断电。

1. **7.3 不是异常挂死，是空转/等待。** 异常探针 `probes/handoff/vecprobe.S`（装自建
   VBAR → 记录 ESR/ELR/FAR/SPSR → 交接厂内核，Android 34 s 起来）自检 `brk #0x1234`
   抓到 `ESR_EL2=0xF2001234`（EC=0x3C、ISS 与参数一致）、`ELR_EL2=0x21680018`、
   `SPSR_EL2=0x600003C9` ⟹ 探针有效；对照组让未打补丁的 7.3 真跑 → **挂住，零异常**。
2. **最强根因候选：`wfe` 等从核。** `0x455000–0x466000` 无回边；5 处 `wfe/wfi`，其中
   `0x4557F0`（`wait_linear_map_split_to_ptes`/`scondary_cpu_wait`）与
   `0x4554D8`（`secondary_holding_pen`）最可疑：从核被 mboot 停在**厂内核**地址上，
   永远到不了 7.3 的同步点 ⟹ 主核在 `wfe` 里无限等，**不产生异常**。
3. **最可能的真正根因**：dtb 的 `enable-method`（`psci` / `spin-table`）与
   `cpu-release-addr` 与 7.3 的期望不一致。**这一项宿主侧就能查，先查它。**
4. 2026-11-22 新增的边界约束：`Image+0x4555b0`（`br x8`）**能回**，
   `Image+0x468060`（`__primary_switched+4`）**不能回** ⟹ 空转点在 `br x8` 之后。
   注意 `ps0`/`mk*` 那类能回的点都走 tramp 的 **PA 入口**，不能回的两个都走**内核 VA 入口**，
   所以"KVA 入口本身是否可用"仍未排除（`kva6` 是为这个建的，零访存，安全）。

**规矩**：设计新探针之前，先 `grep` 一遍 `probes/` 和 `confirmed-facts.md`——
这个仓库里已经躺着 27 个 `.S` 探针，重复造轮子等于重复付代价。
"""

p=os.path.join(D,"HANDOFF.md")
s=open(p).read()
if "当前最强结论（别再重推一遍）" not in s:
    i=s.index("\n## ")
    s=s[:i]+BLOCK+s[i:]
    open(p,"w").write(s)
    print("HANDOFF.md 顶部加了结论块")

p=os.path.join(D,"NEXT-SESSION.md")
s=open(p).read()
if "当前最强结论（别再重推一遍）" not in s:
    i=s.index("\n## ")
    s=s[:i]+BLOCK+s[i:]
    open(p,"w").write(s)
    print("NEXT-SESSION.md 顶部加了结论块")

p=os.path.join(D,"discipline.md")
s=open(p).read()
a="**DDR stash 只在同一次启动内有效；跨复位要用 eMMC。**"
if a in s and "设计新探针之前先 grep" not in s:
    add="""**设计新探针之前，先 grep `probes/` 和 `confirmed-facts.md`。**

代价：2026-11-22 花掉三次断电去验「7.3 是不是被 fault 打死的」——而 2026-11-21
§27 已经用自建向量表实测证明**零异常、是空转**，§28 连最强候选（`wfe` 等从核 /
dtb `cpu-release-addr` 不匹配）都写好了。代码没丢，丢的是**结论没进交接单**：
`HANDOFF.md` 与 `NEXT-SESSION.md` 里当时既没有"空转"也没有 `wfe`。现在两块顶部都加了
「当前最强结论」块。**新会话开工第一件事是读它，而不是从"卡在哪一级"重新出发。**

"""
    s=s.replace(a,add+a,1)
    open(p,"w").write(s)
    print("discipline 已加")
