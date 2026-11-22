# 下次开工的第一件事（2026-11-22 01:5x 写）

设备当前状态：**上一发 `prsw` 没回来，设备 ping 不通，需要一次物理断电**
（拔电源线 → 插回 → 按一下电源键）。boot 槽是厂值 `6272b10dcaf5e9efa40491d87f2c1289`，
`misc` 的 BCB 已被 `recoverycmd` 里的 `mmc erase.p misc` 擦掉，断电后不会锁 recovery。

> **2026-11-22 11:0x 环境变更**：`~/kbuild/` 已清理并迁到 `~/Debian/m7642-build/`
> （16 GB → 6.6 GB，布局见该目录 `README.md` 与 `paths.md` §1）。4.19 树已删除。
> `out/` 里的 27 张上机镜像已按源码重建并逐一比过 md5，全部一致。
> 设备当前是活的（adb 可达），上一发 `ps1` 的挂死已由拔插恢复。

## 0. 必读的上一条结论（§I.33）

NEXT-SESSION 上一版 A 的三张镜像**按原样不可能回来**：桩在 `Image+0x1400000`（PA `0x21680000`），
而 MMU 开后两套映射都止于 `_end`（Image+0x670000）；「线性映射」地址 `0xffffffc0004d5000`
是模块区（`PAGE_OFFSET = 0xffffff8000000000`），且 `start_kernel` 时线性映射还不存在。

同时查出一处**配置漂移**：11-20 的 7.3 Image 是 `CONFIG_MSTAR_M7642_BUILTIN_DTB=n`，
而文档的前提是 `=y`；mboot 交的 `x0=0`，所以 `setup_arch` 拿不到 DT。
已重编 Image（`=y`，DTB 在 Image+0x4C9858），并在 code1 加 shim 把 `x0` 设成 `0x23000000`、
把 mboot 入口寄存器记到 `0x23090000`。详见 confirmed-facts §I.33。

## 0.5 2026-11-22 10:05 更新：post-MMU 仪器成立，卡点在 `__pi_early_map_kernel` 体内

- `mmuon`(`7f309a47…`)、`emap`(`f0ca4aa2…`) 都 **stash 验证通过**（Android 正常起）；
  `prsw`(`b8651fd2…`) **不回来**（488 s）⟹ 卡点在 `__pi_early_map_kernel`
  （`0x4659e0`..`0x46805c`）里，不在 `start_kernel` 之后。
- 顺带实测：mboot 交的 `x0 = 0`（code1 shim 记录），DTB 那环的判断成立。
- 下一批镜像 `mk1`..`mk6`（函数体内 6 个调用点）已构建，md5 与偏移见
  confirmed-facts §34。顺序 mk1→mk6，第一个不回来的就是卡点。
  设备当前挂死（prsw 那一发），**先物理拔插**，再跑：
- **2026-11-22 10:2x 续**：`mk1..mk6`（函数体内 6 个调用点）**全部回来** ⟹
  `__pi_early_map_kernel` 执行完；`ps0`(`0x4555b0`，`br x8`) 回来、`ps1`(`0x468060`) 不回来
  ⟹ 卡点是 **`br x8` 跳内核 VA / `__primary_switched` 第一条**。
  判别镜像 `kva`(`3b220ef4e31cc357c65f08a547021732`) 在 `0x4555b0` 记录 `x8` 并用内核 VA
  读 `_text`/目标页/tramp 页。**设备当前挂死，先拔插**，然后：
  `./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-kva.img 3b220ef4e31cc357c65f08a547021732 kva`


  ```bash
  cd ~/Debian/m7642/probes/handoff
  ./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-mk1.img 371627c1fd729baa16723a3912bcbe1a mk1
  # mk2 50a5f07f / mk3 3b7dac45 / mk4 83cb6f29 / mk5 5d567f3a / mk6 893a2274
  ```

## 1. 恢复设备后先核对（只读，不需要断电磁）

```bash
ADB=~/Debian/tv/adb/platform-tools/adb
$ADB connect 192.168.10.60:5555; sleep 1; $ADB devices
$ADB -s 192.168.10.60:5555 exec-out su -c "dd if=/dev/block/by-name/boot bs=1048576 count=32 2>/dev/null" | md5sum
#   期望 6272b10dcaf5e9efa40491d87f2c1289（厂值 boot）
$ADB -s 192.168.10.60:5555 exec-out su -c "dd if=/dev/block/by-name/misc bs=32 count=1 2>/dev/null" | od -An -tx1
#   期望 32 个 00
```

## 2. 第一发：验证仪器本身（**一定到达**的点）

```bash
cd ~/Debian/m7642/probes/handoff
./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-mmuon.img 7f309a473a77abafe894a0636c91b1c2 mmuon
```

- 检查点 = `__enable_mmu+0x38`（`0x455548`，`msr sctlr_el1` 之后）：MMU 刚开、PC 仍是 PA，
  **不受 `early_map_kernel` 影响**，是仪器的最小可验证点。
- **回来** ⟹ 仪器在 MMU 后可用了 ⟹ 按 §3 的顺序往后推。
- **不回来** ⟹ 先查 `tramp-postmmu.S`，不要继续往后打（每发都要一次人工断电）。

## 3. 之后按这个顺序（每档回来才算「到达」）

| 顺序 | 镜像 | md5 | 检查点 |
|---|---|---|---|
| 2 | `m7642-rec-73-emap.img` | `f0ca4aa27051e9cafff4e289adf5193f` | `__pi_early_map_kernel` 0x4659e0 |
| 3 | `m7642-rec-73-prsw.img` | `b8651fd2121089cb69e8385234fc58a9` | `__primary_switched` 0x46805c |
| 4 | `m7642-rec-73-skmain.img` | `2eac39d1515761d31ce65dd7a5b9b33e` | `start_kernel` 0x46091c |

四张镜像**都带**：`nop @0x46804C`（`preserve_boot_args` 的 `b dcache_inval_poc`，此前所有深检查点
都在带它的镜像上测到）、code1 shim（x0=0x23000000 + 记录到 0x23090000）、tramp、handover。
重建命令：`probes/handoff/build-postmmu.sh && probes/handoff/mk-postmmu-images.sh`（换内核后必须重跑，
脚本从 System.map 复算所有常量）。

`run-postmmu.sh` 会读两个 64 B 记录：

- `0x23090000` = `M764`/`FDT `：mboot 入口的 x0..x5/x30（**x0 是 mboot 真正给的 DTB 指针**）
- `0x23080000` = `M764`/`MMMU`：检查点记录（x30 = 检查点返回地址：内核 VA 或 PA）

## 4. 若 2/3/4 都「不回来」

那说明 7.3 在 `create_init_idmap` 或更早处就挂住（**不是** MMU 之后）：
`0x465E78` 是唯一 stash 验证过的深点，而 `0x465E80` 从未到达过（§I.25，且仪器当时不可靠）。
此时改用 pre-MMU 单步通道（`abort-rung.bin` 的预算交接；**MMU 关时不要用 tramp**——
`dc civac` 在 MMU 关时是另一件事）：

```bash
cd ~/Debian/m7642
python3 tools/host/mk-mainline-abort.py --image ~/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image \
  --at 0x465e80 --stub probes/handoff/abort-rung.bin --nop 0x46804c \
  --out ~/Debian/m7642-build/out/m7642-rec-73-rung-0x465e80.img
# 取输出里的 md5，然后：
probes/handoff/run-rung.sh ~/Debian/m7642-build/out/m7642-rec-73-rung-0x465e80.img <md5> 0x465e80
```

先重跑 `0x465E80`（**带 nop**，与已验证档一致），再往 `map_range` 入口 `0x465CC8` 推。

## 5. 不变的两条线

- **eMMC(FCIE)**：§32 已结案寄存器映射；**boot-path CMD17 探针已就绪、未上机**。
  恢复设备后按顺序：

  ```bash
  # 1) 只读模块复核 34+2 个寄存器（零风险），check-dump 期望 diff 0
  adb push ~/Debian/m7642-build/build/fcie-build/fcie.ko /data/local/tmp/
  adb shell su -c "/vendor/bin/busybox rmmod fcie 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/fcie.ko; rmmod fcie"
  adb exec-out su -c "cat /data/local/tmp/fcie.out" > /tmp/fcie.out
  ~/Debian/m7642/probes/fcie/check-dump.sh /tmp/fcie.out
  # 2) CMD17：code1 处读 LBA 0，与内核 dd 的同一扇区逐字节对比
  cd ~/Debian/m7642/probes/fcie
  ./run-cmd17.sh ~/Debian/m7642-build/out/m7642-rec-73-emmc.img a4479e336f3b4b4ac7fa5ca1aad46887
  ```

  判据：心跳 `rc=0` + `R1` 的 CURRENT_STATE=4/READY_FOR_DATA=1 + 512 B 与 `dd` 一致。
  只读 LBA 0；挂住 = 一次物理断电（boot 槽是厂值，卡只被读过）。

  **2026-11-22 10:00：CMD17 读通道成立**（rc=0、R1=0x900、SD_STATUS=0xff00、
  512 B 与内核 `dd` 的 LBA0 逐字节相同）。之前连续挂死的根因是 **C 代码冲掉了 x0..x5**，
  而厂内核入口要读 `w2`；`emmc_read.S` 已改成入口保存、交接前恢复。
  全量镜像 `9f071ae8ff512a1843396e8849633531`。

- **写路径（CMD24/CMD25）继续冻结**：`probes/fcie` 里没有任何写 eMMC 的代码，也不加。

## 6. 今天（11-22 凌晨）的账

- 发现并修掉上一版 post-MMU 桩的**不可达**（映射范围 + 线性映射地址 + 时机）与
  **BUILTIN_DTB 配置漂移**；重编带内嵌 DTB 的 Image。
- 新仪器：tramp 注入 `.text` 尾部填充（内核 VA 与 idmap 都 ROX），两个入口；handover 仍在 0x21680200。
- 第一发 `prsw` NO_RETURN（505 s）——但那一版漏了 `nop @0x46804C`，已重建四张镜像。
- 机器目前挂死，等一次物理断电。
