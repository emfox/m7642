import os, re, glob
R=os.path.expanduser("~/Debian/m7642")

# 1) run-postmmu.sh: 用 tv-wait 取代裸等待，并把"挂过"当成信息
p=os.path.join(R,"probes/handoff/run-postmmu.sh"); s=open(p).read()
old='''ok=""
for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
echo "  android_up=${ok:-no} ($(( $(date +%s) - t0 ))s)"
[ -n "$ok" ] || { echo "  NO_RETURN: checkpoint not reached, or the handover failed"; exit 8; }'''
new='''# Wait, and if the image hung, press the IR power key and keep waiting.
# A hang is itself data: the record (if any) is what we are after.
W=$(WAITSECS=300; echo ${WAITSECS:-300})
"$D/../../tools/host/tv-wait.sh" "$W" || {
	echo "  NO_RETURN: checkpoint not reached (device did not come back)"; exit 8; }'''
assert old in s, "postmmu wait block not found"
s=s.replace(old,new,1)
if 'D=$(cd "$(dirname "$0")" && pwd)' not in s:
    s=s.replace('IMG=$1; IMD5=$2; TAG=$3','D=$(cd "$(dirname "$0")" && pwd)\nIMG=$1; IMD5=$2; TAG=$3',1)
open(p,"w").write(s); print("run-postmmu.sh: 接入 tv-wait")

# 2) 其余 runner：同样替换
pat=re.compile(r'ok=""\nfor i in \$\(seq 1 60\); do ready && \{ ok=1; break; \}; sleep 5; done\n(.*?)\[ -n "\$ok" \] \|\| \{ echo "(.*?)"; exit 8; \}', re.S)
for f in ["probes/fcie/run-cmd17.sh","probes/fcie/run-wt.sh","probes/fcie/run-wr1.sh","probes/fcie/run-clk.sh","probes/handoff/run-hangtest.sh"]:
    p=os.path.join(R,f)
    if not os.path.exists(p): print("skip",f); continue
    s=open(p).read()
    if "tv-wait.sh" in s: print("already",f); continue
    m=pat.search(s)
    if not m: print("NO MATCH",f); continue
    s=pat.sub('"$(dirname "$0")/../../tools/host/tv-wait.sh" 300 || { echo "  NO_RETURN"; exit 8; }\n', s, count=1)
    open(p,"w").write(s); print("wired",f)
