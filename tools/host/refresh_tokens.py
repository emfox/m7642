import os, sys, json, shutil, time
T = os.path.expanduser("~/.local/share/uv/tools/mihome-ctl/lib/python3.12/site-packages")
sys.path.insert(0, T)
from mihome_ctl.config import StateDir
from mihome_ctl.session import new_connector
from mihome_ctl.core.cloudapi import collect

state = StateDir.resolve()
conn, _ = new_connector(state)
rows = collect(conn, ["cn"])
p = str(state.tokens_json)
shutil.copy(p, p + ".bak-" + time.strftime("%Y%m%d-%H%M%S"))
json.dump(rows, open(p, "w"), ensure_ascii=False, indent=1)
print("refreshed %d devices -> %s" % (len(rows), p))
for r in rows:
    if (r.get("name") or "") in ("电视插座", "墙壁插座"):
        print("  %s  %s  %s" % (r.get("did"), r.get("model"), r.get("name")))
