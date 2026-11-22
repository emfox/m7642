# 厂值 4.9 内核的入口与建页表（反汇编实测）

> 2026-11-19 夜。来源：`shenzong168/android_device_tcl_tcl_m7642` 仓库的
> `prebuilt/kernel`（19,749,376 B，md5 `c7eca76f50b905462788607ad011f01d`）。
> 裸 ARM64 Image（带 EFI stub），`file` 认作 `ARM64 boot executable Image`。
> 本地副本 `~/Debian/m7642-build/ref/m7642-dt/xx/.../prebuilt/kernel`。

## 0. 这份 Image 是不是同一台机器

不是同一台，但是**同产线同代**，可直接对照：

| 项 | 本仓库 prebuilt | 本机厂值 |
|---|---|---|
| 版本串 | `4.9.118+` | `4.9.118+` |
| 编译器 | MStar GCC 4.9-patched_r20170413 | 同 |
| 编译时间 | `Tue Dec 20 23:55:44 CST 2022` | `Sat Sep 17 16:02:34 CST 2022` |
| 特征符号 | `_mstar_str_enter_tee`、`mstar_ion`、`xc5000_config_radio` | 同族 |
| 分区表 | `MBOOT`/`MPOOL`/`RTPM`/`tvservice`/`tcluserdata` | 同 |

⟹ 只差三个月，不是同一固件，但**早期启动代码是同一个 BSP**。

## 1. Image header 对照（决定性）

| 字段 | 原厂 4.9 | 我们 7.3 |
|---|---|---|
| code0 @+0x00 | `91005a4d` `add x13,x18,#0x16` (MZ) | `fa405a4d` 同机制 |
| **code1 @+0x04** | **`143e7fff` `b Image_base+0xFA0000`** | `1411540d` `b Image_base+0x455038` |
| text_offset @+0x08 | `0x80000` | **`0x0`** |
| image_size @+0x10 | `0x1552000` | `0x670000` |
| flags @+0x18 | `0x0A` | `0x0A` |

★★★ **`+0xFA0000` 是原厂写死的真入口**，不是我们猜的。`mk-ladder` 的
`VENDOR_ENTRY=0xFA0000` / `FA_AT=0xF9FE00` 因此完全对得上。
★★ **code1 机制两边一致**（都是 MZ + 相对 `b`）⟹ mboot 只要跳 `Image_base+0` 就进得去，
这解释了「绿检查点总能出来」。
★ `text_offset` 两边不同（0x80000 vs 0），但 code1 是 PC 相对，不影响入口。

## 2. `+0xFA0000` = MStar 定制入口（逐条）

```
+0xFA0000: ldr  x5, [+0xFA0240]      ; x5 = 0x1F001CE0  ← SoC 寄存器
+0xFA0004: ldr  w7, [x5]
+0xFA0008: and  w7, w7, #0xffffff00
+0xFA000C: and  w7, w7, #0xfffff0ff  ; 掩掉 bit8..11
+0xFA0010: ldr  w6, [+0xFA0238]      ; w6 = 0x0000F000
+0xFA0014: cmp  w7, w6
+0xFA0018: b.eq +0xFA0040            ; 相等 → 正常路径
+0xFA001C: adrp x6, 0x21559000
+0xFA0020: add  x6, x6, #0x830       ; 0x21559830
+0xFA0024: ldr  x5, [+0xFA0248]      ; 0x4D535452 = "MSTR"
+0xFA0028: ldr  x7, [x6]
+0xFA002C: cmp  x7, x5
+0xFA0030: b.ne +0xFA0040
+0xFA0034: adrp x5, 0x20288000
+0xFA0038: add  x5, x5, #0x510
+0xFA003C: br   x5                   ; → 0x20288510 另一条路径
```

⟹ 两条**入口判据**，我们此前完全没考虑过：
1. 读 `0x1F001CE0`，掩码后应等于 `0xF000`；
2. 否则看 `0x21559830` 是否已被写成 `"MSTR"`（即「跑过一次」），是则改走 `0x20288510`。

正常路径：

```
+0xFA0040: adrp x0, 0x20281000 ; +0x0    ; boot_args[0]
+0xFA0048: adrp x1, 0x20281000 ; +0x8
+0xFA0050: str  w3, [x0]
+0xFA0054: str  w4, [x1]
+0xFA0058: adrp x0, 0x20281000 ; +0x10
+0xFA0060: str  w2, [x0]
+0xFA0064: mov  x0, #0x23000000   ; ★★★ DTB 硬编码 0x23000000
+0xFA0068: bl   +0xFA0088         ; preserve_boot_args → 存到 0x213A5000
+0xFA006C: bl   0x20EB3010        ; el2_setup
+0xFA0078: bl   0x20EB3128        ; record_mmu_state
+0xFA007C: bl   +0xFA00A8         ; __create_page_tables（MStar 版）
+0xFA0080: bl   0x20EB3340        ; __cpu_setup   → x0 = SCTLR 值
+0xFA0084: b    0x20EB3258        ; __primary_switch
```

★★★ **`mov x0, #0x23000000`** —— 原厂**不信任 mboot 传的 x0**，自己把 DTB 地址写死。
0x23000000 正是 s1 探针写 `/model`（+0x4C）用的地址 ⟹ 该地址是**厂值公认的 DTB 位置**。

## 3. `0x20EB3010` = `el2_setup`（MMU 归因）

```
msr  spsel, #1
mrs  x0, currentel
cmp  x0, #0x8                ; EL2?
b.ne EL1路径
mrs  x0, sctlr_el2
and  x0, x0, #0xfffffffffdffffff   ; ★ 清 SCTLR_EL2.M（bit25）
msr  sctlr_el2, x0
...
msr  vbar_el2, 0x20294800
mov  x0, #0x3c5              ; SPSR_EL2 = EL1h + DAIF 全屏蔽
msr  spsr_el2, x0
msr  elr_el2, x30
mov  w0, #0xe12              ; 返回值：曾在 EL2
eret                         ; ★ EL2 → EL1
```

EL1 路径清 `SCTLR_EL1` 的 bit24(A) 与 bit25(M)，返回 `0xe11`。
`0x20EB3128` 把 `0xe11`/`0xe12` 存到 **`0x21555000`**（`__boot_cpu_mode`）。

★ 与本机 s1 实测 `CurrentEL=2, M=0` 吻合。**归因保持不变**：s1 插在 `+0xFA0000`，
`el2_setup` 尚未执行，所以 `M=0` 是 mboot 交权时的状态，不是内核关的。
（4.9 自己也会关，两者不矛盾，但不能拿它当证据。）

## 4. `+0xFA00A8` = `__create_page_tables`（MStar 版）

```
212200a8: mov  x28, x30
212200ac: adrp x0, 0x217CD000
212200b0: adrp x1, 0x217D2000
212200b4: bl   0x202BDE50              ; ★ __inval_dcache_area(页表区)
212200b8..: 清零 0x217CD000..0x217D2000（16 KB，stp xzr 每轮 32 B）
212200d8: ldr  x7, [+0xFA0250]         ; 属性 = 0x701
212200dc: ldr  x3, [+0xFA0258]         ; 起始物理 = 0x1F200000
212200e0: ldr  x6, [+0xFA0260]         ; 0x1F210000（随后被覆盖，未参与循环）
212200ec: add  x6, x0, #1<<12 ; orr #3 ; 下一级表 | 3
212200f4: str  x6, [x0, x5, lsl#3]     ; 写 PGD 项
21220110: str  x3, [x0, x5, lsl#3]     ; 写 2 MB block，属性 0x701
21220118: add  x3, x3, #0x200, lsl#12  ; += 2 MB
...                                    ; 之后在 0x217D0000 建 TTBR1 一套
```

★★ **建表前必须先 `__inval_dcache_area` 页表区**（`0x217CD000..0x217D2000`）。
★★ `TTBR0_EL1 = 0x217CD000`、`TTBR1_EL1 = 0x217D0000`。
★ 页表在 **Image 末尾**（base+0x1552000 ≈ 0x217D2000 之内），与我方 7.3 的
`0x20730000`（base+0x4B0000，Image 内）设计一致。
★ 映射起始物理 `0x1F200000`（低于内核加载基址 0x20280000 约 16.5 MB），用途未定。

## 5. `0x20EB31E0` = `__enable_mmu`

```
mrs  x1, id_aa64mmfr0_el1
ubfx x2, x1, #28, #4          ; TGran4
cmp  x2, #0
b.ne HALT                     ; TGran4 != 0 ⟹ 不支持 4K 页 ⟹ wfe/wfi 死循环
...
msr  ttbr0_el1, 0x217CD000
msr  ttbr1_el1, 0x217D0000
msr  sctlr_el1, x0            ; x0 = __cpu_setup 返回值
ic   iallu ; dsb nsh ; isb
ret
```

★★ **MStar 显式检查 4K 页支持并在不支持时 HALT（`0x20EB3234` 存 2 到
`0x21555010` 后 `wfe/wfi` 死循环）**。7.3 同位置无此检查。
本机能跑 4K 页 ⟹ `TGran4=0` ⟹ 走正常路径，此检查不构成死因。

## 6. 其它可用常量

| 符号 | 物理地址 | 来源 |
|---|---|---|
| `__boot_cpu_mode` | `0x21555000` | `el2_setup` 返回值的存放处 |
| `boot_args`（MStar 版） | `0x213A5000` | `+0xFA0088` |
| `VBAR_EL2` | `0x20294800` | `el2_setup` |
| `VBAR_EL1` | `0x20283000` | `+0x20EB31AC` |
| `TTBR0_EL1` | `0x217CD000` | `__enable_mmu` |
| `TTBR1_EL1` | `0x217D0000` | `__enable_mmu` |
| `start_kernel` | `0x202A057C` | `b` 目标（物理） |
| `__mmap_switched` | VA `0xFFFFFF8008CB31AC` | 字面池 |
| `_text`（VA） | `0xFFFFFF8008000000` | 由 `__mmap_switched` VA 反推 |
| `_text`（物理） | `0x20280000` | `ARM\x64` magic @ `0x20280038` |

## 7. 对主线死因的意义（尚未验证）

新增三个候选，此前都未考虑：

1. **入口判据 `0x1F001CE0` vs `0xF000`**：MStar 的入口会读它。若该寄存器在
   我们刷 7.3 的状态下取值不同，且 `0x21559830 != "MSTR"`，行为可能分叉。
   —— 但绿检查点出来说明 `primary_entry` 已进入，所以不是当前卡点。
2. **建表前 `__inval_dcache_area`**：4.9 有，7.3 的 `__pi_create_init_idmap` 依赖
   PI 宏在返回后由调用者清。本机 s1 测到 `C=0`（D-cache 关）⟹ cache 关时写直通，
   此条大概率不成立，但**若 C 在 4.9 路径下被打开过则需重测**。
3. **`0x1F200000` 这个映射起点**：4.9 建 idmap 从这里开始，而我们的 7.3 从
   Image 基址开始。若 mboot 依赖「低地址段已被映射」则可能不符。

## 8. 未解决

- 这份 prebuilt 是**哪个具体机型**（TWRP 仓库只有 `omni_tcl_m7642`，没有型号）。
- `0x1F001CE0`、`0x1F200000` 在 m7642 上的寄存器含义（需要 datasheet 或从
  本机 `/proc/iomem`、厂值 dmesg 对照）。
- 4.9 的 `ID_AA64MMFR0.TGran4` 实际值（可由 `0x21555010` 是否被写 2 判断，
  但需在设备上读内存）。

---

## 9. 本机厂值 cmdline（2026-11-19 23:5x 实测，`/proc/cmdline` 全量）

这是本轮最重要的意外收获。之前只从二进制里推测根设备，现在有原文。

```
console=ttyS0,115200 androidboot.console=ttyS0 init=/init
CORE_DUMP_PATH=/data/vendor/core_dump.%%p.gz KDebug=1 delaylogo=true
security=selinux SD_CONFIG=2 loop.max_part=7 str_ignore_wakelock=1 loglevel=3
QOS_SYS=1 QOS_AUTO_ADJ=1 platform=mi
tcon_type_pmu=CS602 tcon_type_gamma=CS602
pmu_path=/vendor/tvconfig/config/tcon/tcon_183/tcon_pmu.bin
gamma_path=/vendor/tvconfig/config/tcon/tcon_183/tcon_p_gamma.bin
GOPDst=3 tcl_ldm_algo_data=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
tcon_type_extend=ST6451D02-5 total_memory=3145728 MIRROR=0
androidboot.verifiedbootstate=orange root=/dev/mmcblk0p22
ENV_VAR_OFFSET=0x0 ENV_VAR_SIZE=0x10000 ENV=EMMC SECURITY=OFF
customer_ini_path=/tvconfig/config/model/Customer_183.ini support_8k_frc=false
USB_OTG_SOFTWARE_ID=host
LX_MEM=0x21600000 LX_MEM2=0x54400000,0x49600000 LX_MEM3=0x180000000,0x40000000
EMAC_MEM=0x100000 PM51_ADDR=0x43FF0000 PM51_LEN=0x10000 tee_mode=optee SAR5=ON
recovery_fbaddr=0x2D100000 pm_path=/vendor/tvconfig/config/PM.bin
RTPM_INFO=1,0x43FF0000 FRC_R2_INFO=1,0x51D03000 VOC_MEM=0x30F00000,0x200000
CMA0=RETURN,miu=0,hid=22,sz=0x4000000,st=0x7400000
CMA1=OTHERS_RETURN,miu=0,hid=23,sz=0x1000000,st=0x34400000
buildvariant=user
```

### 9.1 直接可用的五条

1. ★★★★★ **`console=ttyS0,115200` / `androidboot.console=ttyS0`**
   内核控制台在 cmdline 里**已经配好了**。只要有 UART 物理接入，就能拿到连续输出。
   这是唯一能根治「没有输出通道」的路径，且无需改任何东西。

2. ★★★★★ **`recovery_fbaddr=0x2D100000`**
   fb 基址是 **mboot 通过 cmdline 传的**，不是内核自己算的。
   ⟹ 换任何内核，mboot 传的 cmdline 不变 ⟹ `0x2D100000` 对我们同样有效。
   这解释了「整屏纯绿那一次」为什么能成。

3. ★★★★★ **`LX_MEM=0x21600000`**
   **Linux 可用物理内存从 0x21600000 开始**，而内核被加载在 **0x20280000** ——
   即内核躺在 Linux 内存**之外**的 MStar 保留区里。`total_memory=3145728`（KB = 3 GB），
   另有 `LX_MEM2=0x54400000,0x49600000`、`LX_MEM3=0x180000000,0x40000000`（第二/三段，含第二 MIU）。
   ⚠️ 这与 4.9 建页表起点 `0x1F200000` 对得上：0x1F200000..0x21600000 是 MStar 保留区
   （GOP / MIU / R2 / PM51 / VOC），内核被硬塞在这段里。

4. ★★★ **`SECURITY=OFF` / `androidboot.verifiedbootstate=orange`**
   无安全启动、无 AVB 校验。刷非签名镜像本来就不会被拒——与既有结论一致。

5. ★★★ **`root=/dev/mmcblk0p22`**、`ENV=EMMC ENV_VAR_OFFSET=0x0 ENV_VAR_SIZE=0x10000`
   root 分区与 env 区（64 KB，`mmcblk0` 偏移 0）都在 cmdline 里写明。

### 9.2 面板与硬件型号（顺带记下）

| 参数 | 值 |
|---|---|
| 面板时序 | `tcon_type_pmu=CS602`、`tcon_type_gamma=CS602`、`tcon_type_extend=ST6451D02-5` |
| tcon 配置 | `tcon_183`（PMU / gamma bin 路径） |
| 客户配置 | `Customer_183.ini` |
| PM51 协处理器 | `PM51_ADDR=0x43FF0000`、`PM51_LEN=0x10000` |
| R2/FRC | `FRC_R2_INFO=1,0x51D03000`、`support_8k_frc=false` |
| VOC | `VOC_MEM=0x30F00000,0x200000` |
| CMA | `CMA0 st=0x7400000 sz=0x4000000`、`CMA1 st=0x34400000 sz=0x1000000` |
| LDM 算法数据 | `tcl_ldm_algo_data=0×16` |

### 9.3 设备身份（确认同一型号）

```
ro.build.fingerprint =
  tcl/tcl_m7642/tcl_m7642:9/PPR2.180905.006.A1/chenzhengmao09171647:user/dev-keys
```

设备树仓库写的是：

```
BUILD_FINGERPRINT := tcl/tcl_m7642/tcl_m7642:9/PPR2.180905.006.A1/jenkins12210038:user/dev-keys
```

★★★ **`tcl/tcl_m7642/tcl_m7642` 与 `PPR2.180905.006.A1` 完全一致**，只差末尾构建账户
（`chenzhengmao09171647` vs `jenkins12210038`）。
⟹ **那个仓库就是为本机这个型号做的**，`prebuilt/kernel` 是**同型号**内核，不是"另一台电视"。

### 9.4 唯一对不上的：分区大小

| 来源 | boot / recovery |
|---|---|
| 仓库 `BOARD_BOOTIMAGE_PARTITION_SIZE` | 27,478,016 B |
| **本机实测**（`/sys/class/block/mmcblk0p{7,8}/size` = 65536 扇区） | **33,554,432 B（32 MB）** |

⟹ 仓库常量**不可用于本机**（可能是另一固件批次的 `/proc/partitions` 或手填值）。
⟹ 但 27,478,016 与 `applypatch … recovery:27471872:…` 里的 27,471,872 接近，
   说明它来自"镜像有效长度"而非分区容量。
⟹ **本机权威值：boot/recovery 均 32 MB**，`dd count=8192 bs=4096` 恰好等于分区容量，
   不存在越界。之前记录正确。
