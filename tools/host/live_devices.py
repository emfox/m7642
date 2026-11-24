import os, sys, json
T = os.path.expanduser("~/.local/share/uv/tools/mihome-ctl/lib/python3.12/site-packages")
sys.path.insert(0, T)
from mihome_ctl.config import StateDir
from mihome_ctl.session import new_connector
from mihome_ctl.core.cloudapi import collect

state = StateDir.resolve()
conn, reused = new_connector(state)
rows = collect(conn, ["cn"])
print("session_reused=%s devices=%d" % (reused, len(rows)))
for r in rows:
    name = (r.get("name") or "")
    model = (r.get("model") or "")
    if any(k in name for k in ("插座", "电视")) or "plug" in model:
        print("  did=%s model=%s name=%s online=%s" % (r.get("did"), model, name, r.get("isOnline")))
