p="/home/emfox/Debian/m7642/Documentation/mstar/m7642/NEXT-SESSION.md"
s=open(p).read()
old="## B. 若 A 成立：把 7.3 的卡点继续往下压"
if "post-MMU 仪器成立" in s:
    print("already"); raise SystemExit(0)
i=s.find("## 1. 恢复设备后先核对")
if i < 0:
    print("anchor missing"); raise SystemExit(1)
add = """## 0.5 2026-11-22 10:05 更新：post-MMU 仪器成立，卡点在 `__pi_early_map_kernel` 体内

- `mmuon`(`7f309a47…`)、`emap`(`f0ca4aa2…`) 都 **stash 验证通过**（Android 正常起）；
  `prsw`(`b8651fd2…`) **不回来**（488 s）⟹ 卡点在 `__pi_early_map_kernel`
  （`0x4659e0`..`0x46805c`）里，不在 `start_kernel` 之后。
- 顺带实测：mboot 交的 `x0 = 0`（code1 shim 记录），DTB 那环的判断成立。
- 下一批镜像 `mk1`..`mk6`（函数体内 6 个调用点）已构建，md5 与偏移见
  confirmed-facts §34。顺序 mk1→mk6，第一个不回来的就是卡点。
  设备当前挂死（prsw 那一发），**先物理拔插**，再跑：

  ```bash
  cd ~/Debian/m7642/probes/handoff
  ./run-postmmu.sh ~/kbuild/m7642-out/m7642-rec-73-mk1.img 371627c1fd729baa16723a3912bcbe1a mk1
  # mk2 50a5f07f / mk3 3b7dac45 / mk4 83cb6f29 / mk5 5d567f3a / mk6 893a2274
  ```

"""
s = s[:i] + add + s[i:]
open(p,"w").write(s)
print("NEXT-SESSION updated")
