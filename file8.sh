#!/usr/bin/env bash
set -e
cd "${1:-.}"
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder: bash file8.sh"; exit 1; fi
bk(){ for f in "$@"; do if [ -f "$f" ]; then mkdir -p ".mt_backup/file8/$(dirname "$f")"; [ -e ".mt_backup/file8/$f" ] || cp "$f" ".mt_backup/file8/$f"; fi; done; }
bk app/commands.ts app/routes.ts app/client/app.js
cat > .mt_patch8.cjs << '__EOF_MT__'
const fs = require("fs");
let failed = 0;
function edit(file, fn) {
  const s = fs.readFileSync(file, "utf8");
  const r = fn(s);
  if (r === null) { console.error("patch problem in " + file); failed++; return; }
  if (r !== s) fs.writeFileSync(file, r);
}
edit("app/commands.ts", (s) => {
  const line = '\tsetHours: { run: (u, f) => act.setHours(u.id, f), to: "/home" },\n';
  if (!s.includes(line)) return s.includes("inc.setHours") ? s : null;
  return s.replace(line, "");
});
edit("app/routes.ts", (s) => {
  const line = '\t\tsetHours: post("/income/hours"),\n';
  const n = s.split(line).length - 1;
  if (n === 0) return null;
  if (n === 1) return s;
  const i = s.lastIndexOf(line);
  return s.slice(0, i) + s.slice(i + line.length);
});
edit("app/client/app.js", (s) => {
  if (s.includes("data-sub")) return s;
  const old = "d.addEventListener('click',function(e){\n  var t=e.target,q;\n";
  if (!s.includes(old)) return null;
  const add = old +
"  if((q=t.closest('button[name][value]'))&&q.form){\n" +
"    var sh=q.form.querySelector('input[type=hidden][data-sub=\"'+q.name+'\"]');\n" +
"    if(!sh){sh=d.createElement('input');sh.type='hidden';sh.name=q.name;sh.setAttribute('data-sub',q.name);q.form.appendChild(sh)}\n" +
"    sh.value=q.value;\n" +
"  }\n";
  return s.replace(old, add);
});
if (failed) { console.error(`\n${failed} patch problem(s). Backups are in .mt_backup/file8`); process.exit(1); }
console.log("patches applied");
__EOF_MT__
node .mt_patch8.cjs
rm -f .mt_patch8.cjs
echo "file8 done. Backups: .mt_backup/file8"
