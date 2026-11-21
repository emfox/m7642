#!/bin/bash
# Build the 128 KiB mboot env block that arms the recovery-slot probe.
# Idempotent and read-only against the device: it only produces a local file.
set -eu
K=/home/emfox/kbuild
T=/home/emfox/Debian/m7642/tools/host/envtool.py
NEW='mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 10; bootm 0x25000000'

cp "$K/env-write.bin" "$K/env-before-recprobe.bin"
python3 - "$K/env-write.bin" "$NEW" "$K/env-rec.bin" "$T" <<'PY'
import hashlib, subprocess, sys
src, new, out, tool = sys.argv[1:5]
d = open(src, 'rb').read()
assert len(d) == 131072, len(d)
halves = [d[:65536], d[65536:]]
assert halves[0] == halves[1], "primary and backup differ; fix that first"
parts = []
for i, h in enumerate(halves):
    p = '/tmp/envhalf%d.bin' % i
    open(p, 'wb').write(h)
    subprocess.check_call(['python3', tool, 'set', p, 'recoverycmd=' + new])
    q = open(p, 'rb').read()
    assert len(q) == 65536
    parts.append(q)
r = parts[0] + parts[1]
open(out, 'wb').write(r)
print("wrote", out, len(r), "bytes  md5", hashlib.md5(r).hexdigest())
for i, q in enumerate(parts):
    print("  half%d md5 %s" % (i, hashlib.md5(q).hexdigest()))
PY

echo "=== verify both halves"
for h in 0 1; do python3 "$T" verify /tmp/envhalf$h.bin; done
echo "=== recoverycmd"
python3 "$T" get /tmp/envhalf0.bin recoverycmd
echo "=== keys unchanged"
for k in bootcmd WDT_ENABLE MstarUpgrade_complete; do printf '%s = ' "$k"; python3 "$T" get /tmp/envhalf0.bin "$k"; echo; done
echo "=== entry count / diff vs before"
python3 "$T" list /tmp/envhalf0.bin | wc -l
