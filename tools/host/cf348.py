import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.8" not in s:
    s=s.rstrip("\n")+"""

### 34.8 ★★★★★ 7.3 到达 `start_kernel` —— 根因是「2 MB 对齐修正」（2026-11-22 14:4x）

**一句话：`br x8` 之所以跳到数据区，是因为内核按「镜像不在 2 MB 对齐地址」给自己加了
`+0x80000` 的重定位偏移；把这个修正强制为 0，7.3 就从 `br x8` 一路跑到 `start_kernel`。**

#### 证据链（全部实测）

| 步骤 | 手段 | 结果 |
|---|---|---|
| 1 | 把已证明能用的 tramp 多存几个寄存器（`x8` 与 entry `x0..x4`），由 `abort-postmmu` 统一写盘 | 拿到 `x8 = 0xffffffc0804e805c`、`SCTLR_EL1 = 0x34d4d91d`（MMU/cache 都开） |
| 2 | 对照 `System.map`：`__primary_switched = 0xffffffc08046805c`；镜像 `0x46805c` 处是 `d503245f`（`bti c`），而 `0x4e805c` 处是 `00000000 8062e354` | **`br x8` 跳进了数据区** |
| 3 | 在 `__pi_relocate_kernel`（`Image+0x4679bc`）入口打点，采 `x0..x4` | **`x0 = 0x80000`**（就是重定位偏移）；`x1 = 0x206d8000`（rela 表） |
| 4 | 反汇编调用点与 `__pi_early_map_kernel` 开头 | `0x465a1c: and x25, x19, #0x1fffff`，而 `x19 = adrp _text`；**MMU 关着时 `adrp` 给的是物理地址** ⟹ `0x20280000 & 0x1fffff = 0x80000` |
| 5 | 把 `0x465a1c` 强制成 `mov x25, xzr`（`0xaa1f03f9`），检查点仍在 `0x4555b0` | `x8` 变成 **`0xffffffc08046805c`** ✓ |
| 6 | 检查点后移一位到 `0x468060`（`__primary_switched+4`，走 **KVA 入口**） | **回来**，`x30 = 0xffffffc080468064`（内核 VA） |
| 7 | 检查点放到 `start_kernel`（`Image+0x46091c`） | **回来**，`x30 = 0xffffffc080460920` |

⟹ **7.3 现在能到 `start_kernel`。** 之前所有「`br x8` 之后空转」的现象，根因是
**跳进了数据区**，与 `wfe`/从核/异常都无关（§27 的"零异常"也因此得到解释：
它根本没执行到会空转的代码，而是把数据当指令跑了）。

#### 为什么会这样

arm64 的启动协议要求 **Image 放在 2 MB 对齐的物理地址**上。mboot 把内核装在
`0x20280000`（**不是** 2 MB 对齐：`0x20280000 mod 0x200000 = 0x80000`）。厂内核是为这个
地址编的、自己处理得过来；主线按协议假设对齐，于是自己算出一个 512 KB 的修正量，
把**所有重定位指针**连同 `br x8` 的目标一起推高了 512 KB。

#### 尝试过的两条路

| 做法 | 结果 |
|---|---|
| 改容器头里的 `kernel_addr` 为 2 MB 对齐的 `0x20400000`（`--kernel-addr`） | **硬挂**，红外救不回，需物理拔插 ⟹ mboot 不认这个字段（或仍按 `0x20280000` 装），shim 跳到了错地址 |
| **把对齐修正强制为 0**（`--word 0x465a1c=0xaa1f03f9`） | **成功**（见上表 5–7） |

#### 复现方式

```sh
cd ~/Debian/m7642/probes/handoff
./mk-zfix.sh 0x46091c skmainz kva     # start_kernel 检查点，带对齐修正
./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-skmainz.img <md5> skmainz
```

`mk-zfix.sh <image-offset> <tag> [pa|kva]` 把 `0x465a1c` 的修正清零并打检查点；
`kva` 用于 `br x8` 之后的点（内核 VA 段），`pa` 用于之前的点。

#### 镜像

| 镜像 | md5 | 含义 |
|---|---|---|
| `m7642-rec-73-ps0z.img` | `5e2fbf177c892bd2fe5f8f9fe390eaf6` | 对齐修正 + 检查点 `0x4555b0`，`x8` 已正确 |
| `m7642-rec-73-ps1z.img` | `1a09faa129eddc70289db21a318ae871` | 检查点 `0x468060`（`__primary_switched+4`），回来 |
| `m7642-rec-73-skmainz.img` | `787821010db807f9aef183b633f879b5` | 检查点 `start_kernel`（`0x46091c`），回来 |

#### 下一步

卡点已从「`br x8`」推进到「`start_kernel` 之后」。继续用同一套 `mk-zfix.sh` 把检查点往
`setup_arch` / `mm_init` / `rest_init` 推进，第一个不回来的档就是新的卡点。
注意：**所有后续镜像都必须带这个对齐修正**，否则又会在 `br x8` 处跳飞。
"""
    open(p,"w").write(s); print("confirmed-facts 34.8 已加")

BLOCK="""**2026-11-22 14:4x ★★★★★ 7.3 到达 `start_kernel`（重大突破）**

`br x8` 跳到数据区（`0xffffffc0804e805c`）的根因是：`__pi_early_map_kernel` 用
`and x25, x19, #0x1fffff` 算「镜像与 2 MB 对齐的差」，而 `adrp _text` 在 **MMU 关**时给的是
物理地址 ⟹ `0x20280000 & 0x1fffff = 0x80000`，这个值被当作重定位偏移传给
`__pi_relocate_kernel`（已采到 `x0=0x80000`），把所有重定位指针推高 512 KB。
arm64 要求 Image 放在 2 MB 对齐地址，mboot 偏要放 `0x20280000`。

**修法**：把 `Image+0x465a1c` 强制成 `mov x25, xzr`（`0xaa1f03f9`）。
结果：`x8` 变回 `0xffffffc08046805c`；检查点 `0x468060` 回来（`x30` 是内核 VA）；
**`start_kernel`（`0x46091c`）回来**（`x30 = 0xffffffc080460920`）。

⟹ 后续所有镜像**必须带这个修正**，用 `probes/handoff/mk-zfix.sh <off> <tag> [pa|kva]`。
详见 `confirmed-facts.md` §34.8。

"""
for f in ("NEXT-SESSION.md","HANDOFF.md"):
    p=os.path.join(D,f); s=open(p).read()
    if "7.3 到达 `start_kernel`" in s: continue
    s=s.replace("**2026-11-22 14:0x 最新（优先看这条）**", BLOCK+"**2026-11-22 14:0x（已被上面这条取代，仅存档）**",1)
    open(p,"w").write(s); print("updated",f)
