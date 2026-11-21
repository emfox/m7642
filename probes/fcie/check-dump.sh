#!/bin/bash
# Compare a fcie.ko dump against the 2026-11-22 reference snapshot.
#   adb exec-out su -c "cat /data/local/tmp/fcie.out" > /tmp/fcie.out
#   ./check-dump.sh /tmp/fcie.out
#
# Volatile registers (leftovers of the last command) are reported as INFO and
# do not fail the check; every other register must match bit for bit.
set -u
DIR=$(cd "$(dirname "$0")" && pwd)
F=${1:-/dev/stdin}
awk -v ref="$DIR/regs-reference.txt" '
  BEGIN {
    while ((getline line < ref) > 0) {
      if (line ~ /^#/ || line ~ /^[ \t]*$/) continue;
      n = split(line, a, /[ \t]+/);
      if (a[1] == "pll") key = "pll " a[2]; else key = a[1];
      want[key] = tolower(a[n]);
    }
    close(ref);
    split("00 03 04 05 06 07 08 0b 0c 0d", v, " ");
    for (i in v) vol[v[i]] = 1;
  }
  $1 == "pll" { key = "pll " tolower($2); got[key] = tolower($NF); next }
  NF >= 4 && $1 != "idx" { key = tolower($1); got[key] = tolower($NF) }
  END {
    bad = 0; miss = 0; info = 0;
    for (k in want) {
      if (!(k in got)) { printf "MISSING %s\n", k; miss++; continue }
      if (got[k] == want[k]) continue;
      if (k in vol) { printf "INFO  %s: got %s (ref %s, volatile)\n", k, got[k], want[k]; info++; }
      else { printf "DIFF  %s: got %s want %s\n", k, got[k], want[k]; bad++; }
    }
    printf "checked %d, diff %d, volatile %d, missing %d\n", length(want), bad, info, miss;
    exit ((bad || miss) ? 1 : 0);
  }' "$F"
