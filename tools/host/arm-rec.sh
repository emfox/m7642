#!/system/bin/sh
# Arm the recovery-slot probe: env gets erase-misc + wdt_enable, then the image.
# Every step asserts the exact md5 it expects; any surprise stops the script.
set -e
W=/data/local/tmp
REC=/dev/block/by-name/recovery
ENV_FILE=$W/env-rec.bin
IMG_FILE=$W/rec-hang.img

echo "== precheck: files on device"
E=$(md5sum $ENV_FILE | cut -d' ' -f1); echo "env-rec.bin  $E"
I=$(md5sum $IMG_FILE | cut -d' ' -f1); echo "rec-hang.img $I"
[ "$E" = "74800b24de6ba4eea10f92aa05a074dd" ] || { echo "FAIL env file"; exit 1; }
[ "$I" = "4cdbc794195c44bf964639d0eaf0c9fd" ] || { echo "FAIL img file"; exit 1; }

echo "== precheck: device state"
CUR_ENV=$(dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum | cut -d' ' -f1)
CUR_REC=$(md5sum $REC | cut -d' ' -f1)
echo "env now  $CUR_ENV"
echo "rec now  $CUR_REC"
[ "$CUR_ENV" = "b6dee2daaa9019f6c9d6596692005620" ] || { echo "FAIL env drifted"; exit 1; }
[ "$CUR_REC" = "7c2f467bbda49053951c0ce547d11a00" ] || { echo "FAIL slot drifted"; exit 1; }

echo "== write env"
dd if=$ENV_FILE of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null
sync
NEW_ENV=$(dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum | cut -d' ' -f1)
echo "env readback $NEW_ENV"
[ "$NEW_ENV" = "74800b24de6ba4eea10f92aa05a074dd" ] || { echo "FAIL env readback"; exit 1; }

echo "== write recovery slot"
dd if=$IMG_FILE of=$REC bs=4096 2>/dev/null
sync
NEW_REC=$(md5sum $REC | cut -d' ' -f1)
echo "rec readback $NEW_REC"
[ "$NEW_REC" = "4cdbc794195c44bf964639d0eaf0c9fd" ] || { echo "FAIL slot readback"; exit 1; }

echo "== bcb (must be empty)"
dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | od -A n -t x1
echo "ALL PASS"
