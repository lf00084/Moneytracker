#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0")")"
self="$(basename "$0")"
for f in $(ls -1 *.sh 2>/dev/null | grep -vx "$self"); do
        bash "./$f"
        rm -f "./$f"
done
git add -A
git commit -m "update" || true
git push -u origin main
base="$(basename "$PWD")"
rm -f "../$base.zip"
git ls-files -co --exclude-standard | grep -vE '(^|/)(wrangler\.jsonc|\.dev\.vars)$' | sed "s|^|$base/|" | (cd .. && zip -q "$base.zip" -@)
