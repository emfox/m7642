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
| virt-v1 | `-M virt`（RAM 0x40000000） | **FAIL** | 演示 §6 的障碍：交接地址 0x400b0200 落在 1 GB 块覆盖之外，取指 abort（ESR 0x86000005, FAR=0x400b0200） |

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
| `src/tramp-v2.S` | 22:31 版 `probes/handoff/tramp-postmmu.S` 的原样拷贝（未改一个字；它自己就带 `#ifndef TABLE_PA/TABLE_VA/HANDOVER_PA`，无需参数化） |

`verify-identical.sh` 做两件事：
1. 用「默认 -D」和「System.map 推出的 -D」两种方式分别汇编 `tramp-v1-pinned.S` 与
   `tramp-qemu.S`，四者 .text 必须互相同 md5；
2. 用 `src/tramp-v2.S` 汇编，与 `probes/handoff/tramp-postmmu.bin` 比 md5
   （钉住时是 `dc19259a890f18b7bfe037f7488d2b2e`，完全一致）。

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
```
