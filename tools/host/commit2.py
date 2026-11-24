import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.14" not in s:
    s=s.rstrip("\n")+"""

### 34.14 卡点二：`setup_arch` 内部，窗口已收到 ~0xCC 字节（2026-11-22 15:5x–16:1x）

带 §34.8 的 2 MB 对齐修正后逐发推进（每发 `kva` 入口）：

| 档 | Image 偏移 | 位置 | 结果 |
|---|---|---|---|
| `su3` | `0x4638fc` | `early_init_dt_scan` 返回后 | ✅ 回来（`x30=…463900`） |
| `su4` | `0x463940` | `of_flat_dt_get_machine_name`+`_printk` 之后 | ✅ 回来（`x30=…463944`） |
| `su5` | `0x463954` | `bl parse_early_param` 处 | ✅ 回来（`x30=…463958`） |
| **`b1`** | `0x463b98` | `smp_init_cpus` | ❌ **不回**（记录全零） |
| **`c2`** | `0x463a24` | `paging_init` 返回后 | ❌ **不回** |

⟹ **上界从 `0x463b98` 收窄到 `0x463a24`**，下界 `0x463954`。窗口内只有这几次调用：

```
0x463954  bl parse_early_param
0x4639fc  bl cpu_do_switch_mm
0x463a00  bl efi_init
0x463a14  bl arm64_memblock_init
0x463a20  bl paging_init
```

已建好、待打的三个点（每一发都是 ~35 s 判定 + 挂死则拔电）：

| 档 | 偏移 | 含义 | md5 |
|---|---|---|---|
| `d0` | `0x463958` | `parse_early_param` 返回后（即 `bl` 的下一条） | `ea3cb11c…` |
| `c1` | `0x463a04` | `efi_init` 返回后 | `8ce80b0f…` |
| `d1` | `0x463a18` | `arm64_memblock_init` 返回后 | `521244a9…` |

**读法**：先 `d0`，回来就打 `c1`，再回来打 `d1`；第一个不回的就是新上界。
如果 `d0` 就不回，那卡点在 **`parse_early_param` 内部**（`0x463954`→`0x463958` 之间）。

**注意**：`paging_init` 是强嫌疑——它会重建页表并切换 `TTBR`。如果卡在它里面，
要考虑"tramp 所在页在切换后是否仍可执行/可写 stash"这个问题（`0x36c000` 在 `.text`
范围内，理应可执行，但 `rodata` 全保护下我们只读不写，问题不大）。
"""
    open(p,"w").write(s); print("§34.14 已加")

# emmc.md：补审查结论
p=os.path.join(D,"emmc.md"); s=open(p).read()
if "11.5" not in s:
    s=s.rstrip("\n")+"""

### 11.5 静态审查结论（2026-11-22 16:0x，子代理审计 + 已修）

**最重要的发现：厂源码里 eMMC 主机驱动根本没缺失**（旧说法作废）。位置与关键值：

| 事实 | 出处 |
|---|---|
| 方向位 = `BIT_SD_DAT_DIR_W` = **BIT4** | `drv/mmc/inc/config/eMMC_reg_v5.h:291` |
| `SD_CTRL` 各位：BIT1 RSP_EN、BIT2 CMD_EN、BIT3 DAT_EN、**BIT4 DAT_DIR_W**、BIT5 **ADMA_EN**、BIT6 JOB_START、BIT9 ERR_DET_ON | 同上 `:285-296` |
| CMD17 = `CMD_EN|RSP_EN|DAT_EN|ERR_DET_ON` = **0x020E** | `eMMC_hal_v5.c:2507` |
| **CMD24 命令段** = `CMD_EN|RSP_EN` = **0x0006** | `eMMC_hal_v5.c:3475` |
| **CMD24 数据段** = `DAT_EN|DIR_W|ERR_DET_ON` = **0x0218** | `eMMC_hal_v5.c:3572` |
| 另一个驱动同样写法 | `mstar_mci_v5.c:1138`（写）/ `:791`（读） |

⟹ **写是两段式 job，不是"读路径加一位"**。全树 25 处 `SD_CTRL` 写入，**没有一处**把
`CMD_EN|RSP_EN` 与 `DAT_EN` 组合在一起 ⟹ 原先"枚举 7 个候选"的思路整体废弃。

已按此重写并修掉审计出的三个 P0：

| # | 问题 | 修法 |
|---|---|---|
| 1 | 候选表落进 `.rodata`，而 `objcopy --only-section=.text` 把它截掉 ⟹ 运行时读**镜像外**内存当 `SD_CTRL` | 候选表**整个删除**（两段式不需要枚举）；`build-write.sh` 仍加 `--only-section=.rodata` + `nm -u`/`readelf -r` 自检 |
| 2 | `run-write.sh` 缺 `reboot recovery` ⟹ 桩不执行却照样读到一份旧记录 ⟹ **假阳性"写成功"** | 补 `reboot recovery; sleep 10`；判读改成 python 解析并**校验 magic/tag/长度** |
| 3 | 桩没保存/恢复 `x0..x5` ⟹ 厂内核拿到错 boot_args ⟹ 不起 Android ⟹ 白跑 | 照 `emmc_read.S` 存到 `0x230AFF00`、交接前恢复 |
| 附 | `0x022E`（ADMA_EN）会把 512 B 图案当描述符链 ⟹ 不可控 DMA | 随候选表一起删除 |
| 附 | 收尾少清 `R_EVENT`、`FUNC_CTL`/`SD_MODE` 顺序与读路径相反 | 改成与读路径逐条一致 |
| 附 | 超时分支不填 `diag` ⟹ 最可能的 0xE4/0xE6 时记录全空 | 统一走 `out:` 填 diag |
| 附 | `diag` 放在 `sp-128`，与 C 帧的 `stp x19,x20` 槽位重叠 | 移到固定地址 `0x230AFC00` |

**离线验证**：两段式重写后 `fcie_write.o` 1856 B、**零 `.rodata`**；整链 `emmc_write.elf`
2992 B、`nm -u` 无未定义符号、`readelf -r` 无运行时重定位；镜像 `cd1391ad…`。
读路径回归：重构共享头后镜像 md5 仍为 `9f071ae8…`（未变）。

**还没做的**：真上机。`run-write.sh` 已加分区 size 边界检查（不再只信"+0x80000 是死区"），
且**每次必须换一个 LBA**（一次 `E_VERIFY` 会把那块写成 0xA5 图案）。
"""
    open(p,"w").write(s); print("emmc.md §11.5 已加")
