# 下次开工的第一件事（2026-11-22 02:00 写于夜里）

设备当前状态：**Android 正常运行，无需拔插**。以下三条命令一早就可跑（每条失败会挂死，需要一次
物理断电；成功了就不需要人工）。

## A. 最高优先级：post-MMU 交接桩验证（若成立，仪器从此全自动）

```bash
cd ~/Debian/m7642 && bash tools/host/run-fast.sh ~/kbuild/m7642-out/m7642-rec-73-skmain.img b7970b310cb472f6374c94ac9d793aa8 skmain
```

- **回来** ⟹ MMU 后的检查点可读了 ⟹ 接着跑 `setuparch`(`d3a56dff…`)、`panic2`(`b48b46a5…`)
- **不回来** ⟹ 看 stash；若 stash 有 `M764`/`MMMU` 说明记录成功但交接没成，再查 routine 第 4、5 步
- 关键实现：`probes/handoff/abort-postmmu.S`（线性映射写 → idmap 执行 → 清 M/C/I → 物理地址交接）

## B. 若 A 成立：把 7.3 的卡点继续往下压

现在已验证的边界（stash 核对过）：

```
primary_entry ✓ → __pi_create_init_idmap 入口 ✓ → 0x465E78 ✓ → 颗粒度检查通过 ✓ → 【MMU 开】
                                                                              ↓
                                                                   start_kernel 一带（未定位）
```

用 A 的桩在 `start_kernel` → `setup_arch` → `early_init_dt_verify` / `parse_early_param` 之间二分。

## C. eMMC 持久化（长线，收益最大，风险最高）

已确认：

- 控制器 = **MStar FCIE**，每条命令一个函数：`eMMC_CMD17`/`eMMC_CMD24` + `*_MIU`（DMA 走物理地址）
- `eMMC_PlatformInit`（`0xffffff8008ca6264`）：`[0xffffff8009358048] + 0x247000` → 寄存器基址
- **但该全局读出的值是 `0xffffff800000000a`，不像上下文指针** ⟹ 还要再追一层；
  下次从 `eMMC_Init_Device`（`0xffffff8008c925ec`）往下追它的 callees

工具：`tools/host/dump2.sh <sym> <len>`（转储符号机器码 + 打印运行时地址）、
`tools/host/readglobal.sh <va> <len>`（读任意 VA）。**全部在 Android 里做，不需要断电。**

安全目标（写路径）：`dtb` 分区 +512 KB 之后的死区（mboot 读 1 MB 进内存，内核只解析前 23 KB），
**写前必须硬编码并校验目标 LBA**。

## D. 今天（11/21–22）的账

- **32 笔提交**，末笔 `1825b8f`
- 文档 `confirmed-facts` §I.15–§I.31；`discipline.md` 三条新纪律
- 主要成果：**单步追踪通道**（含 stash 强制验证）、**异常向量探针**（自检通过）、
  **post-MMU 交接桩**、FCIE 逆向第一步
- 关键结论：7.3 **不是异常挂死，是空转/等待**；故障类假设（`dc ivac`、`ldrb`、`map_range`）全部作废
- 我自己犯并已纠正：反汇编基址错 32 MB、code1 目标混用 4.19、判定未核对 stash、判定窗口过短
