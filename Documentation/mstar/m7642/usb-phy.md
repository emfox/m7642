# USB PHY 上电序列：m7642 活体内核 vs m7322 源码

2026-11-17。目的：确认主线移植时能不能直接搬 `ehci-mstar.c` 里的 UTMI 序列，
还是 m7642 换了 PHY 需要另写。

## 一、结论

**能直接搬。** `Titania3_series_start_ehc()` 在设备上的机器码与 m7322 源码同构，
连两个最特征的值都逐字命中：

| 源码 | 机器码 |
|---|---|
| `writew(0x2084, UTMI+0x2*2)` | `movz w1, #0x2084` / `strh w1, [x19, #0x4]` |
| `writew(0x8051, UTMI+0x20*2)` | `movn w1, #0x7fae`（= 0xFFFF8051）/ `strh w1, [x19, #0x40]` |

唯一确认的差异是 UPLL 那一段（见第四节）。

## 二、抓取方法

`/proc/kallsyms` 全是 0（`kptr_restrict=2`），符号名还在：

```
T Titania3_series_start_ehc
T ehci_mstar_hw_init
```

用参数化探针模块按名字取活体地址，把机器码 dump 到文件：

```sh
sh /data/local/tmp/rung.sh "sym=Titania3_series_start_ehc len=8192"
# sym Titania3_series_start_ehc -> 0xffffff8008753764
```

注意 **`rung.sh` 结尾 `cat | head -80` 会把 dump 截断**，要取完整内容就直接 pull
`/data/local/tmp/probeG.out`。

本地还原 + 反汇编（`--adjust-vma` 用真实地址，便于和源码对照）：

```sh
python3 -c '...'            # hexdump -> physeq.bin（见 artifacts/disasm/ 里同一套解析）
aarch64-linux-objdump -D -b binary -m aarch64 -M no-aliases \
    --adjust-vma=0xffffff8008753764 physeq.bin > physeq.asm
```

产物：`artifacts/disasm/physeq.{dump,bin,asm}`。

## 三、逐条对照（寄存器偏移全部按 `*2` 后出现在指令里）

| 源码动作 | 反汇编 | 说明 |
|---|---|---|
| `UTMI+0x2*2 ← 0x2084` | `0x37c0 movz w1,#0x2084` + `strh [x19,#0x4]` | TESTPKG 分支 |
| `UTMI+0x20*2 ← 0x8051` | `0x37d0 movn w1,#0x7fae` + `strh [x19,#0x40]` | 同上 |
| `UTMI+0x0 \| BIT7\|BIT6\|BIT1` | `0x37ec movn w0,#0x3d`；`orr`；`strb [x19]` | `~0x3d` = 0xFFFFFFC2，正好是 bit1/6/7 |
| `UTMI+0x52*2 \| 0x3F` | `0x37fc add x26,x19,#0xa4`；`0x380c orr #0x3f` | 新 HW 端接覆盖 |
| `USBC ← \| (BIT1\|BIT3)` | `0x3824 movz w0,#0xa`；`strb [x27]` | 0xA = bit1\|bit3 |
| `USBC ← (& ~BIT1) \| BIT5` | `0x3840 movn w0,#0x22`；`and`；`orr #0x20` | 释放 UHC reset + 打开 XIU |
| `UHC+0x40*2` VBUS | `0x3854 add x24,x23,#0x80` | `and #0xffffffef` 清 bit4，再置 bit3 |
| `UTMI+0x2a*2` squelch | `0x38c0 add x0,x19,#0x54` | 7 处引用，含轮询 |
| `UTMI+0x3c*2` CA_START / CA_END | `0x38cc add x20,x19,#0x78` | 含 `#0xfff0` 掩码比较（CA Fail 判定） |
| `UTMI+0x22*2` UPLL | `0x3d98 add x3,x27,#0x44` | **语义不同**，见下节 |

`movz/movn` 立即数统计里还有 `#0xfff0`（1 次）、`#0x1f`（5 次）等，与源码的
CA 校验掩码、位操作一一对得上；31 处 `strh/ldrh` 对应所有 `writew/readw`。

## 四、唯一实质差异：UPLL

m7322 源码：

```c
reg_t = readw(UTMI+0x22*2);
if ((reg_t & 0x10e0) != 0x10e0) writew(0x10e0, UTMI+0x22*2);
reg_t = readw(UTMI+0x24*2);
if (reg_t != 0x1) writew(0x1, UTMI+0x24*2);
```

m7642 的机器码里**没有** `movz #0x10e0`、也没有对 `UTMI+0x48`（0x24*2）写 1；
对 `UTMI+0x44`（0x22*2）做的是**字节级读改写、只置 bit0**：

```
0x3d98  add  x3, x27, #0x44
0x3d9c  ldrb w1, [x3]
0x3da8  orr  w1, w1, #0x1
0x3dac  strb w1, [x3]
```

⟹ m7642 的 UPLL 设置被简化成"置一个使能位"。**移植时这一段要按 m7642 写**，
其余照抄。这一处不影响时序主干（CA 校准、端接覆盖、VBUS 都在）。

## 四bis、哪些可选分支真的编进去了

源码里整段序列被一堆 `#ifdef` 和 `flag & EHCFLAG_*` 包着。从 `physeq.asm` 里按特征立即数
反查，能定下"编进去了"这一层：

| 源码分支 | 特征指令 | 结论 |
|---|---|---|
| `ENABLE_USB_HS_CUR_DRIVE_DM_ALLWAYS_HIGH_PATCH` | `#0x10*2=0x20`、`#0x52*2=0xa4` 都在主路径 | 编进去了 |
| `EHCFLAG_TESTPKG` | `movz w1,#0x2084` + `strh [x19,#0x4]` | 编译进去了，但**不会执行**（见第四节 bis 的更正） |
| `ENABLE_DOUBLE_DATARATE_SETTING` | 0xd*2-1 = `0x19`，全文件无此偏移 | **没编进去** |
| `EHCFLAG_DOUBLE_DATARATE` | `movz w0,#0x76`（480×1.5） | 编进去了，但走不走到由运行时 flag 定 |
| `EHCFLAG_DPDM_SWAP` | `add x1,x19,#0x15` 多处 | 编进去了，同上 |
| squelch（`u_param->squelch`） | `add x0,x19,#0x54`（0x2a*2）在主路径 | 编进去了，但值为 0 时跳过 |

**这两个运行时输入的答案（2026-11-17 16:50 补）**：

1. **flag 字不用反汇编去追，源码里写死了**。`ehci_mstar_hw_init()` 的 `flag` 从 0 开始，
   只可能被两个宏置位：

   | 端口 | `_USB_UTMI_DPDM_SWAP_Px` | `_USB_ENABLE_OTG_Px` | 结果 flag |
   |---|---|---|---|
   | 1（bus usb2） | 0 | 已定义 | `EHCFLAG_ENABLE_OTG` = 0x8 |
   | 2（bus usb1） | 0 | 未定义 | 0 |
   | 3（usb3，MT7663） | — | 未定义 | 0 |
   | 4（usb4） | — | 未定义 | 0 |

   `EHCFLAG_TESTPKG` / `EHCFLAG_DOUBLE_DATARATE` / `EHCFLAG_DPDM_SWAP` 的具名常量里
   **没有任何地方置位** ⟹ 那三段是死代码。我上一版写"TESTPKG 已确认执行"是错的，
   错在把"编进了二进制"当成了"会执行"。

   **现场证据**（读 port3 的 UTMI，即 WiFi 那一路）：

   ```
   0x1f202904: 00 a0 00 00      reg 0x02 = 0xa000
   ```

   TESTPKG 会往这里写 `0x2084`，实际是 `0xa000` ⟹ 确实没执行。

2. **squelch 等四个参数取编译期默认值**：活体 DT 的 `Mstar-ehci-N` 节点**一个属性都没有**
   （没有 `utmi,squelch` / `utmi,chirp` / `utmi,disconnect` / `utmi,eye-param`），
   所以走 `of_property_read_u8()` 失败分支：

   | 参数 | 值 | 来源 |
   |---|---|---|
   | squelch | `0x02` | `UTMI_DISCON_LEVEL_2A & 0x0f`，`(0x60|0x02) & 0x0f` |
   | disconnect | `0x60` | `UTMI_DISCON_LEVEL_2A & 0xf0` |
   | chirp | `0x80` | `UTMI_CHIRP_DCT_LEVEL_42 & 0xf0` |
   | eye[0..3] | `10 02 00 81` | `UTMI_EYE_SETTING_2C..2F`，`ehci-mstar-40932.h` 里前六个变体全是 `#if 0`，只有最后一个默认生效 |

   注意 squelch = 0x02 ≠ 0，所以 `if (u_param->squelch)` 成立 ⟹ 那一次 `UTMI+0x54` 写入确实发生。

所以 PHY 驱动**已经具备可写的条件**了。剩下的是把约 50 个 `#if defined(ENABLE_*_ECO)` 块逐个
判定在 m7642 上是否生效 —— 判据是 `physeq.asm` 里有没有对应的 `(偏移, 位)` 组合。
已确认存在的（偏移出现在指令里）：`0x05`(disconnect window)、`0x10`(240/120 phase)、
`0x21`(HS connection fail into VFALL)、`0x41`(EOF1 window)、`0x84`(chirp detect)、
`0x29`(chirp source select)、`0x1d`(MIU 下界地址)。

## 五、对移植的意义
主线要跑 MT7663，PHY 侧只需：

1. 换基址：端口 3 的 `utmi=USB+0x02900`、`usbc=USB+0x02400`、`ehc=USB+0x02600`
   （见 `usb.md`）；
2. 抄 `Titania3_series_start_ehc()` 主干序列，UPLL 段按第四节改写；
3. 寄存器访问套上 16 位拼接访问器（同前）。

⟹ **USB 侧已无"未知量"**，剩下的是写代码。原估 1–2 周不变，但风险从"中"降到"低"。

## 六、可复用的小技巧

抓到机器码后，先用**源码里的特征立即数**去 `grep` 反汇编：像 `0x2084`、`0x8051`、
`0x10e0`、`0xfff0` 这种不像位掩码的裸值，命中一两个就足以判定"这版代码和源码是不是同一支"，
比逐条读汇编快得多。命中为 0 的地方，往往就是两代芯片真正的差异点。
