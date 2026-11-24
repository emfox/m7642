import os
H = os.path.expanduser("~/Debian/m7642/probes/handoff")

p = os.path.join(H, "build-postmmu.sh"); s = open(p).read()
if "COUNT_N" not in s:
    s = s.replace('DEFS="$DEFS -DSAVE_PA=$SAVE_PA $SYMDEFS"',
                  'DEFS="$DEFS -DSAVE_PA=$SAVE_PA -DCOUNT_N=${COUNT_N:-1} $SYMDEFS"')
    open(p, "w").write(s); print("build: COUNT_N 已接")

p = os.path.join(H, "mk-multi.sh"); s = open(p).read()
if "count)" not in s:
    s = s.replace('	readout) tgt=$(( TRAMP_AT + 0x600 )) ;;',
                  '	readout) tgt=$(( TRAMP_AT + 0x600 )) ;;\n\tcount)   tgt=$(( TRAMP_AT + 0x700 )) ;;')
    open(p, "w").write(s); print("mk-multi: count 入口已加")
