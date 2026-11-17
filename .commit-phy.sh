#!/bin/bash
set -e
cd /home/emfox/Debian/m7642
git add -A
git commit -q -s -m "mstar: record which UTMI PHY branches are live on m7642"
git log --oneline | head -3
git status --short
