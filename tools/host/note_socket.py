import os
D = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p = os.path.join(D, "confirmed-facts.md"); s = open(p).read()
if "34.27" not in s:
    s = s.rstrip("\n") + """

### 34.27 智能插座是**蓝牙 Mesh 2.0**，`mihome-ctl` 控不了（2026-11-24）

用户装的插座是「小米智能墙壁插座」`zimi.plug.zncz01`（米家名"电视插座"，did `1043054088`），
**通过蓝牙 Mesh 2.0 接入米家，没有 WiFi 配网**——所以它在设备列表里显示的 IP（`211.90.237.255`）
是无意义占位，控制必须经 **BLE mesh 网关**（如小爱音箱 Pro）。

实测结论：

| 操作 | 结果 |
|---|---|
| `prop-get --did … --siid 2 --piid 1`（云） | ✅ 返回 `True`（可能是缓存值） |
| `prop-set … --value false/0`（云） | ❌ `code: 1` / `-704220043`（设备不可达） |
| `prop-get/prop-set --local` | ❌ 解析出的 IP 是公网地址，miIO 握手失败 |
| `--relogin` | 需要交互式扫码登录，不能无人值守 |

**`mihome-ctl` 里没有任何 mesh/gateway 代码**（`grep -rn mesh` 在包里 0 命中），
所以它属下的 `prop-set` 只能走 MIoT 云，而云对 mesh 子设备需要网关在线转发。
⟹ **本项目不能用它做断电自动化**；要用只能换通路（python-miio 的 gateway RPC + 网关 token）。

顺带装好的东西（有长期价值，留着）：

- `~/.local/bin/arp`：读 `/proc/net/arp` 的 `arp -an` 兼容 shim（`mihome-ctl --local`
  与 python `uuid` 都需要它，而主机没装 net-tools）。注意 `~/.local/bin` **不在非交互 shell 的 PATH** 里。
- `python-miio` 已装进 `~/.local/share/uv/tools/mihome-ctl` 的 venv（`--local` 通路的前提）。

⟹ **恢复挂死设备仍只有两条路**：米家 App / 小爱语音点一下插座，或人手动拔插。
`tools/host/socket.sh` 保留但标注"当前不可用（mesh 设备）"。
"""
    open(p, "w").write(s); print("§34.27 已写入")

# socket.sh 顶部加警示
p = os.path.expanduser("~/Debian/m7642/tools/host/socket.sh"); s = open(p).read()
if "蓝牙 Mesh" not in s:
    s = s.replace("#   socket.sh status",
"""# !! CURRENTLY UNUSABLE: this socket is a Bluetooth Mesh 2.0 device.  mihome-ctl
# has no mesh/gateway support, the cloud rejects prop-set with -704220043 and the
# LAN path resolves a bogus public IP.  Toggle it in the Mi Home app, or by voice.
# Kept for when a cloud/gateway route works.  See confirmed-facts.md §34.27.
#
#   socket.sh status""")
    open(p, "w").write(s); print("socket.sh 已标注不可用")
