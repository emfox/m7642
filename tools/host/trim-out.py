import os, glob, subprocess
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
OUT=os.path.expanduser("~/Debian/m7642-build/out")

p=os.path.join(D,"confirmed-facts.md")
s=open(p).read()
anchor="⟹ **镜像确实只是源码 + Image 的确定性函数**，删掉不损失信息；有 md5 就能判定重建是否等价。"
prov = anchor + """

**可复验性锚点**（有了这三项，任何一张镜像都能重算出文档里的 md5）：

| 锚点 | 值 |
|---|---|
| `kernel/linux-main/arch/arm64/boot/Image` | 6,238,720 B · md5 **`18f7ed3c290050be3102d8665636ea27`** |
| 工具链 | `toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-*`（buildroot GCC 13.3） |
| 构建入口 | `probes/handoff/{build-postmmu,mk-postmmu-images,mk-emap-images,mk-kva-images}.sh`、`probes/fcie/{build-extra,build-stage,build-boot}.sh` |
| 容器来源 | `backups/partitions/rec/recovery_full.bin`（厂值 recovery 全槽） |

**所以 `out/` 只留在办的那几张**（2026-11-22 12:0x 起）：`kva4`/`kva5`/`kva6`。
其余 31 张（含 4 张作废的 `kva`/`kva1`/`kva2`/`kva3`）全部删除——它们对应的
问题都已经回答过，md5 留在本文件里，需要时一条命令重建。
换内核后 Image 的 md5 会变，那时重建出来的镜像 md5 也会变，**这是预期行为**。"""
assert anchor in s
s=s.replace(anchor,prov,1)
open(p,"w").write(s)
print("provenance 已写入 confirmed-facts §34.1")

keep={"m7642-rec-73-kva4.img","m7642-rec-73-kva5.img","m7642-rec-73-kva6.img"}
removed=[]
for f in sorted(glob.glob(os.path.join(OUT,"*.img"))):
    b=os.path.basename(f)
    if b in keep: continue
    os.remove(f); removed.append(b)
print("删除 %d 张：%s" % (len(removed), " ".join(x.replace("m7642-rec-73-","").replace(".img","") for x in removed)))
keep_now=sorted(os.path.basename(f) for f in glob.glob(os.path.join(OUT,"*.img")))
print("保留：", keep_now)
