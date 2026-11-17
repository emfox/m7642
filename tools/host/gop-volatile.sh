#!/bin/bash
# Derive the set of volatile GOP registers from two or more snapshots.
#   tools/gop-volatile.sh snap1.txt snap2.txt [...] > snapshots/volatile.txt
# A register counts as volatile if its value differs across snapshots, or if it
# is absent from any one of them.
set -u

norm() { grep -v '^#' "$1" | awk 'NF==4 {print $1" "$2" "$3" "$4}' | sort -k1,1n -k2,2n -k3,3n; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

i=0
for f in "$@"; do
	norm "$f" > "$TMP/s$i"
	i=$((i + 1))
done
NFILES=$i

awk -v n="$NFILES" '
{
	key = $1" "$2" "$3
	if (!(key in cnt)) { cnt[key] = 0; vals[key] = "" }
	cnt[key]++
	if (vals[key] == "")
		vals[key] = $4
	else if (index("|" vals[key] "|", "|" $4 "|") == 0)
		vals[key] = vals[key] "|" $4
}
END {
	for (k in cnt) {
		if (cnt[k] != n) { print k; continue }   # missing in some snapshot
		m = split(vals[k], parts, "|")
		if (m > 1) print k                        # value differs
	}
}
' "$TMP"/s* | sort -k1,1n -k2,2n -k3,3n
