#!/usr/bin/env bash
set -e
cd "${1:-.}"
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder: bash file10.sh"; exit 1; fi
bk(){ for f in "$@"; do if [ -f "$f" ]; then mkdir -p ".mt_backup/file10/$(dirname "$f")"; [ -e ".mt_backup/file10/$f" ] || cp "$f" ".mt_backup/file10/$f"; fi; done; }
bk app/lib/data.ts app/components/income.tsx
cat > .mt_patch10.cjs << '__EOF_MT__'
const fs = require("fs");
let failed = 0;
function edit(file, fn) {
  const s = fs.readFileSync(file, "utf8");
  const r = fn(s);
  if (r === null) { console.error("patch problem in " + file); failed++; return; }
  if (r !== s) fs.writeFileSync(file, r);
}
function swap(s, old, add) {
  if (!s.includes(old)) return null;
  return s.replace(old, () => add);
}
edit("app/lib/data.ts", (s) => {
  if (s.includes("const live = rows.filter")) return s;
  return swap(
    s,
    "const mapped = rows.map(toIncome);\ns.incomesToday = mapped.filter((i) => !i.live);\nfor (const i of mapped) if (i.sourceId && (i.live || i.usd)) s.exoToday[i.sourceId] = i.usd;\n",
    "const exo = new Set(sourceRows.filter((x) => x.type === \"exoclick\").map((x) => x.id));\nconst live = rows.filter((r) => r.source_id && exo.has(r.source_id));\nfor (const r of live) s.exoToday[r.source_id!] = r.usd_minor || 0;\ns.incomesToday = rows.filter((r) => !live.includes(r)).map(toIncome);\n",
  );
});
edit("app/components/income.tsx", (s) => {
  if (s.includes('|| "earned today"')) return s;
  const a = s.indexOf("const exoSub = ");
  const b = s.indexOf("const Hid = ");
  if (a < 0 || b < 0) return null;
  s = s.slice(0, a) + 'const exoSub = (s: State, x: Source) => s.exo[x.id] || "earned today";\n\n' + s.slice(b);
  s = swap(s, "const usd = s.exoToday[x.id];\n\t\treturn (", "const usd = s.exoToday[x.id] ?? 0;\n\t\treturn (");
  if (s === null) return null;
  return swap(s, '{usd !== undefined ? <b class="ea">{usdTxt(usd)}</b> : null}', '<b class="ea">{usdTxt(usd)}</b>');
});
if (failed) { console.error(`\n${failed} patch problem(s). Backups are in .mt_backup/file10`); process.exit(1); }
console.log("patches applied");
__EOF_MT__
node .mt_patch10.cjs
rm -f .mt_patch10.cjs
echo "file10 done. Backups: .mt_backup/file10"
