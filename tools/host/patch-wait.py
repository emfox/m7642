p="/home/emfox/Debian/m7642/probes/fcie/run-cmd17.sh"
s=open(p).read()
if "WAITSECS" in s:
    print("already"); raise SystemExit(0)
old = 'for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done'
new = 'for i in $(seq 1 $(( ${WAITSECS:-300} / 5 ))); do ready && { ok=1; break; }; sleep 5; done'
assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("patched")
