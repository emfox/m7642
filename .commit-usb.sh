#!/bin/bash
set -e
cd /home/emfox/Debian/m7642
git add -A
git commit -q -s -m "mstar: add EHCI split-register support and USB nodes"
git log --oneline | head -3
echo "=== status ==="; git status --short
echo "=== patches ==="; ls patches/
