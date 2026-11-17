#!/bin/bash
set -e
cd /home/emfox/Debian/m7642
rm -f .msg2.txt
git add -A
git commit -q -s -m "mstar: add USB2 UTMI PHY driver patch"
git log --oneline | head -3
git status --short
