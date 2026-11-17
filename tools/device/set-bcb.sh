#!/system/bin/sh
# Read or rewrite the bootloader command (BCB) field in the misc partition.
#
# Android's toybox dd rejects conv=, so every write here replaces the whole
# first 4 KiB sector (read -> patch -> write block), which needs no conv.
#
# Usage:
#   set-bcb.sh show
#   set-bcb.sh backup <file>        # dump whole misc partition
#   set-bcb.sh set <command> <backup-file>
#   set-bcb.sh restore <backup-file>
#
# Known-good command values accepted by mboot:
#   boot-recovery  boot-poweron  boot-bootloader  update-bootlogo
#   boot-standbymode  standby_mode_pre  autotest  moduletest  mdebugtest
# ("boot-adb" is written by the vendor framework and is not in that list.)
#
set -u
MISC=/dev/block/by-name/misc
W=/data/local/tmp

case "${1:-}" in
show)
    dd if=$MISC bs=1 count=64 2>/dev/null | od -A d -t x1
    ;;
backup)
    [ $# -ge 2 ] || { echo "usage: $0 backup <file>"; exit 1; }
    dd if=$MISC of="$2" bs=4096 2>/dev/null || exit 1
    echo "backed up $MISC -> $2"
    md5sum "$2"
    ;;
set)
    [ $# -ge 3 ] || { echo "usage: $0 set <command> <backup-file>"; exit 1; }
    cmd="$2"; bk="$3"
    [ -f "$bk" ] || { echo "backup file missing: $bk"; exit 1; }
    len=${#cmd}
    [ $len -le 31 ] || { echo "command too long"; exit 1; }

    # always start from the pristine backup, never from a possibly-dirty sector
    dd if=$bk of=$W/sb_orig.bin bs=4096 count=1 2>/dev/null
    : > $W/sb_new.bin
    printf '%s' "$cmd" >> $W/sb_new.bin
    # pad with a NUL, then keep the rest of the sector byte-for-byte
    printf '\000' >> $W/sb_new.bin
    dd if=$W/sb_orig.bin bs=1 skip=$((len + 1)) 2>/dev/null >> $W/sb_new.bin

    size=$(wc -c < $W/sb_new.bin)
    [ "$size" -eq 4096 ] || { echo "internal error: sector size $size"; exit 1; }

    dd if=$W/sb_new.bin of=$MISC bs=4096 count=1 2>/dev/null || exit 1
    sync
    echo "wrote [$cmd], readback:"
    dd if=$MISC bs=1 count=$((len + 1)) 2>/dev/null
    echo ""
    ;;
restore)
    [ $# -ge 2 ] || { echo "usage: $0 restore <backup-file>"; exit 1; }
    [ -f "$2" ] || { echo "backup file missing: $2"; exit 1; }
    dd if="$2" of=$MISC bs=4096 count=1 2>/dev/null || exit 1
    sync
    echo "restored first sector from $2, md5:"
    dd if=$MISC bs=4096 count=1 2>/dev/null | md5sum
    ;;
*)
    echo "usage: $0 show|backup|set|restore ..."
    exit 1
    ;;
esac
