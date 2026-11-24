import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

OLD3="""3. **最可能的真正根因**：dtb 的 `enable-method`（`psci` / `spin-table`）与
   `cpu-release-addr` 与 7.3 的期望不一致。**这一项宿主侧就能查，先查它。**"""
NEW3="""3. ~~最可能的真正根因：dtb 的 `enable-method` / `cpu-release-addr` 与 7.3 不一致~~
   **——已排除（2026-11-21 23:43 实测）**：`/cpus` 根本没有 `enable-method`，各 CPU 是
   自旋表式 `cpu-release-addr = <0 0x100510>`；而 **SMP 初始化在 `start_kernel` 之后**，
   与我们这个早期卡点无关。不要再查这一项。"""

for f in ("NEXT-SESSION.md","HANDOFF.md"):
    p=os.path.join(D,f); s=open(p).read()
    if OLD3 in s:
        s=s.replace(OLD3,NEW3,1)
        if "不要再查这一项" in s and "复工仪式" not in s:
            s=s.replace("**规矩**：设计新探针之前","""**新会话第 0 步**：跑 `tools/host/session-start.sh`（可选带关键词）。它会打印最近提交、
上面这块结论、树里已有的探针清单，以及**上一个会话最后几条用户消息**——信息全在
`~/.dsh/sessions/` 的原始对话记录里，`zstdcat <dir>/session.v4.jsonl.zstd | less` 可查全文。

**规矩**：设计新探针之前""",1)
        open(p,"w").write(s); print("updated",f)

p=os.path.join(D,"discipline.md"); s=open(p).read()
a="**别用短超时 WDT 兜底跑探针：它会把\"能回\"变成\"挂死\"。**"
if a in s and "tv-wait.sh" not in s:
    add="""**挂死后自动救回已经脚本化，不需要人拔插。**

`tools/host/tv-wait.sh`：先等，等不到就**发红外电源键**（`tvpower.sh on`）再等，并在
输出里标明"这一次挂过"。所有 runner（`run-postmmu`/`run-cmd17`/`run-wt`/`run-wr1`/
`run-clk`/`run-hangtest`）都已接上 ⟹ 一发的成本从"等人拔插"降到"多等 25 秒"。
实测：待机态按电源键 → adb 可用 25 s。

"""
    s=s.replace(a,add+a,1); open(p,"w").write(s); print("discipline 已加")
