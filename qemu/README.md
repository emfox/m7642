# QEMU 离线上机测试台 —— `probes/handoff/tramp-postmmu.S`

用途：在**不碰电视**的前提下，验证这段裸机交接桩在「MMU 已开」的三种场景里能不能活到交接点。
不需要 adb、不需要刷写、不需要拔电源；一次全量回归约 2 分钟。

```
qemu-system-aarch64 -machine virt -cpu cortex-a72 ... ← 这个方案对本 tramp 不成立，见 §6
qemu-system-aarch64 -M xlnx-zcu102 -cpu cortex-a72 -m 1G ← 实际采用的板子（RAM 从 PA 0 开始）
```

## 1. 最快上手

```bash
cd ~/Debian/m7642/qemu
./run.sh -l          # 列出全部场景及其期望结果
./run.sh             # 跑全部场景，逐条打印 PASS/FAIL + 失败指令定位
./run.sh P1-v2 P2-v2 # 只跑指定场景
./verify-identical.sh # 证明本目录的 tramp 副本还是「原件」，没被改过语义
```

退出码：`0` = 所有场景都和期望一致；`1` = 有场景和期望不一致。
每个场景的完整串口输出留在 `logs/<场景名>.log`。

依赖：`qemu-system-aarch64`（本机 11.1.3）、
`~/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-{gcc,ld,objcopy,objdump,nm}`、
`python3`。工具链路径可用 `TC=... ./run.sh` 覆盖。

## 2. 测试台是什么

电视上是「内核 → `bl tramp` → tramp → 跳物理交接桩」。测试台把这套东西换成最小的等价物：

```
boot.S（假内核，链接在 PA 上）
  ├─ 放假的 memstart_addr、假的 boot_args[3]
  ├─ 建 39-bit VA 页表（T0SZ=T1SZ=25, 4KB granule, MAIR/AttrIdx=1 Normal WB）
  │    · TTBR0: 1 GB 恒等块（VA 0..1GB → PA 0..1GB）
  │    · TTBR1: kimage 映射（0xffffffc080000000 起，2 MB 块）+ 线性映射（PAGE_OFFSET 起，2 MB 块）
  ├─ 开 MMU（SCTLR.M/C/I），随后**在线性映射 VA 上继续执行**（等价于内核 __primary_switched 之后）
  ├─ [P2] 等价于 cpu_uninstall_idmap()：TTBR0 → 全零页，EPD0=0，TLBI+DSB+ISB
  ├─ 用 AT S1E1R 自检并打印：物理地址当地址用是否可翻译、内核 VA 反解出的 PA
  └─ br 到 tramp 的 _start_kva(VVA)
tramp（原件或其参数化副本）
  └─ br 到 HANDOVER_PA（物理地址）
pad.S（落地桩，放在 HANDOVER_PA）
  ├─ 打印 tramp 算出来的值（v1: kimage/memstart/lin；v2: x5=KIMAGE_OFFSET）+ 现场寄存器
  ├─ 14 项断言（见 §4），全过打印 PASS stage1/stage2，否则 FAIL stage chk=N
  └─ semihosting 退出（退出码 0=PASS，2=断言失败，3=中途异常）
```

失败时不需要猜：`boot.S` 装了 `VBAR_EL1` 异常向量表，任何 abort 都会打印
`esr / far / elr`，`run.sh` 再把 ELR 映射回 tramp 的**具体某条指令**（`locate.py`）。
tramp 自己把 SP 清零，所以异常处理只能靠寄存器 + semihosting，本测试台的 handler
就是为此写成「不用栈、不做任何地址翻译相关访存」。

## 3. 地址空间（`gen.py` 是唯一出处）

| | zcu102 配置（默认） | virt 配置（只用于演示障碍） |
|---|---|---|
| 机器 | `-M xlnx-zcu102 -cpu cortex-a72 -m 1G` | `-M virt -cpu cortex-a72 -m 1G` |
| RAM | PA 0 起 | PA 0x40000000 起 |
| 假 `memstart_addr` | 0x10000000 | 0x40000000 |
| 假内核镜像 `IMAGE_BASE` | 0x20000000 | 0x40080000 |
| tramp blob | IMAGE_BASE+0x20000 | 同 |
| 交接桩（落地桩） | IMAGE_BASE+0x30200 | 同 |
| tramp 的 1 GB 恒等表 | IMAGE_BASE+0x40000 | 同 |
| PAGE_OFFSET | 0xffffff8000000000（tramp 里写死） | 同 |
| KIMAGE_VA | 0xffffffc080000000 | 同 |

**关键点：所有被 tramp 访问的物理地址必须 < 1 GB。** tramp 自己装的那张表只往
`L1[0]` 写一条 1 GB 块描述符，能覆盖的物理范围就是 0..1 GB。这条约束直接决定了
`-M virt` 用不了（§6）。

## 4. 场景清单与每个场景验证什么

`v1` = `probes/handoff/tramp-postmmu.S` 2026-11-22 22:02 的版本（AT 自校准 + memstart/lin）。
`v2` = 同文件 22:31 重写后的版本（不再探测：一切地址 = PA + KIMAGE_OFFSET，表在镜像里）。
两个版本都原样钉在 `src/` 下，见 §7。

| 场景 | 配置 | 期望 | 验证什么 |
|---|---|---|---|
| P1-v1-shipped | v1 原件，idmap 在 | **FAIL** | 出厂 v1 在 P1 就挂：`tramp+0x228 ldp x0,x1,[x16]` 取 boot_args 时段错误。原因见 §5 bug ③ |
| P2-v1-shipped | v1 原件，idmap 拆掉 | **FAIL** | 同上，且换个场景也挂 → 与 idmap 是否存在无关，是常量算错 |
| P1-v1 | v1 + PAGE_OFFSET 修好 | **PASS** | AT 自校准、memstart 读取、lin 计算、boot_args 重载（线性映射）、cache 扫描、1 GB 恒等表安装、跳物理地址，全链路成立 |
| P2-v1 | 同上，idmap 拆掉 | **PASS** | **核心场景**：确认「物理地址当地址用」已不可翻译（AT 返回 F=1），tramp 仍能靠自己的 1 GB 恒等块完成交接 |
| P1-v1-x5zero | 调用者 x5=0，idmap 在 | PASS | 说明 P1 会**掩盖**问题：x5=0 时 tramp 跳回 PA 别名，靠内核旧 idmap 也能活 |
| P2-v1-x5zero | 调用者 x5=0，idmap 拆掉 | **FAIL** | 暴露 `cbnz x5` 这个隐患：VA/PA 模式由**调用者的 x5** 决定，而不是由硬件状态决定 |
| P1-v1-noidmap | 去掉装表那步，idmap 在 | PASS | 证明 P1 对「不装表」完全不敏感（TTBR0 仍是内核旧表） |
| P2-v1-noidmap | 去掉装表那步，idmap 拆掉 | **FAIL** | 反过来证明装表这步是**承重**的：没有它，交接待物理地址必缺页 |
| P1-v1-badlin | 注入错误的 lin（+0x1000） | **FAIL** | 夹具对「lin 算错」有鉴别力：表被写到 4 KB 之外，交接地址取指缺页 |
| P1-v1-dbloff | 复现 bug ①（VA 再加一次偏移） | **FAIL** | 定位到 `tramp+0x14c ldr x28,[x19]`，即读 memstart_addr 那条 |
| P2-v1-paalias | 复现 bug ②（校准后仍跳 PA 别名） | **FAIL** | 定位到 `tramp+0x200`（PA 别名），异常类型是取指 abort |
| P1-v2 | v2 原件，idmap 在 | **PASS** | 22:31 的重写版在测试台上确实能活；它不依赖 memstart/lin，也就不受 bug ③ 影响 |
| P2-v2 | v2 原件，idmap 拆掉 | **PASS** | 同上，且拆了 idmap 也活 → v2 的交接路径成立 |
| P1-v4 | v4 原件，idmap 在 | **PASS** | **世界(a)**：AT 探测到 F=0 → 走 PA 别名老路 → 交接时 M=0、TTBR0/TCR 原封不动、恒等表那页的哨兵没被写过 |
| P2-v4 | v4 原件，idmap 拆掉 | **PASS** | **世界(b)**：F=1 → 留在 VA 建表 → TTBR0=TABLE_PA、表项 `0x4000000000000701`、TCR T0SZ=25/EPD0=0 |
| P1-v4-t0sz16 | 同上，但 TTBR0 起始 T0SZ=16（48-bit，L0 为根，与电视内核同构） | **PASS** | 世界(a) 在电视那种 VA 尺寸下也成立，TCR 保持 `…3510` 不变 |
| P2-v4-t0sz16 | 同上，idmap 拆掉 | **PASS** | 世界(b) 里 **T0SZ 16→25 的改写是承重的**：改写后 `…3510` → `…3519`，1 GB 块被按 3 级解释并生效 |
| P1-v4-roimg | 镜像映射为 **EL1 只读**（AP=11），idmap 在 | **PASS** | 世界(a) 一笔表都不写，所以即使 `.rodata`/镜像只读也能活 |
| P2-v4-roimg | 同上，idmap 拆掉 | **FAIL** | **复现电视上的挂死形态**：`str xzr,[x16,x19,lsl#3]`（清表那步）踩 EL1 只读页 → ESR `0x9600004E`（permission fault, level 2）、FAR=`TABLE_VA` |
| virt-v1 | `-M virt`（RAM 0x40000000） | **FAIL** | 演示 §6 的障碍：交接地址 0x400b0200 落在 1 GB 块覆盖之外，取指 abort（ESR 0x86000005, FAR=0x400b0200） |
| P1-chain-v3 | 完整链路，idmap 在 | **PASS** | tramp(v3) → **真** `abort-postmmu.S`(v3) 写满 0xB0 记录 → 搬 0x12d4a00 字节到 0x20280000 → 跳 0x21220000 的替身内核 |
| P2-chain-v3 | 完整链路，idmap 拆掉 | **PASS** | 同上，且 `AT(pa)` 返回 F=1，交接仍成立 |
| P1-chain-v2 | 同上，tramp 用 22:31 版 | **PASS** | 证明 tramp 那 0xB0 字节的改动与桩的两版都兼容（tramp 本身没变，md5 相同） |

### 4.1 完整链路场景怎么看

`chain` 模式（`./build.sh zcu102 1 vanilla v3 chain`）搭的是和电视同构的一条链：

```
假内核 → tramp(表在镜像里) → br 0x21680200（真桩的 handover_phys）
  真桩：mrs sctlr 存 x27 → 若 M=1 就清 M/C/I → 写 0xB0 记录到 0x23080000
        → 从 0x30000800 搬 0x12d4a00 字节到 0x20280000 → br 0x21220000
  替身内核（落在被搬运的 payload 里，偏移 0xFA0000）→ 打印记录 + 8 项断言 + semihosting 退出
```

桩和 payload 用 `-device loader,file=...,addr=...,force-raw=on` 塞进 RAM（不在 ELF 里，
避免 19 MB 的 ELF）：`gen/stub.bin` @ 0x21680000、`gen/stage.bin` @ 0x30000800。
只有「搬运真的发生」了，0x21220000 才会有代码 —— 所以替身能跑起来本身就是搬运成功的证明；
另外 payload 偏移 0x100000 处放了 `"STAGE-OK"`，落到 0x20380000，替身断言 7 专门检查它。

替身断言：① 魔数 `M764` ② 标签 `MMMU` ③ size==0xB0 ④ `x30`==checkpoint 返回址
⑤ `x21`==0x88 ⑥ 记录里 `+0x70` 的 SCTLR 带 M|C|I ⑦ 0x20380000 的搬运哨兵 ⑧
MIDR/CTR/MPIDR 非零（证明 `mrs` 没被 UNDEFINED）。

**关于 `+0x70` 的那个 SCTLR**：桩是在清 M/C/I **之前** `mrs x16, sctlr_el1; mov x27, x16`，
记录里 `+0x70`(112) 存 x27，`+0x48`(72) 存 x22（checkpoint 的 x0 备份槽）。
实测两场景都是 `sctlr=0xC5183D`，`& 0x1005 == 0x1005`（M=1 C=1 I=1）——即内核现场值，
不是桩清完之后的值。同一次运行里桩自己随后确实把 M/C/I 清掉了（替身是在 MMU 关的状态下
用物理地址跑起来的），这两件事互为对照。

「FAIL」是**期望值**，不是出错：这些场景存在的意义就是证明夹具能把错的东西判成错。

## 5. 这个测试台发现了什么

### bug ③：`PAGE_OFFSET` 常量拼错（v1，真 bug，会挂机）

`tramp-postmmu.S`（22:02 版）：

```asm
	movz	x20, #0x0000		/* PAGE_OFFSET = 0xffffff8000000000 (39-bit VA) */
	movk	x20, #0xff80, lsl #48
	sub	x29, x20, x28		/* x29 = lin */
```

`movk #0xff80, lsl #48` 造出的是 `0xff80_0000_0000_0000`，不是 `0xffff_ff80_0000_0000`。
于是 `lin` 少了 `0x007f_ffff_0000_0000`：

```
正确 lin = 0xffffff7ff0000000      （PAGE_OFFSET 0xffffff8000000000 - memstart 0x10000000）
实际 lin = 0xff7ffffff0000000      ← 现场从 x29 读回的值，和算术完全一致
```

tramp 随后用 `PA + lin` 取 boot_args：`0x20001100 + 0xff7ffffff0000000 = 0xff80000010001100`，
这个 VA 不可翻译 → 在 `tramp+0x228（ldp x0,x1,[x16]）` 数据 abort，
ESR `0x96000004`（translation fault, level 0）。**在电视上这就是「记录为空 + 挂死」**：
异常发生在 IRQ/FIQ 已屏蔽、且还没装自己的恒等表之前，取不到任何记录。

正确写法应为：

```asm
	movz	x20, #0x0000
	movk	x20, #0xff80, lsl #32
	movk	x20, #0xffff, lsl #48
```

22:31 的 v2 重写把 memstart/lin/线性映射整个删掉了（改用 KIMAGE_OFFSET + SCTLR.M 判模式），
bug ③ 因此在 v2 里不存在 —— 测试台对 v2 直接给出 PASS（P1-v2 / P2-v2）。

### 隐患：v1 的 VA/PA 模式由**调用者的 x5** 决定

```asm
7:	adr	x16, 1f
	cbnz	x5, 9f			/* VA 模式：留在内核 VA */
	...				/* 否则：减掉 KIMAGE_OFFSET 跳 PA 别名 */
```

`_start_kva` 入口并不知道调用者的 x5 是什么（checkpoint 处 x5 是内核任意值）。
x5=0 时它会跳到 PA 别名并指望旧 idmap 还在：P1 侥幸活（`P1-v1-x5zero` PASS），
P2 直接取指 abort（`P2-v1-x5zero` FAIL，FAR=0x20020200）。
**修法**：模式只能来自硬件（`SCTLR_EL1.M`）或编译期常量 —— v2 就是这么改的。

### 与 QEMU 实现相关的差异：`PAR_EL1[63:56]` 带属性位

v1 用 `at s1e1r` 自校准，只清 PAR 的低 12 位：

```asm
	lsr	x17, x17, #12
	lsl	x17, x17, #12
```

QEMU 返回的成功 PAR 形如 `0xFF00000020020B80`（`[63:56]` 是内存属性），
真实 ARMv8 的 PAR_EL1 `[63:52]` 是 RES0。所以在 QEMU 上 v1 算出来的
`kimage = 0x00FFFFC060000000`（真值 `0xFFFFFFC060000000`），差一个 `0xFF00_0000_0000_0000`。
v1 只把这个值记录/上报（不拿它做地址），所以不影响流程；落地桩的断言 1 因此比较
kimage 的 48 位 PA 字段而不是全 64 位。**这也说明：如果哪天 PAR 的高位被用于寻址，
真实硬件上也可能踩到同一个坑，建议干脆 `and x17, x17, #0x0000fffffffff000`。**

## 4.2 v4 的两个世界（各自断言）

v4 的 `_start_kva` 先用 `AT S1E1R` 探一个"在 init idmap 里"的物理地址，按硬件事实分岔：

| 断言 | 世界(a) idmap 在（P1） | 世界(b) idmap 没了（P2） |
|---|---|---|
| `AT_S1E1R(IDMAP_PROBE_PA)` | **F=0**（bench 日志 `[idmap ALIVE: F=0]`） | **F=1**（`[idmap GONE: F=1]`） |
| 交接时的 `x5` | **0**（物理寻址） | `KIMAGE_OFFSET` |
| 交接时 `SCTLR_EL1.M` | **0**（tramp 自己清的 C/M/I → 0xC5183D & ~0x1005 = **0xC50838**） | 1（交给桩去清） |
| `TTBR0_EL1` | **仍是内核的 init idmap 根表**（bench: `0x20083000`；T0SZ16 变体：`0x20085000`） | **`TABLE_PA`**（bench: `0x20040000`） |
| `TCR_EL1` | **未被改动**（`0x2B5193519`；T0SZ16 变体 `0x2B5193510`） | T0SZ=25、EPD0=0（T0SZ16 变体里可见 16→25 的改写） |
| 恒等表那页 | **哨兵完好**（`table[0] == table[0x800] == 0x005E4E544C4F4C5E`） | `table[0] == 0x0040000000000701`、其余被清零 |
| boot_args / x3,x4 / x30 | 全部核对通过 | 全部核对通过 |

哨兵由 `boot.S` 在跳进 tramp 前写入（经线性映射，两个场景都有效），v4 若在世界(a) 里
多碰一下这页就会被断言 6/7 抓到。

`t0sz16` 变体（`T0SZ16=1 ./build.sh ... v4`）把 bench 的 TTBR0 做成 **48-bit VA / L0 为根**，
就是电视内核的形态。它覆盖了 v3 之前那条 bench 覆盖不到的东西：
**`TCR.T0SZ` 从 16 改成 25 这一步在世界(b) 是承重的**（不改的话 tramp 的 1 GB 块会被
按 L0 解释 → 保留编码 → 取指异常）。

## 4.3 "表页只读"这个假设（v2/v3 在电视上挂死的解释）

v2/v3 在电视上于「恒等映射还活着」的检查点挂死、记录为空。最省事的解释是：
那一版无条件走建表路线，而表页若在某个检查点已是**只读**（`.rodata` 里的 `reserved_pg_dir`），
清表/写表项就会触发 permission fault —— 而此刻 IRQ/FIQ 还屏蔽着，于是**死循环且记录为空**，
与电视现象完全吻合。

测试台把这个假设做成了可复现的开关：`TABLE_RO=1`（`./build.sh ... roimg`）把**镜像**用
AP=0b11 映射成 EL1 只读，其它一切不变。

| 场景 | 结果 | 证据 |
|---|---|---|
| P1-v4-roimg（idmap 在，镜像只读） | **PASS** | 世界(a) 不碰页表 → 只读镜像也照样交接 |
| P2-v4-roimg（idmap 没了，镜像只读） | **FAIL** | `tramp+0x1a0  str xzr,[x16,x19,lsl#3]`，ESR `0x9600004E` = permission fault level 2，FAR `0xffffffc080040000` = `TABLE_VA` |

注意这条**只证明"若表页只读则必然这样挂"**，不证明电视上那页当时确实是只读（无法离线确定）。
但它同时说明：v4 的世界(a) **根本不需要可写的表页**，所以那个不确定性被绕开了；
而世界(b) 用的是 `.bss`（任何阶段都确定 RW），也比 `reserved_pg_dir` 稳。

## 5.1 v3 桩记录的身份寄存器（QEMU 实测值，供与电视逐项对比）

`./ident.sh` 用**同样的 7 条 `mrs`**（MMU 关、不经过 tramp）取值；
`P1-chain-v3`/`P2-chain-v3` 记录里的值与之相符（TCR/MAIR 在 chain 里是测试台内核设的值）。

| 寄存器 | `-M virt -cpu cortex-a72` | `-M xlnx-zcu102 -cpu cortex-a53` | 说明 |
|---|---|---|---|
| MIDR_EL1 | `0x410FD083` | `0x410FD034` | A72 r0p3 / A53 r0p4（implementer 0x41 = ARM） |
| CTR_EL0 | `0x8444C004` | `0x84448004` | IminLine/DminLine = 64 B；CWG/ERG 位 A72 与 A53 不同 |
| REVIDR_EL1 | `0x00000000` | `0x00000100` | QEMU 各自模型的常量 |
| TCR_EL1 | `0`（未配置） | `0`（未配置） | chain 里 = `0x2B5193519`（测试台内核：T0SZ=T1SZ=25, EPD0=0, TG0=0/TG1=2） |
| MAIR_EL1 | `0`（未配置） | `0`（未配置） | chain 里 = `0xFF00`（idx0=Device-nGnRnE, idx1=Normal WB） |
| ID_AA64MMFR0_EL1 | `0x1124` | `0x1122` | PARange A72=44 bit(4) / A53=40 bit(2)；A72 还有 FGT/ECV 位 |
| MPIDR_EL1 | `0x80000000` | `0x80000000` | Aff0=0，单核 |

⚠️ 实测发现：**`-M xlnx-zcu102` 会钉死 CPU 型号**，`-cpu cortex-a72/max` 都不生效
（MIDR 始终 `0x410FD034`=A53）。要拿 A72 的数据必须换 `-M virt`（所以那一行只能用
`ident.sh` 的独立采集，链路场景在 virt 上跑不起来，原因见 §6）。

## 5.2 `tools/host/decode-record.py` 与桩的偏移一致性（已验）

替身把记录按 probeRW 的格式打成 16 行 hexdump（`0000000023080000: 4d 37 ...`，
每行 16 字节、共 0xB0），直接喂给仓库里的解码器：

```
$ tr -d '\000' < logs/P1-chain-v3.log | grep -E '^00000000' > /tmp/rec.txt
$ python3 tools/host/decode-record.py /tmp/rec.txt
record: magic=b'M764' tag=b'MMMU' size=0xb0 (176 B parsed)
  x30 (checkpoint return) = 0xffffffc0804680a0
  boot_args x0/x1/x2      = 0x0 0x2222222222222222 0x3333333333333333
  handover  x3/x4         = 0x0 0x0
  checkpoint x8/x0/x1     = 0x88 0xa0a0a0a0a0a0a0a0 0xa1a1a1a1a1a1a1a1
  checkpoint x2/x3/x4     = 0xa2a2a2a2a2a2a2a2 0xa3a3a3a3a3a3a3a3 0xa4a4a4a4a4a4a4a4
  SCTLR_EL1               = 0xc5183d  (M=1 C=1 I=1 A=0 SA=1)
  MIDR_EL1                = 0x410fd034  implementer=0x41 ARM part=0xd03 Cortex-A53 vari=0 rev=4
  CTR_EL0                 = 0x84448004  IminLine=64 B DminLine=64 B CWG=64 ERG=64
  REVIDR_EL1              = 0x100
  TCR_EL1                 = 0x2b5193519  T0SZ=25 (39-bit VA) T1SZ=25 (39-bit VA) EPD0=0 EPD1=0 TG0=0 TG1=2
  MAIR_EL1                = 0xff00  attrs = idx0=0x00 idx1=0xff idx2..7=0x00
  ID_AA64MMFR0_EL1        = 0x1122  PARange=2 (40 bits) TGran4=0 TGran16=0
  MPIDR_EL1               = 0x80000000  Aff0=0 Aff1=0
```

解码器的每个字段都和桩的写入偏移、以及替身自己按 qword 读出来的值**逐项一致**
（两条独立路径：解码器解析字节流，替身读 64 位字）。这条保险过。

## 6. 为什么不用 `-M virt`（根本障碍，已实测）

任务最初希望 `-M virt`（RAM 起址 0x40000000）。实测结论：**对本 tramp 不成立**，原因是
tramp 自己装的那张表是「`L1[0]` 一条 1 GB 块」，它只能覆盖 PA 0..1 GB。
`-M virt` 的 RAM 在 0x40000000 以上，任何「让 tramp 交接到的物理地址」都 > 1 GB，
取指必然缺页（`virt-v1` 场景：ESR 0x86000005，FAR=0x400b0200，ESR 的 FSC=5 = level 1
translation fault —— 正是 L1 表项不存在）。

- 换 CPU 模型无用：`cortex-a72/a53/a57/a76/max` 结果一致（已逐一实测）。
- 换 `-M virt,virtualization=on` 无用：问题不在 EL/TTBR 权限，而在物理地址布局。
- 唯一可行的替代是**换一块 RAM 从 PA 0 起的板子**：本机 QEMU 里有
  `-M xlnx-zcu102`（CurrentEL=1，RAM 从 0 起，实测可写 0x20280000/0x23100000 等电视地址）
  和 `-M xlnx-versal-virt`（CurrentEL=3，需要自己降到 EL1，不划算）。
  所以默认板子是 `xlnx-zcu102 -cpu cortex-a72 -m 1G`。
- 附带好处：zcu102 的 RAM 布局与电视同源（都是从 0 起），
  `0x20280000`/`0x21680200`/`0x23100000` 这些电视地址在测试台上都是合法 RAM，
  于是「地址不同也该工作」这件事可以真的验证（本测试台刻意用了完全不同的基址
  0x20000000 与 memstart 0x10000000，tramp 靠自校准/编译期常量都能对上）。

## 7. 原件与副本

| 文件 | 是什么 |
|---|---|
| `src/tramp-v1-pinned.S` | 22:02 版 `probes/handoff/tramp-postmmu.S` 的原样拷贝（只作对照基线） |
| `src/tramp-qemu.S` | 由上面那份派生的**参数化副本**：把 `IDMAP_TABLE_PA`、`HANDOVER_PA` 两个写死地址变成 `#ifndef` 参数，另加 `INJECT_*`（故意注错）与 `FIX_PAGE_OFFSET`（修 bug ③）开关。**所有开关默认关闭时，生成的目标机器码与原件逐字节相同**（`verify-identical.sh` 证明） |
| `src/tramp-v4.S` | 当前版 `probes/handoff/tramp-postmmu.S`（世界 a/b 分岔 + 表搬到 `.bss`）的原样拷贝 |
| `src/tramp-v2.S` / `src/tramp-v3.S` | 22:31 版 `probes/handoff/tramp-postmmu.S` 的原样拷贝（两版 md5 相同；它自己就带 `#ifndef TABLE_PA/TABLE_VA/HANDOVER_PA`，无需参数化） |
| `src/abort-stub-v3.S` | 当前 `probes/handoff/abort-postmmu.S`（0xB0 记录 + 7 个身份寄存器）的原样拷贝 |
| `src/impostor.S` | 完整链路里 0x21220000 处的“替身内核”：打印/校验 0xB0 记录 |
| `src/mrs-collect.S` + `ident.sh` | 独立采集 7 个身份寄存器（不经 tramp，用于 virt+A72 这种链路跑不起来的组合） |

`verify-identical.sh` 做两件事：
1. 用「默认 -D」和「System.map 推出的 -D」两种方式分别汇编 `tramp-v1-pinned.S` 与
   `tramp-qemu.S`，四者 .text 必须互相同 md5；
2. 用 `src/tramp-v2.S` 汇编，与 `probes/handoff/tramp-postmmu.bin` 比 md5
   （钉住时是 `dc19259a890f18b7bfe037f7488d2b2e`，完全一致）；
3. 用 `src/tramp-v4.S` 汇编，与 `probes/handoff/tramp-postmmu.bin` 比 md5
   （钉住时是 `8b6760de157fae90747e54740cdcf3e2`）；
4. 用 `src/abort-stub-v3.S` 的 `#ifndef` 默认值（即 `KADDR=0x20280000` 的电视常量组）
   汇编桩，与 `probes/handoff/abort-postmmu.bin` 比 md5
   （`3efd72efc793d2f6654bca2504095bf8`，完全一致 —— 并且链路场景跑的就是这份桩）。

注意：仓库里的 `tramp-postmmu.S` 仍在被改。测试台**按副本工作**，不会跟着变；
`./build.sh ... v2` 用的是钉住的 22:31 版。要测新版本，把新文件拷成
`src/tramp-v3.S` 并照 §4 加场景即可。

## 8. 已知限制（能证明什么 / 不能证明什么）

**能证明**（都是真跑出来的，不是「应该」）：

- tramp 的地址算术：AT 得到的 PA、`memstart_addr` 的读取、`lin`/`KIMAGE_OFFSET` 的推导；
- 「物理地址当地址用」在 P2 里确实失效（`AT(pa)` 返回 F=1），而 tramp 靠自建 1 GB 块
  仍能完成 `br` 到物理交接地址；
- boot_args 通过映射重载的值、x3/x4 清零、x30 未被破坏、装表后 `TTBR0`/`TCR.EPD0`
  的最终状态、表项内容（v1: `0x0040000000000705`，v2: `0x0040000000000701`）；
- 某条指令为什么挂（ESR/FAR/ELR → 反汇编定位到具体指令）；
- 回归：对故意注错的 5 类变体全部判 FAIL，对修好的版本判 PASS。

**不能证明**：

- **cache / 一致性**：`dc civac`、`ic iallu`、`dsb/isb` 在 TCG 里基本都是空操作。
  tramp 里那段「刷镜像范围的脏行 + 同步 I-cache」在真机上是承重的（自修改/重定位代码），
  测试台只能说「这段指令不炸」，不能说「这段指令够用」。DDR 保留/掉电位、cache
  一致性域（PoU/PoC）行为完全无法覆盖。
- **TLB 行为**：v1 故意**不发 TLBI**，赌「陈旧表项指向同一物理页」。QEMU 在
  `msr ttbr0_el1`/`msr sctlr_el1` 时会自己刷 TLB，因此**这个赌注在测试台上无法被验证**
  （既不会暴露 hazard，也不会证明安全）。v2 改成老老实实 `tlbi vmalle1`，测试台只能
  证明这条指令不炸。真实 Cortex-A73 上的 TLB 时序/投机填充无法仿真。
- **`AT` 语义**：QEMU 的 `at s1e1r` 在 PAR 高位塞了属性位（§5），与真机 PAR 的 RES0 不同；
  AT 与 TLBI/DSB 的交互、AT 在异常/推测路径下的行为也不同。
- **MAIR / AttrIndx**：测试台把 attr0 设成 Device-nGnRnE、attr1 设成 Normal WB RA/WA，
  与内核的 MAIR 未必一致；真机上 Device 内存上取指、Normal WB 的 alias 一致性都可能不同。
  测试台不做内存属性检查（QEMU 不检查 AttrIndx 合法性），所以「AttrIndx 用错」这类
  缺陷**测不出来**。
- **真实 DDR / 互连 / 功耗域**：没有 DDR 训练、没有保留区、没有连写缓冲、没有
  多簇 SMP（单核），因此「广播 TLBI 卡在互连上」这类（v1 注释里担心的）场景无法复现。
- **异常语义的完整性**：只有同步 abort 被覆盖；SError/中断/EL2/EL3 路径不测。
- **不是硬件的替代**：本测试台通过 = 「这段逻辑在给定页表/地址下能走通」，
  不等于「上电视一定不挂」。上机仍需一次验证。

## 9. 文件清单

```
run.sh              回归主入口（14 个场景 + 期望值表 + 失败指令定位）
build.sh            <profile> <scenario> <variant> [v1|v2] 构建假内核+tramp
gen.py              地址空间唯一出处；生成 gen/layout.inc、gen/tramp-defs.txt、gen/profile.sh
verify-identical.sh 证明副本 == 原件
locate.py           ELR → tramp 指令
src/boot.S          假内核（页表/MMU/AT 自检/P2 拆 idmap/跳 tramp）
src/pad.S           落地桩（14 项断言 + 打印 + semihosting 退出）
src/sh.inc          semihosting 宏（不用栈、不依赖翻译）
src/tramp-qemu.S    v1 参数化副本（默认逐字节等于原件）
src/tramp-v1-pinned.S / src/tramp-v2.S   原件钉版
src/link.ld         假内核链接脚本（按 IMAGE_BASE 定址）
gen/                构建产物（layout.inc、tramp.bin、image.elf ...）
logs/               每个场景的输出、tramp 反汇编、layout
ident.sh            采集 7 个身份寄存器（多种 machine × cpu）
src/impostor.S      完整链路的替身内核（0x21220000）
src/abort-stub-v3.S 当前交接桩的原样拷贝
src/mrs-collect.S   独立 mrs 采集器
```
