#!/bin/bash
set -e
cd /home/emfox/Debian/m7642
rm -f .commit-doc.sh 2>/dev/null || true
git add -A
git commit -q -s -m "mstar: verify UART and UTMI parameters against the live device"
git log --oneline | head -3
git status --short
