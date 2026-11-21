#!/usr/bin/env python3
"""Static sanity check for an MStar/TCL USB upgrade .bin before it is flashed.

The device gives no error channel: a bad package looks exactly like a missing
one (no progress bar, straight to boot).  So every check that can be done on
the host must be done here, before the user walks to the TV.

Checks:
  1. footer: magic, crc32(header), constant tag, header[0:16] back-reference
  2. script terminator present, and no junk after it
  3. every filepartload offset+size stays inside the payload area
  4. the partition list is what the caller expects
  5. the set_config lines that decide wipe / watchdog behaviour
"""

import os
import sys
import zlib

HEADER = 0x4000
MAGIC = b"12345678"
TAG = 0xB74AABBA
TERM = "% <- this is end of script symbol"


def main(path):
    size = os.path.getsize(path)
    f = open(path, "rb")
    hdr = f.read(HEADER)
    f.seek(size - 32)
    foot = f.read(32)
    f.close()

    print("file      : %s" % path)
    print("size      : %d (0x%x)" % (size, size))
    print("payload   : %d (0x%x)  [0x%x .. 0x%x)" % (size - HEADER - 32,
                                                    size - HEADER - 32,
                                                    HEADER, size - 32))

    ok = True

    # 1. footer
    magic = foot[0:8]
    crc_stored = int.from_bytes(foot[8:12], "little")
    tag = int.from_bytes(foot[12:16], "little")
    back = foot[16:32]
    crc_calc = zlib.crc32(hdr) & 0xFFFFFFFF
    print("\n[footer]")
    print("  magic     : %r %s" % (magic, "OK" if magic == MAGIC else "*** BAD ***"))
    print("  crc32(hdr): stored 0x%08x  calc 0x%08x  %s"
          % (crc_stored, crc_calc, "OK" if crc_stored == crc_calc else "*** MISMATCH ***"))
    print("  tag       : 0x%08x %s" % (tag, "OK" if tag == TAG else "*** BAD ***"))
    print("  hdr[0:16] : %s" % ("OK" if back == hdr[0:16] else "*** MISMATCH ***"))
    ok &= magic == MAGIC and crc_stored == crc_calc and tag == TAG and back == hdr[0:16]

    # 2. script
    script = hdr.split(b"\x00", 1)[0].decode("latin-1")
    lines = [l.rstrip() for l in script.splitlines()]
    print("\n[script]  %d lines, %d bytes" % (len(lines), len(script)))
    hit = [i for i, l in enumerate(lines) if TERM in l]
    print("  terminator: %s" % ("line %d OK" % (hit[0] + 1) if hit else "*** MISSING ***"))
    if hit:
        # The 16 KiB script area is padded with 0xff (and sometimes 0x00) past
        # the terminator.  That is the format, not junk -- only real text counts.
        tail = [l for l in lines[hit[0] + 1:]
                if l.strip().strip("\xff\x00").strip()]
        print("  after term: %s" % ("clean (0xff padding)" if not tail
                                    else "*** %r ***" % tail[:3]))
        ok &= not tail
    ok &= bool(hit)

    # 3. payload bounds
    print("\n[payload layout]")
    total = 0
    bad = 0
    parts = []
    for i, l in enumerate(lines):
        if l.startswith("filepartload"):
            t = l.split()
            try:
                off = int(t[3], 16)
                ln = int(t[4], 16)
            except (IndexError, ValueError):
                print("  line %d: *** cannot parse: %r ***" % (i + 1, l))
                bad += 1
                continue
            end = off + ln
            good = HEADER <= off and end <= size - 32
            if not good:
                bad += 1
            total += ln
            print("  line %-4d off 0x%08x len 0x%08x end 0x%08x  %s"
                  % (i + 1, off, ln, end, "ok" if good else "*** OUT OF RANGE ***"))
    print("  summed lengths: 0x%x (%d)" % (total, total))
    if bad:
        print("  *** %d bad entries ***" % bad)
    ok &= bad == 0

    # 4. partition coverage
    print("\n[partitions erased]")
    erases = [l.split()[2] for l in lines
              if l.startswith("mmc erase.p")]
    print("  %s" % (", ".join(erases) if erases else "*** none ***"))

    # 5. decisive set_config lines
    print("\n[set_config]")
    for key in ("MstarUpgrade_complete", "WDT_ENABLE", "bootcmd", "recoverycmd"):
        found = [l for l in lines if l.startswith("setenv %s " % key)]
        if not found:
            print("  %-22s : (absent)" % key)
        for l in found:
            print("  %-22s : %s" % (key, l[:110]))
    print("  wipe trigger (MstarUpgrade_complete 1): %s"
          % ("*** PRESENT -> /data will be wiped ***"
             if any(l.strip() == "setenv MstarUpgrade_complete 1" for l in lines)
             else "absent -> /data kept"))

    print("\nRESULT: %s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
