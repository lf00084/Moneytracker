#!/usr/bin/env bash
# file22.sh - fix: edit close button (and menu) not working. Run from the Moneytracker project root.
set -e
f=app/client/app.js
[ -f "$f" ] || { echo "Run this inside the Moneytracker folder"; exit 1; }
if grep -q 'all(".nt-dd:not(\[hidden\])")' "$f"; then
  sed -i 's/all("\.nt-dd:not(\[hidden\])")\.forEach/[].slice.call(d.querySelectorAll(".nt-dd:not([hidden])")).forEach/' "$f"
  echo "fixed $f"
else
  echo "nothing to fix (already applied)"
fi
