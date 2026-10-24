#!/usr/bin/env bash
set -e
cd "${1:-.}"
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder: bash file11.sh"; exit 1; fi
bk(){ for f in "$@"; do if [ -f "$f" ]; then mkdir -p ".mt_backup/file11/$(dirname "$f")"; [ -e ".mt_backup/file11/$f" ] || cp "$f" ".mt_backup/file11/$f"; fi; done; }
bk app/lib/exoclick.ts app/lib/data.ts app/components/income.tsx
cat > scripts/exo-reset.ts << '__EOF_MT__'
import { createClient } from "@libsql/client"

const url = process.env.TURSO_DATABASE_URL
const authToken = process.env.TURSO_AUTH_TOKEN
if (!url) throw new Error("TURSO_DATABASE_URL is not set (put it in .dev.vars)")
const yes = process.argv.includes("--yes")
const client = createClient({ url, authToken })
const fmtDay = new Intl.DateTimeFormat("en-CA", { timeZone: "Africa/Casablanca", year: "numeric", month: "2-digit", day: "2-digit" })
const exoDay = fmtDay.format(Date.now() - 5 * 3600000)
const before = new Date(`${exoDay}T12:00:00Z`)
before.setUTCDate(before.getUTCDate() - 1)
const checked = before.toISOString().slice(0, 10)
const sources = await client.execute("SELECT id, name, config FROM income_sources WHERE type = 'exoclick'")
if (!sources.rows.length) console.log("No ExoClick source found.")
for (const s of sources.rows) {
const rows = await client.execute({ sql: "SELECT day, usd_minor, amount_minor FROM incomes WHERE source_id = ? ORDER BY day", args: [String(s.id)] })
const total = rows.rows.reduce((a, r) => a + Number(r.amount_minor || 0), 0)
console.log(`${s.name}: ${rows.rows.length} rows, ${(total / 100).toFixed(2)} added to your balance`)
for (const r of rows.rows) console.log(`  ${r.day}  $${(Number(r.usd_minor || 0) / 100).toFixed(2)}  ->  ${(Number(r.amount_minor || 0) / 100).toFixed(2)}`)
if (!yes) continue
let cfg: Record<string, unknown> = {}
try {
cfg = JSON.parse(String(s.config || "{}"))
} catch {}
await client.execute({ sql: "DELETE FROM incomes WHERE source_id = ?", args: [String(s.id)] })
await client.execute({ sql: "UPDATE income_sources SET config = ? WHERE id = ?", args: [JSON.stringify({ ...cfg, checked }), String(s.id)] })
console.log(`  removed. ExoClick will start fresh from ${exoDay}.`)
}
if (!yes) console.log("\nNothing changed. Run again with --yes to remove these rows and take the money out of your balance.")
client.close()
__EOF_MT__
cat > .mt_patch11.cjs << '__EOF_MT__'
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
  if (s.includes("export const exoDay")) return s;
  s = swap(s, 'import { addDays, dayOf, today } from "./time.ts"', 'import { addDays, dayOf } from "./time.ts"');
  s = swap(s, 'const BASE = "https://api.exoclick.com/v2"\n', 'const BASE = "https://api.exoclick.com/v2"\nconst EVERY = 4 * 60000\nconst RESET_HOUR = 5\nexport const exoDay = (ms: number) => dayOf(ms - RESET_HOUR * 3600000)\n');
  s = swap(s, "now - (Number(todayRow.meta.fetched_at) || 0) > 45000", "now - (Number(todayRow.meta.fetched_at) || 0) > EVERY");
  s = swap(s, "(lastTry.get(s.id) ?? 0) + 20000 > now", "(lastTry.get(s.id) ?? 0) + 60000 > now");
  s = swap(s, "const t = today()\nconst now = Date.now()\n", "const now = Date.now()\nconst t = exoDay(now)\n");
  if (s === null) return null;
  return s.replace(/\s*$/, "\n") +
"\nexport async function liveExo(uid: string, ids: string[], rate: number): Promise<Record<string, { day: string; usd: number; mad: number }>> {\n" +
"const out: Record<string, { day: string; usd: number; mad: number }> = {}\n" +
"if (!ids.length) return out\n" +
"const day = exoDay(Date.now())\n" +
"for (const id of ids) {\n" +
"const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(id, day) } })\n" +
"const usd = row?.usd_minor || 0\n" +
"out[id] = { day, usd, mad: Math.round((usd * rate) / 100) }\n" +
"}\n" +
"return out\n" +
"}\n";
});
edit("app/lib/data.ts", (s) => {
  if (s.includes("liveExo(uid")) return s;
  s = swap(s, 'import { exoStatus, settleExo } from "./exoclick.ts";', 'import { exoStatus, liveExo, settleExo } from "./exoclick.ts";');
  if (s === null) return null;
  const head = "db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {\n";
  const a = s.indexOf(head);
  if (a < 0) return null;
  const endMark = "\n}),\n";
  const b = s.indexOf(endMark, a);
  if (b < 0) return null;
  const add =
"Promise.all([\n" +
"db.findMany(incomes, { where: { user_id: uid, day: t } }),\n" +
"liveExo(uid, sourceRows.filter((x) => x.type === \"exoclick\" && x.active).map((x) => x.id), user.usd_rate_minor),\n" +
"]).then(([rows, live]) => {\n" +
"const exo = new Set(sourceRows.filter((x) => x.type === \"exoclick\").map((x) => x.id));\n" +
"s.incomesToday = rows.filter((r) => !(r.source_id && exo.has(r.source_id))).map(toIncome);\n" +
"for (const x of sourceRows) {\n" +
"const v = live[x.id];\n" +
"if (!v) continue;\n" +
"s.exoToday[x.id] = v.usd;\n" +
"s.incomesToday.push({ id: `exo-${x.id}`, sourceId: x.id, source: x.name, amount: v.mad, day: v.day, hours: 0, locked: true });\n" +
"}\n" +
"}),\n";
  return s.slice(0, a) + add + s.slice(b + endMark.length);
});
edit("app/components/income.tsx", (s) => {
  if (s.includes("} today`;")) return s;
  const a = s.indexOf("const exoSub = ");
  const b = s.indexOf("const Hid = ");
  if (a < 0 || b < 0) return null;
  s = s.slice(0, a) + 'const exoSub = (s: State, x: Source) => s.exo[x.id] || `${usdTxt(s.exoToday[x.id] ?? 0)} today`;\n\n' + s.slice(b);
  const p1 = /const usd = s\.exoToday\[x\.id\](?: \?\? 0)?;\n\t\treturn \(/;
  const p2 = /\{usd !== undefined \? <b class="ea">\{usdTxt\(usd\)\}<\/b> : null\}|<b class="ea">\{usdTxt\(usd\)\}<\/b>/;
  if (!p1.test(s) || !p2.test(s)) return null;
  return s.replace(p1, "return (").replace(p2, '<b class="ea">+{fmt(sum)}</b>');
});
if (failed) { console.error(`\n${failed} patch problem(s). Backups are in .mt_backup/file11`); process.exit(1); }
console.log("patches applied");
__EOF_MT__
node .mt_patch11.cjs
rm -f .mt_patch11.cjs
echo "file11 done. Backups: .mt_backup/file11"
echo "To take the old ExoClick money out of your balance:"
echo "  bun --env-file=.dev.vars scripts/exo-reset.ts          (only shows what it would remove)"
echo "  bun --env-file=.dev.vars scripts/exo-reset.ts --yes    (removes it)"
