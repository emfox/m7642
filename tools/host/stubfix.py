import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/abort-postmmu.S")
s=open(p).read()
if "tbz\tx16, #0, 9f" in s and "add\tx6, x6, x5" in s:
    print("stub already ok"); raise SystemExit
# 桩不再使用 x5 做地址偏移（x5 只表示"要不要关 MMU"，而 MMU 状态改用硬件判断）
s=s.replace("""	add	x6, x6, x5""","")
s=s.replace("""	add	x6, x6, x5""","")
s=s.replace("""	add	x7, x7, x5""","")
s=s.replace("""	add	x9, x9, x5""","")
open(p,"w").write(s); print("stub: 去掉 x5 偏移")
