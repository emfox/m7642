#!/bin/bash
# Diff two GOP snapshots produced by gop-snap.sh.
#   tools/gop-diff.sh <baseline.txt> <current.txt> [volatile.txt]
# Registers listed in volatile.txt (default: snapshots/volatile.txt) are
# ignored, because a handful of GOP registers tick on their own (counters,
# busy bits) and would otherwise drown the real differences.
set -u

A=${1:?baseline snapshot}
B=${2:?current snapshot}
HERE=$(cd "$(dirname "$0")" && pwd)
VOL=${3:-$HERE/../snapshots/volatile.txt}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

norm() {
	grep -v '^#' "$1" | awk 'NF==4 {print $1" "$2" "$3" "$4}' |
	while read -r i b o v; do
		key="$i $b $o"
		if [ -f "$VOL" ] && grep -qxF "$key" "$VOL"; then
			continue
		fi
		echo "$key $v"
	done | sort -k1,1n -k2,2n -k3,3n
}

norm "$A" > "$TMP/a"
norm "$B" > "$TMP/b"

tot_a=$(wc -l < "$TMP/a")
tot_b=$(wc -l < "$TMP/b")

awk 'NR==FNR {v[$1" "$2" "$3]=$4; next}
     {k=$1" "$2" "$3; if (k in v) { if (v[k]!=$4) print "CHG "k" "v[k]" -> "$4; delete v[k] } else print "ADD "k" "$4 }
     END {for (k in v) print "DEL "k" "$v[k]}' "$TMP/a" "$TMP/b" | sort > "$TMP/d"

add=$(grep -c '^ADD' "$TMP/d" || true)
del=$(grep -c '^DEL' "$TMP/d" || true)
chg=$(grep -c '^CHG' "$TMP/d" || true)
ignored=$(wc -l < "$VOL" 2>/dev/null || echo 0)

echo "baseline: $tot_a regs   current: $tot_b regs   (ignoring $ignored volatile)"
echo "added: $add   removed: $del   changed: $chg"
echo

if [ "$chg" -gt 0 ]; then
	echo "--- changed ---"
	grep '^CHG' "$TMP/d" | head -60
	echo
fi
if [ "$add" -gt 0 ]; then
	echo "--- added (first 30) ---"
	grep '^ADD' "$TMP/d" | head -30
	echo
fi
if [ "$del" -gt 0 ]; then
	echo "--- removed (first 30) ---"
	grep '^DEL' "$TMP/d" | head -30
fi

[ "$add$del$chg" = "000" ] && echo "identical (static registers)"
