import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

p=os.path.join(D,"confirmed-facts.md")
s=open(p).read()
if "34.2" not in s:
    s=s.rstrip("\n")+"""

### 34.2 追 `br x8`：两次作废的探针与真正的约束（2026-11-22 11:1x）

`prsw`/`ps1` 都不回来、`ps0`（`br x8` 本身）回来 ⟹ 失败点在**「跳进内核 VA」这一步**。
设计判别探针时连踩两个坑，两次都花掉一次物理断电：

**坑一：blob 盖掉了 code1 shim。** 第一版 `kvacheck` 有 280 B，放在 `Image+0x36c000`，
而 code1 的 FDT shim 固定在 `Image+0x36c0c0`。结果 `bl 0x36c0c0` 落进 kvacheck 中间——
挂死与「VA 能不能读」毫无关系。离线复验方法：读镜像 `+0x36c0c0` 的 8 字节，
应等于 shim 的 `movz x6,#0 / movk x6,#0x2309,lsl16`（`060080d2 2661a4f2`）。
现在探针一律放 `Image+0x36d000`。

**坑二：MMU 开着的时候写 stash 会挂。** 第二版把 `x8` 先写进 `0x23090000` 再读 VA，
又挂。原因：**MMU 打开时 stash 页不保证可达**——正常 tramp 之所以没事，是因为它
先读 `boot_args`（能读）、**关掉 MMU 之后才写 stash**；而 `0x23090000` 这类 DDR 页不在
idmap 里，MMU 一开就不一定能访问。这一发同样不能证明任何关于 VA 的事。

**由此定下的探针写法**：MMU 开着时只做**那一个**要测的访存，答案留在**寄存器**里；
`msr sctlr_el1` 关掉 M/C/I，之后再把答案写进 stash、再交接。判据标记（`0x600d`）
也只在访存返回后才写，这样「挂」就只能归因于那次访存本身。

已建（`probes/handoff/mk-kva-images.sh`，探针都在 `+0x36d000`）：

| 镜像 | md5 | 问的问题 |
|---|---|---|
| `m7642-rec-73-kva4.img` | `aaba715835b10bb1b4570964fb24beb9` | MMU 开着时读 `_text` 的**内核 VA**（唯一一次访存） |
| `m7642-rec-73-kva5.img` | `bdcc99927d97ca42e45b9cb910c0ffd0` | MMU 开着时**写** DDR `0x23090020` 是否生效 |

记录格式：`0x23090000` = [x8, 读到的值, `0x600d`|`0xbad`, kva5 的回读]，
标记 `0x23090800` = `M764`/`KVA4`|`KVA5`。
"""
    open(p,"w").write(s)
    print("confirmed-facts 34.2 已加")

p=os.path.join(D,"discipline.md")
s=open(p).read()
anchor="**构建目录的移动/清理必须做「重建 + md5 对账」。**"
if anchor in s and "MMU 开着时不要写 stash" not in s:
    add="""**MMU 开着的时候，只能做「要测的那一次访存」，答案先放寄存器，关了 MMU 再落盘。**

代价：2026-11-22 追 `br x8` 时连挂两发、白费两次物理断电。第一发是探针 blob 盖掉了
`Image+0x36c0c0` 的 code1 shim（280 B 放在 `+0x36c000`）；第二发是 MMU 开着就往
`0x23090000` 写记录——stash 页不在 idmap 里，那一写本身就把机器挂死了，
于是「挂了」既不能证明 VA 不可读，也不能证明任何事。正确写法：`mrs/msr sctlr_el1`
把 M/C/I 关掉之后再写 stash（正常 tramp 一直是这么做的）。
**推论：任何 "NO_RETURN" 必须先排除「探针自己写错了」再当结论用。**

"""
    s=s.replace(anchor, add+anchor,1)
    open(p,"w").write(s)
    print("discipline 已加")
