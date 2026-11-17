# CPU 多核启动：不是标准 spin-table

2026-11-17。影响：主线能不能把 4 个 A73 都拉起来，还是只有 1 个核在跑。

## 一、DT 事实

```
cpus {
	cpu@0 { compatible = "arm,cortex-a73","arm,armv8";
	        enable-method = "mstar-spin-table";
	        cpu-release-addr = <0x0 0x100510>; };
	... cpu@1/@2/@3 同
};
```

- **没有 PSCI 节点**（`grep psci` 全树 0 命中）；
- `enable-method` 是私有字符串 `mstar-spin-table`，不是 `spin-table`；
- release 地址 `0x100510` 落在 SRAM（内部 0x100000 区）。

## 二、源码：声明在，定义缺

`arch/arm64/kernel/cpu_ops.c` 里把 `mstar_smp_spin_table` 挂进了 `dt_supported_cpu_ops[]`：

```c
extern const struct cpu_operations mstar_smp_spin_table;
```

但**全树找不到它的定义** —— 和 `arch/arm64/arm-boards/plat-mstar` 一起缺失
（这也是当初把厂商驱动往主线搬时编译挂掉的同一个坑）。
`arch/arm64/kernel/smp_spin_table.c` 本身是**原版未改**的。

⟹ 想看协议只能反汇编。

## 三、活体内核反汇编（`artifacts/disasm/spin_*.asm`）

符号齐全：`mstar_smp_spin_table_{init,prepare,boot,postboot,disable,die,kill}_cpu`。

**`prepare_cpu`（0xffffff8008087168）开头就是关键：**

```
x1 = 0xffffff80093586a0                 ; cpu release 数组
x0 = [x1 + cpu*8]                       ; = DT 里的 cpu-release-addr
x2 = [0xffffff8009358048]               ; = mstar_pm_base（同一个 offset 72 的全局）
x0 = x0*2 + x2                          ; ← 注意：×2 再加 pm_base
x20 = x0+4 ; x19 = x0+8                 ; 后面还要写 +4 / +8 两个字
str w5, [x0]                            ; 16 位有效值写入
```

⟹ release 寄存器不在 `0x100510`，而在 **`mstar_pm_base + 2*0x100510` = `pm+0x200A20`**
（16 位编址的老规矩，和 USB 块一个套路），并且是 **3 个字**的邮箱，不是单个 64 位槽。

**`boot_cpu`（0xffffff8008cb2c60）：**

```
x2 = cpu_release_addr[cpu]
str x2, [全局 0xffffff8009354800]        ; 存一份
bl  <某个函数>
sev                                      ; 唤醒
循环：读全局与 [[0xffffff80091caa80]+0xfa] 比较；再读 release 值，== -1 则成功
返回 0 或 -0x26（-ENOSYS 量级）
```

⟹ 有 **ack 握手**（从核把 -1 写回）和超时判断，不是 fire-and-forget。

## 四、结论

1. 主线 `cpu_ops` 里的 `spin-table` **不能直接用**：它会 `ioremap(cpu-release-addr)` 并按
   64 位小端写入口地址，而这里要写的是 PM 窗口里的 3 字邮箱 + ack。
2. 需要自己写一份 ops（估 **50–100 行**）：`init_cpu` 读 DT、`prepare_cpu` 算
   `pm + 2*addr` 并填邮箱、`boot_cpu` 发 `sev` 后等 ack。协议主干第三节已经写清楚。
3. **不是结构性障碍**：3 个字各是什么（入口/栈/魔数？）还需再读 `init_cpu` 和
   `postboot_cpu` 才能定，但都在可反推范围内。

## 五、对 P0 的影响：没有

**单核能跑完 P0。** 面板显示（simplefb/GOP）和 MT7663（USB）都不需要第二个核，
WiFi 的吞吐掉一半也能用。所以：

- P0/P1 阶段：`enable-method` 直接删掉，只留 CPU0；
- P2 之后再补 SMP glue（那时已经有串口/日志了，调试成本低得多）。

⟹ 这条从"中风险、1–2 周"下调成"**P0 不阻塞，P2 后补 1–2 周**"。

## 六、待办

- [ ] 反汇编 `init_cpu` / `postboot_cpu`，定出邮箱三个字的含义
- [ ] 从 mboot 侧确认从核在 `pm+0x200A20` 上到底怎么轮询（mboot 二进制在 `fw/mboot/`）
