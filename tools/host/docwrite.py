import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")

# emmc.md §11.3 更新：写路径已离线实现
p=os.path.join(D,"emmc.md"); s=open(p).read()
old_start = s.index("### 11.3 要不要现在推进路线 B 的写路径？我的判断")
new = """### 11.3 写路径：**已离线实现**（2026-11-22），等一次上机

| 文件 | 作用 |
|---|---|
| `probes/fcie/fcie_regs.h` | 寄存器/事件/错误码 + 有界等待（`frd`/`fwr`/`ticks`/`wait_mask`），读写共用 |
| `probes/fcie/fcie_write.c` | `fcie_write_block()`（CMD24，镜像 CMD17 的 18 步）+ `fcie_write_probe()` |
| `probes/fcie/emmc_write.S` | code1 桩：调 probe、记录结果、交接厂内核 |
| `probes/fcie/build-write.sh` | `LBA=<n> ./build-write.sh` → `m7642-rec-73-write.img` |
| `probes/fcie/run-write.sh` | 从设备的分区表算出安全 LBA，自动建镜像、上机、判读 |

**离线已验**：
- 两个 `.o` 与整条链（`fcie_write.o` + `fcie_read.o` + `emmc_write.o`）**编译链接通过**，桩 2864 B、0 重定位；
- **回归测试**：重构出共享头之后，读路径镜像 md5 **仍是 `9f071ae8…`**（与重构前逐字节相同）
  ⟹ 抽头没有改变任何行为。

**三层安全设计**（这是"写 eMMC"能接受的前提）：

1. **目标位置**：`dtb` 分区内偏移 `+0x80000`（真 DTB 只有 23 KiB；mboot 整块 1 MiB 读进
   `0x23000000` 但只解析到 `totalsize`，尾部是死区）；
2. **写前拦截**：probe 先用 CMD17 读那块，**不是全 `0x00`/`0xFF` 就直接返回 `E_NOT_EMPTY`
   什么都不写** ⟹ LBA 算错也伤不到真实数据；
3. **写后验证**：用已在设备上验过的 CMD17 路径读回，512 B 逐字节一致才算成功（否则 `E_VERIFY`）；
   控制器状态照旧保存/还原，交接不受影响。

**唯一未知量**：SD 控制器的"方向编码"。厂商 CMD17 路径用 `SD_CTRL = 0x020E`，
寄存器表里没有明确的读写位 ⟹ `fcie_write_probe()` **枚举 7 个候选**（从 `0x020E` 起，
逐个加一位），谁的回读能对上就记谁，结果写进记录的 `diag[0]`。**一次上机就能定下来。**

### 11.4 什么时候上机

卡在 `setup_arch` 的二分只需要 3 发，用不到写路径；等出现"区间大、失败密集"再跑
`run-write.sh`（那一步会真的写 eMMC，第一次做，建议你看着）。
"""
s = s[:old_start] + new
open(p,"w").write(s); print("emmc.md §11.3/11.4 已更新")
