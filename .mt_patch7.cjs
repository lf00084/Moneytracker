const fs = require("fs");
let failed = 0;
function patch(file, pairs) {
  if (!fs.existsSync(file)) { console.error("missing file: " + file); failed++; return; }
  let s = fs.readFileSync(file, "utf8");
  const crlf = s.includes("\r\n");
  const fix = (x) => (crlf ? x.replace(/\r?\n/g, "\r\n") : x);
  for (const [a0, b0] of pairs) {
    const a = fix(a0), b = fix(b0);
    if (s.includes(b)) continue;
    const n = s.split(a).length - 1;
    if (n !== 1) { console.error(`${file}: expected 1 match, found ${n} for: ${a0.slice(0, 70)}`); failed++; continue; }
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(file, s);
}
patch("app/lib/sources/index.ts", [
  ['import { balance } from "./balance.ts"', 'import { balance } from "./balance.ts"\nimport { exoclick } from "./exoclick.ts"'],
  ["const registry: Record<string, SourceType> = { manual, job, balance }", 'const registry: Record<string, SourceType> = { manual, job, fixed: { ...job, key: "fixed", label: "Fixed + hours" }, balance, exoclick }'],
]);
patch("app/lib/view.ts", [
  ['export const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);', 'export const isFixed = (t: string) => t === "job" || t === "fixed";\nexport const srcAmount = (x: Source) => (isFixed(x.type) ? Number(x.config.fixed_minor) || 0 : x.amount);'],
]);
patch("app/db/tables.ts", [
  ["bg_url: c.varchar(2048),", "bg_url: c.varchar(2048),\nusd_rate_minor: c.integer(),"],
  ["ext_key: c.varchar(120),", "ext_key: c.varchar(120),\nusd_minor: c.integer(),"],
]);
patch("database/schema.sql", [
  ["bg_url        TEXT NOT NULL DEFAULT '',", "bg_url        TEXT NOT NULL DEFAULT '',\n  usd_rate_minor INTEGER NOT NULL DEFAULT 1000,"],
  ["ext_key       TEXT NOT NULL DEFAULT ''", "ext_key       TEXT NOT NULL DEFAULT '',\n  usd_minor     INTEGER NOT NULL DEFAULT 0"],
]);
patch("scripts/migrate.ts", [
  ['"ALTER TABLE incomes ADD COLUMN ext_key TEXT NOT NULL DEFAULT \'\'",', '"ALTER TABLE incomes ADD COLUMN ext_key TEXT NOT NULL DEFAULT \'\'",\n"ALTER TABLE incomes ADD COLUMN usd_minor INTEGER NOT NULL DEFAULT 0",\n"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",'],
]);
patch("app/lib/users.ts", [
  ["bg_url: string;", "bg_url: string;\n\tusd_rate_minor: number;"],
  ['bg_url: r.bg_url ?? "",', 'bg_url: r.bg_url ?? "",\n\tusd_rate_minor: r.usd_rate_minor || 1000,'],
  ["input: { currency: string; run_at: string; week_start: string }", "input: { currency: string; run_at: string; week_start: string; usd_rate?: string }"],
  ['week_start: input.week_start.trim().slice(0, 16) || "Monday",', 'week_start: input.week_start.trim().slice(0, 16) || "Monday",\n\t\t...(Number(String(input.usd_rate ?? "").replace(",", ".")) > 0 ? { usd_rate_minor: Math.round(Number(String(input.usd_rate).replace(",", ".")) * 100) } : {}),'],
]);
patch("app/commands.ts", [
  ['import * as act from "./lib/actions.ts";', 'import * as act from "./lib/actions.ts";\nimport * as inc from "./lib/income.ts";'],
  ["addSource: { run: (u, f) => act.addSource(u.id, f), to: \"/income\" },", "addSource: { run: (u, f) => inc.addSource(u.id, f), to: \"/income\" },\n\tsetHours: { run: (u, f) => inc.setHours(u.id, f), to: \"/home\" },\n\taddNamed: { run: (u, f) => inc.addNamed(u.id, f), to: \"/home\" },"],
  ["editSource: { run: (u, f) => act.editSource(u.id, f), to: \"/income\" },", "editSource: { run: (u, f) => inc.editSource(u.id, f), to: \"/income\" },"],
  ['week_start: text(f, "week") }', 'week_start: text(f, "week"), usd_rate: text(f, "usd_rate") }'],
]);
patch("app/routes.ts", [
  ['addIncome: post("/income/add"),', 'addIncome: post("/income/add"),\n\t\tsetHours: post("/income/hours"),\n\t\taddNamed: post("/income/named"),'],
]);
patch("app/loaders/index.ts", [
  ['parts: ["today", "sources", "names",', 'parts: ["today", "sources", "names", "incnames",'],
  ['first: ["today", "sources", "names",', 'first: ["today", "sources", "names", "incnames",'],
]);
patch("app/components/profile.tsx", [
  ['<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />', '<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />\n\t\t<Field label="1 USD in MAD (ExoClick)" value={plain(s.user.usd_rate_minor)} name="usd_rate" />'],
]);
patch("app/lib/data.ts", [
  ['import { getActiveAvatar, type User } from "./users.ts";', 'import { getActiveAvatar, type User } from "./users.ts";\nimport { exoStatus, settleExo } from "./exoclick.ts";\nconst settleAll = async (uid: string) => void (await Promise.all([settleAuto(uid), settleExo(uid)]));'],
  ["export type Income = { id: string; sourceId: string; source: string; amount: number; day: string };", "export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; usd: number; hours: number; live: boolean };"],
  ['| "balance" | "avatar" | "names";', '| "balance" | "avatar" | "names" | "incnames";'],
  ["names: string[];", "names: string[];\nincNames: string[];\nexo: Record<string, string>;\nexoToday: Record<string, number>;"],
  ["names: [],", "names: [],\nincNames: [],\nexo: {},\nexoToday: {},"],
  ["await settleAuto(uid);\nconst [i, p] = await Promise.all([", "await settleAll(uid);\nconst [i, p] = await Promise.all(["],
  ['need.has("balance")) await settleAuto(uid);', 'need.has("balance")) await settleAll(uid);'],
  ["s.sources = sourceRows;", "s.sources = sourceRows;\njobs.push(exoStatus(sourceRows).then((e) => void (s.exo = e)));"],
  ["const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string }): Income => ({ id: r.id, sourceId: r.source_id ?? \"\", source: byId.get(r.source_id ?? \"\") ?? \"Other\", amount: r.amount_minor, day: r.day });",
   "const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string; usd_minor?: number; meta?: string }): Income => {\nconst m = parseJson(r.meta);\nconst live = m.final === 0;\nconst name = byId.get(r.source_id ?? \"\") ?? (String(m.label ?? \"\") || \"Other\");\nreturn { id: r.id, sourceId: r.source_id ?? \"\", source: live ? `${name} (pending)` : name, amount: r.amount_minor, day: r.day, usd: r.usd_minor ?? 0, hours: Number(m.hours) || 0, live };\n};"],
  ["s.incomesToday = rows.map(toIncome);", "const mapped = rows.map(toIncome);\ns.incomesToday = mapped.filter((i) => !i.live);\nfor (const i of mapped) if (i.sourceId && (i.live || i.usd)) s.exoToday[i.sourceId] = i.usd;"],
  ["const inc = is.filter((x) => x.day === day);", "const inc = is.filter((x) => x.day === day && parseJson(x.meta).final !== 0);"],
  ['if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));', 'if (need.has("incnames"))\njobs.push(\ndb\n.exec(sql`select min(json_extract(meta, \'$.label\')) as n, count(*) as c from incomes where user_id = ${uid} and json_extract(meta, \'$.label\') is not null and json_extract(meta, \'$.label\') <> \'\' group by lower(json_extract(meta, \'$.label\')) order by c desc, max(created_at) desc limit 12`)\n.then((r) => void (s.incNames = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),\n);\nif (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));'],
]);
patch("app/client/app.js", [
  ["if(t.closest('[data-theme-toggle]'))", "if((q=t.closest('[data-close]'))){var cd=q.closest('details');if(cd)cd.open=false;return}\n  if(t.closest('[data-theme-toggle]'))"],
  ["form.querySelector('[data-mode-input]').value=q.getAttribute('data-mode');", "form.querySelector('[data-mode-input]').value=q.getAttribute('data-mode');\n    form.setAttribute('data-kind',q.getAttribute('data-mode'));"],
]);
{
  const f = "app/client/app.css";
  const css = fs.readFileSync(".mt_file7.css", "utf8");
  const s = fs.readFileSync(f, "utf8");
  if (!s.includes("/*file7*/")) fs.writeFileSync(f, s.replace(/\s*$/, "\n") + css);
}
if (failed) { console.error(`\n${failed} patch problem(s). Files already patched are kept; nothing was deleted. Backups are in .mt_backup/file7`); process.exit(1); }
console.log("patches applied");
