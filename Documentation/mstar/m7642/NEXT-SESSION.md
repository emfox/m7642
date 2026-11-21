# 下次开工的第一件事（2026-11-22 02:00 写于夜里）

设备当前状态：**Android 正常运行，无需拔插**。以下三条命令一早就可跑（每条失败会挂死，需要一次
物理断电；成功了就不需要人工）。

## A. 最高优先级：post-MMU 交接桩验证（若成立，仪器从此全自动）

```bash
cd ~/Debian/m7642 && bash tools/host/run-fast.sh ~/kbuild/m7642-out/m7642-rec-73-skmain.img 40ef6778dab007af26e8c0cef3f4d1ff skmain
```

- **回来** ⟹ MMU 后的检查点可读了 ⟹ 接着跑 `setuparch`(`d3a56dff…`)、`panic2`(`b48b46a5…`)
- **不回来** ⟹ 看 stash；若 stash 有 `M764`/`MMMU` 说明记录成功但交接没成，再查 routine 第 4、5 步
- 关键实现：`probes/handoff/abort-postmmu.S`（线性映射写 → idmap 执行 → 清 M/C/I → 跳 `0x21680200` 做物理地址交接）
- **已修的自毁 bug**：routine 原放在 `0x206d5000`，而交接要拷贝 `0x20280000..0x21554a00`，正好把它自己盖掉；
  现改为 routine 只做「关 MMU → 跳 `0x21680200`」，交接代码在桩的物理副本里（拷贝区之外）

## B. 若 A 成立：把 7.3 的卡点继续往下压

现在已验证的边界（stash 核对过）：

```
primary_entry ✓ → __pi_create_init_idmap 入口 ✓ → 0x465E78 ✓ → 颗粒度检查通过 ✓ → 【MMU 开】
                                                                              ↓
                                                                   start_kernel 一带（未定位）
```

用 A 的桩在 `start_kernel` → `setup_arch` → `early_init_dt_verify` / `parse_early_param` 之间二分。

## C. eMMC 持久化（长线，收益最大，风险最高）

**基址链已结案（2026-11-22，见 confirmed-facts §32）**：

- `mstar_pm_base = [0xffffff8009358048] = 0xffffff800a000000` = `ioremap(0x1F000000, 0xA00000)`
  （上一轮读到的 `0xffffff800000000a` 是 8 字节当两个 32 位字、按大端拼错；**这条链没有缺环**）
- FCIE0 = `mstar_pm_base + 0x222600` = PA `0x1F222600` / VA `0xffffff800a222600`；
  EMMC_PLL = `+0x247E00`。DMA 寄存器里是 **MIU 地址 = ARM 物理地址 − 0x20000000**
  （实测：静止值 `0x01639680`，不可能是物理地址）
- §32 有 34 个寄存器的实测值、CMD17 的 18 步序列（每条带反汇编地址）、以及空洞表
  （idx `0x19–0x28`/`0x2A–0x33`/`0x3A–0x3E`/`0x40–0x62` 不要连读）

`probes/fcie/`：

- `fcie.c` —— **只读**寄存器 dump 模块，已在设备上跑过（零风险），本轮所有实测值的来源
- `fcie_read.c` / `fcie_probe.c` —— freestanding CMD17，848 B、0 重定位、数据落
  `0x23080000`、心跳在 `0x23080FE0`。**从未执行过**

下一步（按顺序）：

1. 先跑只读模块确认 34 个读数可复现（`./build.sh ko` → push → insmod/rmmod）
2. **CMD17 仍未上机。** 要跑必须同时满足：只读 `lba=0`、R1 的 CURRENT_STATE ≥ 4、
   控制器空闲（停 `/data` 或进 recovery）。**绝不能在 Android 正常读写时跑。**
3. 写路径（CMD24/CMD25）继续冻结。安全目标不变：`dtb` 分区 +512 KB 之后的死区，
   写前硬编码并校验目标 LBA。

工具：`tools/host/dump2.sh <sym> <len>`（转储 + 打印运行时地址）、
`tools/host/readglobal.sh <va> <len>`、`~/kbuild/build-probe.sh fcie`。
**全部在 Android 里做，不需要断电。**

## D. 今天（11/21–22）的账

- **32 笔提交**，末笔 `1825b8f`
- 文档 `confirmed-facts` §I.15–§I.31；`discipline.md` 三条新纪律
- 主要成果：**单步追踪通道**（含 stash 强制验证）、**异常向量探针**（自检通过）、
  **post-MMU 交接桩**、FCIE 逆向第一步
- 关键结论：7.3 **不是异常挂死，是空转/等待**；故障类假设（`dc ivac`、`ldrb`、`map_range`）全部作废
- 我自己犯并已纠正：反汇编基址错 32 MB、code1 目标混用 4.19、判定未核对 stash、判定窗口过短
