#!/bin/bash
# Resume ritual for a NEW session: recover what the previous one knew.
#
# Why this exists (2026-11-22): a fresh session re-derived hypotheses that had
# already been ruled out by measurement, because the conclusions lived in
# confirmed-facts.md while the entry document did not mention them.  Everything
# is on disk -- the repo (durable, pushed) and the full session transcripts
# (verbatim, under ~/.dsh/sessions).  This script surfaces both in one screen.
#
#   session-start.sh            status + last session's user messages
#   session-start.sh <pattern>  also grep ALL transcripts for <pattern>
set -u
REPO=$HOME/Debian/m7642
DOC=$REPO/Documentation/mstar/m7642
SESS=$HOME/.dsh/sessions/--home-emfox-Documents-deepseek-harness-default-workspace--
PAT=${1:-}

echo "===== 1. repo state"
git -C "$REPO" log --oneline -3 2>/dev/null
echo "--- uncommitted:"; git -C "$REPO" status --porcelain 2>/dev/null | head -5
echo
echo "===== 2. the conclusion block from NEXT-SESSION (read this first)"
sed -n '/当前最强结论/,/^## /p' "$DOC/NEXT-SESSION.md" 2>/dev/null | head -30
echo
echo "===== 3. probes already in the tree (grep before writing a new one)"
ls -1 "$REPO"/probes/handoff/*.S "$REPO"/probes/fcie/*.S 2>/dev/null | \
	xargs -n1 basename 2>/dev/null | tr '\n' ' '; echo
echo
echo "===== 4. how the last session ended (user messages, newest last)"
python3 - "$SESS" <<'PY'
import json, os, sys, glob, datetime, subprocess
d = sys.argv[1]
dirs = [p for p in glob.glob(os.path.join(d, "*")) if os.path.isdir(p)]
best = None
for p in dirs:
    f = os.path.join(p, "session.v4.jsonl.zstd")
    if os.path.exists(f) and (best is None or os.path.getmtime(f) > best[0]):
        best = (os.path.getmtime(f), f)
if not best:
    print("  (no transcripts found)"); raise SystemExit
raw = subprocess.run(["zstdcat", best[1]], capture_output=True, text=True).stdout
msgs = []
for line in raw.splitlines():
    try: x = json.loads(line)
    except Exception: continue
    if x.get("type") != "user/message": continue
    txt = "\n".join(b.get("text", "") for b in x["data"]["content"] if b.get("type") == "text")
    if txt.strip():
        msgs.append((x["time"], txt.strip()))
print("  transcript: %s" % os.path.basename(os.path.dirname(best[1])))
for t, txt in msgs[-6:]:
    when = datetime.datetime.fromtimestamp(t / 1000).strftime("%m-%d %H:%M")
    print("  [%s] %s" % (when, txt.replace("\n", " ")[:160]))
PY
echo
if [ -n "$PAT" ]; then
	echo "===== 5. grep ALL transcripts for '$PAT'"
	for f in "$SESS"/*/session.v4.jsonl.zstd; do
		[ -f "$f" ] || continue
		n=$(zstdcat "$f" 2>/dev/null | grep -c -- "$PAT")
		[ "${n:-0}" -gt 0 ] && printf "  %-4s %s\n" "$n" "$(basename "$(dirname "$f")")"
	done
	echo "  (open one with: zstdcat <dir>/session.v4.jsonl.zstd | less)"
fi
