# ramoops：跨崩溃的内核日志通道

## 结论

ramoops 在这台机器上**可用**，而且代价极小：不改 memory 节点、不碰
reserved-memory、不动 DTB，只需要三个 config 和一行 cmdline。

它能覆盖的范围比预期宽：只要内核跑到 `postcore_initcall`（第 2 级），
**从 `stext` 开始的所有 printk 都会被回灌进 DRAM**，之后每次 printk 实时落盘。

真正的盲区是「连 `postcore_initcall` 都没跑到就死了」，也就是 `start_kernel`
前半段和 `setup_arch` 内部的崩溃。这部分只能靠串口或更早的自定义机制。

---

## 1. 为什么这块内存能用

三条独立证据。

### 1.1 原厂树就把它当 ramoops 用

从官方包 `0x5452000`（长 `0x5af3`）提取、`dtc` 反编译出的原厂 DTB 里有：

```
ramoops@42300000  reg = <0 0x42300000 0 0x100000>    ← 1 MB
```

运行中的 Android 从 `/proc/device-tree/ramoops@42300000` 也读到了同一个
`reg`，以及 `console` / `ftrace` / `pmsg` / `record` 各 256 KB。

### 1.2 实测：panic 后日志确实留下来了

`echo c > /proc/sysrq-trigger`，设备约 25 s 自行回到系统，`/sys/fs/pstore/` 出现：

```
console-ramoops    48991 字节   ← 从 [0.000000] 到 end Kernel panic，576 行
dmesg-ramoops-0   129168 字节
```

⟹ 两条事实：看门狗走的是 **warm reset，DDR 内容保留**；ramoops 写入是有效的。

### 1.3 我们的内核忽略 mboot 交的 DTB

`arch/arm64/kernel/m7642-dtb.S` 把板级 DTB 直接编进 Image：

```c
.incbin "arch/arm64/boot/dts/mstar/m7642-tcl-65s535d.dtb"
```

原注释写得很清楚：bootloader 从专用 raw 分区加载自己的 DTB，那份分区
Linux 侧改不动，所以把树带在镜像里、不理 bootloader 传过来的那棵。

⟹ **mboot「不擦 0x42300000」这个行为，靠的是它自己读的原厂 DTB，与我们的
DTB 无关。** 我们白拿这个便利，不需要在自己的树里声明任何东西。

> 待确认：mboot 具体是按 DTB 的 reserved 属性、还是按硬编码地址来做这个保留判断。
> 目前只有「原厂 DTB 声明了它 + 实测内容被保留」这两条相关性证据，**因果未证实**。

---

## 2. 地址落在内存洞里，反而省了事

我们的 `m7642-tcl-65s535d.dts` 三段内存：

| 节点 | 范围 | 大小 |
|---|---|---|
| `memory@20200000` | `[0x20200000, 0x41800000)` | 0x21600000 |
| `memory@54400000` | `[0x54400000, 0x9DA00000)` | 0x49600000 |
| `memory@180000000` | `[0x180000000, 0x1C0000000)` | 0x40000000 |

`0x42300000` **大于** 第一段末尾 `0x41800000`，也不在第二段里 —— 它落在
`[0x41800000, 0x54400000)` 这 300 MB 的空洞中。原厂 `/proc/iomem` 的第一行
`20200000-417fffff : System RAM` 正好印证第一段的边界就在 `0x41800000`。

物理上这块 DRAM 存在（实测可写），只是内核不把它登记成 System RAM。

于是 ramoops 走的是 `fs/pstore/ram_core.c` 里这条运行时分支：

```c
if (pfn_valid(start >> PAGE_SHIFT))
        prz->vaddr = persistent_ram_vmap(start, size, memtype);
else
        prz->vaddr = persistent_ram_iomap(start, size, memtype, prz->label);
```

`0x42300000` 没有 `struct page` ⟹ `pfn_valid()` 为假 ⟹ 落到
`persistent_ram_iomap()`，即 `request_mem_region()` + `ioremap_wc()`。
这是对任意物理地址都能建映射的路径。

**所以不用把这块塞进 memory 节点，也不用在 reserved-memory 里声明它。**
`ramoops_probe()` 里没有任何 `memblock_reserve` 调用（7.3 已把 reserve
责任完全交给 DT reserved-memory 机制或使用者自负），边界检查
`ramoops_init_prz()` 只比较 `*paddr + sz` 与 `cxt->phys_addr + cxt->size`。

---

## 3. 覆盖范围：比预期宽，但有一个明确盲区

### 3.1 时序

```
__initcall__kmod_ramoops__534_988_ramoops_init2      ← postcore_initcall, level 2
__initcall__kmod_pstore__523_756_pstore_init7        ← late_initcall,     level 7
```

ramoops 比 pstore 主框架早五级。这不冲突：`pstore_register()` 用到的
`psinfo` / `backend` 等是静态全局量，`pstore_init()` 只负责建
`/sys/fs/pstore` 并重新扫一遍记录。

`ramoops_init()` = `platform_driver_register(&ramoops_driver)` +
`ramoops_register_dummy()`。cmdline 给了 `mem_size` 时后者当场造一个
platform device，于是 **postcore 阶段就 probe**，不用等
`of_platform_default_populate_init()`（`arch_initcall_sync`，level 3）。

### 3.2 回灌靠 CON_PRINTBUFFER

```c
static void pstore_register_console(void)
{
	strscpy(pstore_console.name, psinfo->name, sizeof(pstore_console.name));
	pstore_console.flags = CON_PRINTBUFFER | CON_ENABLED | CON_ANYTIME;
	register_console(&pstore_console);
}
```

`CON_PRINTBUFFER` 让 `register_console()` 把 `log_buf` 里已存在的全部内容
回灌给这个 console。所以 `ramoops_init` 之前打的所有 printk —— 包括
`setup_arch` 阶段的 —— 会在这一刻被一次性写进 DRAM。

尺寸够：`CONFIG_LOG_BUF_SHIFT=17` ⟹ log_buf 128 KB，console 区 512 KB，
回灌只占四分之一，不会截断。

### 3.3 盲区

| 崩溃位置 | 能否抓到 | 原因 |
|---|---|---|
| `postcore_initcall` 之后 | **能** | 实时写 + 回灌已就绪 |
| `stext` ~ `start_kernel` 中段，但跑到了 level 2 | **能** | 回灌把之前的日志补上 |
| `setup_arch` 崩、没跑到 level 2 | **不能** | 日志只在 `log_buf`（DRAM）里，下次启动被覆盖 |
| ATF 没交权 / 入口地址错 | **不能** | 内核没开始跑 |

表格后三行正是历史上真实卡住的地方（`+0xFA0000` 落在未加载区、`udf #0`、
earlycon 都不出）。ramoops 对这类失败无能为力，**不要指望它**。

可能的补救方向（未做）：固定 `log_buf` 的物理地址，让下一次启动在
`setup_arch` 里就把上次的内容捞出来。这需要 `mem=` 预留 + 自己改
`setup_log_buf()`，属于另一个议题。

---

## 4. 配置改动

### 4.1 `.config`

```
CONFIG_MISC_FILESYSTEMS=y     ← 关键：没有它，下面全部不存在
CONFIG_PSTORE=y
CONFIG_PSTORE_CONSOLE=y
CONFIG_PSTORE_RAM=y
CONFIG_REED_SOLOMON=y         ← PSTORE_RAM select 自动带上
CONFIG_REED_SOLOMON_ENC8=y
CONFIG_REED_SOLOMON_DEC8=y
```

`fs/Kconfig` 把 `source "fs/pstore/Kconfig"` 放在 `if MISC_FILESYSTEMS` 里面。
不开 `MISC_FILESYSTEMS`，`PSTORE` 就是个**未定义符号**：`scripts/config`
能写进 `.config`，但 `make olddefconfig` 会把它当垃圾删掉，而且**不报错**。
这个坑卡了一轮。

刻意没开的：

| 选项 | 原因 |
|---|---|
| `PSTORE_COMPRESS` | 默认 y，会 select ZLIB；console 实时写不需要压缩，省一层 |
| `PSTORE_PMSG` | 不需要用户态消息，少占 256 KB |
| `PSTORE_FTRACE` | 依赖 FUNCTION_TRACER + DEBUG_FS，代价大 |
| `PSTORE_BLK` | 那是拿块设备当后端，另一条路 |

### 4.2 cmdline

```
ramoops.mem_address=0x42300000
ramoops.mem_size=0x100000
ramoops.record_size=0x40000
ramoops.console_size=0x80000
```

参数名来自 `fs/pstore/ram.c` 的 `module_param` 声明，前缀是
`KBUILD_MODNAME`。`fs/pstore/Makefile` 里是

```make
ramoops-objs += ram.o ram_core.o
obj-$(CONFIG_PSTORE_RAM) += ramoops.o
```

composite 目标名为 `ramoops`，所以前缀是 `ramoops.` 而不是 `ram.`。
写错前缀不会报错，只会静默不生效 —— 已在 `vmlinux` 的 `__param` 段核对过：

```
$ strings vmlinux | grep -E "^ramoops\.[a-z_]+$"
ramoops.dump_oops   ramoops.ecc          ramoops.max_reason
ramoops.mem_type    ramoops.mem_size     ramoops.mem_name
ramoops.mem_address ramoops.pmsg_size    ramoops.ftrace_size
ramoops.console_size ramoops.record_size
```

---

## 5. 内存划分

总量 1 MB，console 优先：

| 区 | 范围 | 大小 | 用途 |
|---|---|---|---|
| dmesg #0 | `0x42300000`–`0x4233ffff` | 256 KB | 第一条 oops/panic dump |
| dmesg #1 | `0x42340000`–`0x4237ffff` | 256 KB | 第二条 |
| console | `0x42380000`–`0x423fffff` | 512 KB | 实时 printk 环形缓冲 |

原厂布局是四个区各 256 KB（dmesg / console / pmsg / ftrace）。我们砍掉
后两个，把空间全给 console —— 早期启动日志比 pmsg 值钱。

首次启动时签名不符，`persistent_ram_zap()` 会清空重来，之后自洽。

---

## 6. 上机验证

刷入后，按顺序看三处：

```
# 1. 参数有没有被认下来（probe 时会打印）
dmesg | grep -i "ramoops\|pstore"

# 2. 设备树里这个节点（如果走了 DT 路径才有；我们走 cmdline，可能没有）
ls /proc/device-tree/ | grep -i ramoops

# 3. 文件系统挂上没有
ls /sys/fs/pstore/
```

预期看到的关键行：

```
using module parameters
Registered ramoops as persistent store backend
```

第二行说明 `pstore_register()` 成功，console 后端已生效。

然后做一个真实验证：

```
echo c > /proc/sysrq-trigger
# 等设备自己回来
cat /sys/fs/pstore/console-ramoops | head -50
```

如果这段能读出 `[0.000000]` 开头的内容，通道就通了。

### 失败判读

| 现象 | 含义 |
|---|---|
| 无 `using module parameters` | cmdline 没生效（参数名/前缀写错，或 bootargs 没进 Image） |
| `request mem region ... failed` | `0x42300000` 被别的资源占了（未预期） |
| `Failed to map ... pages` | `ioremap_wc` 失败，基本不可能 |
| `backend 'xxx' already in use` | 另一个 pstore 后端先注册了；只可能是 `efivars_pstore`，无害 |
| 有 backend 但 `console-ramoops` 为空 | 回灌没发生，查 `CONFIG_PSTORE_CONSOLE` |

---

## 7. 待确认

- mboot 保留 `0x42300000` 的**判据**：DTB reserved 属性，还是硬编码地址。
  只有相关性证据，因果未证实。
- 冷启动（断电）后这块内容是否必然丢失。按 `boot-test.md` 的记录是丢的，
  但那是针对普通 DRAM 测的，ramoops 区没有单独测过。
- `CONFIG_EFI_VARS_PSTORE` 当前是 y（`efivars_pstore_init6` 在 `vmlinux` 里）。
  它比 ramoops 晚注册，会被 `pstore_register()` 判 `-EBUSY` 挡掉，只留一条
  warning。可以关掉减少变量，但不是必须。
