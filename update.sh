#!/usr/bin/env bash
set -e
cd "${1:-.}"
mkdir -p app/lib
cat > app/lib/assets.ts << '__EOF_MT__'
import { env } from "../env.ts";
const SITE_DESC = "Moneytracker is a quiet personal money tracker. Log what you spend and earn, track debts and wishes, and watch your road to your goals.";
const bytes = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
const png = (s: string) => new Response(bytes(s), { headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=604800" } });
const text = (body: string, type: string, cache = "public, max-age=86400") => new Response(body, { headers: { "Content-Type": type, "Cache-Control": cache } });
const origin = () => env.APP_ORIGIN.replace(/\/$/, "");
const I192 = "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";
const I512 = "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";
const A180 = "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";
const M512 = "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";
const SVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><rect width=\"24\" height=\"24\" rx=\"5\" fill=\"#13181b\"/><g transform=\"translate(12 12) scale(.62) translate(-12 -12.2)\"><path fill=\"#6fb7c4\" d=\"M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z\"/><path d=\"M9.2 11.4l2 1M14.8 11.4l-2 1\" stroke=\"#13181b\" stroke-width=\"1.5\"/></g></svg>";
const SW = "self.addEventListener(\"install\",()=>self.skipWaiting());self.addEventListener(\"activate\",(e)=>e.waitUntil(self.clients.claim()));self.addEventListener(\"fetch\",(e)=>{if(e.request.mode===\"navigate\")e.respondWith(fetch(e.request).catch(()=>new Response(\"<!doctype html><meta name=viewport content='width=device-width,initial-scale=1'><body style='font:16px system-ui;background:#13181b;color:#e8edf0;display:grid;place-items:center;min-height:100vh;margin:0'><p>You are offline</p>\",{headers:{\"Content-Type\":\"text/html\"}})))});";
export const SITE = { name: "Moneytracker", desc: SITE_DESC, color: "#13181b" };
export const assets = {
manifest: () =>
text(
JSON.stringify({
id: "/",
name: "Moneytracker",
short_name: "Money",
description: SITE_DESC,
start_url: "/home",
scope: "/",
display: "standalone",
orientation: "portrait",
background_color: "#13181b",
theme_color: "#13181b",
categories: ["finance", "productivity"],
icons: [
{ src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
{ src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
{ src: "/icon-maskable.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
],
}),
"application/manifest+json",
),
favicon: () => text(SVG, "image/svg+xml; charset=utf-8"),
icon192: () => png(I192),
icon512: () => png(I512),
iconMaskable: () => png(M512),
appleIcon: () => png(A180),
sw: () => text(SW, "application/javascript; charset=utf-8", "no-cache"),
robots: () => text(`User-agent: *\nAllow: /login\nAllow: /signup\nDisallow: /\nSitemap: ${origin()}/sitemap.xml\n`, "text/plain; charset=utf-8"),
sitemap: () =>
text(
`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>${origin()}/login</loc></url><url><loc>${origin()}/signup</loc></url></urlset>`,
"application/xml; charset=utf-8",
),
};
__EOF_MT__
mkdir -p app
cat > app/routes.ts << '__EOF_MT__'
import { get, post, route } from "remix/routes";
export const routes = route({
	root: get("/"),
	manifest: get("/manifest.webmanifest"),
	favicon: get("/favicon.svg"),
	faviconIco: get("/favicon.ico"),
	icon192: get("/icon-192.png"),
	icon512: get("/icon-512.png"),
	iconMaskable: get("/icon-maskable.png"),
	appleIcon: get("/apple-touch-icon.png"),
	sw: get("/sw.js"),
	robots: get("/robots.txt"),
	sitemap: get("/sitemap.xml"),
	login: get("/login"),
	signIn: post("/login"),
	signup: get("/signup"),
	signUp: post("/signup"),
	logout: post("/logout"),
	googleLogin: get("/login/google"),
	googleCallback: get("/auth/google/callback"),
	home: get("/home"),
	debts: get("/debts"),
	notes: get("/notes"),
	goals: get("/goals"),
	income: get("/income"),
	plan: get("/plan"),
	history: get("/history"),
	profile: get("/profile"),
	profileEdit: get("/profile/edit"),
	setBalance: post("/profile/balance"),
	historyIncome: post("/history/income"),
	settings: get("/settings"),
	buy: post("/buy"),
	deleteBuy: post("/buy/delete"),
	addDebt: post("/debts"),
	payDebt: post("/debts/pay"),
	clearDebt: post("/debts/clear"),
	addNote: post("/notes"),
	deleteNote: post("/notes/delete"),
	addWish: post("/goals"),
	buyWish: post("/goals/buy"),
	deleteWish: post("/goals/delete"),
	addSource: post("/income"),
	addIncome: post("/income/add"),
	deleteIncome: post("/income/delete"),
	toggleSource: post("/income/toggle"),
	deleteSource: post("/income/source/delete"),
	addPlan: post("/plan"),
	saveProfile: post("/profile/edit"),
	saveSettings: post("/settings"),
	quickBuy: post("/settings/quick"),
	setTheme: post("/settings/theme"),
	setBackground: post("/settings/background"),
	resetBackground: post("/settings/background/reset"),
	exportCsv: get("/export.csv"),
	deleteAccount: post("/account/delete"),
});
__EOF_MT__
mkdir -p app/lib
cat > app/lib/money.ts << '__EOF_MT__'
export const toMinor = (s: unknown) => {
	const n = parseFloat(String(s ?? "").replace(",", "."));
	return Number.isFinite(n) && n > 0 && n <= 1e9 ? Math.round(n * 100) : 0;
};
export const fmt = (minor: number) => {
	const v = minor / 100;
	return v.toLocaleString("en-US", { maximumFractionDigits: 2, minimumFractionDigits: Number.isInteger(v) ? 0 : 2 });
};
export const toSigned = (s: unknown) => {
const raw = String(s ?? "").trim();
if (!raw) return null;
const n = parseFloat(raw.replace(",", "."));
return Number.isFinite(n) && Math.abs(n) <= 1e9 ? Math.round(n * 100) : null;
};
__EOF_MT__
mkdir -p app/lib
cat > app/lib/actions.ts << '__EOF_MT__'
import { sql } from "remix/data-table";
import { db, debtPayments, debts, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { balanceOf } from "./data.ts";
import { fmt, toMinor, toSigned } from "./money.ts";
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
const realDay = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T12:00:00Z`)) && new Date(`${v}T12:00:00Z`).toISOString().slice(0, 10) === v;
const pickDay = (f: FormData) => {
const d = text(f.get("day"), 10) || today();
return realDay(d) && d <= today() ? d : null;
};
export async function addBuy(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("label"), 120) || "Item";
const qty = count(f.get("qty")) || 1;
const unit = toMinor(f.get("price"));
if (!unit) return "Enter a price";
const day = pickDay(f);
if (!day) return "Pick a day that is not in the future";
await db.create(purchases, { id: id(), user_id: uid, name, qty, unit_minor: unit, total_minor: unit * qty, day, created_at: Date.now() });
}
export async function addDayIncome(uid: string, f: FormData): Promise<string | void> {
const amount = toMinor(f.get("amount"));
if (!amount) return "Enter an amount";
const day = pickDay(f);
if (!day) return "Pick a day that is not in the future";
await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day, created_at: Date.now(), meta: '{"manual":1}', ext_key: "" });
}
export async function setBalance(uid: string, f: FormData): Promise<string | void> {
const target = toSigned(f.get("balance"));
if (target === null) return "Enter your balance";
const diff = target - (await balanceOf(uid));
if (!diff) return;
const now = Date.now();
if (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: today(), created_at: now, meta: '{"adjust":1}', ext_key: "" });
else await db.create(purchases, { id: id(), user_id: uid, name: "Balance adjustment", qty: 1, unit_minor: -diff, total_minor: -diff, day: today(), created_at: now });
}
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
export async function clearDebt(uid: string, f: FormData) {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 });
}
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
export async function toggleSource(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 });
}
export async function deleteSource(uid: string, f: FormData) {
const sid = text(f.get("id"), 36);
const s = await db.findOne(incomeSources, { where: { id: sid, user_id: uid } });
if (!s) return;
await db.transaction(async (tx) => {
await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`);
await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`);
});
}
export async function deleteIncome(uid: string, f: FormData): Promise<string | void> {
const row = await db.findOne(incomes, { where: { id: text(f.get("id"), 80), user_id: uid } });
if (!row) return;
if (row.ext_key) {
const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null;
if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead";
}
await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } });
}
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
const cell = (v: string | number) => {
let s = String(v);
if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
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
mkdir -p app/lib
cat > app/lib/data.ts << '__EOF_MT__'
import { sql } from "remix/data-table";
import { db, debtPayments, debts, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { settleAuto } from "./auto.ts";
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
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] };
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
await settleAuto(uid);
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
buys: [],
incomesToday: [],
sources: [],
debts: [],
goals: [],
notes: [],
days: [],
balance: 0,
};
if (need.has("today") || need.has("sources") || need.has("history") || need.has("balance")) await settleAuto(uid);
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
const byId = new Map(sourceRows.map((x) => [x.id, x.name]));
const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string }): Income => ({ id: r.id, sourceId: r.source_id ?? "", source: byId.get(r.source_id ?? "") ?? "Other", amount: r.amount_minor, day: r.day });
if (need.has("today")) {
jobs.push(
db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
s.buys = rows.map(toBuy);
}),
db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {
s.incomesToday = rows.map(toIncome);
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
jobs.push(
Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
]).then(([bs, is]) => {
s.days = Array.from({ length: 30 }, (_, i) => {
const day = addDays(t, -i);
const b = bs.filter((x) => x.day === day);
const inc = is.filter((x) => x.day === day);
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
__EOF_MT__
mkdir -p app/ui
cat > app/ui/shell.ts << '__EOF_MT__'
import { css } from "./css.ts";
import { clockWidget, ic, logo, themeIcons } from "./parts.ts";
import { script, themeBoot } from "./script.ts";
import { liveClockNow } from "../lib/time.ts";
import { SITE } from "../lib/assets.ts";
import { env } from "../env.ts";
export type MobileTab = "home" | "notes" | "goals" | "history" | "profile" | "";
export type DesktopTab = "home" | "notes" | "plan" | "history" | "settings" | "";
const splitCss = ".top-status-bar.tsplit{justify-content:space-between}.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}";
export type PageOptions = {
title: string;
user?: boolean;
mobile: string;
desktop: string;
mobileTab?: MobileTab;
desktopTab?: DesktopTab;
dock?: string;
full?: boolean;
theme?: string;
mobileBar?: boolean;
desc?: string;
path?: string;
};
const attr = (s: string) => s.replace(/[&<>"]/g, (c) => `&#${c.charCodeAt(0)};`);
const bottomBar = (a: MobileTab) =>
'<nav class="bt" aria-label="Main">' +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["profile", "Profile", "user", "/profile"],
] as const
)
.map(([key, label, icon, href]) => `<a href="${href}" class="${a === key ? "on" : ""}" aria-label="${label}">${ic(icon)}</a>`)
.join("") +
"</nav>";
const sidebar = (a: DesktopTab) =>
`<aside class="sb d">${logo("/home")}` +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["plan", "Plan", "goal", "/plan"],
["history", "History", "hist", "/history"],
["settings", "Settings", "gear", "/settings"],
] as const
)
.map(([key, label, icon, href]) => `<a class="sbl${a === key ? " on" : ""}" href="${href}">${ic(icon)}${label}</a>`)
.join("") +
`<div class="sp"></div><button type="button" class="sbl" data-theme-toggle>${themeIcons}<span>Theme</span></button>` +
`<form method="post" action="/logout"><button class="sbl">${ic("out")}<span class="neg">Log out</span></button></form></aside>`;
export function page(o: PageOptions): string {
const user = o.user !== false;
const desc = o.desc ?? SITE.desc;
const origin = env.APP_ORIGIN.replace(/\/$/, "");
const ld = JSON.stringify({ "@context": "https://schema.org", "@type": "WebApplication", name: SITE.name, url: origin, description: SITE.desc, applicationCategory: "FinanceApplication", operatingSystem: "Any" }).replace(/</g, "\\u003c");
const { timeStr, dateStr, subDateStr } = liveClockNow();
const clock = clockWidget(timeStr, dateStr, subDateStr);
const topBar = `<div class="top-status-bar">${clock}</div>`;
const mobileTop = `<div class="top-status-bar tsplit">${clock}<div class="clock-subdate" dir="ltr">${subDateStr}</div></div>`;
return (
`<!DOCTYPE html><html lang="en" data-theme="${o.theme === "light" ? "light" : "dark"}"><head><meta charset="utf-8">` +
`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` +
`<meta name="theme-color" content="${SITE.color}"><title>${attr(o.title)} · ${SITE.name}</title>` +
`<meta name="description" content="${attr(desc)}"><meta name="robots" content="${user ? "noindex,nofollow" : "index,follow"}">` +
`<meta name="application-name" content="${SITE.name}"><meta name="apple-mobile-web-app-title" content="${SITE.name}"><meta name="mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black"><meta name="format-detection" content="telephone=no">` +
`<link rel="manifest" href="/manifest.webmanifest"><link rel="icon" href="/favicon.svg" type="image/svg+xml"><link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png"><link rel="apple-touch-icon" href="/apple-touch-icon.png">` +
`<meta property="og:type" content="website"><meta property="og:site_name" content="${SITE.name}"><meta property="og:title" content="${attr(o.title)} · ${SITE.name}"><meta property="og:description" content="${attr(desc)}"><meta property="og:image" content="${origin}/icon-512.png"><meta name="twitter:card" content="summary"><meta name="twitter:title" content="${attr(o.title)} · ${SITE.name}"><meta name="twitter:description" content="${attr(desc)}">` +
(o.path && !user ? `<link rel="canonical" href="${origin}${o.path}"><meta property="og:url" content="${origin}${o.path}">` : "") +
(user ? "" : `<script type="application/ld+json">${ld}</script>`) +
`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap">` +
`<style>${css}${splitCss}</style><script>${o.theme ? "" : themeBoot}</script></head>` +
`<body>` +
`<div class="app">` +
(user
? sidebar(o.desktopTab ?? "")
: `<div class="tf-clock">${clock}<button type="button" class="ib" data-theme-toggle aria-label="Theme">${themeIcons}</button></div>`) +
(user
? `<main><div class="m">${mobileTop}</div><div class="m mm">${o.mobile}</div><div class="d">${topBar}</div><div class="d pg${o.full ? " full" : ""}">${o.desktop}</div></main>`
: `<main class="auth-viewport">${o.desktop}</main>`) +
(user ? `<div class="dock m">${o.dock ?? ""}${bottomBar(o.mobileTab ?? "")}</div>` : "") +
`</div><script>${script}</script><script>if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))</script></body></html>`
);
}
__EOF_MT__
mkdir -p app/pages
cat > app/pages/auth.ts << '__EOF_MT__'
import { fld, GOOGLE, logo } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";
const esc = (s: string) => s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);
const form = (up: boolean, error: string) =>
	`<div class="auth-center-wrap">` +
	`<div class="auth-glass-box">` +
	`<div class="auth-logo-center">${logo("/login")}</div>` +
	`<h1 class="auth-title">${up ? "Create account" : "Sign in"}</h1>` +
	`<div class="auth-sub">${up ? "Quiet money tracking. Start in seconds." : "Quiet money. Welcome back."}</div>` +
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">` +
	`<a class="gbtn" href="/login/google">${GOOGLE}<span>${up ? "Sign up with Google" : "Continue with Google"}</span></a>` +
	`<div class="or">or</div>` +
	(error ? `<div class="auth-err-banner" role="alert">${esc(error)}</div>` : "") +
	(up ? fld("Name", "", { name: "name", p: "Your name" }) : "") +
	fld("Email", "", { t: "email", name: "email", p: "you@email.com" }) +
	fld("Password", "", { t: "password", name: "password", p: "••••••••" }) +
	`<button class="btn full">${up ? "Create account" : "Sign in"}</button>` +
	`<div class="auth-switch-wrap"><a class="lnk-switch" href="${up ? "/login" : "/signup"}">${
		up ? "Already have an account? <b>Sign in</b>" : "Don't have an account? <b>Create account</b>"
	}</a></div>` +
	`</form>` +
	`</div>` +
	`</div>`;
export const loginPage = (error = "") =>
	page({ title: "Sign in", path: "/login", desc: "Sign in to Moneytracker, your quiet personal money tracker.", user: false, full: true, mobile: form(false, error), desktop: form(false, error) });
export const signupPage = (error = "") =>
	page({ title: "Create account", path: "/signup", desc: "Create a free Moneytracker account and start tracking your spending, debts and goals.", user: false, full: true, mobile: form(true, error), desktop: form(true, error) });
__EOF_MT__
mkdir -p app/actions
cat > app/actions/controller.tsx << '__EOF_MT__'
import { completeAuth, finishExternalAuth, startExternalAuth } from "remix/auth";
import { Auth } from "remix/middleware/auth";
import { createController } from "remix/router";
import { Session } from "remix/session";
import * as act from "../lib/actions.ts";
import { assets } from "../lib/assets.ts";
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
const backTo = (f: FormData, fallback: string) => {
	const b = String(f.get("back") ?? "");
	return /^\/(?![/\\])/.test(b) ? b : fallback;
};
function takeError(ctx: Ctx) {
	const session = ctx.get(Session);
	const e = session.get("error");
	return typeof e === "string" ? e : "";
}
const view =
	(path: string, parts: Part[], render: (s: State) => string) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		return html(render(await loadState(user, parts, { back: path, error: takeError(ctx) })));
	};
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
	const session = completeAuth(ctx);
	session.set("auth", { userId });
}
export default createController(routes, {
	actions: {
		root(ctx: Ctx) {
			return go(userOf(ctx) ? "/home" : "/login");
		},
		manifest: () => assets.manifest(),
		favicon: () => assets.favicon(),
		faviconIco: () => assets.icon192(),
		icon192: () => assets.icon192(),
		icon512: () => assets.icon512(),
		iconMaskable: () => assets.iconMaskable(),
		appleIcon: () => assets.appleIcon(),
		sw: () => assets.sw(),
		robots: () => assets.robots(),
		sitemap: () => assets.sitemap(),
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
			session.regenerateId(true);
			return go("/login");
		},
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
		buy: attempt("/home", (u, f) => act.addBuy(u.id, f)),
		setBalance: attempt("/profile", (u, f) => act.setBalance(u.id, f)),
		historyIncome: attempt("/history", (u, f) => act.addDayIncome(u.id, f)),
		deleteBuy: attempt("/home", (u, f) => act.deleteBuy(u.id, f)),
		addDebt: attempt("/debts", (u, f) => act.addDebt(u.id, f)),
		payDebt: attempt("/debts", (u, f) => act.payDebt(u.id, f)),
		clearDebt: attempt("/debts", (u, f) => act.clearDebt(u.id, f)),
		addNote: mutate("/notes", (u, f) => act.saveNote(u.id, f)),
		deleteNote: mutate("/notes", (u, f) => act.deleteNote(u.id, f)),
		addWish: attempt("/goals", (u, f) => act.addGoal(u.id, f)),
		buyWish: attempt("/goals", (u, f) => act.buyWish(u.id, f)),
		deleteWish: attempt("/goals", (u, f) => act.deleteWish(u.id, f)),
		addSource: attempt("/income", (u, f) => act.addSource(u.id, f)),
		addIncome: attempt("/income", (u, f) => act.addIncome(u.id, f)),
		deleteIncome: attempt("/income", (u, f) => act.deleteIncome(u.id, f)),
		toggleSource: attempt("/income", (u, f) => act.toggleSource(u.id, f)),
		deleteSource: attempt("/income", (u, f) => act.deleteSource(u.id, f)),
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
mkdir -p app/pages
cat > app/pages/screens.ts << '__EOF_MT__'
import { esc } from "../lib/html.ts";
import type { DayRow, DebtView, Goal, Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { fld, hd, ic, sec, tg, themeSwitch } from "../ui/parts.ts";
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
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off"><span class="mu">${unit}</span><button class="btn xs">${btn}</button>${flag === "data-addp" ? `<button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove this debt from ${esc(d.person)}? Use it for a mistake." aria-label="Remove debt">${ic("trash")}</button>` : ""}</div></form>`;
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
const bigAdd = (label: string, target = "", right = false) =>
	`<button type="button" class="addb${right ? " r" : ""}" data-bigadd${target ? ` data-for="${target}"` : ""} aria-label="${label}">${ic("plus")}</button>`;
const listCard = (wide: boolean, title: string, right: string, body: string, target: string, label: string) =>
	wide
		? `<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>${title}</span><span class="lb">${right}</span></div>${body}</div>${bigAdd(label, target, true)}</div>`
		: `<div class="cd bgc rgt"><div class="ct"><div class="tg">${title}</div><div class="cb">${body}</div></div>${bigAdd(label, target, true)}</div>`;
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
const roadChips = (s: State) =>
	[
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = roadChips(s);
	return `<div class="cd jarc"><i class="jar" style="width:${c.pct}%"></i><div class="jin"><div class="tg">Road to goals</div><div class="cb"><div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}</div></div></div>`;
};
const goalFold = (s: State, key: string) => {
	const c = calc(s);
	const chipHtml = roadChips(s);
	return `<div class="cd jarc"><i class="jar" style="width:${c.pct}%"></i><details class="dd jin" data-keep-open="${key}"><summary class="osum"><div class="tg0">Road to goals</div><div class="ow"><b class="big2">${c.pct}<small>%</small></b><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chev}</summary><div class="cb">${chipHtml ? `<div class="chips">${chipHtml}</div>` : '<div class="lb">Add a wish or a debt to start.</div>'}</div></details></div>`;
};
const goalLeft = (s: State, g: Goal) => (g.target ? (canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`) : "no price");
const addWishPanel = (s: State) =>
	`<form method="post" action="/goals" class="sf adp" data-adp hidden>${back(s)}<input class="in" name="name" data-name placeholder="What do you want?" autocomplete="off" required><input class="in" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;
const boughtBtn = (s: State, g: Goal) =>
	`<form method="post" action="/goals/buy" style="display:contents" data-confirm="Mark ${esc(g.title)} as bought? It will be added as a spend.">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="btn xs${canBuy(s, g) ? "" : " off"}"${canBuy(s, g) ? "" : " disabled"}>Bought</button></form>`;
const delWish = (s: State, g: Goal) =>
	`<form method="post" action="/goals/delete" style="display:contents" data-confirm="Delete ${esc(g.title)} from your wish list?">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="ub" aria-label="Delete ${esc(g.title)}">${ic("trash")}</button></form>`;
const wishRow = (s: State, g: Goal) =>
	`<div class="db"><div class="dn"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt s"><i style="width:${pctOf(s, g)}%"></i></div></div><span class="wb">${boughtBtn(s, g)}${delWish(s, g)}</span></div>`;
const wishList = (s: State) => s.goals.map((g) => wishRow(s, g)).join("") || '<div class="lb" style="padding:8px 0">Nothing on the list.</div>';
const wishTotal = (s: State) => `${fmt(s.goals.reduce((a, g) => a + g.target, 0))} ${cur(s)}`;
const wishesM = (s: State, open: boolean, key: string) =>
	`<div class="cd bgc">${bigAdd("Add wish")}<div class="ct"><details class="dd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">Wish list</div><div class="ow"><b class="big2">${s.goals.length}</b><span class="lb">${wishTotal(s)}</span></div>${chev}</summary><div class="cb">${wishList(s)}</div></details>${addWishPanel(s)}</div></div>`;
const wishD = (s: State) =>
	`<div class="sc bgc">${bigAdd("Add wish")}<div class="ct"><details data-keep-open="wish-page" open><summary class="sh"><span>Wish list</span><span class="rr"><span class="lb">${s.goals.length} · ${wishTotal(s)}</span>${chev}</span></summary>${wishList(s)}</details>${addWishPanel(s)}</div></div>`;
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
			const tag = !x.active ? "paused" : auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
			const fixed = srcAmount(x);
			const hid = (v: string) => `${back(s)}<input type="hidden" name="id" value="${v}">`;
			const del = `<form method="post" action="/income/source/delete" style="display:contents" data-confirm="Delete ${esc(x.name)}? What it already paid stays in your balance.">${hid(x.id)}<button class="ub" aria-label="Delete ${esc(x.name)}">${ic("trash")}</button></form>`;
			let main: string;
			if (!x.active) main = `<form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Resume</button></form>`;
			else if (auto)
				main = `<b class="ea">+${fmt(x.amount)}</b><form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Pause</button></form>`;
			else if (got.length)
				main = `<button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${hid(got[0]!.id)}<button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form>`;
			else if (fixed)
				main = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(fixed)}</button></form>`;
			else
				main = `<form method="post" action="/income/add" class="ln" style="gap:6px">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required><button class="btn xs o">Add</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div></div><span class="rt">${main}${del}</span></div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';
const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips" style="margin:10px 0 4px"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div><div class="lb" style="margin-bottom:2px">Manual: you tap it, once a day. Auto: added for you.</div>`;
const addSourceForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/income" id="${id}" class="${wide ? "sc" : "cd"} spf" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off"></div>${modeChips}<button class="btn full">Add source</button></form>`;
const todayLine = (s: State) => `<span class="tl">${calc(s).earned ? `+${fmt(calc(s).earned)} today · ${calc(s).earnedLine}` : "nothing earned today yet"}</span>`;
const incomeM = (s: State) => addSourceForm(s, false, "f-src-p") + listCard(false, `Sources${todayLine(s)}`, "", srcRows(s), "f-src-p", "Add source");
const incD = (s: State, title = "Income sources", id = "f-src-d") => addSourceForm(s, true, id) + listCard(true, title, `+${fmt(calc(s).earned)} today`, srcRows(s), id, "Add source");
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
const spendForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/buy" id="${id}" class="${wide ? "sc" : "cd"} spf" data-sp data-adp hidden>${back(s)}${nameChips(s.names)}<div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required></div><button class="btn full">Add a spend</button></form>`;
const buysCard = (s: State) => spendForm(s, false, "f-buy-m") + listCard(false, `Today's buys · ${s.buys.length}`, "", buyRows(s), "f-buy-m", "Add a spend");
const buysD = (s: State) => spendForm(s, true, "f-buy-d") + listCard(true, "Today's buys", `${s.buys.length}`, buyRows(s), "f-buy-d", "Add a spend");
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
const incRow = (s: State, i: Income) =>
`<div class="by"><div><div>${esc(i.source)}</div></div><span class="rt"><b class="ea">+${fmt(i.amount)}</b><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(i.amount)} from ${esc(i.source)}?">${back(s)}<input type="hidden" name="id" value="${i.id}"><button class="ub" aria-label="Undo income">${ic("undo")}</button></form></span></div>`;
const dayItems = (s: State, d: DayRow) =>
d.incomes.map((i) => incRow(s, i)).join("") +
d.buys.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : "", `−${fmt(b.total)}`)).join("");
const dayForms = (s: State, wide: boolean) => {
const t = today();
const date = `<input class="in" type="date" name="day" value="${t}" max="${t}" required>`;
const body =
`<form method="post" action="/buy">${back(s)}<div class="ln"><input class="in" name="label" placeholder="Item" autocomplete="off" required><input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required></div><div class="ln" style="margin-top:8px">${date}<button class="btn xs">Add buy</button></div></form>` +
`<form method="post" action="/history/income" style="margin-top:14px">${back(s)}<div class="ln"><input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required>${date}<button class="btn xs">Add income</button></div></form>`;
return wide ? sec("Add to any day", "", body) : tg("Add to any day", body);
};
const histM = (s: State) =>
err(s) +
dayForms(s, false) +
s.days
.map((d) =>
tg(
esc(d.label),
`<div class="l1"><span><span class="lb">Earned</span> <b class="ea">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${dayItems(s, d)}`,
),
)
.join("");
const histD = (s: State) => {
const e = s.days.reduce((a, d) => a + d.earned, 0);
const b = s.days.reduce((a, d) => a + d.bought, 0);
return sec(
"Last 30 days",
`+${fmt(e)} earned · −${fmt(b)} bought`,
'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="ea">+${fmt(d.earned)}</b><b class="sp">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b><div>${dayItems(s, d)}</div></div>`).join(""),
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
const plainBal = (s: State) => (s.balance / 100).toFixed(2).replace(/\.00$/, "");
const balanceForm = (s: State) =>
	`<form method="post" action="/profile/balance">${back(s)}<div class="fl"><label>Balance (${cur(s)})</label><input class="in f" name="balance" inputmode="decimal" value="${plainBal(s)}" autocomplete="off" required></div><button class="btn full" style="margin-top:14px">Update balance</button></form>`;
const profileM = (s: State) =>
	err(s) +
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div></div></div>` +
	balanceCard(s) +
	tg("Update balance", balanceForm(s)) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);
const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));
const settingsM = (s: State) =>
	err(s) +
	tg("Money & income", prefsForm(s)) +
	tg("Data", dataButtons) + '<div class="lb" style="text-align:center;margin:18px 0">Moneytracker v1.0 · stable</div>';
const settingsD = (s: State) =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	err(s) +
	`<div class="g3"><div>${sec("Balance", "", balanceForm(s))}${sec("Profile", "", profileForm(s, "/home"))}${sec(
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
const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 30 days</span></div>${err(s)}${dayForms(s, true)}${histD(s)}`;
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
		mobile: err(s) + balanceCard(s) + cardsM(s) + addSourceForm(s, false, "f-src-m") + listCard(false, `Income sources${todayLine(s)}`, "", srcRows(s), "f-src-m", "Add source") + buysCard(s) + goalFold(s, "goal") + wishesM(s, false, "wish") + oweM(s, false, "owe"),
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
	page({ ...base(s), title: "Goals", mobileTab: "goals", desktopTab: "plan", mobile: hd("Goals", "wishes + debts") + err(s) + goalM(s) + wishesM(s, true, "wish-page") + debtsM(s), desktop: err(s) + planD(s) });
export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "home", desktopTab: "plan", mobile: err(s) + hd("Income", `+${fmt(calc(s).earned)} today`) + incomeM(s), desktop: err(s) + planD(s) });
export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 30 days") + histM(s), desktop: historyD(s) });
export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });
export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });
export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
__EOF_MT__
