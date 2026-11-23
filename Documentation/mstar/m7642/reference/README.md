# reference/ —— 原厂数据（只读参考）

| 文件 | 来源 | 说明 |
|---|---|---|
| `m7642-factory.dts` | 厂内核运行时 `/proc/device-tree` 整棵 dump，再用 `dtc -I fs` 反编译（2026-11-17 采集） | machine 输出，**不要手工编辑**；它是写我们自己 DTS 时的权威参考（特别是中断号与节点名） |

二进制原件：`~/Debian/m7642-build/diag/live.dtb`（64 KB，`dtc -I dtb -O dts` 得到同一棵树）。
原始 fs dump 的压缩档：`~/Debian/m7642-build/diag/factory-devtree-fs.tar.gz`。

重建方法（在有设备的情况下）：

```sh
adb exec-out su -c 'tar -C /proc/device-tree -cf - .' > tree.tar
mkdir tree && tar -C tree -xf tree.tar
dtc -I fs -O dts tree > m7642-factory.dts
```
