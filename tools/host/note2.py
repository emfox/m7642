import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.16" not in s:
    s=s.rstrip("\n")+"""

### 34.16 ★★★ 卡点四：凶手在 `cpu_uninstall_idmap()` 里（2026-11-22 16:3x）

`e0 = 0x4639b4` 也不回（记录为空），所以卡点被夹进 `0x463958`–`0x4639b4` 这 **0x5C 字节**。
对着源码认出这两行就是它：

```c
local_daif_restore(DAIF_PROCCTX_NOIRQ);   /* 0x463958 mov x0,#0xc0 ; msr daif */
cpu_uninstall_idmap();                    /* 0x463960–0x4639b0 */
```

`cpu_uninstall_idmap()` 的汇编展开（逐条）是：

```
0x463960  ldr  x2, [x20]          ← x20 = &init_mm.pgd（0x46387c 刚往这里存过）
0x463964  adrp x0, reserved_pg_dir
0x46396c  mrs  x1, sp_el0         ← current
0x463970  ldr  x1, [x1, #976]     ← current->active_mm
0x463974  sub  x0, x0, x2         ← phys_to_ttbr()：把 kimage 偏移减掉
0x463978  msr  ttbr0_el1, x0
0x463984  tlbi vmalle1
0x463990  mrs  x0, tcr_el1 ; …    ← T0SZ 不是 25 就改成 25
0x4639b4  cmp  x1, &init_mm ; b.eq 0x463a00   ← active_mm == init_mm 则跳过 cpu_switch_mm
```

**意义**：这是 7.3 **第一次切回它自己的页表映射并刷 TLB**。两个后果：

1. **`phys_to_ttbr()` 依赖 `kimage_voffset`**——而 §34.8 的对齐修正（`mov x25, xzr`）恰好动过这个偏移。
   所以这个卡点**可能是我们那个补丁的副作用**，而不是独立的平台问题；
2. `x1` / `x2` 两个值（`active_mm`、`init_mm.pgd`）都在我们的 tramp 记录范围内，
   一发 `f1`（`0x463978`）就能把 `x0`（要写进 TTBR0 的值）和 `x2`（被减掉的偏移）读出来。

待打的三个点：

| 档 | 偏移 | 位置 | md5 |
|---|---|---|---|
| `f0` | `0x463968` | 两次 `ldr` 之后（0x463960/0x46396c–0x463970 都过了） | `78a79871…` |
| `f1` | `0x463978` | `msr ttbr0_el1` 之前，记录里有 x0/x2 | `b658b732…` |
| `f2` | `0x463984` | `tlbi vmalle1` 处（TTBR0 已写） | `dfd7e21c…` |
| `e1` | `0x4639c0` | 整段之后、`b.eq` 处；`x1` 即 active_mm | `9ce33859…` |

**判读**：`f1` 回来 + `e1` 不回 ⟹ 凶手在 `msr ttbr0_el1`/`tlbi`/TCR 那几条里，且 `x0` 的值是否合理
直接决定"是我们补丁的副作用"还是"平台拒绝这个 TLBI"。
"""
    open(p,"w").write(s); print("§34.16 已加")
