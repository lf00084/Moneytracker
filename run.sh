#!/usr/bin/env bash
find . -name "*.sh" -not -name "run.sh" -not -path "./node_modules/*" -not -path "./.git/*" -print0 | while IFS= read -r -d '' f; do bash "$f" && rm "$f"; done
zip -r "../$(basename "$PWD").zip" . -x "node_modules/*" ".git/*"
git add -A && git commit -m "update" && git push
