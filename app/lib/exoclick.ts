import { sql } from "remix/data-table"
import { db, incomes, incomeSources, users } from "../db/index.ts"
import { decryptSecret } from "./secret.ts"
import { extKey, parseJson, type Json } from "./sources/index.ts"
import { addDays, dayOf } from "./time.ts"

const BASE = "https://api.exoclick.com/v2"
const EVERY = 4 * 60000
const RESET_HOUR = 5
export const exoDay = (ms: number) => dayOf(ms - RESET_HOUR * 3600000)
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
const stale = !todayRow || now - (Number(todayRow.meta.fetched_at) || 0) > EVERY
if (!gap && !stale) return
if ((lastTry.get(s.id) ?? 0) + EVERY > now) return
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
const now = Date.now()
const t = exoDay(now)
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

export async function liveExo(uid: string, ids: string[], rate: number): Promise<Record<string, { day: string; usd: number; mad: number }>> {
const out: Record<string, { day: string; usd: number; mad: number }> = {}
if (!ids.length) return out
const day = exoDay(Date.now())
for (const id of ids) {
const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(id, day) } })
const usd = row?.usd_minor || 0
out[id] = { day, usd, mad: Math.round((usd * rate) / 100) }
}
return out
}
