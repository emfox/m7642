import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p = os.path.join(D, "discipline.md"); s = open(p).read()
if "10 秒" not in s:
    s = s.rstrip("\n") + """

### 挂死后的恢复流程（用户明确，时序不能改）

**设备挂死（画面停在 logo）时，按这个顺序操作，缺一步都开不了机：**

1. **断电源**（插座 OFF）
2. **等 10 秒**（让电源电容放电，真正复位；8 秒不够，30 秒也行但没必要）
3. **开电源**（插座 ON）
4. **等 3 秒**
5. **按红外 POWER**
6. 等 Android 起来（约 40–60 秒）再继续测

要点：

- 断电后重开，电视**必然回到待机**；待机下红外 POWER 才能开机。
- **按红外的时机很重要**：上电后 **3 秒**按，太早/太晚都不行（错开就会卡在 logo 起不来）。
- 因此"断电 8 秒 → 立刻上电 → 等 25 秒再按红外"这种自作主张的时序是**错的**，
  2026-11-24 晚因为改了时序，连续几次都救不回来。
- 卡在 logo 的成因：BCB 仍指向 recovery 分区，而那发的 recovery 镜像本身会挂；
  上电 3 秒按红外可以让它放弃 recovery 路径、正常启动。
"""
    open(p, "w").write(s); print("discipline: 恢复时序已写入")
