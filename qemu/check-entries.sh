#!/bin/bash
# check-entries.sh -- static check: do the image builders agree with
# probes/handoff/tramp-entries.env about where _start_kva lives?
#
# The 2026-11-22 night failures were caused by exactly this disagreement: the
# tramp grew a `.org 0x10`, so _start_kva moved from blob offset 4 to 0x10,
# while a builder still patched "Image + 0x36c004".  The bench reproduces the
# `bl` path (see README 4.25); this script is the cheap static companion.
set -u
CD=$(cd "$(dirname "$0")" && pwd); cd "$CD"
REPO=${REPO:-/home/emfox/Debian/m7642}
ENV=$REPO/probes/handoff/tramp-entries.env
[ -f "$ENV" ] || { echo "no $ENV  (run probes/handoff/build-postmmu.sh first)"; exit 1; }
# shellcheck disable=SC1090
. "$ENV"
OFF=$((TRAMP_KVA_ENTRY - TRAMP_AT))
echo "tramp-entries.env: TRAMP_AT=$TRAMP_AT  TRAMP_KVA_ENTRY=$TRAMP_KVA_ENTRY  => _start_kva at blob offset $OFF"
echo
bad=0
for f in "$REPO"/probes/handoff/*.sh; do
    n=$(basename "$f")
    env_ok=no; stale=no
    grep -q 'tramp-entries\.env' "$f" && env_ok=yes
    grep -qE 'TRAMP_AT *\+ *4\b|0x36c004' "$f" && stale=yes
    if [ "$stale" = yes ] && [ "$env_ok" = no ]; then
        printf '  %-24s %s  <-- HARDCODES the old +4 entry, does not read the env\n' "$n" "STALE"
        bad=$((bad+1))
    elif [ "$env_ok" = yes ]; then
        printf '  %-24s %s  (sources tramp-entries.env)\n' "$n" "ok"
    else
        printf '  %-24s %s\n' "$n" "-"
    fi
done
echo
if [ "$bad" -eq 0 ]; then
    echo "OK: no builder still hardcodes a +4 kernel-VA entry"
else
    echo "WARNING: $bad builder(s) still patch the pre-.org-0x10 offset;"
    echo "         p1/p2 built with them would land on _start+4 (the bug the"
    echo "         bench's P1-v5-bl-drift scenario reproduces)."
fi
