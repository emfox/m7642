#!/bin/bash
# run.sh -- offline bench for probes/handoff/tramp-postmmu.S
#
#   ./run.sh              run every scenario (about 20 s)
#   ./run.sh P1 P2        run selected scenarios by name
#   ./run.sh -l           list scenarios
#
# Each scenario is a (profile, scenario, variant, tramp-source) tuple with the
# verdict we expect.  The exit status is 0 only when every scenario matches.
set -u
CD=$(cd "$(dirname "$0")" && pwd)
cd "$CD"
TC=${TC:-/home/emfox/Debian/m7642-build/toolchain/gcc13/bin}
QEMU=${QEMU:-qemu-system-aarch64}
TIMEOUT=${TIMEOUT:-20}
LOG=logs
mkdir -p "$LOG"
export TC

# name | profile | scenario | variant | fixed? | tramp | expect | what it is for
SCENARIOS="
P1-v1-shipped|zcu102|1|vanilla|0|v1|FAIL|v1 as shipped (22:02): PAGE_OFFSET bug, idmap alive
P2-v1-shipped|zcu102|2|vanilla|0|v1|FAIL|v1 as shipped (22:02): PAGE_OFFSET bug, idmap gone
P1-v1|zcu102|1|vanilla|1|v1|PASS|v1 with PAGE_OFFSET repaired, idmap alive
P2-v1|zcu102|2|vanilla|1|v1|PASS|v1 with PAGE_OFFSET repaired, idmap gone
P1-v1-x5zero|zcu102|3|vanilla|1|v1|PASS|v1, caller leaves x5 == 0 (idmap carries it)
P2-v1-x5zero|zcu102|4|vanilla|1|v1|FAIL|v1 with x5 == 0 and the idmap gone
P1-v1-noidmap|zcu102|1|no-idmap|1|v1|PASS|v1 without the 1GB table, idmap alive
P2-v1-noidmap|zcu102|2|no-idmap|1|v1|FAIL|v1 without the 1GB table, idmap gone
P1-v1-badlin|zcu102|1|badlin|1|v1|FAIL|injected: v1 with a wrong linear offset
P1-v1-dbloff|zcu102|1|dbl-offset|1|v1|FAIL|injected: bug ① (double offset) again
P2-v1-paalias|zcu102|2|pa-alias|1|v1|FAIL|injected: bug ② (PA alias hop) again
P1-v2|zcu102|1|vanilla|0|v2|PASS|v2 as shipped (22:31), idmap alive
P2-v2|zcu102|2|vanilla|0|v2|PASS|v2 as shipped (22:31), idmap gone
virt-v1|virt|1|vanilla|1|v1|FAIL|RAM at 0x40000000 vs the tramp's 1GB block
"

list() {
    echo "$SCENARIOS" | while IFS='|' read -r name prof scen var fix tver expect desc; do
        [ -z "${name:-}" ] && continue
        case "$name" in \#*) continue;; esac
        printf '  %-14s %-7s scen %-2s variant %-11s fixed=%s tramp=%-2s expect %-4s  %s\n' \
            "$name" "$prof" "$scen" "$var" "$fix" "$tver" "$expect" "$desc"
    done
}

if [ "${1:-}" = "-l" ]; then list; exit 0; fi
WANT="$*"
pass=0; bad=0
printf '%-16s %-8s %-14s %s\n' SCENARIO EXPECT GOT VERDICT
echo "---------------------------------------------------------------------------"
while IFS='|' read -r name prof scen var fix tver expect desc; do
    [ -z "${name:-}" ] && continue
    if [ -n "$WANT" ] && ! echo " $WANT " | grep -q " $name "; then continue; fi

    BASE_FIX=$fix QUIET=1 ./build.sh "$prof" "$scen" "$var" "$tver" >/dev/null 2>&1 || {
        printf '%-16s %-8s %-14s BUILD FAILED\n' "$name" "$expect" "-"; bad=$((bad+1)); continue; }
    # shellcheck disable=SC1090
    eval "$(cat gen/profile.sh)"
    lf=$LOG/$name.log
    timeout "$TIMEOUT" "$QEMU" -display none -audio none -nographic \
        -semihosting-config enable=on,target=native \
        -M "$MACHINE" -cpu cortex-a72 -m 1G -kernel gen/image.elf \
        </dev/null >"$lf" 2>&1
    rc=$?
    cp gen/tramp.dis gen/image.elf gen/layout.inc "$LOG/" 2>/dev/null || true

    if grep -q "^PASS stage" "$lf" && [ $rc -eq 0 ]; then
        got=PASS; kind=""
    elif grep -q "EXCEPTION" "$lf"; then
        got=FAIL; kind="fault (guest took an abort)"
    elif grep -q "FAIL stage chk=" "$lf"; then
        got=FAIL; kind="pad check $(grep -o 'chk=0*[0-9A-F]*' "$lf" | tail -1 | sed 's/chk=0*/chk /;s/^chk $//')"
    elif [ $rc -eq 124 ]; then
        got=FAIL; kind="hang (no output)"
    else
        got=FAIL; kind="qemu exit $rc"
    fi
    ok=$([ "$got" = "$expect" ] && echo ok || echo MISMATCH)
    if [ "$ok" = ok ]; then pass=$((pass+1)); else bad=$((bad+1)); fi
    printf '%-16s %-8s %-14s %-9s %s\n' "$name" "$expect" "$got" "$kind" "$ok"
    echo "    $desc"
    if [ "$got" = FAIL ] && [ -n "$kind" ]; then
        elr=$(grep -o 'elr=0x[0-9A-Fa-f]*' "$lf" | tail -1 | cut -d= -f2)
        if [ -n "$elr" ]; then
            python3 locate.py gen/tramp.dis "$TRAMP_VA" "$TRAMP_PA" "$elr" "$HANDOVER_PA"
            grep -o 'esr=0x[0-9A-Fa-f]*' "$lf" | tail -1 | sed 's/^/    ESR /'
            grep -o 'far=0x[0-9A-Fa-f]*' "$lf" | tail -1 | sed 's/^/    FAR /'
        fi
        grep -o 'FAIL stage.*' "$lf" | tail -1 | sed 's/^/    /'
    fi
    if [ "$got" = PASS ]; then
        grep -o '\[pad\] kimage=0x[0-9A-Fa-f]* memstart=0x[0-9A-Fa-f]* lin=0x[0-9A-Fa-f]*' "$lf" |
            tail -1 | sed 's/^/    /'
    fi
    echo ""
done <<EOF
$SCENARIOS
EOF

echo "---------------------------------------------------------------------------"
echo "as expected: $pass    mismatched: $bad"
[ "$bad" -eq 0 ] || { echo "FAIL"; exit 1; }
echo "ALL SCENARIOS BEHAVED AS EXPECTED"
