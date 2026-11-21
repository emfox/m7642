#!/bin/bash
# Run one 7.3 rung: flash the recovery slot, reboot into it, and report whether
# the abort stub ran (Android came back + stash shows x30 = rung address).
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
R=${1:?usage: rung73.sh A|B|C|D|E}
case $R in
  A) IMG=$HOME/kbuild/m7642-out/m7642-rec-73-rungA.img; IMD5=1cb41a671c70b1b83f9cc668fcbe8217; OFF=0x4;;
  B) IMG=$HOME/kbuild/m7642-out/m7642-rec-73-rungB.img; IMD5=75efe3cf0669f6f0aad9ee8b24335e6b; OFF=0x455038;;
  C) IMG=$HOME/kbuild/m7642-out/m7642-rec-73-rungC.img; IMD5=d5ddfa21086f47ce83d2b03d1d2ae62c; OFF=0x465e5c;;
  D) IMG=$HOME/kbuild/m7642-out/m7642-rec-73-rungD.img; IMD5=b977e569c7e172914e437e3b571b33e0; OFF=0x465eb8;;
  E) IMG=$HOME/kbuild/m7642-out/m7642-rec-73-rungE.img; IMD5=ffbfd7349d44d3b753b6eca19d8f51ce; OFF=0x465ef0;;
  *) echo "unknown rung"; exit 1;;
esac
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "RESULT $R: device not in Android, skipping"; exit 2; }
$ADB -s $TV push "$IMG" /data/local/tmp/rung.img >/dev/null
o=$(root "dd if=/data/local/tmp/rung.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "RESULT $R: slot write mismatch ($o)"; exit 3; }
echo "=== rung $R armed (patch at $OFF), reboot at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery
sleep 14
ok=""
for i in $(seq 1 20); do
  $ADB connect $TV >/dev/null 2>&1
  s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then ok=1; echo "=== Android back at $(date +%H:%M:%S) uptime $(root 'cut -d. -f1 /proc/uptime' | tr -d '\r')s"; break; fi
  sleep 5
done
if [ -z "$ok" ]; then echo "RESULT $R: NO RETURN (died before or at rung $OFF)"; exit 4; fi
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=72 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:' | sed 's/^/  /'
echo "RESULT $R: returned; x30 above should be $((OFF+4)) = $(printf '0x%x' $((OFF+4)))"
