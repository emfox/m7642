import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.15" not in s:
    s=s.rstrip("\n")+"""

### 34.15 卡点三：`0x463958` 之后紧跟一段「关中断 + 换 TTBR0 + TLBI」的代码（2026-11-22 16:2x）

`su5`/`d0` 都回来了（`d0 = 0x463958`，实测 **10 s 就回来**——新快路径生效），
而 `c1 = 0x463a04` 不回**且记录为空** ⟹ 那个点根本没执行到。

把 `0x463958` 起 0xAC 字节摊开后，看到 `d0` 后面立刻是这样的序列：

```
0x463958  mov  x0, #0xc0
0x46395c  msr  daif, x0          ← I/F 全屏蔽（中断关闭）
0x463964  adrp x0, reserved_pg_dir
0x463974  sub  x0, x0, x2
0x463978  msr  ttbr0_el1, x0     ← 换 TTBR0
0x463984  tlbi vmalle1
0x463990  mrs  x0, tcr_el1
0x463994  and  x2, x0, #0x3f ; cmp x2, #0x19
0x46399c  b.eq 0x4639b4          ← T0SZ 已经是 25 就跳过改写
0x4639a8  msr  tcr_el1, x0       ← 否则把 T0SZ 改成 25
0x4639b4  adrp x0, …+0xa80       ← init_thread_union 附近
0x4639c0  b.eq 0x463a00          ← x1 == 该地址则直接跳到 bl efi_init
0x4639d4  b.eq 0x463d98          ← 否则另有支路
0x4639e8  b.hi 0x463d78          ← 再一支路
0x4639fc  bl   cpu_do_switch_mm
0x463a00  bl   efi_init
0x463a04  ← c1 的检查点（从未执行到）
```

**两条推论**：

1. 这一段**关着中断**。里面任何异常（比如 `ttbr0_el1` 指向的 `reserved_pg_dir` 不可用导致的
   取指/取数中止）都会变成**关中断的死循环**——外部表现正是"停 logo、ping 不通、按键无效"。
2. `c1` 没到，有两种可能：**(a) 死在这段里**，或 **(b) 从 `0x4639d4`/`0x4639e8` 分支走了别的路**
   （那两条 `b.eq`/`b.hi` 的目标 `0x463d98`/`0x463d78` 都在 `0x463a04` 之后，
   所以**即使内核健康，`0x463a04` 也可能永远不执行**）。⟹ "c1 不回"不能直接判成"efi_init 挂了"。

**为此建的下一批点**（主路径必经，且能顺便把分支条件读出来）：

| 档 | 偏移 | 含义 | md5 |
|---|---|---|---|
| `e0` | `0x4639b4` | TTBR0/TLBI/TCR 那段**之后**第一条：过了就说明这段没杀我们 | `e761d7d4…` |
| `e1` | `0x4639c0` | `b.eq` 本身；tramp 的 entry 寄存器里有 `x1`，正好是被比较的值 | `9ce33859…` |

`e1` 回来之后，把记录的 `x1` 与 `0xffffffc0805d9a80` 比一下就知道走没走 `0x463a00` 那条直路。

**代价说明**：这一发 `c1` 挂死后**红外两次都没救回**（`d1` 连推都推不上），又只能拔电。
所以后续每发都要挑"最可能在健康路径上"的点，并尽量用 `merge` 把多个点串在一次上电里。
"""
    open(p,"w").write(s); print("§34.15 已加")

p=os.path.join(D,"discipline.md"); s=open(p).read()
if "关中断的调试窗口" not in s:
    s=s.rstrip("\n")+"""

### 关中断的调试窗口要格外小心

`setup_arch` 里有一段 `msr daif,#0xc0` + `msr ttbr0_el1` + `tlbi vmalle1` 的代码
（`0x46395c`–`0x4639b0`）。**中断关着的时候任何异常都不会被打印，只会变成死循环**，
外部表现与"内核挂死"完全一样，而且这类挂在 `0x463958` 之后出现时
`0x463a04` 这类点会"记录为空"——**不能凭"记录为空"断定内核没到过附近**，
还要看是不是分支跳过去了（`0x4639d4`/`0x4639e8` 两条支路都绕过 `0x463a04`）。
"""
    open(p,"w").write(s); print("discipline 已加")
