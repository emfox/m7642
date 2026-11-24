import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

p=os.path.join(D,"confirmed-facts.md")
s=open(p).read()
old="""| `m7642-rec-73-kva5.img` | `bdcc99927d97ca42e45b9cb910c0ffd0` | MMU 开着时**写** DDR `0x23090020` 是否生效 |"""
new="""| `m7642-rec-73-kva5.img` | `bdcc99927d97ca42e45b9cb910c0ffd0` | MMU 开着时**写** DDR `0x23090020` 是否生效 |
| `m7642-rec-73-kva6.img` | `70d57d95221a0786dc5ec2233456e4a0` | **零次访存**：只用 `mrs` 抓 `x8`/SCTLR/TTBR1/TCR/VBAR/ESR/FAR |

**实测到这里**：`kva1`（旧版，MMU 开着写 stash）挂、`kva4`（MMU 开着读 `_text` 内核 VA）
挂（500 s，11:35）。两次都还不能当结论——`kva6` 是零访存对照，先确认「那一刻 MMU 是否
真的开着、`x8` 是否是 `__primary_switched` 的内核 VA」，再谈 VA 能不能读。
`kva6` 的记录：`0x23090000` = [x8, SCTLR, TTBR1, TCR]、
`0x23090020` = [VBAR, ESR, FAR]，标记 `M764`/`KVA6`。"""
assert old in s
s=s.replace(old,new,1)
open(p,"w").write(s)
print("confirmed-facts: kva6 与当前状态已记")

p=os.path.join(D,"NEXT-SESSION.md")
s=open(p).read()
add="""
> **2026-11-22 11:4x 停在这里（设备挂死，需一次拔插）**：追 `br x8` 的这一轮，`kva1`
> 和 `kva4` 都挂，但两次都**不能当结论**——`kva1` 是 MMU 开着写 stash（探针自己的错），
> `kva4` 是 MMU 开着读内核 VA，挂在它自己那次访存上。零访存对照已建好：
> **`kva6` = `70d57d95221a0786dc5ec2233456e4a0`**（只 `mrs`，安全），恢复设备后先跑它：
>
> ```sh
> cd ~/Debian/m7642/probes/handoff
> ./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-kva6.img 70d57d95221a0786dc5ec2233456e4a0 kva6
> ```
>
> 记录 `0x23090000` = [x8, SCTLR, TTBR1, TCR]、`0x23090020` = [VBAR, ESR, FAR]。
> 判读：SCTLR 的 M 位若为 0 ⟹ 那一刻 MMU 其实没开（VA 访存必挂，`br x8` 也必挂）；
> 若为 1 ⟹ 看 x8 是否等于 `0xffffffc08046805c`（= `__primary_switched` 的内核 VA），
> 不等就是重定位没填字面量（`0x4555c0` 的 R_AARCH64_RELATIVE）。
> 之后才轮到 `kva5`（MMU 开着写 DDR 的对照），再决定 VA 到底能不能读。
"""
if "kva6" not in s:
    i=s.index("\n## ")
    s=s[:i]+add+s[i:]
    open(p,"w").write(s)
    print("NEXT-SESSION: 停下点与下一步已记")
