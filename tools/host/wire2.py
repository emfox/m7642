import os
R=os.path.expanduser("~/Debian/m7642")

p=os.path.join(R,"probes/fcie/run-cmd17.sh"); s=open(p).read()
old='''ok=""
for i in $(seq 1 $(( ${WAITSECS:-300} / 5 ))); do ready && { ok=1; break; }; sleep 5; done
echo "  android_up=${ok:-no} ($(( $(date +%s) - t0 ))s)"
[ -n "$ok" ] || { echo "  NO_RETURN: the probe hung, or the handover failed"; exit 8; }'''
new='''# wait, and press the IR power key if the image hung (see tools/host/tv-wait.sh)
"$(dirname "$0")/../../tools/host/tv-wait.sh" "${WAITSECS:-300}" || {
	echo "  NO_RETURN: the probe hung and did not come back"; exit 8; }'''
assert old in s
s=s.replace(old,new,1); open(p,"w").write(s); print("run-cmd17.sh wired")

# hangtest: 挂死是**预期**，所以这里的等待要"先等，再红外救，并报告它确实挂过"
p=os.path.join(R,"probes/handoff/run-hangtest.sh"); s=open(p).read()
old='''ok=""
for i in $(seq 1 80); do	# up to 400 s
	ready && { ok=1; break; }
	sleep 5
done
el=$(( $(date +%s) - t0 ))
if [ -n "$ok" ]; then
	echo "  ✅ 自己回到 Android，用时 ${el}s（无人工干预）"
else
	echo "  ❌ ${el}s 内没有回来 —— WDT 没布防或没生效"
	exit 8
fi'''
new='''# 这张镜像**故意**死循环：期望它挂，然后靠红外救回来。 tv-wait 会把
# "挂过一次"报出来，那正是本测试要的证据。
if "$D/../../tools/host/tv-wait.sh" 60; then
	el=$(( $(date +%s) - t0 ))
	echo "  ✅ 已确认它会挂，并且设备被自动救回（总 ${el}s，无人工）"
else
	el=$(( $(date +%s) - t0 ))
	echo "  ❌ ${el}s 内红外也没救回来 —— 需要物理拔插"
	exit 8
fi'''
assert old in s
s=s.replace(old,new,1); open(p,"w").write(s); print("run-hangtest.sh wired")
