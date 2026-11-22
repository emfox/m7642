#!/bin/sh
# Put an image into the boot slot.
#
# The recovery slot has no display on this box, so colour probes parked there
# are unreadable.  boot is the one slot where the panel is known to be lit (the
# logo is always visible), and mboot does not verify kernel contents, so a
# patched factory kernel is accepted.
#
# There is no BCB handshake here: the boot slot is what mboot runs on a normal
# power-on.  That also means a bad image is a bad boot -- the way back is the
# rescue stick (rescue-fast.bin rewrites boot), not a warm reset.
#
#   IMG=~/Debian/m7642-build/out/m7642-boot-beacon.img tools/host/bootarm.sh arm
#   tools/host/bootarm.sh verify
#   tools/host/bootarm.sh reboot
#
# Root goes through /system/bin/su (rootd daemon, started by init at boot).
set -eu

IMG=${IMG:-}
ADB=${ADB:-adb}
HOST=${HOST:-192.168.10.60:5555}
PART=/dev/block/by-name/boot
STAGE=/data/local/tmp/boot-beacon.img

A() { "$ADB" -s "$HOST" "$@"; }
say() { printf '\n== %s ==\n' "$*"; }

"$ADB" connect "$HOST" >/dev/null 2>&1 || true
A shell true >/dev/null 2>&1 || { echo "连不上 $HOST" >&2; exit 1; }

su_ok() { A shell '/system/bin/su -c true' >/dev/null 2>&1; }
need_su() { su_ok || { echo "su 不可用，先恢复 root 通道" >&2; exit 1; }; }

case "${1:-}" in
arm)
    [ -n "$IMG" ] || { echo "用法: IMG=<镜像> $0 arm" >&2; exit 2; }
    [ -f "$IMG" ] || { echo "找不到镜像 $IMG" >&2; exit 2; }
    need_su

    want=$(stat -c %s "$IMG")
    part=$(A shell "/system/bin/su -c 'blockdev --getsize64 $PART 2>/dev/null || echo 0'" | tr -d '\r')
    echo "镜像 $want 字节 / 分区 ${part:-?} 字节"
    # blockdev is not guaranteed on toybox; only enforce when it answered.
    if [ -n "$part" ] && [ "$part" != "0" ] && [ "$want" != "$part" ]; then
        echo "尺寸不一致，拒绝写入" >&2
        exit 1
    fi

    say "比对待刷镜像与分区现状"
    img_md5=$(md5sum "$IMG" | cut -d' ' -f1)
    echo "本地   $img_md5"

    say "推送 $IMG"
    A push "$IMG" "$STAGE" >/dev/null

    say "写入 $PART"
    A shell "/system/bin/su -c 'dd if=$STAGE of=$PART bs=4096 2>&1 | tail -1; sync'"

    say "回读校验（前 4 MB）"
    # bs=1M is not understood by this toybox dd and silently yields an empty
    # stream, i.e. the md5 of nothing (d41d8cd9...).  Use a real block size.
    A shell "/system/bin/su -c 'dd if=$PART bs=4096 count=1024 2>/dev/null | md5sum; rm -f $STAGE'" | tr -d '\r'
    echo "本地前 4 MB $(head -c 4194304 "$IMG" | md5sum | cut -d' ' -f1)"

    say "下一步"
    echo "重启后屏幕应出现整屏纯色并保持约 8 秒，然后 Android 正常启动。"
    echo "起不来的话：U 盘 rescue-fast.bin（含 boot 段），拔电 → 按住电源 → 插电。"
    ;;
verify)
    need_su
    say "boot 槽头部"
    A shell "/system/bin/su -c 'dd if=$PART bs=1 count=12 2>/dev/null | od -A n -t x1'" | tr -d '\r'
    find "$HOME/Debian/m7642-build" -maxdepth 4 -name 'boot-stock-backup.bin' 2>/dev/null | head -1 |
        while read -r f; do echo "厂值备份 $f  $(md5sum "$f" | cut -d' ' -f1)"; done
    ;;
reboot)
    say "重启"
    A reboot
    echo "已发重启，需要按一次电源（这台机器 reboot 会先进待机）"
    ;;
*)
    sed -n '2,18p' "$0"
    exit 2
    ;;
esac
