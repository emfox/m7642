import io
p="/home/emfox/Debian/m7642/Documentation/mstar/m7642/discipline.md"
s=open(p).read()
if "「进了 recovery」只能用 misc 标记证明" in s:
    print("already present"); raise SystemExit(0)
anchor="**任何「到达」必须由 stash 证明，不能只看「设备回来了」。**"
assert anchor in s
add = """**「进了 recovery」只能用 misc 标记证明，`ro.boot.bootreason` 不算。**

代价：2026-11-22 08:03 的一发 ctl 报「Android 起来了」，stash 却是 dtb 残渣——事后查是
`adb reboot recovery` 没生效（走了 `bootcmd`），而 `ro.boot.bootreason` 仍显示 `recovery`
（reason 串会被下一次启动继承）。标记法：往 misc **末尾**写 4 KB `0xA5`，
`recoverycmd` 的第一条 `mmc erase.p misc` 会擦掉它；标记消失才算真进了 recovery。

"""
s=s.replace(anchor, add+anchor, 1)
open(p,"w").write(s)
print("added")
