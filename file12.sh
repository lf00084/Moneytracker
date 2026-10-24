#!/usr/bin/env bash
set -e
cd "${1:-.}"
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder: bash file12.sh"; exit 1; fi
bk(){ for f in "$@"; do if [ -f "$f" ]; then mkdir -p ".mt_backup/file12/$(dirname "$f")"; [ -e ".mt_backup/file12/$f" ] || cp "$f" ".mt_backup/file12/$f"; fi; done; }
bk app/client/app.js app/components/income.tsx app/lib/exoclick.ts
cat > .mt_patch12.cjs << '__EOF_MT__'
const fs = require("fs");
let failed = 0;
function edit(file, fn) {
  const s = fs.readFileSync(file, "utf8");
  const r = fn(s);
  if (r === null) { console.error("patch problem in " + file); failed++; return; }
  if (r !== s) fs.writeFileSync(file, r);
}
function swap(s, old, add) {
  if (s === null || !s.includes(old)) return null;
  return s.replace(old, () => add);
}
edit("app/lib/exoclick.ts", (s) => {
  if (s.includes("+ EVERY > now")) return s;
  return swap(s, "(lastTry.get(s.id) ?? 0) + 60000 > now", "(lastTry.get(s.id) ?? 0) + EVERY > now");
});
edit("app/components/income.tsx", (s) => {
  if (s.includes("data-exo")) return s;
  s = swap(s, '\t\t<div class="sw">\n', '\t\t<div class="sw" data-exo={x.type === "exoclick" ? "1" : undefined}>\n');
  return swap(s, '\t\t<div class="dbw">\n', '\t\t<div class="dbw" data-exo={x.type === "exoclick" ? "1" : undefined}>\n');
});
edit("app/client/app.js", (s) => {
  if (s.includes("exoTick")) return s;
  s = swap(s, "requestAnimationFrame(function(){queued=0;init()});", "requestAnimationFrame(function(){queued=0;init();syncBal()});");
  const add =
"var EXO_MS=240000,exoAt=Date.now(),rb=false;\n" +
"try{rb=sessionStorage.getItem('mt:rb')==='1';sessionStorage.removeItem('mt:rb')}catch(e){}\n" +
"function syncBal(){\n" +
"  if(rb&&all('[data-eye]').length){rb=false;all('[data-eye]').forEach(function(q){q.setAttribute('data-s','1')})}\n" +
"  all('[data-eye][data-s=\"1\"]').forEach(function(q){\n" +
"    var v=q.parentNode.firstChild,b=v.getAttribute('data-bal');\n" +
"    if(v.getAttribute('data-sh')===b)return;\n" +
"    v.setAttribute('data-sh',b);\n" +
"    v.innerHTML=b+' <small>'+v.getAttribute('data-cur')+'</small>';\n" +
"  });\n" +
"}\n" +
"function exoTick(){\n" +
"  if(!d.querySelector('[data-exo]')||d.hidden||Date.now()-exoAt<EXO_MS)return;\n" +
"  var a=d.activeElement;\n" +
"  if(a&&a.matches&&a.matches('input,textarea,select'))return;\n" +
"  if(d.querySelector('[data-adp]:not([hidden]),[data-addp]:not([hidden]),[data-pnl]:not([hidden])'))return;\n" +
"  try{if(d.querySelector('[data-eye][data-s=\"1\"]'))sessionStorage.setItem('mt:rb','1')}catch(e){}\n" +
"  location.reload();\n" +
"}\n" +
"setInterval(exoTick,30000);\n" +
"d.addEventListener('visibilitychange',exoTick);\n" +
"function settle(){exoAt=Date.now();init();syncBal();tails();unbusy()}";
  return swap(s, "function settle(){init();tails();unbusy()}", add);
});
if (failed) { console.error(`\n${failed} patch problem(s). Backups are in .mt_backup/file12`); process.exit(1); }
console.log("patches applied");
__EOF_MT__
node .mt_patch12.cjs
rm -f .mt_patch12.cjs
echo "file12 done. Backups: .mt_backup/file12"
