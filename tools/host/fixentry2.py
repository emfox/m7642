import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/build-postmmu.sh")
s=open(p).read()
s=s.replace('''[ "$PA_ENTRY"  = "0x0"  ] || { echo "FAIL: _start at $PA_ENTRY, expected 0x0" >&2; exit 1; }
[ "$KVA_ENTRY" = "0x10" ] || { echo "FAIL: _start_kva at $KVA_ENTRY, expected 0x10" >&2; exit 1; }
[ "$FDT_ENTRY" = "0xc0" ] || { echo "FAIL: _start_fdt at $FDT_ENTRY, expected 0xc0" >&2; exit 1; }''',
'''[ $((PA_ENTRY))  -eq 0   ] || { echo "FAIL: _start at $PA_ENTRY, expected 0x0" >&2; exit 1; }
[ $((KVA_ENTRY)) -eq 16  ] || { echo "FAIL: _start_kva at $KVA_ENTRY, expected 0x10" >&2; exit 1; }
[ $((FDT_ENTRY)) -eq 192 ] || { echo "FAIL: _start_fdt at $FDT_ENTRY, expected 0xc0" >&2; exit 1; }''')
open(p,"w").write(s); print("比较改成数值")
