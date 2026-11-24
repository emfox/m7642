import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.7" not in s:
    s=s.rstrip("\n")+"""

### 34.7 ★★★ 找到 `br x8` 的去向了：它跳进**数据区**（2026-11-22 14:0x 实测）

把已证明能用的 tramp 扩展两条指令（`mov x21,x8` / `mrs x22,sctlr_el1`），由
`abort-postmmu` 统一写盘（单一写者、已验证的写窗口），`ps0` 一发拿到：

| 字段 | 值 | 判读 |
|---|---|---|
| `x8`（`br x8` 的目标） | **`0xffffffc0804e805c`** | 见下 |
| `SCTLR_EL1` | **`0x34d4d91d`** | M=1（MMU 开）、C=1（D-cache 开）、I=1 |
| `x30` | `0x206d55b4` | checkpoint 返回地址，⟹ `_text` 运行在 PA `0x20280000` ✓ |

**关键**：`System.map` 里 `__primary_switched = 0xffffffc08046805c`，镜像 `0x46805c` 处是
`d503245f`（`bti c`）✓；而 `x8` 指向的 `0x4e805c` 处是 **`00000000 8062e354`**——那是
`.rodata/data` 区，**不是代码**。

⟹ **`br x8` 一跳过去就执行数据，必然挂死。** 这就是 `prsw`/`ps1`（以及未打补丁的 7.3
真跑）在 `br x8` 之后没有下文的直接原因，而且**与我们的 tramp 无关**。

**差值 +0x80000（512 KB）**。已排除的：
- 不是 KASLR：`CONFIG_RANDOMIZE_BASE` **未开**（`CONFIG_RELOCATABLE=y`）；
- 不是装错地址：`x30` 与 shim 都指向 `_text` PA `0x20280000`；
- 不是我们改坏的：`0x4555c0` 的 `R_AARCH64_RELATIVE` addend 仍是
  `-0x3f7fb97fa4` ⟹ 未重定位时应为 `0xffffffc08046805c` ✓。

⟹ **是内核自己的 `relocate_kernel` 加了 +0x80000**，即它认为自己比链接地址高了 512 KB。
下一步该查的是 `__pi_relocate_kernel` 的 offset 从哪来（`kimage_voffset` 的计算），
以及为什么恰好是 0x80000（注意我们的 `--stub` 把 kernel 补齐到 `0x1400000`、
`kernel_size` 变成 `0x1400800`，这是个高度可疑的候选）。

**判据**：这一条一旦坐实，就能解释"7.3 跑到 `br x8` 就空转"的全部现象，
不需要 `wfe` 假设，也不需要从核假设。
"""
    open(p,"w").write(s); print("confirmed-facts 34.7 已加")

for f,marker in (("NEXT-SESSION.md","34.7"),("HANDOFF.md","34.7")):
    p=os.path.join(D,f); s=open(p).read()
    if "br x8 跳进数据区" in s: continue
    s=s.replace("**新会话第 0 步**","""**2026-11-22 14:0x 最新（优先看这条）**：`x8`（`br x8` 目标）实测为
`0xffffffc0804e805c`，而 `__primary_switched` 在 `0x8046805c`——**差 +0x80000，落在数据区**，
`br x8` 一跳过去就是执行数据 ⟹ 这一条足以解释"跑到 `br x8` 之后没有下文"。
`SCTLR_EL1=0x34d4d91d` ⟹ MMU/cache 都开着。详见 `confirmed-facts.md` §34.7。
下一步：查 `__pi_relocate_kernel` 的 offset 为什么是 +0x80000（`--stub` 把 kernel
补齐到 `0x1400000` 是首要嫌疑）。

**新会话第 0 步**""",1)
    open(p,"w").write(s); print("updated",f)
