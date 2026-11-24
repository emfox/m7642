import os
p=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642/confirmed-facts.md")
s=open(p).read()
start=s.index("- ★ **`reboot recovery` 之后会不会自己回来")
end=s.index("- ⚠️ **DDR 能否保留，取决于复位方式")
new = """- ★ **`adb reboot recovery` 之后会不会自己回来，取决于镜像行为**【2026-11-21 观察 + 2026-11-22 用户实测】：
  - 镜像 `bootm` 后**返回**（没卡死）⟹ mboot 交权 PM51 ⟹ **停在待机，要按电源键**；
  - 镜像**卡死**（带电）⟹ **停在 logo、无人处理电源键** ⟹ **只能拔电**
    （用户实测：屏幕停 logo、红外与实体遥控都无反应、`ping` 不通）；
  - ⟹ 判据是**屏幕**：黑屏 = 进过待机（切过电、DDR 全丢）；停 logo = AP 仍带电（同样拿不到 DDR）；
  - 正常启动耗时 **35–40 s**（含人按电源键的反应时间），所以**启动时长不能当判据**；
  - **`recoverycmd` 里加 `wdt_enable` 不会让卡死的镜像自动复位**（四次实验见 §34.13）。
"""
s = s[:start] + new + s[end:]
s = s.replace("见 `wdt-beacon.md` §九末", "见 `wdt-beacon.md` §二")
s = s.replace("详见 `wdt-beacon.md` §十。", "详见 `wdt-beacon.md` §三。")
s = s.replace("详见 `wdt-beacon.md` §十二", "详见 `wdt-beacon.md` §三")
open(p,"w").write(s)
print("§G 重写完成; 残余作废标记:", s.count("作废"), "残余删除线:", s.count("~~"))
