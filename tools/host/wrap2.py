import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"NEXT-SESSION.md"); s=open(p).read()
if "停下点（2026-11-22 15:1x）" not in s:
    i=s.index("\n## ")
    block="""
## 停下点（2026-11-22 15:1x）

设备**硬挂**，需要一次物理拔插（红外救不回，见 §34.9 的退化说明）。
拔插后按这个顺序做，**每一发都当成有预算的**：

```sh
cd ~/Debian/m7642/probes/handoff

# 0) 复工仪式：确认上次结论、看树里已有什么
../..//tools/host/session-start.sh 2>/dev/null || true

# 1) 先打 setup_arch 里最可疑的那个：early_init_dt_scan 之后
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
$ADB connect 192.168.10.60:5555
$ADB -s 192.168.10.60:5555 exec-out su -c "dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=512 seek=16376 count=8; sync"
WAITSECS=90 ./run-postmmu.sh ~/Debian/m7642-build/out/m7642-rec-73-su3.img 16e574ed1de95ea49cdb4485f0114f03 su3

# 2) 判读
#   su3 回来  ⟹ 卡点在 early_init_dt_scan 之后 → 依次打 su4(727bb105) / su5(43038060)
#   su3 不回来 ⟹ 卡点在 early_init_dt_scan 之前或之内 → 先打 su1(760ad6bb) / su2(4d9718fd)
```

**硬约束**：这一段的挂死都要人工拔插，所以**不要一次连打多档**；每发之前先想好
"回来/不回来各自说明什么"。
"""
    s=s[:i]+block+s[i:]
    open(p,"w").write(s); print("NEXT-SESSION 停下点已写")
