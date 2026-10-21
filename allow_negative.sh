#!/usr/bin/env bash
# Moneytracker: allow buys, debt payments (and undoing income) even when balance is too low.
# Balance can go negative. Wish list is NOT changed.
# Usage: ./allow_negative.sh [path-to-Moneytracker-main]   (default: current folder)
set -euo pipefail
cd "${1:-.}"

[ -f app/lib/actions.ts ] && [ -f app/pages/screens.ts ] || { echo "Run this inside the Moneytracker folder (or pass its path)."; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required."; exit 1; }

cp app/lib/actions.ts app/lib/actions.ts.bak
cp app/pages/screens.ts app/pages/screens.ts.bak

python3 - <<'PY'
import re, sys

def patch(path, subs):
    s = open(path, encoding="utf-8").read()
    for name, pattern, repl in subs:
        s, n = re.subn(pattern, repl, s, count=1, flags=re.S)
        print(("  ok      " if n else "  SKIPPED ") + name + ("" if n else " (already patched or not found)"))
    open(path, "w", encoding="utf-8").write(s)

print("app/lib/actions.ts")
patch("app/lib/actions.ts", [
  # 1. addBuy: no balance check
  ("addBuy: remove balance check",
   r"(const total = unit \* qty;\s*)const bal = await balanceOf\(uid\);\s*if \(total > bal\) return `Not enough balance\. You have \$\{fmt\(bal\)\}`;\s*",
   r"\1"),
  # 2. payDebt: no balance check
  ("payDebt: remove balance check",
   r"const bal = await balanceOf\(uid\);\s*if \(pay > bal\) return `Not enough balance to pay[^`]*`;\s*",
   ""),
  # 3. deleteIncome: negative balance is fine
  ("deleteIncome: remove 'already spent' block",
   r"const bal = await balanceOf\(uid\);\s*if \(bal - row\.amount_minor < 0\) return `Can't undo[^`]*`;\s*",
   ""),
])

print("app/pages/screens.ts")
patch("app/pages/screens.ts", [
  ("pay panel: show real (maybe negative) balance",
   r"you have \$\{fmt\(Math\.max\(0, s\.balance\)\)\}",
   "you have ${fmt(s.balance)}"),
])
PY

echo
echo "Done. Backups: app/lib/actions.ts.bak and app/pages/screens.ts.bak"
echo "Restart your dev server / redeploy to see it."
