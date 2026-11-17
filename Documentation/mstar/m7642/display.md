# 在线读取 m7642 显示寄存器：方法与实测数据

日期 2026-11-17。目标：不刷机、不重启、不插 U 盘，从运行中的厂商内核里把显示子系统的真实数据读出来。

## 一、先说结论

做到了。现在有一个可用的「显示寄存器读取器」，能在真机上读出 GOP 的实时寄存器值，
而且读到的几何值精确对上当前分辨率：

| 位置 | 值 | 含义 |
|---|---|---|
| bank 1, off 5 | `0x0780` = **1920** | 画面宽度 |
| bank 1, off 8 | `0x0438` = **1080** | 画面高度 |
| bank 1, off 9 | `0x0780` = **1920** | 行跨距 / 另一路宽度 |
| bank 1, off 1 | `0x2000` = 8192 | 行缓冲或对齐后的 stride |
| bank 0, off 18/19 | `0x3fff` / `0x0fff` | 4095 层级掩码类值 |

64 个寄存器中 44 个非零，说明读到的是活的硬件，不是一块空内存。

## 二、过程中撞到的真正障碍：`module_init` 从不执行

这一条推翻了上一轮「L1 已打通」的结论，必须更正。

现象：任何模块 `insmod` 都返回 0、`/proc/modules` 里是 `Live`，
但模块里的 `printk` 从不进 dmesg，`filp_open` 也不创建文件——**代码根本没跑**。

一比特判定：让 `module_init` 直接 `return -EIO`，模块依然是 `Live`（这个 ROM 的加载器
忽略了 init 的返回值，所以返回值不能当信号）。真正的证据在 ELF 里：

| 项 | 我们的模块 | 厂商模块（devnode.ko） |
|---|---|---|
| `.gnu.linkonce.this_module` | 0x300 | 0x300 |
| `mod->init` 重定位偏移 | **0x158** | **0x160** |
| `mod->exit` 重定位偏移 | 0x2e8 | 0x2e8 |

`struct module` 的布局差了 8 字节。内核在 0x160 读到的是 NULL，于是 `do_init_module()`
直接跳过初始化，模块照样挂进链表显示为 Live。

我们实测自己这份头文件算出来的偏移是 `init=344 (0x158) exit=744 (0x2e8) size=768`，
总大小与厂商一致、`exit` 位置也一致，只有 `init` 前少 8 字节、`init` 后多 8 字节。
配置里 `CONFIG_MODULE_SIG` 与 `CONFIG_UNUSED_SYMBOLS` 两边都是关闭的，
说明差别来自 TCL 私有树对 `struct module` 的改动，不是我们能靠改 config 对齐的。

### 规避办法（已验证）

**把探针代码放进 `module_exit`，用 `rmmod` 触发。** `exit` 的偏移恰好是对的。

```sh
/vendor/bin/busybox insmod /data/local/tmp/probe.ko   # init 空转
/system/bin/rmmod probe                               # 真正执行探针
```

注意工具选择（上一轮踩过）：`busybox insmod` 正常、`toybox insmod` 会让内核自旋；
`rmmod` 正好相反，必须用 toybox 的 `/system/bin/rmmod`。

## 三、输出通道

`printk` 完全不可用：`console=ttyS0,115200` 而串口没有对端，且模块的 printk 连
dmesg 都没进。改用内核里直接写文件：

```c
f = filp_open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
kernel_write(f, buf, len, pos);   /* 4.9 的第 4 个参数是 loff_t，不是指针 */
filp_close(f, NULL);
```

`filp_open` / `kernel_write` 都是导出符号，CRC 与设备一致。
生成的文件是 0600 root，取回前要 `chmod 644`。

## 四、符号解析的能力边界

`kallsyms_lookup_name` 是导出的（CRC `e007de41`），可以解析任意**函数**符号：

```
_stext                    = ffffff8008082000
MDrv_SYS_RegOP            = ffffff8008896550
MHal_GFLIP_ReadGopReg     = ffffff80088f0d60
MHal_GFLIP_WriteGopReg    = ffffff80088f0cfc
```

但 `iomem_resource`、`mstar_fb_fix`、`memstart_addr` 这些**数据**符号全部返回 0，
原因是 `# CONFIG_KALLSYMS_ALL is not set` —— kallsyms 里只收 text 段符号。
要拿数据符号的地址只能靠反汇编：把函数机器码读出来，解码其中的 `adrp` + `ldr`。

`/proc/iomem` 用全能力 root 读出来只有这些：

```
20200000-417fffff : System RAM
  20280000-2121ffff : Kernel code
  213a0000-217d0fff : Kernel data
41900000-419bffff : persistent_ram ×4
54400000-9d9fffff : System RAM
180000000-1bfffffff : System RAM
ffffff800a340000-ffffff800a343fff : mali.0
```

**MStar 的外设没有注册到 iomem**，全部是硬编码地址，所以这条路拿不到任何外设基址。

## 五、`mstar_pm_base` 与 RIU 窗口

反汇编 `MDrv_SYS_RegOP` 得到这个模式（arm64 分支）：

```
adrp x1, page
ldr  x1, [x1, #72]          ; mstar_pm_base
add  x1, x1, #0x800, lsl #12 ; + 0x800000
```

解码 `adrp` 得到变量地址 `0xffffff8009358048`，读出来的值是：

```
mstar_pm_base = 0xffffff800a000000
RIU 窗口      = 0xffffff800a800000
```

这个地址落在 `0xffffff800a340000`（mali.0 的 ioremap 区）附近，属于 vmalloc/ioremap 区，
不像线性映射，所以确实是设备映射。

**但直接按 m7322 的偏移去读是错的。** 以 `REG_GOP_BASE = 0x20200`（来自 `hal/m7322/gflip/mhal_gflip_reg.h`）
为起点读 64 个字，全部为 0；`ioremap(0x2D100000)` 也直接失败。这说明 m7642 的
GOP 偏移与 m7322 不同——公开树里没有 m7642 的寄存器表，正是这个原因。

## 六、正确做法：直接调用厂商自己的访问函数

既然内核里就有厂商编译好的访问器，就不要自己猜地址。从反汇编解出签名：

```
MHal_GFLIP_ReadGopReg(u8 idx, u16 bank, u16 offset, u16 *out)
```

参数依据：函数开头 `cmp w19, #2; b.hi <清零点>`（idx 上限 2）、
`uxth w20, w1` / `uxth w21, w2`（bank/offset 是 16 位）、
错误路径 `strh wzr, [x3]`（第 4 个参数是 u16 输出指针）。

调用后立刻拿到真实数据（idx 0，bank 0..3，offset 0..15）：

```
-- bank 0 --             -- bank 1 --             -- bank 3 --
00: 4018                00: 4051                00: c008
01: 0002                01: 2000                01: 4002
02: 0018                02: 2f9a                02: 0000
05: 0000                05: 0780  <- 1920        03: 3a07
08: 00ba                08: 0438  <- 1080        04: 9814
09: 0806                09: 0780  <- 1920        05: 80ff
12: 3fff                10: 80ff                08: 40be
13: 0fff                                       12: 3fff
15: 011c                                       15: 0116
```

bank 2 是 8 个值的两遍重复（`fc 88 f2 75 1b fe f7 49`），像色彩键或调色板。

安全边界：这一整轮只做了 MMIO **读**，设备全程存活（`/proc/uptime` 连续，闸门未受影响）。
读错地址在这个 SoC 上不会挂总线，只有写寄存器才危险。

## 七、可复现的流程

```sh
# 1. 构建（设备原始 .config + 合成的 Module.symvers）
CROSS=$HOME/kbuild/aarch64--glibc--stable-2018.11-1/bin/aarch64-linux-
make -s -C kernel_mstar-main O=$PWD/modtest2/out ARCH=arm64 CROSS_COMPILE=$CROSS \
     M=$PWD/probe8 modules

# 2. 推送并运行（init 空转，rmmod 触发 exit）
adb push probe8.ko /data/local/tmp/
adb shell 'echo "sh /data/local/tmp/runprobe.sh probe8" > /data/local/tmp/tvroot.cmd'
adb shell '/factory/su -p -c "cat /data/local/tmp/tvroot.out"'
adb pull /data/local/tmp/probe8.out

# 3. 反汇编（可选，用于解签名/找基址）
python3 tools/host/disasm_probe5.py
```

`runprobe.sh` 封装了「rmmod → insmod → rmmod → chmod」这套动作。

## 八、这套工具能干什么、不能干什么

能：

- 读任意内核函数的机器码并反汇编，从而反推出私有 HAL 的常量和调用协议；
- 调用厂商自己的访问函数，把任意子系统当成 oracle 查询（GOP 已验证）；
- 只读探查硬件状态，风险极低。

不能：

- 用 `module_init` 注册常驻驱动（布局不对，init 永远不被调用）；
- 靠 kallsyms 取数据符号地址（KALLSYMS_ALL 关闭）；
- 靠 `/proc/iomem` 拿外设基址（MStar 不注册）。

所以它适合**侦察**，不适合承载真正的驱动。要跑常驻驱动，仍然必须自己编内核。

## 九、后续（同日已推进）

1. **TCON / DIP 查完了：内核里几乎没有代码。**
   `grep -i tcon /proc/kallsyms` 没有任何 `MDrv_TCON`/`MHal_TCON` 符号，
   `MHal_DIP_*` 只剩一个取时钟的函数。⟹ **面板时序由 bootloader 配好，内核不参与**，
   与 cmdline 的 `tcon_type_extend=ST6451D02-5` 一致。对 simplefb 方案是利好——不用重做时序。
2. **GOP 寄存器全量快照已完成**：3 个索引 × 16 个 bank × 256 偏移，
   共 1241 个非零寄存器，含窗口矩形、色彩键、测试图案等。
   详见 [gop-registers.md](gop-registers.md)，原始数据 `artifacts/probe-out/probeD16.out`。
3. **帧缓冲地址不在 GOP 窗口寄存器里**（三种编码在 16 个 bank 全零命中），
   但这不影响 simplefb —— cmdline 已经给了 `recovery_fbaddr=0x2D100000`。
4. 下一步若要继续：把快照做成「黄金状态」，将来自己写 GOP 初始化时逐字段对照；
   或改用 `/dev/mik!disp` 的 ioctl（需要编一个 32 位用户态程序）。
