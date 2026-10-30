#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0")")"
self="$(basename "$0")"
for f in $(ls -1 *.sh 2>/dev/null | grep -vx "$self" | sort -V); do
	bash "./$f"
	rm -f "./$f"
done
git add -A
git commit -m "update" || true
git push -u origin main
