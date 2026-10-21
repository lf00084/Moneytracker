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

/** Wipes a debt entered by mistake. History is kept, and typing the name again brings the person back. */
export async function clearDebt(uid: string, f: FormData) {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 });
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

export async function deleteWish(uid: string, f: FormData) {
await db.exec(sql`delete from goals where id = ${text(f.get("id"), 36)} and user_id = ${uid}`);
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
const amount = toMinor(f.get("amount"));
if ((mode === "daily" || mode === "monthly") && !amount) return "Enter how much it pays";
const taken = await db.findMany(incomeSources, { where: { user_id: uid } });
if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`;
const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(incomeSources, {
id: id(),
user_id: uid,
name,
mode: mode === "daily" || mode === "monthly" ? "auto" : "manual",
amount_minor: amount,
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

/** Pause or resume a source. A paused auto source stops paying until resumed. */
export async function toggleSource(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 });
}

/** Deletes a source. What it already paid stays in your balance and history. */
export async function deleteSource(uid: string, f: FormData) {
const sid = text(f.get("id"), 36);
const s = await db.findOne(incomeSources, { where: { id: sid, user_id: uid } });
if (!s) return;
await db.transaction(async (tx) => {
await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`);
await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`);
});
}

/** Undo an income row. Blocked if the money is already spent and the balance would go below zero. */
export async function deleteIncome(uid: string, f: FormData): Promise<string | void> {
const row = await db.findOne(incomes, { where: { id: text(f.get("id"), 80), user_id: uid } });
if (!row) return;
if (row.ext_key) {
const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null;
if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead";
}
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
