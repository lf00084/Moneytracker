#!/usr/bin/env bash
set -e
cd "${1:-.}"
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder: bash file7.sh"; exit 1; fi
bk(){ for f in "$@"; do if [ -f "$f" ]; then mkdir -p ".mt_backup/file7/$(dirname "$f")"; [ -e ".mt_backup/file7/$f" ] || cp "$f" ".mt_backup/file7/$f"; fi; done; }
bk app/client/app.css app/client/app.js app/commands.ts app/components/income.tsx app/components/profile.tsx app/db/tables.ts app/lib/data.ts app/lib/sources/index.ts app/lib/users.ts app/lib/view.ts app/loaders/index.ts app/routes.ts database/schema.sql scripts/migrate.ts
mkdir -p app/lib/sources app/components
cat > app/lib/secret.ts << '__EOF_MT__'
import { env } from "../env.ts"
const enc = new TextEncoder()
const dec = new TextDecoder()
let cached: { s: string; k: CryptoKey } | null = null
const b64 = (u: Uint8Array) => btoa(String.fromCharCode(...u))
const unb64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))
async function key() {
if (cached && cached.s === env.SESSION_SECRET) return cached.k
const base = await crypto.subtle.importKey("raw", enc.encode(env.SESSION_SECRET), "PBKDF2", false, ["deriveKey"])
const k = await crypto.subtle.deriveKey({ name: "PBKDF2", salt: enc.encode("moneytracker-secret-v1"), iterations: 100000, hash: "SHA-256" }, base, { name: "AES-GCM", length: 256 }, false, ["encrypt", "decrypt"])
cached = { s: env.SESSION_SECRET, k }
return k
}
export async function encryptSecret(plain: string): Promise<string> {
const iv = crypto.getRandomValues(new Uint8Array(12))
const ct = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv }, await key(), enc.encode(plain)))
return `v1.${b64(iv)}.${b64(ct)}`
}
export async function decryptSecret(v: string): Promise<string | null> {
try {
const [p, i, c] = v.split(".")
if (p !== "v1" || !i || !c) return null
return dec.decode(await crypto.subtle.decrypt({ name: "AES-GCM", iv: unb64(i) }, await key(), unb64(c)))
} catch {
return null
}
}
__EOF_MT__
cat > app/lib/exoclick.ts << '__EOF_MT__'
import { sql } from "remix/data-table"
import { db, incomes, incomeSources, users } from "../db/index.ts"
import { decryptSecret } from "./secret.ts"
import { extKey, parseJson, type Json } from "./sources/index.ts"
import { addDays, dayOf, today } from "./time.ts"

const BASE = "https://api.exoclick.com/v2"
const tokens = new Map<string, { t: string; exp: number }>()
const lastTry = new Map<string, number>()
const errors = new Map<string, string>()
type Day = { usd: number; imp: number; clicks: number }

const jf = async (url: string, init: RequestInit) => {
const c = new AbortController()
const id = setTimeout(() => c.abort(), 8000)
try {
return await fetch(url, { ...init, signal: c.signal })
} finally {
clearTimeout(id)
}
}
const login = async (apiKey: string): Promise<string | null> => {
const hit = tokens.get(apiKey)
if (hit && hit.exp > Date.now()) return hit.t
const r = await jf(`${BASE}/login`, { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify({ api_token: apiKey }) })
if (!r.ok) return null
const b: any = await r.json().catch(() => null)
const t = b?.token ?? b?.session_token ?? b?.access_token ?? b?.session_key ?? b?.key
if (!t) return null
tokens.set(apiKey, { t: String(t), exp: Date.now() + 14 * 60000 })
return String(t)
}
const call = (token: string, from: string, to: string) =>
jf(`${BASE}/statistics/p/date?date_from=${from}&date_to=${to}`, { headers: { Authorization: `Bearer ${token}`, Accept: "application/json" } })
const listOf = (b: any): any[] => (Array.isArray(b?.result) ? b.result : Array.isArray(b?.data) ? b.data : Array.isArray(b) ? b : [])
const cents = (v: unknown) => Math.round((Number(v) || 0) * 100)
const revOf = (r: any) => cents(r.revenue ?? r.earnings ?? r.money ?? r.publisher_revenue ?? 0)
const dateOf = (r: any) => {
const d = String(r.date ?? r.ddate ?? r.day ?? r.d ?? "")
return /^\d{4}-\d{2}-\d{2}/.test(d) ? d.slice(0, 10) : ""
}
const add = (m: Map<string, Day>, d: string, r: any) => {
const x = m.get(d) ?? { usd: 0, imp: 0, clicks: 0 }
x.usd += revOf(r)
x.imp += Number(r.impressions ?? r.views ?? r.imp ?? 0) || 0
x.clicks += Number(r.clicks ?? r.click ?? 0) || 0
m.set(d, x)
}

export async function fetchDays(apiKey: string, from: string, to: string): Promise<Map<string, Day> | string> {
try {
let token = await login(apiKey)
if (!token) return "ExoClick rejected the API key"
let r = await call(token, from, to)
if (r.status === 401 || r.status === 403) {
tokens.delete(apiKey)
token = await login(apiKey)
if (!token) return "ExoClick rejected the API key"
r = await call(token, from, to)
}
if (!r.ok) return `ExoClick error ${r.status}`
const out = new Map<string, Day>()
for (const row of listOf(await r.json().catch(() => null))) {
const d = dateOf(row)
if (d) add(out, d, row)
}
return out
} catch {
return "Could not reach ExoClick"
}
}

const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []))
const col = (r: any, n: string, i: number) => r[n] ?? r[i]

async function settleOne(uid: string, s: { id: string; config: string; created_at: number }, rate: number, t: string, now: number) {
const cfg = parseJson(s.config)
const enc = String(cfg.key_enc ?? "")
if (!enc) return
const apiKey = await decryptSecret(enc)
if (!apiKey) return
const y = addDays(t, -1)
const checked = String(cfg.checked ?? "")
const floor = addDays(t, -31)
let from = checked ? addDays(checked, 1) : dayOf(s.created_at)
if (from < floor) from = floor
const gap = from <= y
const res = rowsOf(await db.exec(sql`select id, day, usd_minor, meta from incomes where user_id = ${uid} and source_id = ${s.id} and day >= ${from}`))
const have = new Map<string, { id: string; usd: number; meta: Json }>()
for (const r of res) have.set(String(col(r, "day", 1)), { id: String(col(r, "id", 0)), usd: Number(col(r, "usd_minor", 2)) || 0, meta: parseJson(String(col(r, "meta", 3))) })
const todayRow = have.get(t)
const stale = !todayRow || now - (Number(todayRow.meta.fetched_at) || 0) > 45000
if (!gap && !stale) return
if ((lastTry.get(s.id) ?? 0) + 20000 > now) return
lastTry.set(s.id, now)
const data = await fetchDays(apiKey, from, t)
if (typeof data === "string") {
errors.set(s.id, data)
return
}
errors.delete(s.id)
const days = new Set<string>([...data.keys(), t])
for (const [d, r] of have) if (d < t && r.meta.final !== 1) days.add(d)
for (const d of days) {
const ex = have.get(d)
if (ex && ex.meta.final === 1) continue
const got = data.get(d)
const usd = got ? got.usd : (ex?.usd ?? 0)
const final = d < t
if (!ex && final && usd === 0) continue
const values = {
usd_minor: usd,
amount_minor: final ? Math.round((usd * rate) / 100) : 0,
meta: JSON.stringify({ final: final ? 1 : 0, rate_minor: rate, fetched_at: now, imp: got?.imp ?? 0, clicks: got?.clicks ?? 0 }),
}
if (ex) await db.update(incomes, ex.id, values)
else {
try {
await db.create(incomes, { id: crypto.randomUUID(), user_id: uid, source_id: s.id, day: d, created_at: now, ext_key: extKey(s.id, d), ...values })
} catch {}
}
}
if (gap) await db.update(incomeSources, s.id, { config: JSON.stringify({ ...cfg, checked: y }) })
}

export async function settleExo(uid: string): Promise<void> {
const all = await db.findMany(incomeSources, { where: { user_id: uid, type: "exoclick" } })
const srcs = all.filter((s) => s.active !== 0)
if (!srcs.length) return
const u = await db.find(users, uid)
const rate = u?.usd_rate_minor || 1000
const t = today()
const now = Date.now()
for (const s of srcs) {
try {
await settleOne(uid, s, rate, t, now)
} catch {
errors.set(s.id, "Could not sync ExoClick")
}
}
}

export async function exoStatus(list: { id: string; type: string; config: Json }[]): Promise<Record<string, string>> {
const out: Record<string, string> = {}
for (const x of list) {
if (x.type !== "exoclick") continue
const enc = String(x.config.key_enc ?? "")
out[x.id] = !enc ? "Set your API key" : !(await decryptSecret(enc)) ? "Session secret changed. Set the API key again" : (errors.get(x.id) ?? "")
}
return out
}
__EOF_MT__
cat > app/lib/income.ts << '__EOF_MT__'
import { db, incomes, incomeSources } from "../db/index.ts"
import { toMinor } from "./money.ts"
import { encryptSecret } from "./secret.ts"
import { extKey, parseJson } from "./sources/index.ts"
import { today } from "./time.ts"

const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max)
const isFixed = (t: string) => t === "job" || t === "fixed"

export async function addSource(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("name"), 80)
if (!name) return "Enter a name"
const kind = text(f.get("kind"), 12) || "fixed"
const taken = await db.findMany(incomeSources, { where: { user_id: uid } })
if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`
let type = "manual"
let mode = "manual"
let every = ""
let amount = 0
let currency = "MAD"
let config: Record<string, number | string> = {}
if (kind === "fixed") {
const fixed = toMinor(f.get("fixed"))
const rate = toMinor(f.get("rate"))
if (!fixed) return "Enter the fixed amount per day"
if (!rate) return "Enter the price per extra hour"
type = "fixed"
config = { fixed_minor: fixed, rate_minor: rate }
} else if (kind === "daily" || kind === "monthly") {
amount = toMinor(f.get("amount"))
if (!amount) return "Enter how much it pays"
mode = "auto"
every = kind === "daily" ? "day" : "month"
} else if (kind === "exoclick") {
const k = text(f.get("api_key"), 200)
if (!k) return "Enter your ExoClick API key"
type = "exoclick"
mode = "auto"
every = "day"
currency = "USD"
config = { key_enc: await encryptSecret(k) }
} else if (kind !== "manual") return "Pick a source type"
const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] })
await db.create(incomeSources, { id: crypto.randomUUID(), user_id: uid, name, mode, amount_minor: amount, every, created_at: Date.now(), type, config: JSON.stringify(config), currency, active: 1, sort: (last?.sort ?? -1) + 1 })
}

export async function editSource(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } })
if (!s) return "Unknown source"
const name = text(f.get("name"), 80)
if (!name) return "Enter a name"
const taken = await db.findMany(incomeSources, { where: { user_id: uid } })
if (taken.some((x) => x.id !== s.id && x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`
const cfg = parseJson(s.config)
const patch: { name: string; config?: string; amount_minor?: number } = { name }
if (isFixed(s.type)) {
const fixed = toMinor(f.get("fixed"))
const rate = toMinor(f.get("rate"))
if (!fixed) return "Enter the fixed amount per day"
if (!rate) return "Enter the price per extra hour"
patch.config = JSON.stringify({ ...cfg, fixed_minor: fixed, rate_minor: rate })
} else if (s.type === "exoclick") {
const k = text(f.get("api_key"), 200)
if (k) patch.config = JSON.stringify({ ...cfg, key_enc: await encryptSecret(k) })
} else if (s.mode === "auto") {
const a = toMinor(f.get("amount"))
if (!a) return "Enter how much it pays"
patch.amount_minor = a
}
await db.update(incomeSources, s.id, patch)
}

export async function setHours(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } })
if (!s || !isFixed(s.type)) return "Unknown source"
const raw = text(f.get("hours"), 8).replace(",", ".")
let h = raw === "" ? 0 : Number(raw)
if (!Number.isFinite(h) || h < 0 || h > 24) return "Hours must be between 0 and 24"
h = Math.round(h * 100) / 100
const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, today()) } })
if (!row) return `Add ${s.name} first`
const meta = parseJson(row.meta)
const cfg = parseJson(s.config)
if (f.get("toggle") && Number(meta.hours) === h) h = 0
const fixed = Number(meta.fixed_minor) || Number(cfg.fixed_minor) || 0
const rate = Number(cfg.rate_minor) || 0
await db.update(incomes, row.id, { amount_minor: fixed + Math.round(h * rate), meta: JSON.stringify({ ...meta, fixed_minor: fixed, hours: h, rate_minor: rate }) })
}

export async function addNamed(uid: string, f: FormData): Promise<string | void> {
const amount = toMinor(f.get("amount"))
if (!amount) return "Enter an amount"
const label = text(f.get("label"), 60)
await db.create(incomes, { id: crypto.randomUUID(), user_id: uid, amount_minor: amount, day: today(), created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: "" })
}
__EOF_MT__
cat > app/lib/sources/exoclick.ts << '__EOF_MT__'
import type { SourceType } from "./types.ts"
export const exoclick: SourceType = {
key: "exoclick",
label: "ExoClick",
auto: true,
keyed: true,
fields: [],
dayFields: [],
parseConfig: () => ({}),
entry: () => "ExoClick income is added automatically",
}
__EOF_MT__
cat > app/components/income.tsx << '__EOF_MT__'
import type { Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { calc, gotToday, isFixed, plain, srcAmount } from "../lib/view.ts";
import { Icon } from "./Icon.tsx";
import { Back, Empty, ExpandCard, ListCard, NameChips } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };
const rateOf = (x: Source) => Number(x.config.rate_minor) || 0;
const tagOf = (x: Source) => (!x.active ? "paused" : x.type === "exoclick" ? "exoclick" : isFixed(x.type) ? "fixed" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "daily") : "manual");
const usdTxt = (n: number) => `$${fmt(n)}`;
const exoSub = (s: State, x: Source) => {
	const st = s.exo[x.id];
	const usd = s.exoToday[x.id];
	if (st) return st;
	if (usd === undefined) return "syncing...";
	return `≈ ${fmt(Math.round((usd * s.user.usd_rate_minor) / 100))} ${s.user.currency} when the day ends`;
};

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
));

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`incl. ${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">+{fmt(i.amount)}</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<button class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
));

const HoursPanel = view<{ s: State; x: Source; row: Income }>(({ s, x, row }) => {
	const rate = rateOf(x);
	const h = row.hours;
	const opts = [1, 2, 3, 4];
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`} open={h ? undefined : true}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))}` : `${fmt(rate)} / hour`}</span>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hxb">
				<div class="hxg">
					{opts.map((n) => (
						<form key={n} method="post" action="/income/hours" style={contents}>
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input type="hidden" name="hours" value={String(n)} />
							<input type="hidden" name="toggle" value="1" />
							<button class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</button>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<button class="btn xs o">Set</button>
					<button type="button" class="btn xs o" data-close>
						Close
					</button>
				</form>
			</div>
		</details>
	);
});

const SourceMain = view<{ s: State; x: Source; toggle: boolean }>(({ s, x, toggle }) => {
	const got = gotToday(s, x);
	const sum = got.reduce((a, i) => a + i.amount, 0);
	const fixed = srcAmount(x);
	if (toggle && !x.active) {
		return (
			<form method="post" action="/income/toggle" style={contents}>
				<Hid s={s} id={x.id} />
				<button class="btn xs o">Resume</button>
			</form>
		);
	}
	if (x.type === "exoclick") {
		const usd = s.exoToday[x.id];
		return (
			<>
				{usd !== undefined ? <b class="ea">{usdTxt(usd)}</b> : null}
				{s.exo[x.id] ? (
					<a class="btn xs o" href="/income">
						Fix
					</a>
				) : null}
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		);
	}
	if (x.mode === "auto") {
		return (
			<>
				<b class="ea">+{fmt(x.amount)}</b>
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		);
	}
	if (got.length) {
		return (
			<>
				<b class="ea">+{fmt(sum)}</b>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		);
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o">Add {fmt(fixed)}</button>
			</form>
		);
	}
	return (
		<form method="post" action="/income/add" class="ln" style={{ gap: "6px" }}>
			<Back s={s} />
			<input type="hidden" name="source_id" value={x.id} />
			<input class="in pr2" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs o">Add</button>
		</form>
	);
});

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
));

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type);
	const got = fixedSrc ? gotToday(s, x)[0] : undefined;
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} + ${fmt(rateOf(x))} / hour`) : "";
	return (
		<div class="sw">
			<div class="rw">
				<div>
					<div>{x.name}</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle={false} />
				</span>
			</div>
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	);
});

const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<button class="btn full">Add income</button>
	</>
));

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
	["exoclick", "ExoClick"],
];

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<input class="in" name="name" placeholder="Source name (e.g. Construction)" autocomplete="off" required />
		<input type="hidden" name="kind" value="fixed" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 8px" }}>
			{KINDS.map(([k, l]) => (
				<span key={k} class={k === "fixed" ? "chip on" : "chip"} data-mode={k} style={{ cursor: "pointer" }}>
					{l}
				</span>
			))}
		</div>
		<div class="kf kf-fixed">
			<div class="ln">
				<input class="in" name="fixed" placeholder="Per day" inputmode="decimal" autocomplete="off" />
				<input class="in" name="rate" placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
			</div>
			<div class="lb">Tap it once a day on Home, then pick the extra hours.</div>
		</div>
		<div class="kf kf-manual">
			<div class="lb">You type the amount yourself each day.</div>
		</div>
		<div class="kf kf-daily kf-monthly">
			<input class="in" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
			<div class="lb">Added for you automatically.</div>
		</div>
		<div class="kf kf-exoclick">
			<input class="in" name="api_key" type="password" placeholder="ExoClick API key" autocomplete="off" />
			<div class="lb">Saved encrypted. Counted in USD during the day, converted to {s.user.currency} when the day ends.</div>
		</div>
		<button class="btn full">Add source</button>
	</>
));

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-kind="fixed" data-adp hidden>
		<SourceFields s={s} />
	</form>
));

export const IncomeDesktop = view<{ s: State; title?: string; id?: string }>(({ s, title = "Income today", id = "f-inc-d" }) => {
	const sources = s.sources.filter((x) => x.active);
	const others = s.incomesToday.filter((i) => !i.sourceId);
	return (
		<>
			<form method="post" action="/income/named" id={id} class="sc spf" data-adp hidden>
				<NamedFields s={s} />
			</form>
			<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add manual income">
				{sources.length || others.length ? (
					<>
						{sources.map((x) => (
							<HomeRow key={x.id} s={s} x={x} />
						))}
						{others.map((i) => (
							<IncomeRow key={i.id} s={s} i={i} />
						))}
					</>
				) : (
					<Empty>No sources yet. Add one on the Income page.</Empty>
				)}
			</ListCard>
		</>
	);
});

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type);
	const fixed = srcAmount(x);
	const cur = s.user.currency;
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : "";
	return (
		<div class="dbw">
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{tagOf(x)}</span>
					</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">{x.active ? "Pause" : "Resume"}</button>
					</form>
					<button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}>
						<Icon name="edit" />
					</button>
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			<form method="post" action="/income/edit" class="ad" data-addp hidden>
				<Hid s={s} id={x.id} />
				<label>Edit {x.name}</label>
				<input class="in f" name="name" value={x.name} autocomplete="off" required />
				{fixedSrc ? (
					<div class="ln" style={{ marginTop: "8px" }}>
						<input class="in" name="fixed" value={fixed ? plain(fixed) : ""} placeholder="Per day" inputmode="decimal" autocomplete="off" />
						<input class="in" name="rate" value={rateOf(x) ? plain(rateOf(x)) : ""} placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
					</div>
				) : null}
				{x.type === "exoclick" ? <input class="in" style={{ marginTop: "8px" }} name="api_key" type="password" placeholder="New API key (leave empty to keep)" autocomplete="off" /> : null}
				{!fixedSrc && x.type !== "exoclick" && x.mode === "auto" ? <input class="in" style={{ marginTop: "8px" }} name="amount" value={plain(x.amount)} placeholder="Amount" inputmode="decimal" autocomplete="off" /> : null}
				<button class="btn xs" style={{ marginTop: "10px" }}>
					Save
				</button>
			</form>
		</div>
	);
});

export const IncomeExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="income"
		open
		title="Income sources"
		label="Add source"
		head={
			<>
				<b class="big2">{s.sources.length}</b>
				<span class="lb">{`${s.sources.filter((x) => x.active).length} active`}</span>
			</>
		}
		form={<SourceForm s={s} />}
	>
		{s.sources.length ? <>{s.sources.map((x) => <ManageRow key={x.id} s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>}
	</ExpandCard>
));

export const HomeIncome = view<{ s: State }>(({ s }) => {
	const c = calc(s);
	const sources = s.sources.filter((x) => x.active);
	const others = s.incomesToday.filter((i) => !i.sourceId);
	return (
		<ExpandCard
			storeKey="inc"
			open
			title="Income today"
			label="Add manual income"
			head={
				<>
					<b class="big2">
						+{fmt(c.earned)} <small>{s.user.currency}</small>
					</b>
					<span class="lb">{c.earnedLine}</span>
				</>
			}
			form={
				<form method="post" action="/income/named" class="sf xfm" data-adp hidden>
					<NamedFields s={s} />
				</form>
			}
		>
			{sources.length || others.length ? (
				<>
					{sources.map((x) => (
						<HomeRow key={x.id} s={s} x={x} />
					))}
					{others.map((i) => (
						<IncomeRow key={i.id} s={s} i={i} />
					))}
				</>
			) : (
				<Empty>No sources yet. Add one on the Income page.</Empty>
			)}
		</ExpandCard>
	);
});
__EOF_MT__
cat > .mt_file7.css << '__EOF_MT__'

/*file7*/
.sw{border-bottom:1px solid var(--ln)}
.sw:last-child{border:0}
.sw>.rw{border:0}
.hx{margin:0 0 12px;border:1px solid var(--ln);background:var(--bg);border-radius:14px;overflow:hidden}
.hx>summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 12px;list-style:none;cursor:pointer;font-size:12px;color:var(--mu);font-family:var(--mono)}
.hx>summary::-webkit-details-marker{display:none}
.hx>summary>span:nth-child(2){margin-left:auto;color:var(--earn)}
.hx[open]>summary .chev{transform:rotate(180deg)}
.hxb{padding:2px 12px 12px}
.hxg{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}
.hc{display:flex;flex-direction:column;align-items:center;gap:2px;padding:9px 4px;border-radius:12px}
.hc b{font-size:14px;color:var(--ink)}
.hc small{font-size:11px;font-family:var(--mono)}
.hc.on b{color:var(--ac)}
.hxm{display:flex;gap:8px;align-items:center;margin-top:10px}
.hxm .in{padding:9px 12px;font-size:14px}
.hxm .btn{flex:none}
.kf{display:none;margin-top:2px}
form[data-kind=fixed] .kf-fixed,form[data-kind=manual] .kf-manual,form[data-kind=daily] .kf-daily,form[data-kind=monthly] .kf-monthly,form[data-kind=exoclick] .kf-exoclick{display:block}
.kf .in{margin-bottom:8px}
.kf .ln .in{margin-bottom:8px}
.kf .lb{margin-bottom:10px}
.ad>.in{display:block;width:100%}
__EOF_MT__
cat > .mt_patch7.cjs << '__EOF_MT__'
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
__EOF_MT__
node .mt_patch7.cjs
rm -f .mt_patch7.cjs .mt_file7.css
echo "file7 done. Backups: .mt_backup/file7"
if [ -f .dev.vars ] && command -v bun >/dev/null 2>&1; then npm run db:migrate || echo "Migration failed. Run: npm run db:migrate"; else echo "Now run: npm run db:migrate   (adds incomes.usd_minor and users.usd_rate_minor, needed before the app starts)"; fi
