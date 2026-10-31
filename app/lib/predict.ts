import { sql } from "remix/data-table"
import { db, predictAccount, predictDays, predictMoves, users } from "../db/index.ts"
import { decryptSecret, encryptSecret } from "./crypto.ts"
import { toMinor } from "./money.ts"
import { today } from "./time.ts"
import { toMad } from "./trade-math.ts"
import { todayFor, type User } from "./users.ts"
import { id, rowsOf, text } from "./util.ts"

const BASE = "https://api.binance.com"
const EVERY = 3 * 60000
const RETRY = 20000
const lastTry = new Map<string, number>()

export type WalletMove = { id: string; kind: "buy" | "sell"; usdt: number; mad: number; day: string; at: number }
export type WalletDay = { day: string; profit: number; balance: number }
export type WalletView = {
	connected: boolean
	error: string
	usdt: number
	syncedAt: number
	rate: number
	valueMad: number
	today: number
	total: number
	boughtUsdt: number
	soldUsdt: number
	madSpent: number
	madGot: number
	days: WalletDay[]
	moves: WalletMove[]
}

const cents = (v: unknown) => Math.round((Number(v) || 0) * 100)

const col = (r: any, n: string, i: number) => r[n] ?? r[i]

const scalar = (r: unknown) => {
	const row = rowsOf(r)[0]
	return Number(row?.s ?? row?.[0] ?? 0) || 0
}

const hex = (b: ArrayBuffer) => Array.from(new Uint8Array(b), (x) => x.toString(16).padStart(2, "0")).join("")

async function sign(secret: string, query: string) {
	const enc = new TextEncoder()
	const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"])
	return hex(await crypto.subtle.sign("HMAC", key, enc.encode(query)))
}

async function call(apiKey: string, secret: string, path: string, params: Record<string, string> = {}): Promise<{ data: any } | { error: string }> {
	const query = new URLSearchParams({ ...params, recvWindow: "10000", timestamp: String(Date.now()) }).toString()
	const signature = await sign(secret, query)
	const c = new AbortController()
	const timer = setTimeout(() => c.abort(), 8000)
	try {
		const r = await fetch(`${BASE}${path}?${query}&signature=${signature}`, { headers: { "X-MBX-APIKEY": apiKey }, signal: c.signal })
		const body: any = await r.json().catch(() => null)
		if (!r.ok) return { error: String(body?.msg ?? `Binance error ${r.status}`).slice(0, 280) }
		return { data: body }
	} catch {
		return { error: "Could not reach Binance" }
	} finally {
		clearTimeout(timer)
	}
}

async function fetchWallet(apiKey: string, secret: string, known: string): Promise<{ usdt: number; wallet: string } | string> {
	let wallet = known
	if (!wallet) {
		const w = await call(apiKey, secret, "/sapi/v1/w3w/wallet/prediction/wallet/list")
		if ("error" in w) return w.error
		wallet = String(w.data?.wallets?.[0]?.walletAddress ?? "")
		if (!wallet) return "No prediction wallet found on this Binance account"
	}
	const p = await call(apiKey, secret, "/sapi/v1/w3w/wallet/prediction/position/list", { walletAddress: wallet, limit: "1" })
	if ("error" in p) return p.error
	const total = p.data?.summary?.totalValue
	if (total === undefined || total === null || !Number.isFinite(Number(total))) return "Binance did not return the wallet value"
	return { usdt: cents(total), wallet }
}

async function rebuild(uid: string) {
	const [days, moves] = await Promise.all([
		db.findMany(predictDays, { where: { user_id: uid }, orderBy: ["day", "asc"], limit: 800 }),
		db.findMany(predictMoves, { where: { user_id: uid }, limit: 5000 }),
	])
	let prevDay = ""
	let prevBal = 0
	for (const d of days) {
		const ms = moves.filter((m) => m.day <= d.day && (prevDay ? m.day > prevDay : m.day === d.day))
		const bought = ms.filter((m) => m.kind === "buy").reduce((a, m) => a + m.usdt_minor, 0)
		const sold = ms.filter((m) => m.kind === "sell").reduce((a, m) => a + m.usdt_minor, 0)
		const open = prevDay ? prevBal : d.balance_minor - bought + sold
		const profit = d.balance_minor - open - bought + sold
		if (d.open_minor !== open || d.bought_minor !== bought || d.sold_minor !== sold || d.profit_minor !== profit) {
			await db.update(predictDays, d.id, { open_minor: open, bought_minor: bought, sold_minor: sold, profit_minor: profit })
		}
		prevDay = d.day
		prevBal = d.balance_minor
	}
}

async function saveDay(uid: string, balance: number, now: number) {
	const t = await todayFor(uid)
	const key = `${uid}:${t}`
	const row = await db.find(predictDays, key)
	if (row) await db.update(predictDays, key, { balance_minor: balance, saved_at: now })
	else await db.create(predictDays, { id: key, user_id: uid, day: t, open_minor: 0, balance_minor: balance, bought_minor: 0, sold_minor: 0, profit_minor: 0, saved_at: now })
	await rebuild(uid)
}

export async function syncPredict(uid: string, force = false): Promise<void> {
	try {
		const a = await db.findOne(predictAccount, { where: { user_id: uid } })
		if (!a || !a.key_enc || !a.secret_enc) return
		const now = Date.now()
		if (!force && now - a.synced_at < EVERY) return
		if ((lastTry.get(uid) ?? 0) + RETRY > now) return
		lastTry.set(uid, now)
		const key = await decryptSecret(a.key_enc)
		const secret = await decryptSecret(a.secret_enc)
		if (!key || !secret) {
			await db.update(predictAccount, uid, { last_error: "Session secret changed. Save the API keys again", updated_at: now })
			return
		}
		const r = await fetchWallet(key, secret, a.wallet)
		if (typeof r === "string") {
			await db.update(predictAccount, uid, { last_error: r, updated_at: now })
			return
		}
		await db.update(predictAccount, uid, { wallet: r.wallet, usdt_minor: r.usdt, synced_at: now, last_error: "", updated_at: now })
		await saveDay(uid, r.usdt, now)
	} catch {}
}

export async function syncAllPredict(): Promise<void> {
	const rows = rowsOf(await db.exec(sql`select user_id as u from predict_account where key_enc <> ''`))
	for (const r of rows) {
		await syncPredict(String(col(r, "u", 0)), true)
	}
}

export async function predictTotal(uid: string): Promise<number> {
	const [a, u, r] = await Promise.all([
		db.findOne(predictAccount, { where: { user_id: uid } }),
		db.find(users, uid),
		db.exec(sql`select coalesce(sum(case when kind = 'buy' then 0 - mad_minor else mad_minor end), 0) as s from predict_moves where user_id = ${uid}`),
	])
	const rate = Number(u?.usdt_rate_minor) > 0 ? Number(u?.usdt_rate_minor) : 1100
	return scalar(r) + (a ? toMad(a.usdt_minor, rate) : 0)
}

export async function loadWallet(user: User): Promise<WalletView> {
	const uid = user.id
	await syncPredict(uid)
	const [a, days, moves] = await Promise.all([
		db.findOne(predictAccount, { where: { user_id: uid } }),
		db.findMany(predictDays, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 400 }),
		db.findMany(predictMoves, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 5000 }),
	])
	const t = today(user.day_start)
	const buys = moves.filter((m) => m.kind === "buy")
	const sells = moves.filter((m) => m.kind === "sell")
	const usdt = a?.usdt_minor ?? 0
	return {
		connected: !!a && !!a.key_enc,
		error: a?.last_error ?? "",
		usdt,
		syncedAt: a?.synced_at ?? 0,
		rate: user.usdt_rate,
		valueMad: toMad(usdt, user.usdt_rate),
		today: days.find((d) => d.day === t)?.profit_minor ?? 0,
		total: days.reduce((x, d) => x + d.profit_minor, 0),
		boughtUsdt: buys.reduce((x, m) => x + m.usdt_minor, 0),
		soldUsdt: sells.reduce((x, m) => x + m.usdt_minor, 0),
		madSpent: buys.reduce((x, m) => x + m.mad_minor, 0),
		madGot: sells.reduce((x, m) => x + m.mad_minor, 0),
		days: days.slice(0, 30).map((d) => ({ day: d.day, profit: d.profit_minor, balance: d.balance_minor })),
		moves: moves.slice(0, 30).map((m) => ({ id: m.id, kind: m.kind === "sell" ? "sell" : "buy", usdt: m.usdt_minor, mad: m.mad_minor, day: m.day, at: m.created_at })),
	}
}

export async function addMove(uid: string, f: FormData, kind: "buy" | "sell"): Promise<string | void> {
	const usdt = toMinor(f.get("usdt"))
	const mad = toMinor(f.get("mad"))
	if (!usdt) return "Enter how many USDT"
	if (!mad) return kind === "buy" ? "Enter how much MAD you paid" : "Enter how much MAD you got"
	await db.create(predictMoves, { id: id(), user_id: uid, kind, usdt_minor: usdt, mad_minor: mad, day: await todayFor(uid), created_at: Date.now() })
	await rebuild(uid)
}

export async function deleteMove(uid: string, f: FormData): Promise<string | void> {
	await db.deleteMany(predictMoves, { where: { id: text(f.get("id"), 36), user_id: uid } })
	await rebuild(uid)
}

export async function saveKeys(uid: string, f: FormData): Promise<string | void> {
	const key = text(f.get("api_key"), 200)
	const secret = text(f.get("api_secret"), 200)
	if (!key || !secret) return "Enter the API key and the secret"
	const now = Date.now()
	const row = { key_enc: await encryptSecret(key), secret_enc: await encryptSecret(secret), wallet: "", last_error: "", synced_at: 0, updated_at: now }
	const had = await db.findOne(predictAccount, { where: { user_id: uid } })
	if (had) await db.update(predictAccount, uid, row)
	else await db.create(predictAccount, { user_id: uid, usdt_minor: 0, ...row })
	lastTry.delete(uid)
	await syncPredict(uid, true)
	const a = await db.findOne(predictAccount, { where: { user_id: uid } })
	if (a?.last_error) return a.last_error
}

export async function syncNow(uid: string): Promise<string | void> {
	lastTry.delete(uid)
	await syncPredict(uid, true)
	const a = await db.findOne(predictAccount, { where: { user_id: uid } })
	if (a?.last_error) return a.last_error
}

export async function forgetKeys(uid: string): Promise<string | void> {
	await db.deleteMany(predictAccount, { where: { user_id: uid } })
}
