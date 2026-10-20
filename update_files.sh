#!/usr/bin/env bash
set -e
cd "${1:-.}"
mkdir -p app/lib
cat > app/lib/actions.ts <<'__EOF_MT__'
import { sql } from "remix/data-table";

import { db, debtPayments, debts, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { balanceOf } from "./data.ts";
import { fmt, toMinor } from "./money.ts";
import { extKey, parseJson, typeOf } from "./sources/index.ts";
import { today } from "./time.ts";
import { updateBg } from "./users.ts";
import { ICON_KEYS } from "../ui/parts.ts";

const id = () => crypto.randomUUID();
const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max);
const count = (v: unknown) => {
const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")));
return Number.isFinite(n) && n > 0 ? Math.min(n, 100000) : 0;
};

// ---------- buys ----------

export async function addBuy(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("label"), 120) || "Item";
const qty = count(f.get("qty")) || 1;
const unit = toMinor(f.get("price"));
if (!unit) return "Enter a price";
const total = unit * qty;
const bal = await balanceOf(uid);
if (total > bal) return `Not enough balance. You have ${fmt(bal)}`;
await db.create(purchases, { id: id(), user_id: uid, name, qty, unit_minor: unit, total_minor: total, day: today(), created_at: Date.now() });
}

/** Undo a buy. If it was a debt payment, the debt comes back too. */
export async function deleteBuy(uid: string, f: FormData): Promise<string | void> {
const p = await db.findOne(purchases, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!p) return;
await db.transaction(async (tx) => {
if (p.debt_id) {
const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } });
const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor;
const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } });
if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back });
await tx.exec(sql`delete from debt_payments where purchase_id = ${p.id} and user_id = ${uid}`);
}
await tx.exec(sql`delete from purchases where id = ${p.id} and user_id = ${uid}`);
});
}

// ---------- debts ----------

/** Adds to a person already on the list (debt_id), or creates / revives a person by name. */
export async function addDebt(uid: string, f: FormData): Promise<string | void> {
const debtId = text(f.get("debt_id"), 36);
if (debtId) {
const d = await db.findOne(debts, { where: { id: debtId, user_id: uid } });
if (!d) return;
if (d.kind === "item") {
const n = count(f.get("amount"));
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n });
} else {
const m = toMinor(f.get("amount"));
if (!m) return "Enter an amount";
await db.update(debts, d.id, { amount_minor: d.amount_minor + m });
}
return;
}

const name = text(f.get("name"), 80);
const cig = count(f.get("cig"));
const money = toMinor(f.get("amount"));
if (!name) return "Enter a name";
if (!cig && !money) return "Enter an amount";

await db.transaction(async (tx) => {
const all = await tx.findMany(people, { where: { user_id: uid } });
let person = all.find((p) => p.name.toLowerCase() === name.toLowerCase());
if (!person) person = await tx.create(people, { id: id(), user_id: uid, name }, { returnRow: true });

const mine = await tx.findMany(debts, { where: { user_id: uid, person_id: person.id } });
if (money) {
const row = mine.find((d) => d.kind === "money");
if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money });
else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, created_at: Date.now() });
}
if (cig) {
const row = mine.find((d) => d.kind === "item");
if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig });
else
await tx.create(debts, {
id: id(),
user_id: uid,
person_id: person.id,
kind: "item",
item_name: "cig",
item_qty: cig,
amount_minor: 0,
created_at: Date.now(),
});
}
});
}

/** Money paid also becomes a buy today ("Paid Youssef"). Items just count down. */
export async function payDebt(uid: string, f: FormData): Promise<string | void> {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;

if (d.kind === "item") {
const n = Math.min(count(f.get("amount")), d.item_qty ?? 0);
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n });
return;
}

const pay = Math.min(toMinor(f.get("amount")), d.amount_minor);
if (!pay) return "Enter an amount";
const bal = await balanceOf(uid);
if (pay > bal) return `Not enough balance to pay ${fmt(pay)}. You have ${fmt(Math.max(0, bal))}`;
const person = await db.find(people, d.person_id);
const purchaseId = id();
const now = Date.now();

await db.transaction(async (tx) => {
await tx.create(purchases, {
id: purchaseId,
user_id: uid,
name: `Paid ${person?.name ?? ""}`.trim(),
qty: 1,
unit_minor: pay,
total_minor: pay,
day: today(),
debt_id: d.id,
created_at: now,
});
await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now });
await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay });
});
}

// ---------- goals ----------

export async function addGoal(uid: string, f: FormData): Promise<string | void> {
const title = text(f.get("name"), 120);
if (!title) return "Enter what you want";
await db.create(goals, {
id: id(),
user_id: uid,
title,
target_minor: toMinor(f.get("price")),
saved_minor: 0,
is_wish: 1,
created_at: Date.now(),
});
}

export async function buyWish(uid: string, f: FormData): Promise<string | void> {
const g = await db.findOne(goals, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!g) return;
const price = g.target_minor;
if (price > 0) {
const bal = await balanceOf(uid);
if (price > bal) return `Not enough balance for ${g.title}. You have ${fmt(Math.max(0, bal))}`;
}
await db.transaction(async (tx) => {
if (price > 0) await tx.create(purchases, { id: id(), user_id: uid, name: g.title, qty: 1, unit_minor: price, total_minor: price, day: today(), created_at: Date.now() });
await tx.exec(sql`delete from goals where id = ${g.id} and user_id = ${uid}`);
});
}

// ---------- income ----------

export async function addSource(uid: string, f: FormData) {
const name = text(f.get("name"), 80);
if (!name) return "Enter a name";
const kind = typeOf(text(f.get("type"), 16));
const config = kind.parseConfig(f);
if (typeof config === "string") return config;
const mode = text(f.get("mode"), 10);
const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(incomeSources, {
id: id(),
user_id: uid,
name,
mode: mode === "daily" || mode === "monthly" ? "auto" : "manual",
amount_minor: toMinor(f.get("amount")),
every: mode === "daily" ? "day" : mode === "monthly" ? "month" : "",
created_at: Date.now(),
type: kind.key,
config: JSON.stringify(config),
currency: text(f.get("currency"), 8).toUpperCase() || "MAD",
active: 1,
sort: (last?.sort ?? -1) + 1,
});
}

const realDay = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T12:00:00Z`)) && new Date(`${v}T12:00:00Z`).toISOString().slice(0, 10) === v;

/** Saves, updates or clears one day of one source. Job and manual sources keep one row per day, balance keeps one row per update. */
export async function saveDay(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = text(f.get("day"), 10) || today();
if (!realDay(day) || day > today()) return "Pick a day that is not in the future";
const kind = typeOf(s.type);
const key = extKey(s.id, day);

if (text(f.get("op"), 10) === "delete") {
const rowId = text(f.get("income_id"), 80);
if (rowId) await db.deleteMany(incomes, { where: { id: rowId, user_id: uid, source_id: s.id } });
else if (kind.keyed) await db.deleteMany(incomes, { where: { user_id: uid, ext_key: key } });
return;
}

let last: ReturnType<typeof parseJson> | null = null;
if (!kind.keyed) {
const rows = await db.findMany(incomes, { where: { user_id: uid, source_id: s.id }, orderBy: ["day", "desc"], limit: 200 });
const prev = rows.filter((r) => r.day <= day).sort((a, b) => (a.day === b.day ? b.created_at - a.created_at : a.day < b.day ? 1 : -1))[0];
last = prev ? parseJson(prev.meta) : null;
}

const entry = kind.entry({ config: parseJson(s.config), form: f, fallback: s.amount_minor, last });
if (typeof entry === "string") return entry;
const values = { amount_minor: entry.amount, meta: JSON.stringify(entry.meta) };

if (kind.keyed) {
const existing = await db.findOne(incomes, { where: { user_id: uid, ext_key: key } });
if (existing) {
await db.update(incomes, existing.id, values);
return;
}
}
await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, day, created_at: Date.now(), ext_key: kind.keyed ? key : "", ...values });
}

/** The "Add 120" button on a source. A manual or job source can be added once per day. */
export async function addIncome(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = today();
if (typeOf(s.type).keyed) {
const done = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, day) } });
if (done) return `${s.name} is already added today`;
}
f.set("day", day);
return saveDay(uid, f);
}

/** Undo an income row. Blocked if the money is already spent and the balance would go below zero. */
export async function deleteIncome(uid: string, f: FormData): Promise<string | void> {
const row = await db.findOne(incomes, { where: { id: text(f.get("id"), 80), user_id: uid } });
if (!row) return;
const bal = await balanceOf(uid);
if (bal - row.amount_minor < 0) return `Can't undo: you already spent it. Balance is ${fmt(Math.max(0, bal))}`;
await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } });
}

// ---------- quick buys ----------

export async function quickOp(uid: string, f: FormData) {
const op = text(f.get("op"), 10);
const qid = text(f.get("id"), 36);
const name = text(f.get("name"), 60);
const icon = ICON_KEYS.includes(String(f.get("icon"))) ? String(f.get("icon")) : "Tag";
const price = toMinor(f.get("price"));

if (op === "delete" && qid) {
await db.deleteMany(quickBuys, { where: { id: qid, user_id: uid } });
} else if (op === "save" && qid && name) {
await db.updateMany(quickBuys, { name, icon, price_minor: price }, { where: { id: qid, user_id: uid } });
} else if (op === "add" && name) {
const last = await db.findOne(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(quickBuys, { id: id(), user_id: uid, name, icon, price_minor: price, sort: (last?.sort ?? -1) + 1 });
}
}

// ---------- notes ----------

export async function saveNote(uid: string, f: FormData) {
const body = text(f.get("text"), 5000);
if (!body) return;
const noteId = text(f.get("id"), 36);
const now = Date.now();
if (noteId) await db.updateMany(notes, { body, updated_at: now }, { where: { id: noteId, user_id: uid } });
else await db.create(notes, { id: id(), user_id: uid, body, created_at: now, updated_at: now });
}

export async function deleteNote(uid: string, f: FormData) {
await db.deleteMany(notes, { where: { id: text(f.get("id"), 36), user_id: uid } });
}

// ---------- account ----------

/** Foreign keys are not relied on: every table is cleared by hand, children first. */
export async function deleteAccount(uid: string) {
await db.transaction(async (tx) => {
for (const stmt of [
sql`delete from debt_payments where user_id = ${uid}`,
sql`delete from debts where user_id = ${uid}`,
sql`delete from people where user_id = ${uid}`,
sql`delete from purchases where user_id = ${uid}`,
sql`delete from incomes where user_id = ${uid}`,
sql`delete from income_sources where user_id = ${uid}`,
sql`delete from goals where user_id = ${uid}`,
sql`delete from notes where user_id = ${uid}`,
sql`delete from quick_buys where user_id = ${uid}`,
sql`delete from user_images where user_id = ${uid}`,
sql`delete from oauth_accounts where user_id = ${uid}`,
sql`delete from passwords where user_id = ${uid}`,
sql`delete from sessions where user_id = ${uid}`,
sql`delete from users where id = ${uid}`,
])
await tx.exec(stmt);
});
}

// ---------- export ----------

const cell = (v: string | number) => {
let s = String(v);
if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`; // stops spreadsheet formulas
return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export async function exportCsv(uid: string) {
const [bs, is, ss] = await Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomeSources, { where: { user_id: uid } }),
]);
const names = new Map(ss.map((s) => [s.id, s.name]));
const lines = ["date,type,name,qty,amount"];
for (const i of is) lines.push([i.day, "income", cell(names.get(i.source_id ?? "") ?? "Other"), 1, fmt(i.amount_minor).replace(/,/g, "")].join(","));
for (const b of bs) lines.push([b.day, "buy", cell(b.name), b.qty, fmt(b.total_minor).replace(/,/g, "")].join(","));
return lines.join("\n");
}

// ---------- background ----------

export async function validateAndSetBackground(uid: string, rawUrl: string): Promise<string | null> {
	const trimmed = rawUrl.trim();
	if (!trimmed) return "Please enter an image URL.";

	let parsed: URL;
	try {
		parsed = new URL(trimmed);
	} catch {
		return "Invalid address.";
	}

	if (parsed.protocol !== "https:") {
		return "URL must use https.";
	}

	const host = parsed.hostname.toLowerCase();
	if (
		host === "localhost" ||
		host === "127.0.0.1" ||
		host === "::1" ||
		host === "0.0.0.0" ||
		host.endsWith(".local") ||
		host.endsWith(".internal") ||
		host.startsWith("10.") ||
		host.startsWith("192.168.") ||
		/^172\.(1[6-9]|2\d|3[01])\./.test(host) ||
		host.startsWith("169.254.")
	) {
		return "Invalid address.";
	}

	let res: Response;
	try {
		const controller = new AbortController();
		const timeoutId = setTimeout(() => controller.abort(), 6000);
		res = await fetch(parsed.toString(), {
			signal: controller.signal,
			headers: { "User-Agent": "Moneytracker/1.0" },
		});
		clearTimeout(timeoutId);
	} catch {
		return "Cannot download.";
	}

	if (!res.ok) {
		return "Cannot download.";
	}

	const cl = res.headers.get("content-length");
	if (cl && parseInt(cl, 10) > 5 * 1024 * 1024) {
		return "Too large.";
	}

	const ct = (res.headers.get("content-type") || "").toLowerCase().trim();
	if (!ct.startsWith("image/png") && !ct.startsWith("image/jpeg") && !ct.startsWith("image/jpg")) {
		return "Not a PNG or JPEG.";
	}

	let buffer: ArrayBuffer;
	try {
		buffer = await res.arrayBuffer();
	} catch {
		return "Cannot download.";
	}

	if (buffer.byteLength > 5 * 1024 * 1024) {
		return "Too large.";
	}

	if (buffer.byteLength < 8) {
		return "Not a PNG or JPEG.";
	}

	const bytes = new Uint8Array(buffer.slice(0, 8));
	const isPng = bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47;
	const isJpg = bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;

	if (!isPng && !isJpg) {
		return "Not a PNG or JPEG.";
	}

	await updateBg(uid, { mode: "url", url: trimmed });
	return null;
}

export async function resetUserBackground(uid: string) {
	await updateBg(uid, { mode: "auto", url: "" });
}
__EOF_MT__
echo updated app/lib/actions.ts
mkdir -p app/lib
cat > app/lib/data.ts <<'__EOF_MT__'
import { sql } from "remix/data-table";

import { db, debtPayments, debts, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { fmt } from "./money.ts";
import { parseJson, type Json } from "./sources/index.ts";
import { addDays, dayLabel, today } from "./time.ts";
import { getActiveAvatar, type User } from "./users.ts";

export type Quick = { id: string; name: string; icon: string; price: number };
export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number };
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string };
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number };
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number };
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean };
export type Note = { id: string; body: string; at: number; edited: boolean };
export type DayRow = { label: string; earned: number; bought: number; items: string[] };

export type Part = "quick" | "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar" | "names";

export type State = {
user: User;
back: string;
error: string;
avatar: string | null;
quick: Quick[];
names: string[];
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
const [i, p] = await Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]);
return scalar(i) - scalar(p);
}

/** Loads only the parts a page needs, in parallel. */
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
buys: [],
incomesToday: [],
sources: [],
debts: [],
goals: [],
notes: [],
days: [],
balance: 0,
};

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
}

if (need.has("today")) {
const byId = new Map(sourceRows.map((x) => [x.id, x.name]));
jobs.push(
db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
s.buys = rows.map(toBuy);
}),
db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {
s.incomesToday = rows.map((r) => ({ id: r.id, sourceId: r.source_id ?? "", source: byId.get(r.source_id ?? "") ?? "Other", amount: r.amount_minor, day: r.day }));
}),
);
}

if (need.has("names"))
jobs.push(
db
.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null group by lower(name) order by c desc, max(created_at) desc`)
.then((r) => void (s.names = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
);

if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));

if (need.has("goals"))
jobs.push(
db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }).then((rows) => {
s.goals = rows.map((g) => ({ id: g.id, title: g.title, target: g.target_minor, saved: g.saved_minor, done: !!g.done_at }));
}),
);

if (need.has("notes"))
jobs.push(
db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }));
}),
);

if (need.has("history")) {
const from = addDays(t, -6);
jobs.push(
Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 400 }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 400 }),
]).then(([bs, is]) => {
s.days = Array.from({ length: 7 }, (_, i) => {
const day = addDays(t, -i);
const b = bs.filter((x) => x.day === day && day >= from);
const inc = is.filter((x) => x.day === day);
return {
label: dayLabel(day),
earned: inc.reduce((a, x) => a + x.amount_minor, 0),
bought: b.reduce((a, x) => a + x.total_minor, 0),
items: b.map((x) => `${x.name}${x.qty > 1 ? ` ×${x.qty}` : ""} ${fmt(x.total_minor)}`),
};
});
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
.filter((d) => d.owed > 0) // paid-off people stay in the database but leave the list
.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1));
}
__EOF_MT__
echo updated app/lib/data.ts
mkdir -p app
cat > app/routes.ts <<'__EOF_MT__'
import { get, post, route } from "remix/routes";

export const routes = route({
	// Auth
	root: get("/"),
	login: get("/login"),
	signIn: post("/login"),
	signup: get("/signup"),
	signUp: post("/signup"),
	logout: post("/logout"),
	googleLogin: get("/login/google"),
	googleCallback: get("/auth/google/callback"),

	// Pages
	home: get("/home"),
	debts: get("/debts"),
	notes: get("/notes"),
	goals: get("/goals"),
	income: get("/income"),
	plan: get("/plan"),
	history: get("/history"),
	profile: get("/profile"),
	profileEdit: get("/profile/edit"),
	settings: get("/settings"),

	// Forms
	buy: post("/buy"),
	deleteBuy: post("/buy/delete"),
	addDebt: post("/debts"),
	payDebt: post("/debts/pay"),
	addNote: post("/notes"),
	deleteNote: post("/notes/delete"),
	addWish: post("/goals"),
	buyWish: post("/goals/buy"),
	addSource: post("/income"),
	addIncome: post("/income/add"),
	deleteIncome: post("/income/delete"),
	addPlan: post("/plan"),
	saveProfile: post("/profile/edit"),
	saveSettings: post("/settings"),
	quickBuy: post("/settings/quick"),
	setTheme: post("/settings/theme"),
	setBackground: post("/settings/background"),
	resetBackground: post("/settings/background/reset"),

	// Account
	exportCsv: get("/export.csv"),
	deleteAccount: post("/account/delete"),
});
__EOF_MT__
echo updated app/routes.ts
mkdir -p app/actions
cat > app/actions/controller.tsx <<'__EOF_MT__'
import { completeAuth, finishExternalAuth, startExternalAuth } from "remix/auth";
import { Auth } from "remix/middleware/auth";
import { createController } from "remix/router";
import { Session } from "remix/session";

import * as act from "../lib/actions.ts";
import { googleProvider } from "../lib/auth.ts";
import { env } from "../env.ts";
import { loadState, type Part, type State } from "../lib/data.ts";
import {
	setTheme,
	signInWithPassword,
	signUpWithPassword,
	updatePrefs,
	updateProfile,
	upsertFromGoogle,
	type User,
} from "../lib/users.ts";
import { loginPage, signupPage } from "../pages/auth.ts";
import {
	debtsPage,
	goalsPage,
	historyPage,
	homePage,
	incomePage,
	notesPage,
	profileEditPage,
	profilePage,
	settingsPage,
} from "../pages/screens.ts";
import { routes } from "../routes.ts";

const html = (body: string) => new Response(body, { headers: { "Content-Type": "text/html; charset=utf-8" } });
const go = (href: string) => new Response(null, { status: 303, headers: { Location: href } });

type Ctx = Parameters<typeof completeAuth>[0] & { get: (key: any) => any };

const userOf = (ctx: Ctx): User | null => {
	const a = ctx.get(Auth);
	return a?.ok ? (a.identity as User) : null;
};

const formOf = (ctx: Ctx) => (ctx.get(FormData) as FormData | null) ?? new FormData();

/** Only local paths are allowed, so a form cannot send you to another site. */
const backTo = (f: FormData, fallback: string) => {
	const b = String(f.get("back") ?? "");
	return /^\/(?![/\\])/.test(b) ? b : fallback;
};

function takeError(ctx: Ctx) {
	const session = ctx.get(Session);
	const e = session.get("error");
	return typeof e === "string" ? e : "";
}

/** A page that reads from the database. Anyone not signed in goes to /login. */
const view =
	(path: string, parts: Part[], render: (s: State) => string) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		return html(render(await loadState(user, parts, { back: path, error: takeError(ctx) })));
	};

/** A form that changes data for the signed-in user, then returns to `fallback` (or the form's `back`). */
const mutate =
	(fallback: string, run: (user: User, f: FormData, ctx: Ctx) => Promise<unknown>) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		const f = formOf(ctx);
		await run(user, f, ctx);
		return go(backTo(f, fallback));
	};

const attempt =
	(fallback: string, run: (user: User, f: FormData) => Promise<string | void>) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		const f = formOf(ctx);
		const to = backTo(f, fallback);
		const error = await run(user, f);
		return error ? fail(ctx, to, error) : go(to);
	};

function fail(ctx: Ctx, to: string, message: string) {
	ctx.get(Session).flash("error", message);
	return go(to);
}

function signInAs(ctx: Ctx, userId: string) {
	const session = completeAuth(ctx); // rotates the session id first, so a stolen old id is useless
	session.set("auth", { userId });
}

export default createController(routes, {
	actions: {
		root(ctx: Ctx) {
			return go(userOf(ctx) ? "/home" : "/login");
		},

		// ---------- email + password ----------
		login(ctx: Ctx) {
			if (userOf(ctx)) return go("/home");
			return html(loginPage(takeError(ctx)));
		},
		async signIn(ctx: Ctx) {
			const f = formOf(ctx);
			const user = await signInWithPassword(String(f.get("email") ?? ""), String(f.get("password") ?? ""));
			if (!user) return fail(ctx, "/login", "Wrong email or password.");
			signInAs(ctx, user.id);
			return go("/home");
		},
		signup(ctx: Ctx) {
			if (userOf(ctx)) return go("/home");
			return html(signupPage(takeError(ctx)));
		},
		async signUp(ctx: Ctx) {
			const f = formOf(ctx);
			const result = await signUpWithPassword({
				name: String(f.get("name") ?? ""),
				email: String(f.get("email") ?? ""),
				password: String(f.get("password") ?? ""),
			});
			if (!result.ok) return fail(ctx, "/signup", result.error);
			signInAs(ctx, result.user.id);
			return go("/home");
		},
		logout(ctx: Ctx) {
			const session = ctx.get(Session);
			session.unset("auth");
			session.regenerateId(true); // true deletes the old row from the sessions table
			return go("/login");
		},

		// ---------- google ----------
		googleLogin(ctx: Ctx) {
			if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
				return fail(ctx, "/login", "Google login is not configured. Please sign in with email and password.");
			}
			return startExternalAuth(googleProvider, ctx as never, { returnTo: "/home" });
		},
		async googleCallback(ctx: Ctx) {
			try {
				const { result, returnTo } = await finishExternalAuth(googleProvider, ctx as never);
				const user = await upsertFromGoogle(result.account, result.profile as never);
				signInAs(ctx, user.id);
				return go(returnTo ?? "/home");
			} catch (err) {
				console.error("google sign-in failed", err);
				return fail(ctx, "/login", "Google sign-in failed. Try again.");
			}
		},

		// ---------- pages ----------
		home: view("/home", ["today", "sources", "names", "debts", "goals", "notes", "balance"], homePage),
		debts: view("/debts", ["debts", "goals", "balance"], debtsPage),
		notes: view("/notes", ["notes"], notesPage),
		goals: view("/goals", ["goals", "debts", "balance"], goalsPage),
		income: view("/income", ["sources", "today"], incomePage),
		plan: view("/plan", ["goals", "debts", "sources", "today", "balance"], goalsPage),
		history: view("/history", ["history"], historyPage),
		profile: view("/profile", ["avatar", "balance"], profilePage),
		profileEdit: view("/profile/edit", ["avatar"], profileEditPage),
		settings: view("/settings", [], settingsPage),

		// ---------- forms ----------
		buy: attempt("/home", (u, f) => act.addBuy(u.id, f)),
		deleteBuy: attempt("/home", (u, f) => act.deleteBuy(u.id, f)),
		addDebt: attempt("/debts", (u, f) => act.addDebt(u.id, f)),
		payDebt: attempt("/debts", (u, f) => act.payDebt(u.id, f)),
		addNote: mutate("/notes", (u, f) => act.saveNote(u.id, f)),
		deleteNote: mutate("/notes", (u, f) => act.deleteNote(u.id, f)),
		addWish: attempt("/goals", (u, f) => act.addGoal(u.id, f)),
		buyWish: attempt("/goals", (u, f) => act.buyWish(u.id, f)),
		addSource: attempt("/income", (u, f) => act.addSource(u.id, f)),
		addIncome: attempt("/income", (u, f) => act.addIncome(u.id, f)),
		deleteIncome: attempt("/income", (u, f) => act.deleteIncome(u.id, f)),
		addPlan: mutate("/plan", async () => {}),
		quickBuy: mutate("/settings", (u, f) => act.quickOp(u.id, f)),

		async saveProfile(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			const f = formOf(ctx);
			const error = await updateProfile(user.id, {
				name: String(f.get("name") ?? ""),
				email: String(f.get("email") ?? ""),
				phone: String(f.get("phone") ?? ""),
				bio: String(f.get("bio") ?? ""),
			});
			return error ? fail(ctx, "/profile/edit", error) : go("/profile");
		},
		saveSettings: mutate("/settings", (u, f) =>
			updatePrefs(u.id, {
				currency: String(f.get("currency") ?? ""),
				run_at: String(f.get("run_at") ?? ""),
				week_start: String(f.get("week") ?? ""),
			}),
		),
		async setTheme(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return new Response(null, { status: 401 });
			await setTheme(user.id, String(formOf(ctx).get("theme") ?? ""));
			return new Response(null, { status: 204 });
		},
		async setBackground(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			const f = formOf(ctx);
			const url = String(f.get("url") ?? "");
			const error = await act.validateAndSetBackground(user.id, url);
			return error ? fail(ctx, "/settings", error) : go("/settings");
		},
		async resetBackground(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			await act.resetUserBackground(user.id);
			return go("/settings");
		},

		// ---------- account ----------
		async exportCsv(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			return new Response(await act.exportCsv(user.id), {
				headers: {
					"Content-Type": "text/csv; charset=utf-8",
					"Content-Disposition": 'attachment; filename="moneytracker.csv"',
				},
			});
		},
		async deleteAccount(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			await act.deleteAccount(user.id);
			const session = ctx.get(Session);
			session.unset("auth");
			session.regenerateId(true);
			return go("/signup");
		},
	},
});
__EOF_MT__
echo updated app/actions/controller.tsx
mkdir -p app/pages
cat > app/pages/screens.ts <<'__EOF_MT__'
import { esc } from "../lib/html.ts";
import type { DebtView, Goal, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { chips, fld, hd, ic, sec, tg, themeSwitch } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";

function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);

	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${esc(n)} ${fmt(a)}`).join(" · ") || "nothing yet";

	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";

	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = Math.min(Math.max(0, s.balance), wishTarget);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;

	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}

const cur = (s: State) => esc(s.user.currency);
const back = (s: State) => `<input type="hidden" name="back" value="${esc(s.back)}">`;
const err = (s: State) => (s.error ? `<div class="neg" role="alert" style="margin:10px 0;font-size:13px">${esc(s.error)}</div>` : "");
/** How much of the balance covers each wish (each wish is compared with the whole balance). */
const covered = (s: State) => new Map(s.goals.map((g) => [g.id, Math.min(Math.max(0, s.balance), g.target)] as const));
const pctOf = (s: State, g: Goal) => (g.target ? Math.min(100, Math.round(((covered(s).get(g.id) ?? 0) / g.target) * 100)) : 0);
const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target;

const avatar = (s: State) => {
	const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : "";
	return `<div class="av"${url ? ` style="background:url('${esc(url)}') center/cover"` : ""}>${url ? "" : esc((s.user.name.trim()[0] ?? "?").toUpperCase())}</div>`;
};

const debtRow = (s: State, d: DebtView) => {
	const unit = d.kind === "money" ? cur(s) : esc(d.item);
	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
	const panel = (flag: string, action: string, title: string, btn: string) =>
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off"><span class="mu">${unit}</span><button class="btn xs">${btn}</button></div></form>`;
	return (
		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="sp">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
		panel("data-addp", "/debts", "Add to", "Add") +
		panel("data-payp", "/debts/pay", "Pay", "Pay") +
		`</div>`
	);
};

const debtList = (s: State) => s.debts.map((d) => debtRow(s, d)).join("") || '<div class="lb" style="padding:8px 0">Nobody to pay. All clear.</div>';

const nameChips = (names: string[]) =>
	names.length ? `<div class="chips nm">${names.map((n) => `<span class="chip" data-nm="${esc(n)}">${esc(n)}</span>`).join("")}</div>` : "";

const bigAdd = (label: string) => `<button type="button" class="addb" data-bigadd aria-label="${label}">${ic("plus")}</button>`;

const addDebtPanel = (s: State) =>
	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

const owePair = (s: State) => {
	const c = calc(s);
	return `<div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>`;
};

const chev = `<span class="chev">${ic("chev")}</span>`;

const tgp = (t: string, key: string, b: string) =>
	`<div class="cd"><div class="tg th2"><span>${t}</span><button type="button" class="pl" data-plus="${key}" aria-label="Add">${ic("plus")}</button></div><div class="cb">${b}</div></div>`;

const spendRow = (s: State, id: string, n: string, sub: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${sub}</div></div><span class="rt"><b class="sp">${a}</b><form method="post" action="/buy/delete" style="display:contents" data-confirm="Undo this buy? The money comes back.">${back(s)}<input type="hidden" name="id" value="${id}"><button class="ub" aria-label="Undo buy">${ic("undo")}</button></form></span></div>`;

const oweM = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="cd bgc">${bigAdd("Add debt")}<div class="ct"><details class="dd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">I owe</div><div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>${chev}</summary><div class="cb">${debtList(s)}</div></details>${addDebtPanel(s)}</div></div>`;
};

const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="sc bgc">${bigAdd("Add debt")}<div class="ct"><details data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>${addDebtPanel(s)}</div></div>`;
};

const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = [
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
	return tg(
		"Road to goals",
		`<div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div><div class="mt"><i style="width:${c.pct}%"></i></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}`,
	);
};

const goalFold = (s: State, key: string) => {
	const c = calc(s);
	const chipHtml = [
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
	return `<details class="cd" data-keep-open="${key}"><summary class="osum"><div class="tg0">Road to goals</div><div class="ow"><b class="big2">${c.pct}<small>%</small></b><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chev}</summary><div class="cb"><div class="mt"><i style="width:${c.pct}%"></i></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}</div></details>`;
};

const goalLeft = (s: State, g: Goal) => (g.target ? (canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`) : "no price");

const addWishPanel = (s: State) =>
	`<form method="post" action="/goals" class="sf adp" data-adp hidden>${back(s)}<input class="in" name="name" data-name placeholder="What do you want?" autocomplete="off" required><input class="in" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

const boughtBtn = (s: State, g: Goal) =>
	`<form method="post" action="/goals/buy" style="display:contents" data-confirm="Mark ${esc(g.title)} as bought? It will be added as a spend.">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="btn xs${canBuy(s, g) ? "" : " off"}"${canBuy(s, g) ? "" : " disabled"}>Bought</button></form>`;

const wishesM = (s: State) =>
	`<div class="cd bgc">${bigAdd("Add wish")}<div class="ct"><div class="tg">Wish list</div><div class="cb">${
		s.goals
			.map(
				(g) =>
					`<div class="wi"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt"><i style="width:${pctOf(s, g)}%"></i></div><div class="wa">${boughtBtn(s, g)}</div></div>`,
			)
			.join("") || '<div class="lb" style="padding:8px 0">Nothing on the list.</div>'
	}</div>${addWishPanel(s)}</div></div>`;

const wishD = (s: State) =>
	`<div class="sc bgc">${bigAdd("Add wish")}<div class="ct"><div class="sh"><span>Wish list</span><span class="lb">${s.goals.filter((g) => !g.done).length} active</span></div>${
		s.goals
			.map(
				(g) =>
					`<div class="wr"><div style="flex:1"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt"><i style="width:${pctOf(s, g)}%"></i></div></div>${boughtBtn(s, g)}</div>`,
			)
			.join("") || '<div class="lb" style="padding:14px 0">Nothing on the list.</div>'
	}${addWishPanel(s)}</div></div>`;

const debtsM = (s: State) =>
	`<div class="cd bgc">${bigAdd("Add debt")}<div class="ct"><div class="tg">Debts</div><div class="cb">${owePair(s)}${debtList(s)}</div>${addDebtPanel(s)}</div></div>`;

const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);

const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id);

const srcRows = (s: State) =>
	s.sources
		.map((x) => {
			const got = gotToday(s, x);
			const sum = got.reduce((a, i) => a + i.amount, 0);
			const auto = x.mode === "auto";
			const tag = auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
			const sub = got.length ? `<span class="ok">got +${fmt(sum)} today</span>` : auto ? (x.every === "month" ? "monthly" : "every day") : "nothing today yet";
			let right: string;
			if (auto) right = `<b class="ea">+${fmt(x.amount)}</b>`;
			else if (got.length) {
				right = `<span class="rt"><button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${back(s)}<input type="hidden" name="id" value="${got[0]!.id}"><button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form></span>`;
			} else
				right = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(srcAmount(x))}</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div><div class="lb">${sub}</div></div>${right}</div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';

const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div>`;

const addSourceForm = (s: State, wide: boolean) =>
	wide
		? `<form method="post" action="/income" class="ln" style="margin-top:18px">${back(s)}<input class="in" name="name" placeholder="New source" autocomplete="off"><input class="in" name="amount" style="width:100px" placeholder="Amount" inputmode="decimal"><button class="btn xs">Add</button>${modeChips}</form>`
		: `<form method="post" action="/income">${back(s)}${fld("Name", "", { name: "name" })}${fld("Amount", "", { t: "number", name: "amount" })}${modeChips}<button class="btn full" style="margin-top:14px">Add source</button></form>`;

const todayLine = (s: State) => `<span class="tl">${calc(s).earned ? `+${fmt(calc(s).earned)} today · ${calc(s).earnedLine}` : "nothing earned today yet"}</span>`;

const incomeM = (s: State) => tg(`Sources${todayLine(s)}`, srcRows(s)) + tg("Add a source", addSourceForm(s, false));

const incD = (s: State, title = "Income sources") => sec(title, `+${fmt(calc(s).earned)} today`, srcRows(s) + addSourceForm(s, true));

const cardsM = (s: State) => {
	const c = calc(s);
	const row = (cls: string, big: string) => `<div class="big2 ${cls}" style="white-space:nowrap">${big} <small>${cur(s)}</small></div>`;
	return `<div class="two">${tg("Earned today", row("ea", `+${fmt(c.earned)}`))}${tg("Bought today", row("sp", `−${fmt(c.bought)}`))}</div>`;
};

const buyRows = (s: State) =>
	`<div>${
		s.buys
			.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), `${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`, `−${fmt(b.total)}`))
			.join("") || '<div class="lb" style="padding:8px 0">Nothing bought today.</div>'
	}</div>`;

const spendForm = (s: State) =>
	`<form method="post" action="/buy" class="sf" data-sp>${back(s)}${nameChips(s.names)}<input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

/** "Today's buys" with a plus that opens the add form on top of the list. */
const buysCard = (s: State) =>
	`<div class="cd"><div class="tg th2"><span>Today's buys · ${s.buys.length}</span><button type="button" class="pl" data-plus="buy" aria-label="Add a buy">${ic("plus")}</button></div><div class="cb"><div class="pnl top" data-pnl hidden>${spendForm(s)}</div>${buyRows(s)}</div></div>`;

const buysD = (s: State) =>
	`<div class="sc"><div class="sh"><span>Today's buys</span><span class="rr"><span class="lb">${s.buys.length}</span><button type="button" class="pl" data-plus="buy" aria-label="Add a buy">${ic("plus")}</button></span></div><div class="pnl top" data-pnl hidden style="margin-top:14px">${spendForm(s)}</div>${buyRows(s)}</div>`;

const hero = (s: State) => {
	const c = calc(s);
	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v ea">+${fmt(c.earned)}</div><div class="lb">${c.earnedLine}</div></div><div><div class="lb">Bought today</div><div class="v sp">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
};

const noteList = (s: State, key: string) => {
	if (key === "dash")
		return `<div data-list="dash">${
			s.notes
				.slice(-2)
				.reverse()
				.map((n) => `<div class="rw"><span>${esc(n.body)}</span><span class="lb">${hhmm(n.at)}</span></div>`)
				.join("") || '<div class="lb" style="padding:8px 0">No notes yet.</div>'
		}</div>`;
	let last = "";
	let out = "";
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at));
		if (label !== last) {
			out += `<div class="day"><span>${esc(label)}</span></div>`;
			last = label;
		}
		out +=
			`<div class="msg" data-id="${n.id}"><div class="bub">${esc(n.body)}</div><div class="meta">${n.edited ? "edited · " : ""}${hhmm(n.at)}</div>` +
			`<div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button>` +
			`<form method="post" action="/notes/delete" style="display:contents" data-confirm="Delete this note?">${back(s)}<input type="hidden" name="id" value="${n.id}"><button class="btn xs dng">Delete</button></form></div></div>`;
	}
	return `<div data-list="${key}">${out}</div>`;
};

const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';

const composer = (s: State, key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes">${back(s)}<input type="hidden" name="id" data-eid><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;

const noteD = (s: State) =>
	sec(
		"Note to yourself",
		`${s.notes.length} saved`,
		`<form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0">${back(s)}<input type="hidden" name="id" data-eid><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></form>${noteList(s, "dash")}`,
	);

const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`;

const histM = (s: State) =>
	s.days
		.map((d) =>
			tg(
				esc(d.label),
				`<div class="l1"><span><span class="lb">Earned</span> <b class="ea">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${chips(d.items.map(esc))}`,
			),
		)
		.join("");

const histD = (s: State) => {
	const e = s.days.reduce((a, d) => a + d.earned, 0);
	const b = s.days.reduce((a, d) => a + d.bought, 0);
	return sec(
		"Last 7 days",
		`+${fmt(e)} earned · −${fmt(b)} bought`,
		'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
			s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="ea">+${fmt(d.earned)}</b><b class="sp">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b>${chips(d.items.map(esc))}</div>`).join(""),
	);
};

const editFields = (s: State) =>
	fld("Name", esc(s.user.name), { f: true, name: "name" }) +
	fld("Email", esc(s.user.email), { t: "email", name: "email" }) +
	fld("Phone", esc(s.user.phone), { t: "tel", name: "phone", p: "+212 6 00 00 00 00" }) +
	fld("Bio", esc(s.user.bio), { name: "bio", p: "A line about you" });

const profileForm = (s: State, cancel: string) =>
	`<form method="post" action="/profile/edit">${err(s)}${editFields(s)}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="${cancel}">Cancel</a></div></form>`;

const prefsForm = (s: State) =>
	`<form method="post" action="/settings">${fld("Currency", esc(s.user.currency), { name: "currency" })}${fld("Auto income runs at", esc(s.user.run_at), { name: "run_at" })}${fld("Week starts", esc(s.user.week_start), { name: "week" })}<button class="btn" style="margin-top:14px">Save</button></form>`;

const dataButtons = `<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>`;

const balanceCard = (s: State) =>
	tg(
		"Total balance",
		`<div class="ow" style="margin:0"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></div>`,
	);

const profileM = (s: State) =>
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div></div></div>` +
	balanceCard(s) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);

const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));

const settingsM = (s: State) =>
	err(s) +
	tg("Money & income", prefsForm(s)) +
	tg("Data", dataButtons);

const settingsD = (s: State) =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	err(s) +
	`<div class="g3"><div>${sec("Profile", "", profileForm(s, "/home"))}${sec(
		"Account",
		"",
		`<form method="post" action="/logout"><button class="btn o">Log out</button></form>`,
	)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Money & income", "", prefsForm(s))}${sec(
		"Data",
		"",
		dataButtons,
	)}</div></div>`;

const dashboardD = (s: State) =>
	hero(s) +
	`<div class="g2"><div>${buysD(s)}</div><div>${oweD(s, false, "owe")}${incD(s, "Income today")}${noteD(s)}</div></div>`;

const debtsD = (s: State) => {
	const c = calc(s);
	return (
		`<div class="hd"><h1 class="t">Debts</h1><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span></div>` +
		`<div class="g3"><div>${oweD(s, true, "owe-page")}</div><div>${sec(
			"How it works",
			"",
			'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div>',
		)}</div></div>`
	);
};

const notesD = (s: State) => `<div class="chat" data-x>${chatHead}${noteList(s, "d")}<div style="margin:30px 0 0">${composer(s, "d")}</div></div>`;

const planD = (s: State) => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${wishD(s)}</div><div>${incD(s)}</div></div>`;

const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 7 days</span></div>${histD(s)}`;

const base = (s: State) => ({
	theme: s.user.theme,
});

const homeBar = () => `<div style="text-align:right"><div style="font-size:14px;font-weight:600;letter-spacing:-.01em">Today</div><div class="lb">${longDay(today())}</div></div>`;

export const homePage = (s: State) =>
	page({
		...base(s),
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobileBar: homeBar(),
		mobile: err(s) + cardsM(s) + tgp(`Income sources${todayLine(s)}`, "src", `<div>${srcRows(s)}</div><div class="pnl" data-pnl hidden>${addSourceForm(s, false)}</div>`) + buysCard(s) + goalFold(s, "goal") + oweM(s, false, "owe"),
		desktop: err(s) + dashboardD(s),
	});

export const debtsPage = (s: State) =>
	page({
		...base(s),
		title: "Debts",
		mobileTab: "home",
		desktopTab: "home",
		mobile: err(s) + hd("Debts", s.debts.map((d) => esc(d.person)).slice(0, 2).join(" + ")) + goalM(s) + oweM(s, true, "owe-page"),
		desktop: err(s) + debtsD(s),
	});

export const notesPage = (s: State) =>
	page({ ...base(s), title: "Notes", mobileTab: "notes", desktopTab: "notes", mobile: chatHead + noteList(s, "m"), dock: composer(s, "m"), desktop: notesD(s) });

export const goalsPage = (s: State) =>
	page({ ...base(s), title: "Goals", mobileTab: "goals", desktopTab: "plan", mobile: hd("Goals", "wishes + debts") + err(s) + goalM(s) + wishesM(s) + debtsM(s), desktop: err(s) + planD(s) });

export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "home", desktopTab: "plan", mobile: err(s) + hd("Income", `+${fmt(calc(s).earned)} today`) + incomeM(s), desktop: err(s) + planD(s) });

export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 7 days") + histM(s), desktop: historyD(s) });

export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });

export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });

export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
__EOF_MT__
echo updated app/pages/screens.ts
mkdir -p app/ui
cat > app/ui/css.ts <<'__EOF_MT__'
export const css = String.raw`
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}

body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}

a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}button{cursor:pointer}
.mu,.lb{color:var(--mu)}.lb{font-size:11px;font-family:var(--mono)}.pos{color:var(--pos)!important}.neg{color:var(--neg)!important}.ea{color:var(--earn)!important}.sp{color:var(--spend)!important}.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}summary::-webkit-details-marker{display:none}

button,input[type=button],input[type=submit],.btn,.sbl,.qk button,.qk4 button,.chip,.ib,.pl{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.qk button:active,.qk4 button:active,.chip:active,.ib:active,.pl:active{transform:scale(.97);opacity:.88}

.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
.tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}

.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;background:var(--s1);border:1px solid var(--ln);border-radius:24px;padding:38px 32px 34px;box-shadow:var(--sh1)}
@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px;border-radius:20px}}
.auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
.auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
.auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
.auth-err-banner{background:rgba(255,90,77,0.12);border:1px solid rgba(255,90,77,0.3);border-radius:12px;padding:10px 14px;color:var(--neg);font-size:13px;font-weight:500;text-align:center;margin:12px 0}
.auth-switch-wrap{display:flex;justify-content:center;margin-top:22px;text-align:center}
.lnk-switch{font-size:14px;color:var(--mu);text-decoration:none}
.lnk-switch b{color:var(--ac);text-decoration:underline;text-underline-offset:3px}
.lnk-switch:hover{color:var(--ink)}

@media(min-width:900px){.m{display:none!important}}
@media(max-width:899px){.d{display:none!important}}

.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){.app{flex-direction:column}}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}

.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg,.bt .lg svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib.sm{width:28px;height:28px}.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}

.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:20px 20px 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}.bt .on svg.ic{stroke-width:2}
.bt .lg svg{opacity:.55;width:26px;height:26px;border-radius:7px}.bt .lg.on svg{opacity:1}

.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}

h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}

.cd{background:var(--s1);border:1px solid var(--ln);border-radius:16px;box-shadow:var(--sh1);margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}.two .cb{padding:3px 12px 10px}.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}

.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:12px;padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
.btn:hover{filter:brightness(1.06)}
.btn.o{background:var(--s1);color:var(--ink);border:1px solid var(--ln);box-shadow:var(--sh1)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
.btn.full{width:100%;padding:13px;border-radius:12px;margin-top:16px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:500;color:var(--mu);margin-bottom:6px;letter-spacing:-.01em}

.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:10px 14px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
.in:focus,.in.f:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.in::placeholder{color:var(--mu);opacity:.6}
.ln{display:flex;gap:10px;align-items:center}

.stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
.stp button{width:34px;height:34px;border:1px solid var(--ln);background:var(--s1);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;color:var(--ink)}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:12px 16px;border-radius:12px;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}

.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}

.qk{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:12px}
.qk button{display:flex;flex-direction:column;align-items:center;gap:6px;padding:14px 6px 12px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);color:var(--ink)}
.qk button svg.ic{color:var(--spend)}
.qk button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}.qk button.on small{color:var(--spend);opacity:.8}
.qk span{font-weight:600;font-size:13px}.qk small{font-size:11px;color:var(--mu);font-family:var(--mono)}
.pn{display:flex;gap:16px;align-items:flex-end;flex-wrap:wrap}
.pn2{display:flex;gap:12px;align-items:flex-end}
.pn2 .pf{flex:1;min-width:0}
.pn2 .pq{flex:none}
.pn2 label{display:block;margin-bottom:6px}
.pn2 .stp{gap:6px}.pn2 .stp .in{width:46px;padding:10px 4px}
.th2{display:flex;justify-content:space-between;align-items:center;padding:10px 10px 0 14px!important}
.pl{width:32px;height:32px;border-radius:10px;border:1px solid var(--ln);background:var(--s2);color:var(--ink);display:flex;align-items:center;justify-content:center;padding:0;flex:none;box-shadow:var(--sh1)}
.pl svg.ic{width:18px;height:18px;transition:transform .18s ease}
.pl.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}.pl.on svg.ic{transform:rotate(45deg)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.tt{display:flex;align-items:center;gap:12px;margin-top:16px}.tt b{flex:1;font-size:26px;letter-spacing:-.04em}

.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ln3{display:flex;gap:12px;align-items:center}.n3{width:76px;flex:none}

.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}.cm .eb b{font-weight:600}.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}

.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}.li:hover{background:var(--s2)}.li:last-child{border:0}.li:first-child{padding-top:14px}

.hero{display:grid;grid-template-columns:repeat(4,1fr);border:1px solid var(--ln);border-radius:16px;background:var(--s1);box-shadow:var(--sh1);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;background:var(--s1);border:1px solid var(--ln);border-radius:16px;padding:18px 22px 20px;box-shadow:var(--sh1)}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:16px}
.qk4 button{display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;color:var(--ink);text-align:left;box-shadow:var(--sh1)}
.qk4 button svg.ic{color:var(--spend)}
.qk4 button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}
.qk4 b{display:block;font-size:14px}.qk4 small{font-size:12px;opacity:.65;font-family:var(--mono)}
.qrow{display:flex;align-items:center;gap:16px;margin-top:16px;padding:16px 18px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);flex-wrap:wrap}
.qrow .eq{font-size:22px;font-weight:600;letter-spacing:-.04em}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
.sl{background:var(--ac);color:var(--on);padding:48px;display:flex;flex-direction:column;justify-content:space-between}
.sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
.sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
.wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.au .in{padding:13px 16px;font-size:15px}
.au .fl{margin-top:14px}.au .fl label{margin-bottom:6px;font-weight:600;font-size:12px;letter-spacing:0.02em}
.au .btn.full{padding:14px 20px;font-size:16px;border-radius:12px;margin-top:20px;font-weight:700}
.au .gbtn{padding:13px 18px;font-size:14px;border-radius:12px;font-weight:600}
.au .gbtn:hover{background:var(--s2)}
.au .or{margin:18px 0 6px}

details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s ease}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}

.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:var(--bg);border:1px solid var(--ln);color:var(--ink)}
.qe{display:flex;gap:10px;align-items:center;padding:10px 0;border-bottom:1px solid var(--ln)}
.qe .in{font-size:14px;padding:8px 12px}
.qadd{display:flex;gap:10px;align-items:center;margin-top:14px}
.qadd .in{font-size:14px;padding:8px 12px}
.sf .in{display:block;margin-bottom:10px}
.sf .btn.full{margin-top:0}
.chips.nm{flex-wrap:nowrap;overflow-x:auto;margin:0 0 10px;padding-bottom:2px;scrollbar-width:none}
.chips.nm::-webkit-scrollbar{display:none}
.chips.nm .chip{flex:none;white-space:nowrap}
.bgc{display:flex;overflow:hidden;padding:0}
.bgc>.ct{flex:1;min-width:0}
.sc.bgc>.ct{padding:18px 22px 20px}
.addb{flex:none;width:64px;border:0;border-right:1px solid var(--acl);border-radius:0;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0}
.addb svg.ic{width:30px;height:30px;stroke-width:2;transition:transform .18s ease}
.addb.on svg.ic{transform:rotate(45deg)}
.addb:active{transform:none;opacity:.8}
.bgc .adp{margin:6px 14px 14px}
.sc.bgc .adp{margin:14px 0 0}
details.dd>summary{padding:14px 16px;display:block;position:relative}
details.dd[open]>summary{padding-bottom:4px}
details.dd>.cb{padding-top:6px}
details.dd .chev{position:absolute;right:16px;top:14px}
.sc.bgc summary.sh{cursor:pointer}
.wi{padding:12px 0;border-top:1px solid var(--ln)}
.wi:first-child{border-top:0;padding-top:0}
.wa{display:flex;gap:8px;justify-content:flex-end;align-items:center;margin-top:10px}
.l1{gap:12px}.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.tl{display:block;font-weight:400;margin-top:3px;font-size:11px;color:var(--mu);font-family:var(--mono)}
.th2>span{min-width:0}
.pnl.top{margin:0 0 12px;padding:0 0 12px;border-top:0;border-bottom:1px solid var(--ln)}
.sh .pl{margin-left:10px}
.ok{color:var(--earn)}

`;
__EOF_MT__
echo updated app/ui/css.ts
mkdir -p app/ui
cat > app/ui/script.ts <<'__EOF_MT__'
/**
 * Tiny inline script, plain JavaScript. All data now lives in the database and every change is a
 * normal form post. This script only handles what a form cannot: picking a quick buy, the
 * quantity stepper, open/close panels, selecting a note, choosing an income mode, and the theme.
 * The browser still remembers two small UI things: the theme and whether "I owe" is open.
 */
export const themeBoot = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;

export const script = String.raw`
(function(){
var d=document,r=d.documentElement;
function all(sel,root){return [].slice.call((root||d).querySelectorAll(sel))}
function money(n){return (Math.round(n*100)/100).toLocaleString('en-US')}

function setTheme(t){
  r.setAttribute('data-theme',t);
  try{localStorage.setItem('mtheme',t)}catch(e){}
  try{fetch('/settings/theme',{method:'POST',body:new URLSearchParams({theme:t}),credentials:'same-origin',redirect:'manual'})}catch(e){}
}

/* ---------- quick buy ---------- */
function calc(f){
  var q=parseFloat(f.querySelector('[data-qty]').value)||0,p=parseFloat(String(f.querySelector('[data-price]').value).replace(',','.'))||0;
  var t=Math.round(q*p*100)/100,o=f.querySelector('[data-tot]');
  o.textContent=(o.getAttribute('data-pre')||'')+(t?'−':'')+money(t);
}
function pick(q,keep){
  var w=q.closest('[data-qb]'),f=w.querySelector('[data-qp]'),n=q.getAttribute('data-q');
  all('[data-q]',w).forEach(function(b){b.classList.toggle('on',b===q)});
  f.hidden=false;
  f.querySelector('[data-cat]').value=n;
  var ti=f.querySelector('[data-qt]');if(ti)ti.textContent=n;
  var lw=f.querySelector('[data-labelwrap]');if(lw)lw.hidden=!q.hasAttribute('data-o');
  if(!keep)f.querySelector('[data-qty]').value=1;
  f.querySelector('[data-price]').value=q.getAttribute('data-p')||'';
  calc(f);
}
all('.qk4').forEach(function(g){var first=g.querySelector('[data-q]');if(first)pick(first,false)});

/* ---------- notes ---------- */
function endEdit(c){
  var id=c.querySelector('[data-eid]');if(id)id.value='';
  var eb=c.querySelector('.eb');if(eb)eb.hidden=true;
  c.querySelector('textarea').value='';
}
all('[data-list]').forEach(function(L){
  var last=L.lastElementChild;
  if(L.getAttribute('data-list')!=='dash'&&last&&last.scrollIntoView)last.scrollIntoView({block:'end'});
});

/* ---------- "I owe" open or closed, kept in the browser ---------- */
var open={};try{open=JSON.parse(localStorage.getItem('mt:open')||'{}')}catch(e){}
all('details[data-keep-open]').forEach(function(x){var k=x.getAttribute('data-keep-open');if(k in open)x.open=!!open[k]});
d.addEventListener('toggle',function(e){
  var x=e.target;
  if(x.matches&&x.matches('details[data-keep-open]')){
    open[x.getAttribute('data-keep-open')]=x.open;
    try{localStorage.setItem('mt:open',JSON.stringify(open))}catch(err){}
  }
},true);

/* ---------- clicks ---------- */
d.addEventListener('click',function(e){
  var t=e.target,q;
  if(t.closest('[data-theme-toggle]')){setTheme(r.getAttribute('data-theme')==='dark'?'light':'dark');return}
  if((q=t.closest('[data-set-theme]'))){setTheme(q.getAttribute('data-set-theme'));return}
  if((q=t.closest('[data-eye]'))){
    var v=q.parentNode.firstChild,hide=q.getAttribute('data-s')!=='1';
    q.setAttribute('data-s',hide?'1':'0');
    v.innerHTML=hide?(v.getAttribute('data-bal')+' <small>'+v.getAttribute('data-cur')+'</small>'):'••••••';
    return
  }
  if((q=t.closest('[data-tg],[data-pay]'))){
    var w=q.closest('.dbw'),which=q.hasAttribute('data-tg')?'[data-addp]':'[data-payp]',other=q.hasAttribute('data-tg')?'[data-payp]':'[data-addp]';
    var p=w.querySelector(which),o=w.querySelector(other);
    if(o)o.hidden=true;
    p.hidden=!p.hidden;
    if(!p.hidden){var i=p.querySelector('input[name=amount]');if(i)i.focus()}
    return
  }
  if((q=t.closest('[data-plus]'))){
    var pn=q.closest('.cd,.sc').querySelector('[data-pnl]');
    if(pn){
      pn.hidden=!pn.hidden;
      q.classList.toggle('on',!pn.hidden);
      if(!pn.hidden){var fi=pn.querySelector('input:not([type=hidden])');if(fi)fi.focus()}
    }
    return
  }
  if((q=t.closest('[data-nm]'))){
    var nf=q.closest('form'),nin=nf.querySelector('[data-name]'),pin=nf.querySelector('[data-price]');
    nin.value=q.getAttribute('data-nm');
    if(pin)pin.focus();
    return
  }
  if((q=t.closest('[data-bigadd]'))){
    var ap=q.closest('.bgc').querySelector('[data-adp]');
    ap.hidden=!ap.hidden;
    q.classList.toggle('on',!ap.hidden);
    if(!ap.hidden){var ai=ap.querySelector('[data-name]');if(ai)ai.focus()}
    return
  }
  if((q=t.closest('[data-q]'))){pick(q,false);return}
  if((q=t.closest('[data-step]'))){
    var f2=q.closest('[data-qp]'),i2=f2.querySelector('[data-qty]');
    i2.value=Math.max(1,(parseFloat(i2.value)||0)+parseInt(q.getAttribute('data-step'),10));calc(f2);return
  }
  if((q=t.closest('[data-mode]'))){
    var form=q.closest('form');
    all('[data-mode]',form).forEach(function(c){c.classList.toggle('on',c===q)});
    form.querySelector('[data-mode-input]').value=q.getAttribute('data-mode');
    return
  }
  if((q=t.closest('.bub'))){
    q.classList.toggle('sel');var a=q.parentNode.querySelector('.acts');a.hidden=!a.hidden;return
  }
  if((q=t.closest('[data-act]'))){
    var m=q.closest('.msg'),act=q.getAttribute('data-act'),body=m.querySelector('.bub').textContent;
    if(act==='copy'){try{navigator.clipboard.writeText(body)}catch(x){}return}
    if(act==='edit'){
      var key=m.parentNode.getAttribute('data-list'),c=d.querySelector('[data-comp="'+key+'"]');
      c.querySelector('[data-eid]').value=m.getAttribute('data-id');
      c.querySelector('.eb').hidden=false;
      var ta=c.querySelector('textarea');ta.value=body;ta.focus();
    }
    return
  }
  if((q=t.closest('[data-cancel]'))){endEdit(q.closest('[data-comp]'));return}
});

d.addEventListener('input',function(e){
  var f=e.target.closest&&e.target.closest('[data-qp]');
  if(f)calc(f);
});

d.addEventListener('submit',function(e){
  var f=e.target,msg=f.getAttribute&&f.getAttribute('data-confirm');
  if(msg&&!confirm(msg))e.preventDefault();
});

d.addEventListener('keydown',function(e){
  if(e.key!=='Enter'||e.shiftKey)return;
  var t=e.target;
  if(t.matches&&t.matches('[data-comp] textarea')){
    e.preventDefault();
    if(t.value.trim()){var f=t.closest('form');if(f.requestSubmit)f.requestSubmit();else f.submit()}
  }
});

/* ---------- live clock (Africa/Casablanca) ---------- */
function updateLiveClock(){
  var tEls = all('[data-clock-time]');
  var dEls = all('[data-clock-date]');
  var sEls = all('[data-clock-subdate]');
  if(!tEls.length) return;
  var now = new Date();
  try{
    var tf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', hour: '2-digit', minute: '2-digit', hour12: false });
    var df = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', weekday: 'long', day: 'numeric', month: 'long' });
    var nf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', day: '2-digit', month: '2-digit', year: 'numeric' });
    var af = new Intl.DateTimeFormat('ar-MA', { timeZone: 'Africa/Casablanca', weekday: 'long' });
    var tStr = tf.format(now);
    var dStr = df.format(now);
    var sStr = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + '</span>';
    tEls.forEach(function(el){ el.textContent = tStr; });
    dEls.forEach(function(el){ el.textContent = dStr; });
    sEls.forEach(function(el){ el.innerHTML = sStr; });
  }catch(err){}
}
setInterval(updateLiveClock, 1000);

/* ---------- background fallback ---------- */
var bgCustomEl = d.querySelector('[data-bg-custom]');
if(bgCustomEl){
  var bgUrl = bgCustomEl.getAttribute('data-bg-custom');
  if(bgUrl){
    var testImg = new Image();
    testImg.onerror = function(){
      bgCustomEl.classList.add('bg-fallback-auto');
    };
    testImg.src = bgUrl;
  }
}
})();
`;
__EOF_MT__
echo updated app/ui/script.ts
mkdir -p app/ui
cat > app/ui/parts.ts <<'__EOF_MT__'
/** Small HTML builders shared by every screen. Everything is static sample markup. */

export const P: Record<string, string> = {
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
	moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
	Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
	Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
	Other: '<path d="M12 5v14M5 12h14"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	chev: '<path d="M6 9l6 6 6-6"/>',
	Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
	Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
	Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
	Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
	Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
	Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
};

export const ic = (k: string) => `<svg class="ic" viewBox="0 0 24 24">${P[k] ?? ""}</svg>`;

export const GOOGLE =
	'<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>';

export const GOAT =
	'<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/></svg>';

export const logo = (href: string) => `<a class="logo" href="${href}">${GOAT}<span>moneytracker</span></a>`;

export const themeIcons = `<svg class="ic t-sun" viewBox="0 0 24 24">${P.sun}</svg><svg class="ic t-moon" viewBox="0 0 24 24">${P.moon}</svg>`;

// ---------- building blocks ----------

export const tg = (t: string, b: string) => `<div class="cd"><div class="tg">${t}</div><div class="cb">${b}</div></div>`;

export const sec = (t: string, r: string, b: string) =>
	`<div class="sc"><div class="sh"><span>${t}</span><span class="lb">${r}</span></div>${b}</div>`;

type FieldOpts = { name?: string; t?: string; p?: string; f?: boolean; keep?: string };
export const fld = (label: string, value: string, o: FieldOpts = {}) =>
	`<div class="fl"><label>${label}</label><input class="in${o.f ? " f" : ""}"${o.name ? ` name="${o.name}"` : ""}${o.keep ? ` data-keep="${o.keep}"` : ""}${
		o.t ? ` type="${o.t}"` : ""
	} value="${value}"${value ? "" : ` placeholder="${o.p ?? ""}"`} autocomplete="off"></div>`;

export const hd = (t: string, r: string, back?: string) =>
	`<div class="hd">${
		back ? `<a class="back" href="${back}">${ic("back")}<h1 class="t">${t}</h1></a>` : `<h1 class="t">${t}</h1>`
	}<span class="lb">${r}</span></div>`;

export const clockWidget = (timeStr: string, dateStr: string, subDateStr = "") =>
	`<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time"><div class="clock-time" data-clock-time>${timeStr}</div><div class="clock-date" data-clock-date>${dateStr}</div><div class="clock-subdate" data-clock-subdate dir="ltr">${subDateStr}</div></div>`;

export const chips = (a: string[]) => `<div class="chips" style="margin:0">${a.map((i) => `<span class="chip">${i}</span>`).join("")}</div>`;

export const by = (n: string, s: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${s}</div></div><b class="neg">${a}</b></div>`;

/** A person I owe. The "+" button opens the add panel under the row. */
export const dbt = (n: string, l: string, p: number, add?: boolean) =>
	`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${n}">${ic("plus")}</button><div class="dn"><div class="l1"><b>${n}</b><span class="neg">${l}</span></div><div class="mt s n"><i style="width:${p}%"></i></div></div><button type="button" class="btn xs o">Pay</button></div>` +
	`<form method="post" action="/debts" class="ad"${add ? "" : " hidden"}><label>Add to ${n}</label><div class="ln"><input class="in f" name="amount" value="200"><span class="mu">MAD</span><button class="btn xs">Add</button></div><div class="lb">800 → 1,000 MAD · same person, no new row</div></form></div>`;

export const newPerson =
	'<div class="sub">New person</div><form method="post" action="/debts" class="ln3"><input class="in" name="name" placeholder="Name"><input class="in n3" name="cig" placeholder="3"><input class="in n3" name="cur" value="MAD"><button class="btn xs">Add</button></form><div class="lb" style="margin-top:10px">Cleared: Karim (hidden). Type his name to bring him back.</div>';

export const buyRows =
	'<div data-buys>' +
	by("Paid Youssef", "13:40", "−24") + by("Bread", "13:00", "−4") + by("Smoke ×3", "09:30 · 3 × 2", "−6") + by("Coffee", "08:10", "−12") + "</div>";

export const srcRows =
	'<div class="rw"><div><div>Ad revenue</div><div class="lb">auto · every day 06:00</div></div><b class="pos">+64</b></div><div class="rw"><div><div>Tips</div><div class="lb">manual · added today</div></div><button type="button" class="btn xs o" style="opacity:.5">Add 120</button></div><div class="rw"><div><div>Salary</div><div class="lb">monthly · Nov 1</div></div><b class="pos">+8,000</b></div>';

// ---------- notes ----------

const acts = (show: boolean) =>
	`<div class="acts"${show ? "" : " hidden"}><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button><button type="button" class="btn xs dng" data-act="del">Delete</button></div>`;

const bub = (t: string, tm: string, sel = false, ed = false) =>
	`<div class="msg"><div class="bub${sel ? " sel" : ""}">${t}</div><div class="meta">${ed ? "edited · " : ""}${tm}</div>${acts(sel)}</div>`;

export const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';

export const chatBody = (key: string, sel: boolean) =>
	`<div data-list="${key}"><div class="day"><span>Yesterday</span></div>${bub('Laptop: Lenovo 15"\n6,000 MAD — wait for Black Friday', "21:14")}<div class="day"><span>Today</span></div>${bub(
		"Call Youssef about the 800 on Friday",
		"09:02",
		sel,
	)}${bub("Bread 4 · Coffee 12 · Smoke 6", "13:05", false, true)}</div>`;

export const composer = (key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes"><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;

// ---------- history ----------

export type Day = { d: string; earned: string; bought: string; items: string[]; net: string };
export const H: Day[] = [
	{ d: "Today", earned: "+184", bought: "−46", items: ["Coffee 12", "Smoke ×3 6", "Bread 4", "Paid Youssef 24"], net: "+138" },
	{ d: "Yesterday", earned: "+64", bought: "−210", items: ["Groceries 150", "Taxi 28", "Smoke 20", "Coffee 12"], net: "−146" },
	{ d: "Sat 10 Oct", earned: "+64", bought: "−95", items: ["Lunch 60", "Smoke 20", "Coffee 11", "Bread 4"], net: "−31" },
	{ d: "Fri 9 Oct", earned: "+230", bought: "−38", items: ["Coffee 12", "Smoke 20", "Bread 6"], net: "+192" },
	{ d: "Thu 8 Oct", earned: "+64", bought: "−130", items: ["Phone credit 100", "Smoke 20", "Bread 10"], net: "−66" },
];

// ---------- settings ----------

export const editFields = () =>
	fld("Name", "Sami", { f: true, name: "name", keep: "profile.name" }) +
	fld("Email", "sami@email.com", { t: "email", name: "email", keep: "profile.email" }) +
	fld("Phone", "+212 6 00 00 00 00", { t: "tel", name: "phone", keep: "profile.phone" }) +
	fld("Bio", "Saving for the laptop", { name: "bio", keep: "profile.bio" });

export const themeSwitch = () =>
	`<div class="sg"><button type="button" data-set-theme="dark">${ic("moon")}Dark</button><button type="button" data-set-theme="light">${ic("sun")}White</button></div>`;

export type Quick = { n: string; p: string; i: string };
export const QUICK_DEF: Quick[] = [
	{ n: "Smoke", p: "2", i: "Smoke" },
	{ n: "Coffee", p: "12", i: "Coffee" },
	{ n: "Bread", p: "4", i: "Bread" },
];
export const ICON_KEYS = ["Smoke", "Coffee", "Bread", "Food", "Bus", "Phone", "Gift", "Cart", "Tag"];

/** Quick buy editor. The rows are drawn by the page script from what is saved in the browser. */
export const quickEditor = () =>
	`<div class="lb" style="margin-bottom:6px">These are the buttons under Quick buy. Change a name, price or icon and it saves right away.</div><div data-qedit></div><div class="qadd" data-qadd><select class="in sel" data-ai aria-label="Icon">${ICON_KEYS.map((k) => `<option value="${k}">${k}</option>`).join("")}</select><input class="in" data-an placeholder="Name" autocomplete="off"><input class="in n3" data-ap placeholder="Price" inputmode="decimal" autocomplete="off"><button type="button" class="btn xs" data-qaddbtn>Add</button></div>`;

// ---------- auth form ----------

/** Sign in / sign up. Submitting just goes to the dashboard: no session, no cookie. */
export const auth = (up: boolean, wide: boolean) =>
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">${wide ? "" : '<div style="height:22px"></div>'}<h1 class="t" style="margin-bottom:20px">${
		up ? "Sign up" : "Sign in"
	}</h1><a class="gbtn" href="/home">${GOOGLE}${up ? "Sign up with Google" : "Continue with Google"}</a><div class="or">or</div>${
		up ? fld("Name", "", { name: "name", p: "Your name" }) : ""
	}${fld("Email", "", { t: "email", name: "email", p: "you@email.com" })}${fld("Password", "", {
		t: "password",
		name: "password",
		p: "••••••••",
	})}<button class="btn full">${up ? "Create account" : "Sign in"}</button><div style="display:flex;justify-content:space-between;margin-top:16px"><a class="lnk" href="${
		up ? "/login" : "/signup"
	}">${up ? "I have an account" : "Create account"}</a>${up ? "" : '<a class="lnk" href="/login">Forgot password?</a>'}</div></form>`;
__EOF_MT__
echo updated app/ui/parts.ts
