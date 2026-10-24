import { sql } from "remix/data-table";
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { settleAuto } from "./auto.ts";
import type { TradeSession } from "./trade-math.ts";
import { loadTrades } from "./trading.ts";
import { parseJson, type Json } from "./sources/index.ts";
import { addDays, dayLabel, today } from "./time.ts";
import { getActiveAvatar, type User } from "./users.ts";
import { exoStatus, settleExo } from "./exoclick.ts";
const settleAll = async (uid: string) => void (await Promise.all([settleAuto(uid), settleExo(uid)]));
export type Quick = { id: string; name: string; icon: string; price: number };
export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number };
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; hours: number; locked: boolean };
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number };
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number };
export type GoalItem = { id: string; name: string; price: number; done: boolean };
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] };
export type Note = { id: string; body: string; at: number; edited: boolean };
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] };
export type Part = "quick" | "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar" | "names" | "trading";
export type State = {
user: User;
back: string;
error: string;
avatar: string | null;
quick: Quick[];
names: string[];
incNames: string[];
exo: Record<string, string>;
exoToday: Record<string, number>;
incomeNames: string[];
trades: TradeSession[];
buys: Buy[];
incomesToday: Income[];
sources: Source[];
debts: DebtView[];
goals: Goal[];
notes: Note[];
days: DayRow[];
balance: number;
};
const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []));
const scalar = (r: unknown) => {
const row = rowsOf(r)[0];
return Number(row?.s ?? row?.[0] ?? 0) || 0;
};
export async function balanceOf(uid: string): Promise<number> {
await settleAll(uid);
const [i, p] = await Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]);
return scalar(i) - scalar(p);
}
export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
const need = new Set(parts);
const uid = user.id;
const t = today();
const s: State = {
user,
back: extra.back,
error: extra.error ?? "",
avatar: null,
quick: [],
names: [],
incNames: [],
exo: {},
exoToday: {},
incomeNames: [],
trades: [],
buys: [],
incomesToday: [],
sources: [],
debts: [],
goals: [],
notes: [],
days: [],
balance: 0,
};
if (need.has("today") || need.has("sources") || need.has("history") || need.has("balance")) await settleAll(uid);
const jobs: Promise<void>[] = [];
if (need.has("avatar")) jobs.push(getActiveAvatar(uid).then((a) => void (s.avatar = a)));
if (need.has("quick"))
jobs.push(
db.findMany(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "asc"] }).then((rows) => {
s.quick = rows.map((r) => ({ id: r.id, name: r.name, icon: r.icon, price: r.price_minor }));
}),
);
const needSources = need.has("sources") || need.has("today") || need.has("history");
let sourceRows: Source[] = [];
if (needSources) {
const rows = await db.findMany(incomeSources, { where: { user_id: uid }, orderBy: ["created_at", "asc"] });
sourceRows = rows
.map((r) => ({
id: r.id,
name: r.name,
mode: r.mode,
every: r.every ?? "",
amount: r.amount_minor,
created: r.created_at,
type: r.type || "manual",
config: parseJson(r.config),
currency: r.currency || "MAD",
active: r.active !== 0,
sort: r.sort ?? 0,
}))
.sort((a, b) => a.sort - b.sort);
s.sources = sourceRows;
jobs.push(exoStatus(sourceRows).then((e) => void (s.exo = e)));
}
const byId = new Map(sourceRows.map((x) => [x.id, x.name]));
const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string; meta: string }): Income => {
const m = parseJson(r.meta);
return {
id: r.id,
sourceId: r.source_id ?? "",
source: byId.get(r.source_id ?? "") ?? (String(m.name ?? "").trim() || "Other"),
amount: r.amount_minor,
day: r.day,
hours: Number(m.hours) || 0,
locked: !!m.trade,
};
};
if (need.has("today")) {
jobs.push(
db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
s.buys = rows.map(toBuy);
}),
db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {
const mapped = rows.map(toIncome);
s.incomesToday = mapped.filter((i) => !i.live);
for (const i of mapped) if (i.sourceId && (i.live || i.usd)) s.exoToday[i.sourceId] = i.usd;
}),
);
}
if (need.has("names"))
jobs.push(
db
.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null and name not like 'Deposit % USDT' group by lower(name) order by c desc, max(created_at) desc`)
.then((r) => void (s.names = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
db
.exec(sql`select min(json_extract(meta, '$.name')) as n, count(*) as c from incomes where user_id = ${uid} and source_id is null and ext_key = '' and coalesce(json_extract(meta, '$.name'), '') <> '' group by lower(json_extract(meta, '$.name')) order by c desc, max(created_at) desc limit 30`)
.then((r) => void (s.incomeNames = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
);
if (need.has("incnames"))
jobs.push(
db
.exec(sql`select min(json_extract(meta, '$.label')) as n, count(*) as c from incomes where user_id = ${uid} and json_extract(meta, '$.label') is not null and json_extract(meta, '$.label') <> '' group by lower(json_extract(meta, '$.label')) order by c desc, max(created_at) desc limit 12`)
.then((r) => void (s.incNames = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
);
if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));
if (need.has("trading")) jobs.push(loadTrades(uid).then((t) => void (s.trades = t)));
if (need.has("goals"))
jobs.push(
Promise.all([
db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
db.findMany(goalItems, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
]).then(([rows, its]) => {
s.goals = rows.map((g) => {
const items: GoalItem[] = its.filter((i) => i.goal_id === g.id).map((i) => ({ id: i.id, name: i.name, price: i.price_minor, done: !!i.done_at }));
const left = items.filter((i) => !i.done);
return { id: g.id, title: g.title, target: left.reduce((a, i) => a + i.price, 0), saved: g.saved_minor, done: items.length > 0 && left.length === 0, items };
});
}),
);
if (need.has("notes"))
jobs.push(
db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }));
}),
);
if (need.has("history")) {
jobs.push(
Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
]).then(([bs, is]) => {
s.days = Array.from({ length: 30 }, (_, i) => {
const day = addDays(t, -i);
const b = bs.filter((x) => x.day === day);
const inc = is.filter((x) => x.day === day && parseJson(x.meta).final !== 0);
return {
day,
label: dayLabel(day),
earned: inc.reduce((a, x) => a + x.amount_minor, 0),
bought: b.reduce((a, x) => a + x.total_minor, 0),
buys: b.map(toBuy),
incomes: inc.map(toIncome),
};
}).filter((d, i) => i === 0 || d.buys.length || d.incomes.length);
}),
);
}
if (need.has("balance"))
jobs.push(
Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]).then(([i, p]) => void (s.balance = scalar(i) - scalar(p))),
);
await Promise.all(jobs);
return s;
}
const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number }): Buy => ({
id: r.id,
name: r.name,
qty: r.qty,
unit: r.unit_minor,
total: r.total_minor,
day: r.day,
at: r.created_at,
});
async function loadDebts(uid: string): Promise<DebtView[]> {
const [pe, de, pay] = await Promise.all([
db.findMany(people, { where: { user_id: uid } }),
db.findMany(debts, { where: { user_id: uid } }),
db.findMany(debtPayments, { where: { user_id: uid } }),
]);
const names = new Map(pe.map((p) => [p.id, p.name]));
const paid = new Map<string, number>();
for (const p of pay) paid.set(p.debt_id, (paid.get(p.debt_id) ?? 0) + p.amount_minor);
return de
.map((d): DebtView => {
const kind = d.kind === "item" ? "item" : "money";
return {
id: d.id,
person: names.get(d.person_id) ?? "?",
kind,
item: d.item_name || "cig",
owed: kind === "item" ? (d.item_qty ?? 0) : d.amount_minor,
paid: paid.get(d.id) ?? 0,
};
})
.filter((d) => d.owed > 0)
.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1));
}
