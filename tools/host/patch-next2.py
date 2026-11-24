p="/home/emfox/Debian/m7642/Documentation/mstar/m7642/NEXT-SESSION.md"
s=open(p).read()
if "mk 阶梯" in s or "ps1" in s:
    print("already"); raise SystemExit(0)
anchor="- 下一批镜像 `mk1`..`mk6`（函数体内 6 个调用点）已构建"
i=s.find(anchor)
if i<0:
    print("anchor missing"); raise SystemExit(1)
j=s.find("\n\n", i)
add = """
- **2026-11-22 10:2x 续**：`mk1..mk6`（函数体内 6 个调用点）**全部回来** ⟹
  `__pi_early_map_kernel` 执行完；`ps0`(`0x4555b0`，`br x8`) 回来、`ps1`(`0x468060`) 不回来
  ⟹ 卡点是 **`br x8` 跳内核 VA / `__primary_switched` 第一条**。
  判别镜像 `kva`(`3b220ef4e31cc357c65f08a547021732`) 在 `0x4555b0` 记录 `x8` 并用内核 VA
  读 `_text`/目标页/tramp 页。**设备当前挂死，先拔插**，然后：
  `./run-postmmu.sh ~/kbuild/m7642-out/m7642-rec-73-kva.img 3b220ef4e31cc357c65f08a547021732 kva`
"""
s = s[:j] + add + s[j:]
open(p,"w").write(s)
print("NEXT-SESSION updated")
