#!/usr/bin/env bash
# file21.sh - trading plan, day reset at 5, pad order, balance icons, pad edit/menu, shared Submit spinner.
# Run from the Moneytracker project root. Installs nothing.
set -e
[ -f app/lib/trading.ts ] || { echo "Run this inside the Moneytracker folder"; exit 1; }

mkdir -p "$(dirname app/lib/trade-math.ts)"
cat > app/lib/trade-math.ts <<'GOAT_EOF'
export const BTC_STAKE = 800
export const BTC_ROUNDS = 2
export const PRED_STAKE = 400
export const PRED_COUNT = 2
export const DEPOSIT = BTC_STAKE * BTC_ROUNDS + PRED_STAKE * PRED_COUNT
export const PICKS: [string, number][] = [
	["BTC", 5],
	["ETH", 5],
]

export type Game = "btc" | "pred"
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number; state: "set" | "done"; asset: string; tf: number }
export type TradeSession = {
	id: string
	day: string
	deposit: number
	rate: number
	status: "open" | "settled"
	pnl: number
	returnUsdt: number
	returnMad: number
	at: number
	results: TradeResult[]
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const btcOf = (r: TradeResult[]) => r.filter((x) => x.game === "btc").sort((a, b) => a.idx - b.idx)
export const predOf = (r: TradeResult[]) => r.filter((x) => x.game === "pred").sort((a, b) => a.idx - b.idx)
export const btcWon = (r: TradeResult[]) => btcOf(r).some((x) => isDone(x) && x.won)
export const btcDone = (r: TradeResult[]) => btcWon(r) || doneOf(btcOf(r)).length >= BTC_ROUNDS
const predDone = (r: TradeResult[]) => doneOf(predOf(r)).length >= PRED_COUNT
export const allDone = (r: TradeResult[]) => btcDone(r) && predDone(r)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const missAmount = (game: Game) => (game === "btc" ? BTC_STAKE : PRED_STAKE)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const strip = (r: TradeResult[]) => doneOf(r).map((x) => (x.won ? "W" : "M")).join(" ")
GOAT_EOF
echo "updated app/lib/trade-math.ts"

mkdir -p "$(dirname app/lib/trading.ts)"
cat > app/lib/trading.ts <<'GOAT_EOF'
import { sql } from "remix/data-table"
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts"
import { today } from "./time.ts"
import { todayFor } from "./users.ts"
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcOf,
	DEPOSIT,
	doneOf,
	isDone,
	missAmount,
	PICKS,
	PRED_COUNT,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "./trade-math.ts"
import type { User } from "./users.ts"
import { id, text } from "./util.ts"

const usdtMinor = (v: unknown) => {
	const raw = String(v ?? "").trim().replace(",", ".")
	if (!raw) return null
	const n = Math.abs(Number(raw))
	return Number.isFinite(n) && n <= 100000 ? Math.round(n * 100) : null
}

const toResult = (r: { id: string; game: string; idx: number; won: number; pnl_minor: number; state: string; asset: string; tf: number }): TradeResult => ({
	id: r.id,
	game: r.game === "pred" ? "pred" : "btc",
	idx: r.idx,
	won: r.won !== 0,
	pnl: r.pnl_minor,
	state: r.state === "set" ? "set" : "done",
	asset: r.asset || "",
	tf: r.tf || 0,
})

async function resultsOf(uid: string, sessionId: string): Promise<TradeResult[]> {
	const rows = await db.findMany(tradeResults, { where: { user_id: uid, session_id: sessionId }, orderBy: ["created_at", "asc"] })
	return rows.map(toResult)
}

export async function loadTrades(uid: string): Promise<TradeSession[]> {
	const rows = await db.findMany(tradeSessions, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 30 })
	if (!rows.length) return []
	const res = await db.findMany(tradeResults, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 })
	const by = new Map<string, TradeResult[]>()
	for (const r of res) {
		const list = by.get(r.session_id) ?? []
		list.push(toResult(r))
		by.set(r.session_id, list)
	}
	return rows.map(
		(s): TradeSession => ({
			id: s.id,
			day: s.day,
			deposit: s.deposit_minor,
			rate: s.rate_minor,
			status: s.status === "settled" ? "settled" : "open",
			pnl: s.pnl_minor ?? 0,
			returnUsdt: s.return_usdt_minor ?? 0,
			returnMad: s.return_mad_minor ?? 0,
			at: s.created_at,
			results: (by.get(s.id) ?? []).sort((a, b) => (a.game === b.game ? a.idx - b.idx : a.game === "btc" ? -1 : 1)),
		}),
	)
}

export async function startTrade(user: User): Promise<string | void> {
	const uid = user.id
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open trade first"
	const day = today(user.day_start)
	const already = await db.findOne(tradeSessions, { where: { user_id: uid, day } })
	if (already) return `One trade a day. The next one opens at ${String(user.day_start).padStart(2, "0")}:00`
	const cost = toMad(DEPOSIT, user.usdt_rate)
	if (!cost) return "Set the USDT price in Settings first"
	const now = Date.now()
	const sessionId = id()
	const purchaseId = id()
	await db.transaction(async (tx) => {
		await tx.create(purchases, {
			id: purchaseId,
			user_id: uid,
			name: `Deposit ${DEPOSIT / 100} USDT`,
			qty: 1,
			unit_minor: cost,
			total_minor: cost,
			day,
			created_at: now,
		})
		await tx.create(tradeSessions, {
			id: sessionId,
			user_id: uid,
			day,
			deposit_minor: DEPOSIT,
			rate_minor: user.usdt_rate,
			purchase_id: purchaseId,
			status: "open",
			pnl_minor: 0,
			return_usdt_minor: 0,
			return_mad_minor: 0,
			created_at: now,
		})
	})
}

async function settle(uid: string, s: { id: string; deposit_minor: number; rate_minor: number }, results: TradeResult[]) {
	const pnl = totalPnl(results)
	const back = backUsdt(s.deposit_minor, pnl)
	const mad = toMad(back, s.rate_minor)
	const now = Date.now()
	const t = await todayFor(uid)
	const incomeId = mad > 0 ? id() : ""
	await db.transaction(async (tx) => {
		if (mad > 0) {
			await tx.create(incomes, {
				id: incomeId,
				user_id: uid,
				amount_minor: mad,
				day: t,
				created_at: now,
				meta: JSON.stringify({ trade: 1, name: "Trading", usdt_minor: back }),
				ext_key: `trade:${s.id}`,
			})
		}
		await tx.update(tradeSessions, s.id, {
			status: "settled",
			pnl_minor: pnl,
			return_usdt_minor: back,
			return_mad_minor: mad,
			income_id: incomeId,
			settled_at: now,
		})
	})
}

export async function setPredict(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const game: Game = f.get("game") === "pred" ? "pred" : "btc"
	const idx = Math.floor(Number(f.get("idx")))
	const max = game === "btc" ? BTC_ROUNDS : PRED_COUNT
	if (!Number.isInteger(idx) || idx < 1 || idx > max) return "Unknown predict"
	let asset = ""
	let tf = 0
	if (game === "btc") {
		const [a, t] = text(f.get("pick"), 8).split("-")
		const ok = PICKS.some(([pa, pt]) => pa === a && pt === Number(t))
		if (!ok) return "Pick BTC or ETH and 5 or 15 minutes"
		asset = a!
		tf = Number(t)
	}
	const rows = await resultsOf(uid, s.id)
	if (rows.some((r) => r.game === game && r.idx === idx)) return "That predict is already set"
	if (game === "btc") {
		if (btcDone(rows)) return "The up or down predicts are finished"
		if (btcOf(rows).some((r) => !isDone(r))) return "Wait for the result of the last predict first"
		if (idx !== btcOf(rows).length + 1) return "Do the predicts in order"
	}
	await db.create(tradeResults, { id: id(), user_id: uid, session_id: s.id, game, idx, won: 0, pnl_minor: 0, state: "set", asset, tf, created_at: Date.now() })
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const game: Game = f.get("game") === "pred" ? "pred" : "btc"
	const idx = Math.floor(Number(f.get("idx")))
	const outcome = text(f.get("outcome"), 4)
	if (outcome !== "win" && outcome !== "miss") return "Pick Win or Miss"
	const rows = await resultsOf(uid, s.id)
	const cur = rows.find((r) => r.game === game && r.idx === idx)
	if (!cur || isDone(cur)) return "Set this predict first"
	const won = outcome === "win"
	let pnl = 0
	if (won) {
		const amount = usdtMinor(f.get("pnl"))
		if (!amount) return "Enter the PnL in USDT"
		pnl = amount
	} else {
		pnl = -missAmount(game)
	}
	await db.update(tradeResults, cur.id, { state: "done", won: won ? 1 : 0, pnl_minor: pnl })
	const next = rows.map((r): TradeResult => (r.id === cur.id ? { ...r, state: "done", won, pnl } : r))
	if (allDone(next)) await settle(uid, s, next)
}

export async function undoResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const r = await db.findOne(tradeResults, { where: { id: text(f.get("result_id"), 36), session_id: s.id, user_id: uid } })
	if (!r) return
	if (r.game === "btc") {
		const last = btcOf(await resultsOf(uid, s.id)).at(-1)
		if (last?.id !== r.id) return "Undo the latest predict first"
	}
	if (r.state === "set") await db.deleteMany(tradeResults, { where: { id: r.id, user_id: uid } })
	else await db.update(tradeResults, r.id, { state: "set", won: 0, pnl_minor: 0 })
}

export async function finishTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const rows = await resultsOf(uid, s.id)
	const done = doneOf(rows)
	if (!done.length) return "Add at least one result first"
	await db.deleteMany(tradeResults, { where: { session_id: s.id, user_id: uid, state: "set" } })
	await settle(uid, s, done)
}

export async function reopenTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s || s.status !== "settled") return
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open trade first"
	const key = `trade:${s.id}`
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key = ${key}`)
		await tx.exec(
			sql`update trade_sessions set status = 'open', income_id = '', settled_at = null, pnl_minor = 0, return_usdt_minor = 0, return_mad_minor = 0 where id = ${s.id} and user_id = ${uid}`,
		)
	})
}
GOAT_EOF
echo "updated app/lib/trading.ts"

mkdir -p "$(dirname app/lib/users.ts)"
cat > app/lib/users.ts <<'GOAT_EOF'
import { db, oauthAccounts, passwords, userImages, users } from "../db/index.ts"
import { fakeVerify, hashPassword, verifyPassword } from "./crypto.ts"
import { today } from "./time.ts"
import { id } from "./util.ts"

export type User = {
	id: string
	email: string
	name: string
	currency: string
	theme: string
	run_at: string
	day_start: number
	week_start: string
	usd_rate_minor: number
	usdt_rate: number
}

const normEmail = (e: string) => e.trim().toLowerCase()
const toUser = (r: any): User => ({
	id: r.id,
	email: r.email,
	name: r.name,
	currency: r.currency || "MAD",
	theme: r.theme || "dark",
	run_at: r.run_at || "06:00",
	day_start: Number.isInteger(r.day_start) && r.day_start >= 0 && r.day_start <= 23 ? r.day_start : 5,
	week_start: r.week_start || "Monday",
	usd_rate_minor: r.usd_rate_minor || 1000,
	usdt_rate: Number(r.usdt_rate_minor) > 0 ? Number(r.usdt_rate_minor) : 1100,
})

export async function getUserById(id: string): Promise<User | null> {
	const row = await db.find(users, id)
	return row ? toUser(row) : null
}

const newUserRow = (id: string, email: string, name: string, verified: number, now: number) => ({
	id,
	email,
	name: name || email.split("@")[0]!,
	email_verified: verified,
	currency: "MAD",
	theme: "dark",
	run_at: "06:00",
	day_start: 5,
	week_start: "Monday",
	usdt_rate_minor: 1100,
	created_at: now,
	updated_at: now,
})

type SignUpResult = { ok: true; user: User } | { ok: false; error: string }

export async function signUpWithPassword(input: { name: string; email: string; password: string }): Promise<SignUpResult> {
	const email = normEmail(input.email)
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return { ok: false, error: "Enter a valid email." }
	if (input.password.length < 8) return { ok: false, error: "Password needs at least 8 characters." }
	if (input.password.length > 200) return { ok: false, error: "Password is too long." }
	if (await db.findOne(users, { where: { email } })) return { ok: false, error: "That email already has an account." }

	const hash = await hashPassword(input.password)
	const now = Date.now()
	const userId = id()
	const row = newUserRow(userId, email, input.name.trim().slice(0, 80), 0, now)

	try {
		await db.transaction(async (tx) => {
			await tx.create(users, row)
			await tx.create(passwords, { user_id: userId, hash, updated_at: now })
		})
	} catch {
		return { ok: false, error: "That email already has an account." }
	}
	return { ok: true, user: toUser(row) }
}

export async function signInWithPassword(emailRaw: string, password: string): Promise<User | null> {
	const user = await db.findOne(users, { where: { email: normEmail(emailRaw) } })
	const pw = user ? await db.findOne(passwords, { where: { user_id: user.id } }) : null
	if (!user || !pw) {
		await fakeVerify(password)
		return null
	}
	return (await verifyPassword(password, pw.hash)) ? toUser(user) : null
}

type GoogleProfile = { id?: string; email?: string | null; name?: string | null; picture?: string | null }

export async function upsertFromGoogle(account: { providerAccountId: string }, profile: GoogleProfile): Promise<User> {
	const link = await db.findOne(oauthAccounts, { where: { provider: "google", provider_account_id: account.providerAccountId } })
	if (link) {
		const existing = await db.find(users, link.user_id)
		if (existing) return toUser(existing)
	}

	const email = normEmail(profile.email ?? "")
	if (!email) throw new Error("Google did not return an email.")
	const now = Date.now()

	return db.transaction(async (tx) => {
		let user = await tx.findOne(users, { where: { email } })
		if (!user) {
			user = await tx.create(users, newUserRow(id(), email, profile.name?.trim() ?? "", 1, now), { returnRow: true })
		}
		await tx.create(oauthAccounts, {
			id: id(),
			user_id: user.id,
			provider: "google",
			provider_account_id: account.providerAccountId,
			created_at: now,
		})
		if (profile.picture) {
			const hasAvatar = await tx.findOne(userImages, { where: { user_id: user.id, kind: "avatar", is_active: 1 } })
			if (!hasAvatar) {
				await tx.create(userImages, {
					id: id(),
					user_id: user.id,
					kind: "avatar",
					source: "google",
					url: profile.picture,
					mime: "",
					size_bytes: 0,
					is_active: 1,
					created_at: now,
				})
			}
		}
		return toUser(user)
	})
}

export async function getActiveAvatar(userId: string): Promise<string | null> {
	const img = await db.findOne(userImages, {
		where: { user_id: userId, kind: "avatar", is_active: 1 },
		orderBy: ["created_at", "desc"],
	})
	return img?.url ?? null
}

export async function updateProfile(userId: string, input: { name: string; email: string }) {
	const email = normEmail(input.email)
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return "Enter a valid email."
	const clash = await db.findOne(users, { where: { email } })
	if (clash && clash.id !== userId) return "That email belongs to another account."
	await db.update(users, userId, {
		name: input.name.trim().slice(0, 80) || email.split("@")[0]!,
		email,
		updated_at: Date.now(),
	})
	return null
}

export async function updatePrefs(userId: string, input: { currency: string; run_at: string; day_start: number; week_start: string; usdt_rate_minor: number; usd_rate_minor: number }) {
	const runAt = input.run_at.trim()
	await db.update(users, userId, {
		currency: input.currency.trim().toUpperCase().slice(0, 8) || "MAD",
		run_at: /^([01]?\d|2[0-3]):[0-5]\d$/.test(runAt) ? runAt.padStart(5, "0") : "06:00",
		week_start: input.week_start.trim().slice(0, 16) || "Monday",
		...(Number.isInteger(input.day_start) && input.day_start >= 0 && input.day_start <= 23 ? { day_start: input.day_start } : {}),
		...(input.usd_rate_minor > 0 && input.usd_rate_minor <= 100000000 ? { usd_rate_minor: input.usd_rate_minor } : {}),
		...(input.usdt_rate_minor > 0 && input.usdt_rate_minor <= 100000000 ? { usdt_rate_minor: input.usdt_rate_minor } : {}),
		updated_at: Date.now(),
	})
}

export async function setTheme(userId: string, theme: string) {
	if (theme !== "dark" && theme !== "light") return
	await db.update(users, userId, { theme, updated_at: Date.now() })
}

export async function todayFor(userId: string) {
	const row = await db.find(users, userId)
	return today(row ? toUser(row).day_start : 5)
}
GOAT_EOF
echo "updated app/lib/users.ts"

mkdir -p "$(dirname app/lib/auto.ts)"
cat > app/lib/auto.ts <<'GOAT_EOF'
import { sql } from "remix/data-table"

import { db, incomes, incomeSources, users } from "../db/index.ts"
import { addDays, dayOf, hhmm, today } from "./time.ts"
import { extKey, id, rowsOf } from "./util.ts"

const hm = (v: string | null | undefined) => {
	const m = /^(\d{1,2}):(\d{2})$/.exec(v ?? "")
	return m ? `${m[1]!.padStart(2, "0")}:${m[2]}` : "06:00"
}

const pad = (n: number) => String(n).padStart(2, "0")
const lastDayOf = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).getUTCDate()

const shiftHm = (v: string, h: number) => {
	const m = ((((Number(v.slice(0, 2)) * 60 + Number(v.slice(3, 5)) - h * 60) % 1440) + 1440) % 1440)
	return `${pad(Math.floor(m / 60))}:${pad(m % 60)}`
}

export async function settleAuto(uid: string): Promise<void> {
	const all = await db.findMany(incomeSources, { where: { user_id: uid, mode: "auto" } })
	const srcs = all.filter((s) => s.active !== 0 && s.amount_minor > 0)
	if (!srcs.length) return

	const u = await db.find(users, uid)
	const h = u && Number.isInteger(u.day_start) && u.day_start >= 0 && u.day_start <= 23 ? u.day_start : 5
	const runAt = shiftHm(hm(u?.run_at), h)
	const now = Date.now()
	const t = today(h)
	const nowHm = hhmm(now, h)

	const res = await db.exec(sql`select ext_key as k from incomes where user_id = ${uid} and ext_key <> ''`)
	const have = new Set(rowsOf(res).map((r) => String(r.k ?? r[0] ?? "")))

	const due = (d: string) => d < t || (d === t && nowHm >= runAt)

	for (const s of srcs) {
		const created = dayOf(s.created_at, h)
		const createdHm = hhmm(s.created_at, h)
		const started = (d: string) => d > created || (d === created && createdHm < runAt)
		const days: string[] = []

		if (s.every === "month") {
			const dom = Number(created.slice(8, 10))
			let y = Number(created.slice(0, 4))
			let m = Number(created.slice(5, 7))
			const endY = Number(t.slice(0, 4))
			const endM = Number(t.slice(5, 7))
			for (let i = 0; i < 36 && (y < endY || (y === endY && m <= endM)); i++) {
				days.push(`${y}-${pad(m)}-${pad(Math.min(dom, lastDayOf(y, m)))}`)
				if (++m > 12) (m = 1), y++
			}
		} else {
			const from = created > addDays(t, -62) ? created : addDays(t, -62)
			for (let d = from; d <= t; d = addDays(d, 1)) days.push(d)
		}

		for (const d of days) {
			if (!due(d) || !started(d)) continue
			const key = extKey(s.id, d)
			if (have.has(key)) continue
			have.add(key)
			try {
				await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, amount_minor: s.amount_minor, day: d, created_at: now, meta: '{"auto":1}', ext_key: key })
			} catch {}
		}
	}
}
GOAT_EOF
echo "updated app/lib/auto.ts"

mkdir -p "$(dirname scripts/migrate.ts)"
cat > scripts/migrate.ts <<'GOAT_EOF'
import { createClient } from "@libsql/client"
import { readFileSync } from "node:fs"

const url = process.env.TURSO_DATABASE_URL
const authToken = process.env.TURSO_AUTH_TOKEN
if (!url) throw new Error("TURSO_DATABASE_URL is not set (put it in .dev.vars)")

const client = createClient({ url, authToken })
const schema = readFileSync(new URL("../database/schema.sql", import.meta.url), "utf8")

await client.executeMultiple(schema)

const addColumns = [
	"ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE users ADD COLUMN run_at TEXT NOT NULL DEFAULT '06:00'",
	"ALTER TABLE users ADD COLUMN week_start TEXT NOT NULL DEFAULT 'Monday'",
	"ALTER TABLE users ADD COLUMN day_start INTEGER NOT NULL DEFAULT 5",
	"ALTER TABLE users ADD COLUMN bg_mode TEXT NOT NULL DEFAULT 'auto'",
	"ALTER TABLE users ADD COLUMN bg_url TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE users ADD COLUMN usdt_rate_minor INTEGER NOT NULL DEFAULT 1100",
	"ALTER TABLE income_sources ADD COLUMN type TEXT NOT NULL DEFAULT 'manual'",
	"ALTER TABLE income_sources ADD COLUMN config TEXT NOT NULL DEFAULT '{}'",
	"ALTER TABLE income_sources ADD COLUMN currency TEXT NOT NULL DEFAULT 'MAD'",
	"ALTER TABLE income_sources ADD COLUMN active INTEGER NOT NULL DEFAULT 1",
	"ALTER TABLE income_sources ADD COLUMN sort INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE incomes ADD COLUMN meta TEXT NOT NULL DEFAULT '{}'",
	"ALTER TABLE incomes ADD COLUMN ext_key TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE incomes ADD COLUMN usd_minor INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",
	"ALTER TABLE trade_results ADD COLUMN state TEXT NOT NULL DEFAULT 'done'",
	"ALTER TABLE trade_results ADD COLUMN asset TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE trade_results ADD COLUMN tf INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE debts ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE debts ADD COLUMN last_delta INTEGER NOT NULL DEFAULT 0",
]
for (const statement of addColumns) {
	try {
		await client.execute(statement)
		console.log("added:", statement)
	} catch (err) {
		if (!/duplicate column/i.test(String(err))) throw err
	}
}

await client.execute("UPDATE users SET day_start = 5 WHERE day_start = 17")
await client.execute("CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_key_idx ON incomes(ext_key) WHERE ext_key <> ''")
await client.execute("INSERT INTO goal_items (id, user_id, goal_id, name, price_minor, done_at, created_at) SELECT lower(hex(randomblob(16))), user_id, id, title, target_minor, NULL, created_at FROM goals g WHERE target_minor > 0 AND NOT EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = g.id)")
await client.execute("UPDATE goals SET target_minor = 0 WHERE target_minor > 0 AND EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = goals.id)")

const { rows } = await client.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
console.log("tables:", rows.map((r) => r.name).join(", "))
client.close()
GOAT_EOF
echo "updated scripts/migrate.ts"

mkdir -p "$(dirname app/client/app.js)"
cat > app/client/app.js <<'GOAT_EOF'
(function () {
	if (window.__mt) return
	window.__mt = 1
	var d = document
	var r = d.documentElement
	var all = function (sel, root) {
		return [].slice.call((root || d).querySelectorAll(sel))
	}
	var focusFirst = function (box) {
		var i = box.querySelector("input:not([type=hidden])")
		if (i) i.focus()
	}

	function setTheme(t) {
		r.setAttribute("data-theme", t)
		try {
			localStorage.setItem("mtheme", t)
		} catch (e) {}
		try {
			fetch("/settings/theme", { method: "POST", body: new URLSearchParams({ theme: t }), credentials: "same-origin", redirect: "manual" })
		} catch (e) {}
	}

	function endEdit(c) {
		var id = c.querySelector("[data-eid]")
		if (id) id.value = ""
		var eb = c.querySelector(".eb")
		if (eb) eb.hidden = true
		c.querySelector("textarea").value = ""
	}

	var open = {}
	try {
		open = JSON.parse(localStorage.getItem("mt:open") || "{}")
	} catch (e) {}

	d.addEventListener(
		"toggle",
		function (e) {
			var x = e.target
			if (x.matches && x.matches("details[data-keep-open]")) {
				open[x.getAttribute("data-keep-open")] = x.open
				try {
					localStorage.setItem("mt:open", JSON.stringify(open))
				} catch (err) {}
			}
			if (x.matches && x.matches(".xd") && !x.open) {
				var xf = x.querySelector("[data-adp]")
				var xb = x.parentNode.querySelector("[data-xplus]")
				if (xf) xf.hidden = true
				if (xb) xb.classList.remove("on")
			}
		},
		true,
	)

	d.addEventListener("click", function (e) {
		var t = e.target
		if (t.closest && !t.closest("[data-xplus]") && t.closest("details[data-fixed] > summary")) {
			e.preventDefault()
			return
		}
		var q = t.closest("button[name][value]")
		if (q && q.form) {
			var sh = q.form.querySelector('input[type=hidden][data-sub="' + q.name + '"]')
			if (!sh) {
				sh = d.createElement("input")
				sh.type = "hidden"
				sh.name = q.name
				sh.setAttribute("data-sub", q.name)
				q.form.appendChild(sh)
			}
			sh.value = q.value
		}
		if ((q = t.closest("[data-close]"))) {
			var cd = q.closest("details")
			if (cd) cd.open = false
			return
		}
		if (t.closest("[data-theme-toggle]")) return setTheme(r.getAttribute("data-theme") === "dark" ? "light" : "dark")
		if ((q = t.closest("[data-set-theme]"))) return setTheme(q.getAttribute("data-set-theme"))
		if ((q = t.closest("[data-pw]"))) {
			var pwi = q.parentNode.querySelector("input")
			if (pwi) {
				var pwShow = pwi.type === "password"
				pwi.type = pwShow ? "text" : "password"
				q.setAttribute("aria-pressed", pwShow ? "true" : "false")
				q.setAttribute("aria-label", pwShow ? "Hide password" : "Show password")
			}
			return
		}
		if ((q = t.closest("[data-eye]"))) {
			var v = q.closest(".hm-bal").querySelector(".hm-dots")
			var hide = q.getAttribute("data-s") !== "1"
			q.setAttribute("data-s", hide ? "1" : "0")
			v.innerHTML = hide ? v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>" : "••••••"
			return
		}
		if ((q = t.closest("[data-edit-bal]"))) {
			var bf = q.closest(".cd,.sc").querySelector("[data-balf]")
			bf.hidden = !bf.hidden
			q.setAttribute("aria-label", bf.hidden ? "Edit balance" : "Cancel")
			q.classList.toggle("hi", !bf.hidden)
			if (!bf.hidden) {
				var bi = bf.querySelector("input:not([type=hidden])")
				if (bi) {
					bi.focus()
					bi.select()
				}
			}
			return
		}
		if ((q = t.closest("[data-all]"))) {
			var af = q.closest(".iw").querySelector("input")
			af.value = q.getAttribute("data-all")
			af.focus()
			return
		}
		if ((q = t.closest("[data-tg],[data-pay]"))) {
			var add = q.hasAttribute("data-tg")
			var w = q.closest(".dbw")
			var p = w.querySelector(add ? "[data-addp]" : "[data-payp]")
			var o = w.querySelector(add ? "[data-payp]" : "[data-addp]")
			if (o) o.hidden = true
			p.hidden = !p.hidden
			if (!p.hidden) {
				var i = p.querySelector("input[name=amount]")
				if (i) i.focus()
			}
			return
		}
		if ((q = t.closest("[data-xplus]"))) {
			e.preventDefault()
			var xc = q.closest(".xc")
			var xd = xc.querySelector("details")
			var xm = xc.querySelector("[data-adp]")
			if (xm) {
				if (xd && !xd.open) {
					xd.open = true
					xm.hidden = false
				} else xm.hidden = !xm.hidden
				q.classList.toggle("on", !xm.hidden)
				if (!xm.hidden) focusFirst(xm)
			}
			return
		}
		if ((q = t.closest("[data-nm]"))) {
			var nf = q.closest("form")
			nf.querySelector("[data-name]").value = q.getAttribute("data-nm")
			var pin = nf.querySelector("[data-price]")
			if (pin) pin.focus()
			return
		}
		if ((q = t.closest("[data-bigadd]"))) {
			var tf = q.getAttribute("data-for")
			var ap = tf ? d.getElementById(tf) : q.closest(".bgc").querySelector("[data-adp]")
			ap.hidden = !ap.hidden
			q.classList.toggle("on", !ap.hidden)
			if (!ap.hidden) focusFirst(ap)
			return
		}
		if ((q = t.closest("[data-mode]"))) {
			var form = q.closest("form")
			var mode = q.getAttribute("data-mode")
			all("[data-mode]", form).forEach(function (c) {
				c.classList.toggle("on", c === q)
			})
			form.querySelector("[data-mode-input]").value = mode
			form.setAttribute("data-kind", mode)
			form.setAttribute("data-m", mode)
			return
		}
		if ((q = t.closest(".bub"))) {
			q.classList.toggle("sel")
			var a = q.parentNode.querySelector(".acts")
			a.hidden = !a.hidden
			return
		}
		if ((q = t.closest("[data-act]"))) {
			var m = q.closest(".msg")
			var act = q.getAttribute("data-act")
			var body = m.querySelector(".bub").textContent
			if (act === "copy") {
				try {
					navigator.clipboard.writeText(body)
				} catch (x) {}
			} else if (act === "edit") {
				var c = d.querySelector('[data-comp="' + m.parentNode.getAttribute("data-list") + '"]')
				c.querySelector("[data-eid]").value = m.getAttribute("data-id")
				c.querySelector(".eb").hidden = false
				var ta = c.querySelector("textarea")
				ta.value = body
				ta.focus()
			}
			return
		}
		if ((q = t.closest("[data-cancel]"))) endEdit(q.closest("[data-comp]"))
	})

	d.addEventListener(
		"click",
		function (e) {
			var b = e.target.closest && e.target.closest("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn"))) e.preventDefault()
		},
		true,
	)

	// Fallback spinner for any submit button that is not the shared Submit component.
	var SPIN = '<span class="sb-i" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg></span>'
	d.addEventListener("submit", function (e) {
		var f = e.target
		var msg = f.getAttribute && f.getAttribute("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		var sub = e.submitter
		setTimeout(function () {
			if (e.defaultPrevented) return
			all("button", f).forEach(function (b) {
				if (b.disabled) return
				b.disabled = true
				if (!sub || b === sub) {
					b.setAttribute("data-busy", "1")
					b.setAttribute("aria-busy", "true")
					if (!b.querySelector(".sb-i")) b.insertAdjacentHTML("beforeend", SPIN)
				} else b.setAttribute("data-lock", "1")
			})
		}, 0)
	})

	function unbusy() {
		all("button[data-busy],button[data-lock]").forEach(function (b) {
			b.disabled = false
			b.removeAttribute("data-busy")
			b.removeAttribute("data-lock")
			b.removeAttribute("aria-busy")
		})
	}
	window.addEventListener("pageshow", function (e) {
		if (e.persisted) unbusy()
	})

	d.addEventListener("keydown", function (e) {
		var t = e.target
		if (e.key !== "Enter" || e.shiftKey || !(t.matches && t.matches("[data-comp] textarea"))) return
		e.preventDefault()
		if (t.value.trim()) t.closest("form").requestSubmit()
	})

	var zone = "Africa/Casablanca"
	var fmt = function (loc, o) {
		o.timeZone = zone
		return new Intl.DateTimeFormat(loc, o)
	}
	var tf = fmt("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })
	var df = fmt("en-GB", { weekday: "long", day: "numeric", month: "long" })
	var nf = fmt("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })
	var af = fmt("ar-MA", { weekday: "long" })
	function tick() {
		var now = new Date()
		var sub = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + "</span>"
		all("[data-clock-time]").forEach(function (el) {
			el.textContent = tf.format(now)
		})
		all("[data-clock-date]").forEach(function (el) {
			el.textContent = df.format(now)
		})
		all("[data-clock-subdate]").forEach(function (el) {
			el.innerHTML = sub
		})
	}
	setInterval(tick, 1000)

	all("details[data-keep-open]").forEach(function (x) {
		var k = x.getAttribute("data-keep-open")
		if (k in open) x.open = !!open[k]
	})

	var rb = false
	try {
		rb = sessionStorage.getItem("mt:rb") === "1"
		sessionStorage.removeItem("mt:rb")
	} catch (e) {}
	if (rb) all("[data-eye]").forEach(function (q) {
		q.setAttribute("data-s", "1")
		var v = q.parentNode.firstChild
		v.innerHTML = v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>"
	})

	all("[data-list]").forEach(function (L) {
		var last = L.lastElementChild
		if (L.getAttribute("data-list") !== "dash" && last && last.scrollIntoView) last.scrollIntoView({ block: "end" })
	})

	var loaded = Date.now()
	setInterval(function () {
		if (!d.querySelector("[data-exo]") || d.hidden || Date.now() - loaded < 240000) return
		var a = d.activeElement
		if (a && a.matches && a.matches("input,textarea,select")) return
		if (d.querySelector("[data-adp]:not([hidden]),[data-addp]:not([hidden])")) return
		try {
			if (d.querySelector('[data-eye][data-s="1"]')) sessionStorage.setItem("mt:rb", "1")
		} catch (e) {}
		location.reload()
	}, 30000)
})()

;(function () {
	var d = document
	var K = "mt:pad:v1"
	var TABS = {
		projects: { space: "project", entry: "note", head: "Projects", add: "New project", ph: "Write a note", empty: "No projects yet. Add your first one above.", noun: "notes" },
		people: { space: "person", entry: "quote", head: "People", add: "Add a person", ph: "What did they say?", empty: "No one yet. Add a person, then what they said.", noun: "things said" },
		books: { space: "book", entry: "lesson", head: "Books", add: "Book name", sub: "Author (optional)", ref: "Chapter or page (optional)", ph: "What did you learn?", empty: "No books yet. Add a book, then what you learned from it.", noun: "lessons" },
		tips: { entry: "tip", flat: true, ph: "Something useful to remember", ref: "Where from (optional)", empty: "Nothing saved yet." },
	}
	var data = { spaces: [], entries: [] }
	var load = function () {
		try {
			var v = JSON.parse(localStorage.getItem(K) || "null")
			if (v && v.spaces && v.entries) data = v
		} catch (e) {}
	}
	var save = function () {
		try {
			localStorage.setItem(K, JSON.stringify(data))
		} catch (e) {}
	}
	var uid = function () {
		return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
	}
	var esc = function (s) {
		return String(s).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
		})
	}
	var when = function (t) {
		return new Date(t).toLocaleDateString("en-GB", { day: "numeric", month: "short" })
	}
	var spaceOf = function (id) {
		return data.spaces.filter(function (s) {
			return s.id === id
		})[0]
	}
	var entriesOf = function (fn) {
		return data.entries
			.filter(fn)
			.sort(function (a, b) {
				return b.at - a.at
			})
	}
	var entryHtml = function (e, label) {
		return (
			'<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + "</div>" +
			'<div class="pdm"><span class="lb">' + (label ? esc(label) + " · " : "") + (e.ref ? esc(e.ref) + " · " : "") + when(e.at) + "</span>" +
			'<span class="pda"><button type="button" class="chip' + (e.home ? " on" : "") + '" data-pd="home">Home</button>' +
			'<button type="button" class="chip" data-pd="edit">Edit</button>' +
			'<button type="button" class="chip" data-pd="del">Delete</button></span></div></div>'
		)
	}
	var composer = function (c, spaceId) {
		return (
			'<form class="pdf" data-pd="entry" data-space="' + (spaceId || "") + '">' +
			'<textarea class="pdi" name="body" rows="3" placeholder="' + esc(c.ph) + '" required></textarea>' +
			(c.ref ? '<input class="pdi" name="ref" placeholder="' + esc(c.ref) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>'
		)
	}
	var tabHtml = function (key) {
		var c = TABS[key]
		var id = decodeURIComponent(location.hash.slice(1))
		if (c.flat) return composer(c, "") + (entriesOf(function (e) { return e.kind === c.entry }).map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">' + c.empty + "</div>")
		var sp = id && spaceOf(id)
		if (sp && sp.kind === c.space) {
			var list = entriesOf(function (e) { return e.space === sp.id })
			return (
				'<div class="pdhd"><a class="chip" href="#" data-pd="back">‹ ' + c.head + "</a>" +
				'<button type="button" class="chip" data-pd="delspace" data-id="' + sp.id + '">Delete</button></div>' +
				'<h2 class="pdtt">' + esc(sp.title) + "</h2>" + (sp.sub ? '<div class="lb">' + esc(sp.sub) + "</div>" : "") +
				composer(c, sp.id) +
				(list.map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">Nothing here yet.</div>')
			)
		}
		var spaces = data.spaces
			.filter(function (s) { return s.kind === c.space })
			.sort(function (a, b) { return b.at - a.at })
		return (
			'<form class="pdf" data-pd="space"><input class="pdi" name="title" placeholder="' + esc(c.add) + '" autocomplete="off" required>' +
			(c.sub ? '<input class="pdi" name="sub" placeholder="' + esc(c.sub) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>' +
			(spaces.map(function (s) {
				var n = data.entries.filter(function (e) { return e.space === s.id }).length
				return '<a class="pdc" href="#' + encodeURIComponent(s.id) + '"><span><b>' + esc(s.title) + '</b><span class="lb">' + (s.sub ? esc(s.sub) + " · " : "") + n + " " + c.noun + '</span></span><span class="mu">›</span></a>'
			}).join("") || '<div class="lb pde">' + c.empty + "</div>")
		)
	}
	var homeHtml = function () {
		var list = entriesOf(function (e) { return e.home }).slice(0, 6)
		return (
			'<div class="sh"><span>Pinned notes</span><span class="lb">' + list.length + "</span></div>" +
			'<form class="pdf" data-pd="entry" data-space="" data-home="1"><input class="pdi" name="body" placeholder="Add a note to home" autocomplete="off" required><button class="btn xs">Add</button></form>' +
			(list.map(function (e) {
				var s = e.space && spaceOf(e.space)
				return '<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + '</div><div class="pdm"><span class="lb">' + (s ? esc(s.title) + " · " : "") + when(e.at) + '</span><span class="pda"><button type="button" class="chip" data-pd="home">Unpin</button></span></div></div>'
			}).join("") || '<div class="lb pde">Pin any note with the Home button.</div>')
		)
	}
	var paint = function () {
		[].slice.call(d.querySelectorAll("[data-pad]")).forEach(function (r) {
			var a = d.activeElement
			if (a && r.contains(a) && a.value) return
			r.innerHTML = tabHtml(r.getAttribute("data-pad"))
		})
		var h = d.activeElement
		;[].slice.call(d.querySelectorAll("[data-pad-home]")).forEach(function (r) {
			if (h && r.contains(h) && h.value) return
			r.innerHTML = homeHtml()
		})
	}
	var repaint = function () {
		save()
		;[].slice.call(d.querySelectorAll("[data-pad],[data-pad-home]")).forEach(function (r) {
			r.innerHTML = r.hasAttribute("data-pad") ? tabHtml(r.getAttribute("data-pad")) : homeHtml()
		})
	}
	d.addEventListener("submit", function (e) {
		var f = e.target
		var kind = f.getAttribute && f.getAttribute("data-pd")
		if (kind !== "space" && kind !== "entry") return
		e.preventDefault()
		var root = f.closest("[data-pad]")
		var tab = root && root.getAttribute("data-pad")
		var c = tab && TABS[tab]
		var v = function (n) {
			var i = f.elements[n]
			return i ? i.value.trim() : ""
		}
		var now = Date.now()
		if (kind === "space" && c) {
			if (!v("title")) return
			data.spaces.push({ id: uid(), kind: c.space, title: v("title").slice(0, 120), sub: v("sub").slice(0, 120), at: now })
		} else if (kind === "entry") {
			if (!v("body")) return
			var home = f.getAttribute("data-home") === "1"
			data.entries.push({ id: uid(), space: f.getAttribute("data-space") || null, kind: c ? c.entry : "note", body: v("body").slice(0, 4000), ref: v("ref").slice(0, 120), home: home, at: now })
		}
		repaint()
	})
	d.addEventListener("click", function (e) {
		var b = e.target.closest && e.target.closest("[data-pd]")
		if (!b || b.tagName === "FORM") return
		var act = b.getAttribute("data-pd")
		var row = b.closest("[data-id]")
		var id = row ? row.getAttribute("data-id") : b.getAttribute("data-id")
		var en = id && data.entries.filter(function (x) { return x.id === id })[0]
		if (act === "back") {
			e.preventDefault()
			history.pushState("", "", location.pathname)
			return repaint()
		}
		if (act === "home" && en) en.home = !en.home
		else if (act === "edit" && en) {
			var t = prompt("Edit", en.body)
			if (t === null || !t.trim()) return
			en.body = t.trim().slice(0, 4000)
		} else if (act === "del" && en) {
			if (!confirm("Delete this?")) return
			data.entries = data.entries.filter(function (x) { return x.id !== id })
		} else if (act === "delspace" && id) {
			if (!confirm("Delete this and everything inside it?")) return
			data.spaces = data.spaces.filter(function (x) { return x.id !== id })
			data.entries = data.entries.filter(function (x) { return x.space !== id })
			history.pushState("", "", location.pathname)
		} else return
		repaint()
	})
	addEventListener("hashchange", paint)
	addEventListener("storage", function (e) {
		if (e.key !== K) return
		load()
		paint()
	})
	load()
	paint()
})()

/* file20 */
;(function () {
	var d = document
	var hold = 0
	var fired = false
	var sx = 0
	var sy = 0
	var toast = function (t) {
		var x = d.createElement("div")
		x.className = "nt-toast"
		x.textContent = t
		d.body.appendChild(x)
		setTimeout(function () {
			x.remove()
		}, 1100)
	}
	var copy = function (t) {
		try {
			if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(t)
		} catch (e) {}
		var a = d.createElement("textarea")
		a.value = t
		a.style.cssText = "position:fixed;opacity:0"
		d.body.appendChild(a)
		a.select()
		try {
			d.execCommand("copy")
		} catch (e) {}
		a.remove()
		return Promise.resolve()
	}
	var edit = function (it) {
		var f = it && it.querySelector("[data-edit]")
		var b = it && it.querySelector("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		var mn = it.querySelector(".nt-mn")
		if (mn) mn.hidden = true
		var ta = f.querySelector("input[name=body],textarea")
		if (!ta.value) ta.value = ta.defaultValue || it.querySelector("[data-copy] p").textContent.trim()
		ta.focus()
		ta.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "center", behavior: "smooth" })
	}
	d.addEventListener("pointerdown", function (e) {
		var b = e.target.closest && e.target.closest("[data-copy]")
		if (!b) return
		fired = false
		sx = e.clientX
		sy = e.clientY
		clearTimeout(hold)
		hold = setTimeout(function () {
			fired = true
			if (navigator.vibrate) navigator.vibrate(15)
			edit(b.closest("[data-pad-item]"))
		}, 450)
	})
	d.addEventListener("pointermove", function (e) {
		if (hold && (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8)) clearTimeout(hold)
	})
	;["pointerup", "pointercancel", "pointerleave"].forEach(function (n) {
		d.addEventListener(n, function () {
			clearTimeout(hold)
		}, true)
	})
	d.addEventListener("contextmenu", function (e) {
		if (e.target.closest && e.target.closest("[data-copy]")) e.preventDefault()
	})
	var closeMenus = function () {
		all(".nt-dd:not([hidden])").forEach(function (m) {
			m.hidden = true
			var o = m.parentNode.querySelector("[data-menu]")
			if (o) o.setAttribute("aria-expanded", "false")
		})
	}
	d.addEventListener("keydown", function (e) {
		if (e.key === "Escape") closeMenus()
	})
	d.addEventListener("click", function (e) {
		var t = e.target
		var mb = t.closest && t.closest("[data-menu]")
		if (mb) {
			var dd = mb.parentNode.querySelector(".nt-dd")
			var was = !dd.hidden
			closeMenus()
			if (!was) {
				dd.hidden = false
				mb.setAttribute("aria-expanded", "true")
			}
			return
		}
		var me = t.closest && t.closest("[data-menu-edit]")
		if (me) {
			closeMenus()
			edit(me.closest("[data-pad-item]"))
			return
		}
		if (!(t.closest && t.closest(".nt-dd"))) closeMenus()
		var b = t.closest && t.closest("[data-copy]")
		if (b) {
			if (fired) {
				fired = false
				return
			}
			var p = b.querySelector("p")
			copy((p || b).textContent.trim()).then(function () {
				toast("Copied")
			})
			return
		}
		var x = t.closest && t.closest("[data-edit-x]")
		if (x) {
			var it = x.closest("[data-pad-item]")
			it.querySelector("[data-edit]").hidden = true
			it.querySelector("[data-copy]").hidden = false
			var mn2 = it.querySelector(".nt-mn")
			if (mn2) mn2.hidden = false
			return
		}
		var a = t.closest && t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")
		if (a) {
			setTimeout(function () {
				var box = a.closest(".xc,.dbw,.sc,.cd") || d
				var f = [].slice.call(box.querySelectorAll("[data-adp],[data-addp],[data-payp]")).filter(function (n) {
					return !n.hidden && n.offsetParent
				})[0]
				if (!f) return
				var i = f.querySelector("input:not([type=hidden]),textarea")
				if (i) i.focus({ preventScroll: true })
				f.scrollIntoView({ block: "center", behavior: "smooth" })
			}, 60)
		}
	})

	var dis = {}
	try {
		dis = JSON.parse(localStorage.getItem("mt:inv") || "{}")
	} catch (e) {}
	;[].slice.call(d.querySelectorAll("[data-inv]")).forEach(function (n) {
		if (dis[n.getAttribute("data-inv")]) n.hidden = true
	})
	d.addEventListener("click", function (e) {
		var x = e.target.closest && e.target.closest("[data-inv-x]")
		if (!x) return
		var n = x.closest("[data-inv]")
		dis[n.getAttribute("data-inv")] = 1
		try {
			localStorage.setItem("mt:inv", JSON.stringify(dis))
		} catch (err) {}
		n.hidden = true
	})
})()
GOAT_EOF
echo "updated app/client/app.js"

mkdir -p "$(dirname app/client/app.css)"
cat > app/client/app.css <<'GOAT_EOF'
:root:root:root{--pico-font-family:var(--font-sys);--pico-font-size:100%;--pico-line-height:1.45;--pico-background-color:var(--bg);--pico-color:var(--ink);--pico-muted-color:var(--mu);--pico-muted-border-color:var(--ln);--pico-primary:var(--ac);--pico-primary-background:var(--ac);--pico-primary-border:var(--ac);--pico-primary-hover:var(--ac);--pico-primary-hover-background:var(--ac);--pico-primary-hover-border:var(--ac);--pico-primary-focus:var(--acs);--pico-primary-inverse:var(--on);--pico-border-radius:12px;--pico-border-width:1px;--pico-outline-width:3px;--pico-block-spacing-vertical:0px;--pico-block-spacing-horizontal:0px;--pico-form-element-background-color:var(--s1);--pico-form-element-border-color:var(--ln);--pico-form-element-color:var(--ink);--pico-form-element-placeholder-color:var(--mu);--pico-form-element-active-background-color:var(--s1);--pico-form-element-active-border-color:var(--ac);--pico-form-element-focus-color:var(--ac);--pico-form-element-disabled-background-color:var(--s2);--pico-form-element-spacing-vertical:.8rem;--pico-form-element-spacing-horizontal:1rem;--pico-form-element-invalid-border-color:var(--neg);--pico-form-element-invalid-active-border-color:var(--neg);--pico-form-element-invalid-focus-color:var(--neg)}
html input:not([type=checkbox]):not([type=radio]):not([type=hidden]),html select,html textarea,form,h1,h2,h3{margin:0}
button:not(:focus-visible):focus{box-shadow:none}
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}
.cd,.sc,.xc,.hero{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}
a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}
button{cursor:pointer}
.mu,.lb{color:var(--mu)}
.lb{font-size:11px;font-family:var(--mono)}
.pos{color:var(--pos)!important}
.neg{color:var(--neg)!important}
.ea{color:var(--earn)!important}
.sp{color:var(--spend)!important}
.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}
details{margin:0}
details>summary:not([role])::after,details>summary::after{content:none}
details>summary:not([role]){color:inherit}
details[open]>summary{margin-bottom:0}
summary::-webkit-details-marker{display:none}
button,input[type=button],input[type=submit],.btn,.sbl,.chip,.ib{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.chip:active,.ib:active{transform:scale(.97);opacity:.88}
.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
@media(min-width:900px){
	.m{display:none!important}
}
@media(max-width:899px){
	.d{display:none!important}
}
.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){
	.app{flex-direction:column}
}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}
.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib{flex:none;aspect-ratio:1}
.ib.sm{width:28px;height:28px;min-width:28px}
.ib svg.ic{width:16px;height:16px}
.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}
.bt .on svg.ic{stroke-width:2}
.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}
.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}
.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}
h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}
.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}
.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}
.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}
.cd{margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}
.two .cb{padding:3px 12px 10px}
.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}
.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.fl{margin-top:14px}
.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}
.ln{display:flex;gap:10px;align-items:center}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}
.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}
.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}
.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}
.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}
.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}
.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}
.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}
.cm .eb b{font-weight:600}
.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}
.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}
.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}
.li:hover{background:var(--s2)}
.li:last-child{border:0}
.li:first-child{padding-top:14px}
.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}
.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}
.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
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
.sc.bgc summary.sh{cursor:pointer}
.l1{gap:12px}
.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}
.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.ok{color:var(--earn)}
.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}
.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}
.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}
.spf .ln .in{flex:1 1 0}
.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
.rw>.rt{max-width:62%;justify-content:flex-end}
.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
.xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
.xh::-webkit-details-marker{display:none}
.xh>div{min-width:0}
.xc .chev{position:absolute;right:66px;top:50%;margin-top:-10px}
.xp{position:absolute;right:12px;top:18px;width:46px;height:44px;border-radius:13px;border:1px solid var(--acl);background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0;z-index:2}
.xp svg.ic{width:24px;height:24px;stroke-width:2;transition:transform .18s ease}
.xp.on svg.ic{transform:rotate(45deg)}
.xb{padding:4px 16px 8px;border-top:1px solid var(--ln)}
.xf{padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.xl{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:12px;color:var(--mu);font-family:var(--mono)}
.xl b{color:var(--ink);font-weight:600;white-space:nowrap}
.xf form{margin:12px 0 0}
.xfm .ln{gap:10px;margin:0}
.xfm .ln .in{flex:1 1 0;margin:0}
.xfm .ln .in.pr{flex:0 0 96px;width:96px}
.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}
.gw:last-child{border-bottom:0}
.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}
.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}
.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}
.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}
.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
.top-status-bar.tsplit{justify-content:space-between}
.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}
.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}
main{transition:opacity .2s ease}
html[data-nav=busy],html[data-nav=busy] a,html[data-nav=busy] button{cursor:progress}
html[data-nav=busy] main{opacity:.55}
button[data-busy]{cursor:progress}
.btn[data-busy]{opacity:.7}
.sb-l{display:contents}
.sb-i{position:absolute;inset:0;display:none;align-items:center;justify-content:center;pointer-events:none}
button[data-busy]{position:relative}
button[data-busy] .sb-l{visibility:hidden}
button[data-busy] .sb-i{display:flex}
button[data-busy] .sb-i svg.ic{width:18px;height:18px;transform:none;animation:spin .7s linear infinite}
button[data-lock]{opacity:.5}
@keyframes spin{to{transform:rotate(360deg)}}
@media(prefers-reduced-motion:reduce){
	main{transition:none}
	button[data-busy] .sb-i svg.ic{animation:none}
}
.trd{max-width:640px;margin:0 auto}
.tbn{margin:2px 0 6px;line-height:1.5}
.tbr{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px 0;border-bottom:1px solid var(--ln)}
.tbr:last-child{border-bottom:0;padding-bottom:0}
.tbr.lock{opacity:.45}
.tbf{display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0}
.tbf .in{width:96px;flex:0 1 96px;min-width:0;padding:8px 10px;font-size:14px;border-radius:12px}
.btn.win{background:rgba(76,195,138,.14);color:var(--pos);border-color:rgba(76,195,138,.45)}
.tbs{font-size:11px;font-weight:600;border:1px solid currentColor;border-radius:12px;padding:2px 9px;font-family:var(--mono)}
.sw{border-bottom:1px solid var(--ln)}
.sw:last-child{border:0}
.sw>.rw{border:0}
.hx{margin:0 0 12px;border:1px solid var(--ln);background:var(--bg);border-radius:14px;overflow:hidden}
.hx>summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 12px;list-style:none;cursor:pointer;font-size:12px;color:var(--mu);font-family:var(--mono)}
.hx>summary::-webkit-details-marker{display:none}
.hx>summary>span:nth-child(2){margin-left:auto;color:var(--earn)}
.hx>summary .chev{position:static;margin:0;right:auto;top:auto;flex:none}
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
.btn.miss{background:var(--s2);color:var(--mu);border-color:var(--ln)}

.btn{font-weight:600;font-size:15px;letter-spacing:.01em;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:999px;min-height:44px;padding:0 24px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center;box-shadow:0 1px 2px rgba(0,0,0,.28),0 1px 3px 1px rgba(0,0,0,.14);transition:box-shadow .2s,filter .2s,transform .12s}
.btn:hover{filter:brightness(1.07);box-shadow:0 1px 3px rgba(0,0,0,.28),0 4px 8px 3px rgba(0,0,0,.14)}
.btn.o{background:transparent;color:var(--ac);border:1px solid var(--acl);box-shadow:none}
.btn.o:hover{background:var(--acs);filter:none;box-shadow:none}
.btn.xs{min-height:32px;padding:0 14px;font-size:12px;box-shadow:none}
.btn.full{width:100%;min-height:52px;font-size:16px;font-weight:700;margin-top:20px}
.in{min-width:0;font-size:15px;font-family:inherit}
.of{position:relative;margin-top:14px}
.of input{height:56px;padding:22px 16px 6px;border-radius:12px;font-size:16px}
.of label{position:absolute;left:17px;top:19px;margin:0;color:var(--mu);font-size:16px;line-height:1;pointer-events:none;transition:top .15s,font-size .15s,color .15s}
.of input::placeholder{color:transparent}
.of input:focus+label,.of input:not(:placeholder-shown)+label,.of input:-webkit-autofill+label{top:9px;font-size:11px;font-weight:600;color:var(--ac)}

/* file15 */
.earn-top{display:flex;flex-direction:column;gap:3px;min-width:0}
.earn-top .lb{font-size:11px}
.earn-top b{font-size:20px;font-weight:700;letter-spacing:-.04em;line-height:1;white-space:nowrap}
.earn-top small,.rt b small{font-size:11px;color:var(--mu);font-weight:400;letter-spacing:0;margin-left:3px}
.xbare .xb{border-top:0;padding:8px 16px 6px}
.addrow{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:11px 14px;border:1px dashed var(--acl);border-radius:var(--rm);background:var(--acs);color:var(--ac);font-weight:600;font-size:13px}
.addrow svg.ic{width:18px;height:18px;stroke-width:2;transition:transform .18s ease}
.addrow.on svg.ic{transform:rotate(45deg)}
.incbare{padding:6px 22px 18px}
.incbare .addrow{margin-top:12px}
details[data-fixed]>.xh{cursor:default;padding-right:70px}
.dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}
.mm>.cd .big2{font-size:24px}
.mm .two .big2{font-size:20px}
.mm .xbare .xb{padding:2px 14px}
.hr{display:grid;grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;align-items:center;padding:9px 0}
.hn{min-width:0;font-size:15px}
.hr .ea{white-space:nowrap;text-align:right;font-size:15px}
.hr .ub{width:32px;height:32px;border-radius:12px;background:var(--s2)}
.hspan{grid-column:2/4;justify-self:end}
.sw .ad{margin:0 0 10px}
.hx{margin:0 0 8px;border:0;background:var(--s2);border-radius:14px}
.hx>summary{min-height:38px;padding:5px 6px 5px 12px;justify-content:flex-start;gap:10px}
.hx>summary>span:nth-child(2){margin-left:0;color:var(--mu)}
.hx>summary .chev{margin-left:auto;width:28px;height:28px;border-radius:50%;background:var(--s1);align-items:center;justify-content:center}

.pdtabs{margin:8px 0 4px;flex-wrap:nowrap;overflow-x:auto;scrollbar-width:none}
.pdtabs::-webkit-scrollbar{display:none}
.pdtabs .chip{flex:none;white-space:nowrap}
.pdx{margin-top:12px}
.pdf{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 14px}
.pdi{flex:1 1 140px;min-width:0;width:100%;font-size:15px;font-family:inherit;background:var(--s1);color:var(--ink);border:1px solid var(--ln);border-radius:14px;padding:10px 14px;margin:0;resize:none;outline:0}
.pdi:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
textarea.pdi{flex-basis:100%}
.pdf .btn.xs{margin-left:auto}
.pdc{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:14px 16px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdc>span:first-child{display:flex;flex-direction:column;gap:2px;min-width:0}
.pdc b{font-weight:600;letter-spacing:-.01em;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.pdn{padding:12px 14px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdt{white-space:pre-wrap;word-break:break-word}
.pdm{display:flex;justify-content:space-between;align-items:center;gap:8px;margin-top:8px;flex-wrap:wrap}
.pda{display:flex;gap:6px}
.pda .chip{padding:3px 10px;font-size:11px}
.pdhd{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}
.pdtt{font-size:20px;font-weight:700;letter-spacing:-.03em;margin:4px 0 2px}
.pde{padding:14px 2px}
.pdhome .pdf{margin:12px 0}
.pdhome .pdn{background:var(--s2);box-shadow:none}

.app:has(.nt-page) .tsplit .clock-time{display:none}
.nt-ttl{font-size:18px;font-weight:700;letter-spacing:-.02em}
.nt-page{display:flex;flex-direction:column;gap:10px;padding:2px 0 14px}
.nt-c{background:var(--s1);border:1px solid var(--ln);border-radius:22px}
.nt-m{font-family:var(--mono);font-size:12px;color:var(--mu)}
.nt-spread{display:flex;justify-content:space-between;align-items:baseline}
.nt-seg{display:flex;background:var(--s2);border-radius:14px;padding:3px;gap:2px}
.nt-seg a{flex:1;text-align:center;padding:7px 0;border-radius:11px;font-size:14px;font-weight:600;color:var(--mu)}
.nt-seg a.on{background:var(--s1);color:var(--ink);box-shadow:0 1px 2px rgba(0,0,0,.1)}
.nt-pj{display:flex;gap:8px;overflow:hidden}
.nt-pc{flex:none;padding:7px 12px;border-radius:18px;border:1px solid var(--ln);background:var(--s1);font-size:14px;font-weight:600;color:var(--ink);display:flex;gap:6px;align-items:center}
.nt-pc small{font:12px var(--mono);color:var(--mu)}
.nt-pc.on{background:var(--acs);border-color:var(--acl);color:var(--ac)}
.nt-ph{padding:12px 14px}
.nt-ph b{font-size:18px}
.nt-bar2{height:5px;background:var(--s2);border-radius:3px;margin-top:9px}
.nt-bar2 i{display:block;height:5px;width:67%;background:var(--ac);border-radius:3px}
.nt-fl{display:flex;gap:6px;padding:0 2px}
.nt-fl span{font:12px var(--mono);padding:5px 11px;border-radius:12px;background:var(--s2);color:var(--mu)}
.nt-fl .on{background:var(--ink);color:var(--bg)}
.nt-list{overflow:hidden}
.nt-it{display:flex;gap:10px;align-items:flex-start;padding:11px 14px;border-top:1px solid var(--ln)}
.nt-it:first-child{border-top:0}
.nt-ck{flex:none;width:22px;height:22px;border-radius:50%;border:2px solid var(--mu);margin-top:1px;display:flex;align-items:center;justify-content:center;color:var(--on)}
.nt-ck.d{background:var(--ac);border-color:var(--ac)}
.nt-ck svg.ic{width:16px;height:16px;stroke-width:2.4}
.nt-it p{margin:0;font-size:15px;line-height:1.35}
.nt-it.dn p{color:var(--mu);text-decoration:line-through}
.nt-it.nt{border-left:3px solid var(--ac);background:var(--acs)}
.nt-it.nt p{font-size:14px}
.nt-it .nt-m{margin-top:3px}
.nt-gl{font:12px var(--mono);color:var(--mu);padding:2px 4px 0}
.nt-q{padding:13px 14px;border-top:1px solid var(--ln)}
.nt-q:first-child{border-top:0}
.nt-q p{margin:0 0 10px;font-size:15px;line-height:1.4}
.nt-who{display:flex;align-items:center;gap:10px}
.nt-av{width:30px;height:30px;border-radius:50%;background:var(--acs);color:var(--ac);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center}
.nt-who b{font-size:14px;display:block}
.nt-who .nt-tag{margin-left:auto}
.nt-tag{font:11px var(--mono);padding:2px 8px;border-radius:8px;background:var(--s2);color:var(--mu)}
.nt-tag.t{background:var(--acs);color:var(--ac)}
.nt-cmp{flex:none;padding:8px 12px 10px;background:var(--bg)}
.nt-cin{display:flex;align-items:center;gap:8px;padding:6px 6px 6px 14px}
.nt-cin input{flex:1;border:0;background:none;font:inherit;font-size:15px;height:38px;min-width:0;color:var(--ink);outline:0;box-shadow:none;padding:0}
.nt-tg2{display:flex;background:var(--s2);border-radius:12px;padding:2px}
.nt-tg2 span{padding:5px 10px;border-radius:10px;font-size:12px;font-weight:600;color:var(--mu)}
.nt-tg2 .on{background:var(--s1);color:var(--ac)}
.nt-sd{width:38px;height:38px;border-radius:50%;background:var(--ac);color:var(--on);border:0;display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.nt-sd svg.ic{width:18px;height:18px;stroke-width:2}
.nt-ov{position:fixed;inset:0;background:rgba(17,24,39,.42);z-index:40}
.nt-sht{position:fixed;left:50%;transform:translateX(-50%);width:100%;max-width:560px;bottom:0;background:var(--s1);border-radius:26px 26px 0 0;padding:10px 16px calc(16px + env(safe-area-inset-bottom,0px));display:flex;flex-direction:column;gap:10px;box-shadow:0 -8px 24px rgba(0,0,0,.15);z-index:41}
.nt-gr{width:40px;height:4px;border-radius:2px;background:var(--ln);align-self:center}
.nt-shh{display:flex;justify-content:space-between;align-items:center}
.nt-shh b{font-size:18px}
.nt-fi{background:var(--bg);border-radius:14px;padding:8px 12px}
.nt-fi .nt-m{display:block;font-size:11px}
.nt-fi b{font-size:16px;font-weight:600}
.nt-cl{display:flex;gap:12px;align-items:center}
.nt-cl i{width:26px;height:26px;border-radius:50%}
.nt-cl i.on{outline:2px solid var(--ink);outline-offset:2px}
.nt-op{display:flex;gap:12px;align-items:center;padding:9px 12px;border:1px solid var(--ln);border-radius:16px}
.nt-op.on{border-color:var(--ac);background:var(--acs)}
.nt-op b{font-size:15px;display:block}
.nt-op span.d{font-size:12px;color:var(--mu)}
.nt-rd{width:20px;height:20px;border-radius:50%;border:2px solid var(--mu);margin-left:auto;flex:none}
.nt-op.on .nt-rd{border:6px solid var(--ac)}
.nt-pv{width:46px;height:36px;border-radius:10px;background:var(--s2);flex:none;display:flex;flex-direction:column;justify-content:center;gap:5px;padding:0 8px}
.nt-pr2{display:flex;align-items:center;gap:4px}
.nt-pr2 u{width:7px;height:7px;border-radius:50%;border:1.5px solid var(--mu);box-sizing:border-box;flex:none}
.nt-pr2 i{height:4px;flex:1;border-radius:2px;background:var(--mu)}
.nt-tr2{display:flex;justify-content:space-between;align-items:center;font-size:14px}
.nt-tgl{width:40px;height:24px;border-radius:12px;background:var(--ac);position:relative}
.nt-tgl::after{content:"";position:absolute;right:3px;top:3px;width:18px;height:18px;border-radius:50%;background:var(--on)}
.nt-go{height:48px;border-radius:24px;background:var(--ac);color:var(--on);font-weight:700;font-size:16px;display:flex;align-items:center;justify-content:center}

/* file18: home (mobile) + bottom bar restyle */
html{--h-ink:var(--ink);--h-ink2:var(--ink);--h-mu:var(--mu);--h-ln:var(--ln);--h-ln2:var(--ln);--h-card:var(--s1);--h-chip:var(--s2);--h-chip2:var(--s2);--h-bar:var(--s2);--h-sub:var(--s2);--h-bg:var(--bg);--h-earn:var(--earn);--h-ac:var(--ac);--h-acs:var(--acs);--h-acl:var(--acl);--h-pur:var(--spend);--h-solid:var(--ac);--h-fill:var(--ac);--h-on:var(--on);--h-btmu:var(--mu);--h-btln:var(--ln);--h-mono:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--h-sans:Inter,var(--font-sys)}
html[data-theme=light]{--h-ink:#1f2430;--h-ink2:#374151;--h-mu:#5f6672;--h-ln:#eceef1;--h-ln2:#e1e4e8;--h-card:#fff;--h-chip:#eceef1;--h-chip2:#f1f2f4;--h-bar:#e5e7eb;--h-sub:#f1f2f4;--h-bg:#f3f4f6;--h-earn:#8a5a00;--h-ac:#2f6f78;--h-acs:#d6f1f1;--h-acl:#a9dcdc;--h-pur:#6a4fd1;--h-solid:#3b727b;--h-fill:#2f6f78;--h-on:#fff;--h-btmu:#5f6672;--h-btln:#e5e7eb}

/* bottom bar (all pages) */
.bt{height:64px;padding:0 10px env(safe-area-inset-bottom,0px);justify-content:space-around;border-top:1px solid var(--h-btln);background:var(--s1);box-shadow:none}
.bt a,.bt button{flex:none;width:52px;height:42px;border-radius:14px;border:1px solid transparent;color:var(--h-btmu)}
.bt a.on{width:58px;background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.bt a.on::before{content:none}
.bt svg.ic,.bt .on svg.ic{width:20px;height:20px;stroke-width:1.8}

/* top row on home */
.app:has(.hm) .mm{padding-left:12px;padding-right:12px}
.app:has(.hm) .top-status-bar.tsplit{padding:14px 16px 0}
.app:has(.hm) .top-status-bar.tsplit .clock-time{font-family:var(--h-sans);font-size:18px;font-weight:700;letter-spacing:0;color:var(--h-ink)}
.app:has(.hm) .top-status-bar.tsplit .clock-subdate,.app:has(.hm) .top-status-bar.tsplit .clock-num,.app:has(.hm) .top-status-bar.tsplit .clock-dot{font-family:var(--h-mono);font-size:13px;font-weight:500;color:var(--h-mu);opacity:1}
.app:has(.hm) .top-status-bar.tsplit .clock-ar{font-size:13px;font-weight:500;color:var(--h-mu)}

/* home base */
.hm{display:flex;flex-direction:column;gap:6px;padding-top:8px;font-family:var(--h-sans);color:var(--h-ink)}
.hm-c,.hm .xc{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none;margin:0}
.hm-m,.hm .tg0{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .tg0{font-weight:400}

/* balance */
.hm-bal{display:grid;grid-template-columns:1fr auto;grid-template-areas:"l b" "v b";align-items:center;height:44px;padding:4px 6px 4px 14px;column-gap:10px}
.hm-bal .hm-m{grid-area:l;font-size:11px;line-height:1.1}
.hm-bal .hm-dots{grid-area:v}
.hm-bal .ib{grid-area:b;align-self:center;justify-self:end;width:32px;height:32px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);box-shadow:none}
.hm .ib svg.ic{width:20px;height:20px;stroke-width:1.8}
.hm-dots{display:block;font-size:17px;line-height:1;letter-spacing:3px;font-weight:700}
.hm-dots:has(small){letter-spacing:0;font-size:19px}
.hm-dots small{font-size:12px;font-weight:500;color:var(--h-mu);letter-spacing:0}

/* earned / bought */
.hm-two{display:flex;gap:6px}
.hm-two .hm-c{flex:1;min-width:0;padding:6px 12px}
.hm-big{font-size:20px;font-weight:700;line-height:1.2;margin-top:2px;white-space:nowrap}
.hm-big small{font-size:13px;font-weight:500;color:var(--h-mu)}

/* income card */
.hm .xbare .xb{padding:4px 14px;border:0}
.hm .sw{border-top:1px solid var(--h-ln);border-bottom:0}
.hm .sw:first-child,.hm .sw:has(.hx)+.sw{border-top:0}
.hm .sw:last-child{border:0}
.hm .sw+.sw:last-child{border-top:1px solid var(--h-ln)}
.hm .hr{grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;min-height:44px;padding:4px 0}
.hm .hn{font-size:15px;font-weight:500}
.hm .hn .lb,.hm .by .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hr .ea,.hm .by .ea{color:var(--h-earn)!important;font-weight:600;font-size:15px;white-space:nowrap;text-align:right}
.hm .hr .ea small,.hm .by .ea small{font-size:12px;font-weight:500;color:inherit;margin-left:3px}
.hm .ub{width:30px;height:30px;border-radius:50%;border:0;background:var(--h-chip2);color:var(--h-mu);box-shadow:none}
.hm .hr .ub{justify-self:end;align-self:center}
.hm .ub svg.ic{width:16px;height:16px;stroke-width:1.6}
.hm .by{border-bottom:0;border-top:1px solid var(--h-ln);min-height:44px;padding:4px 0}
.hm .by:first-child{border-top:0}
.hm .btn.xs{height:36px;min-height:36px;padding:0 18px;border-radius:18px;font:600 15px/1 var(--h-sans);letter-spacing:0;box-shadow:none}
.hm .btn.xs.o{border:1px solid var(--h-acl);background:var(--h-card);color:var(--h-ac)}
.hm .btn.xs.o:hover{background:var(--h-acs);filter:none}
.hm .btn.xs:not(.o){background:var(--h-fill);border:1px solid var(--h-fill);color:var(--h-on)}
.hm .btn.xs.hadd{height:30px;min-height:30px;padding:0 14px;border-radius:15px;font-size:13px;align-self:center;justify-self:end}
.hm .btn.xs.off,.hm .btn.xs:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu);opacity:.8}
.hm .sw .ad{background:var(--h-bg);border:1px solid var(--h-ln2);border-radius:14px;padding:8px;margin:0 0 8px}
.hm .ad .ln{gap:8px;margin:0}
.hm .ad .in{height:36px;padding:0 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font-size:14px;margin:0}
.hm .ad .iw{height:36px;padding:0 12px;border-radius:14px;border-color:var(--h-ln2);background:var(--h-card)}
.hm .ad .iw .in{height:34px;padding:0;border:0;background:transparent}
.hm .ad label{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .in::placeholder{color:var(--h-mu);opacity:.85}

/* extra hours */
.hm .hx{background:var(--h-chip);border:0;border-radius:16px;margin:0 0 4px;overflow:hidden}
.hm .hx>summary{min-height:38px;padding:0 5px 0 12px;gap:8px;font:400 13px/1 var(--h-mono);color:var(--h-ink2)}
.hm .hx>summary>span:nth-child(2){color:var(--h-mu)}
.hm .hx>summary .chev{background:var(--h-card);color:var(--h-mu);width:28px;height:28px}
.hm .hxb{padding:0}
.hm .hxg{gap:8px;padding:2px 10px 0}
.hm .hc{background:var(--h-card);border:0;border-radius:12px;padding:7px 4px;gap:0;color:var(--h-ink);box-shadow:none}
.hm .hc b{font-size:14px;font-weight:600;color:var(--h-ink)}
.hm .hc small{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hc.on{background:var(--h-acs);box-shadow:inset 0 0 0 1px var(--h-acl)}
.hm .hc.on b{color:var(--h-ac)}
.hm .hxm{margin:0;padding:10px;gap:8px}
.hm .hxm .in{height:36px;padding:0 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font-size:14px;flex:1;margin:0}

/* expandable cards: buys, goals, owe */
.hm .xh{min-height:0;padding:9px 112px 9px 16px}
.hm .xn .xh{padding-right:52px}
.hm details[data-fixed]>.xh{padding:9px 70px 0 16px}
.hm .osum .ow{margin:0;gap:0;flex-wrap:nowrap;align-items:baseline}
.hm .ow .big2{font-size:26px;font-weight:700;letter-spacing:0;line-height:1.15}
.hm .ow .big2.sp{color:var(--h-pur)!important}
.hm .ow .big2 small{font:500 13px/1 var(--h-mono);color:var(--h-mu);margin-left:6px;letter-spacing:0}
.hm .ow .big2.sp small{color:var(--h-mu);margin-left:0}
.hm .ow>.lb,.hm .ow>.sm{font:500 13px/1 var(--h-mono);color:var(--h-mu)!important;margin-left:6px}
.hm .xc .chev{top:22px;margin-top:0;color:var(--h-ink);right:75px}
.hm .xn .chev{right:16px}
.hm .xc .chev svg.ic{width:22px;height:22px;stroke-width:1.8}
.hm .xp{width:46px;height:38px;border-radius:14px;top:13px;right:14px;border:1px solid var(--h-acl);background:var(--h-acs);color:var(--h-ac)}
.hm .xc:has(details[data-fixed]) .xp{top:10px}
.hm .xp svg.ic{width:20px;height:20px;stroke-width:1.8}
.hm .xj{opacity:.2}
.hm .xb{padding:0;border-top:0}
.hm .xbare .xb{padding:4px 14px}
.hm details[data-fixed] .xb{padding:2px 16px 9px}
.hm .xb .lb[style]{font:400 14px/1.4 var(--h-sans);color:var(--h-mu);padding:0!important}
.hm .xf{padding:9px 16px;background:var(--h-sub);border-top:1px solid var(--h-ln)}
.hm .xl{font:400 14px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .xl b{color:var(--h-ink)}
.hm .lnk{color:var(--h-ac);font:600 15px/1.3 var(--h-sans);text-decoration:underline;text-underline-offset:3px}
.hm details[data-keep-open=owe] .xf{padding:0;border:0;background:none}
.hm details[data-keep-open=owe] .xf .xl{display:none}
.hm details[data-keep-open=owe] .xf form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--h-ln);background:var(--h-sub)}
.hm details[data-fixed] .xf{padding:0;border:0;background:none}
.hm details[data-fixed] .xf form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--h-ln);background:var(--h-sub)}
.hm .xf .in,.hm .xf .iw{border-color:var(--h-ln2);background:var(--h-card);color:var(--h-ink)}
.hm .xf .btn.full{border-radius:24px;min-height:48px;font-size:16px;background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none}
.hm .xf .chip{background:var(--h-card);border-color:var(--h-ln2);color:var(--h-mu)}

/* goals open */
.hm .gw{padding:10px 16px 4px;border-top:1px solid var(--h-ln);border-bottom:0}
.hm .gw .db{padding:0;border:0;gap:0}
.hm .gw .l1{margin-bottom:0;align-items:baseline}
.hm .gw .l1 b{font-size:17px;font-weight:700;white-space:normal;overflow:visible}
.hm .gw .l1 .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .gw .mt{height:4px;margin:8px 0;background:var(--h-bar);border-radius:2px}
.hm .gw .mt i{background:var(--h-mu);border-radius:2px}
.hm .gw .mt.full i{background:var(--h-ac)}
.hm .gi{height:48px;margin-left:6px;padding:0 0 0 22px;gap:10px;border-left:2px solid var(--h-ln2)}
.hm .gn{font-size:16px}
.hm .gi .lb{font:400 13px/1 var(--h-mono);color:var(--h-mu);margin-right:4px}
.hm .gi .btn.xs{height:34px;min-height:34px;padding:0 18px;border-radius:20px;background:var(--h-solid);border-color:var(--h-solid)}
.hm .gi .btn.xs.off{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}

/* owe open */
.hm .xc .db{padding:9px 14px;gap:12px;border-top:1px solid var(--h-ln);border-bottom:0;align-items:center}
.hm .gw .db{padding:0;border:0;gap:0}
.hm .db .ib.sm{width:40px;height:40px;min-width:40px;background:var(--h-acs);border:1px solid var(--h-acl);color:var(--h-ac);box-shadow:none}
.hm .db .l1 b{font-size:17px;font-weight:600}
.hm .db .l1>span{font-size:16px;color:var(--h-ink2)}
.hm .dn .dl{margin:2px 0 6px;font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .db .mt.s{height:4px;background:var(--h-bar);border-radius:2px}
.hm .db .mt.s i{border-radius:2px}
.hm .db .btn.xs{height:34px;min-height:34px;border-radius:20px}
.hm .db .l1>b{white-space:normal;overflow:visible}

/* file19: pad + other pages */
.hm{display:block;gap:0;padding-top:0}
.hm-f{display:flex;flex-direction:column;gap:6px;padding-top:8px}
.mm.hm{padding-top:8px}
.hm .cd,.hm .sc,.hm .hero{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none}
.hm .cd{margin-top:8px}
.hm .tg{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .lb,.hm .mu.sm{font-family:var(--h-mono)}
.hm .rw,.hm .by,.hm .db{border-color:var(--h-ln)}
.hm .big{font-size:34px;font-weight:700;letter-spacing:0}
.hm .big2{font-weight:700;letter-spacing:0}
.hm .hd{margin:10px 4px 2px}
.hm .hd h1.t{font-size:18px;font-weight:700;letter-spacing:0}
.hm .btn{background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none;font-family:var(--h-sans)}
.hm .btn.o{background:var(--h-card);border-color:var(--h-acl);color:var(--h-ac)}
.hm .btn.full{border-radius:24px;min-height:48px;font-size:16px}
.hm .btn.off,.hm .btn:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .in,.hm .of input{background:var(--h-card);border:1px solid var(--h-ln2);border-radius:14px;color:var(--h-ink)}
.hm .chip{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .chip.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .av{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .sg{background:var(--h-chip);border-color:var(--h-ln)}
.hm .li:hover{background:var(--h-chip)}
.hm .mt{background:var(--h-bar)}
.hm .mt i{background:var(--h-mu)}
.hm .mt.n i{background:var(--h-pur)}
.hm .pos{color:var(--pos)!important}
.hm .nt-page{padding-top:0}

/* pad */
.nt-c{background:var(--h-card);border-color:var(--h-ln)}
.nt-m{font-family:var(--h-mono);color:var(--h-mu)}
.nt-f{display:contents}
.nt-b{flex:1;min-width:0}
.nt-it{align-items:flex-start}
button.nt-ck{background:none;padding:0;cursor:pointer;color:var(--h-on);flex:none}
button.nt-ck.d{background:var(--h-ac);border-color:var(--h-ac)}
.nt-x{flex:none;width:26px;height:26px;border-radius:50%;border:0;background:none;color:var(--h-mu);padding:0;display:flex;align-items:center;justify-content:center;opacity:.75}
.nt-x svg.ic{width:16px;height:16px;transform:rotate(45deg)}
.nt-em{padding:16px 14px}
.nt-pj{overflow-x:auto;scrollbar-width:none}
.nt-pj::-webkit-scrollbar{display:none}
.nt-pc{text-decoration:none;white-space:nowrap}
.nt-dot{width:8px;height:8px;border-radius:50%;flex:none}
.nt-pc.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.nt-fl a{font:12px var(--h-mono);padding:5px 11px;border-radius:12px;background:var(--h-chip);color:var(--h-mu)}
.nt-fl a.on{background:var(--h-ink);color:var(--h-card)}
.nt-bar2{background:var(--h-bar)}
.nt-bar2 i{background:var(--h-ac)}
.nt-del{text-align:center;margin:2px 0 6px}
.nt-del button{background:none;border:0;padding:6px;color:var(--h-mu);font-size:12px;text-decoration:underline;width:auto}
.nt-who .nt-tag{margin-left:auto}
.nt-cin .nt-who-i{flex:0 0 76px;width:76px;border-right:1px solid var(--h-ln);padding-right:8px;border-radius:0}
.nt-cin input{background:none;border:0;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-tg2{position:relative;background:var(--h-chip)}
.nt-tg2 label{display:flex;margin:0}
.nt-tg2 input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-tg2 input:checked+span{background:var(--h-card);color:var(--h-ac)}
.nt-tg2 span{cursor:pointer}
.nt-sd{background:var(--h-fill);color:var(--h-on)}
.nt-sel{width:100%;margin:6px 0 0;padding:6px 12px;height:34px;border-radius:14px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);font-size:13px}
.nt-cmp{background:var(--bg)}
.nt-sht{max-height:92dvh;overflow:auto;background:var(--h-card)}
.nt-fi{display:block;background:var(--h-bg);margin:0}
.nt-fi input{display:block;width:100%;height:auto;border:0;background:none;padding:0;margin:0;font-size:16px;font-weight:600;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-cl label{position:relative;display:block;margin:0;cursor:pointer}
.nt-cl input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-cl input:checked+i{outline:2px solid var(--h-ink);outline-offset:2px}
.nt-op{position:relative;cursor:pointer;margin:0}
.nt-op input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-op:has(input:checked){border-color:var(--h-ac);background:var(--h-acs)}
.nt-op:has(input:checked) .nt-rd{border:6px solid var(--h-ac)}
.nt-tr2{margin:0;cursor:pointer}
input.nt-tgl[type=checkbox],input.nt-tgl[type=checkbox]:checked{-webkit-appearance:none;appearance:none;background-image:none;width:40px;height:24px;border-radius:12px;border:0;padding:0;margin:0;position:relative;background-color:var(--h-chip);flex:none}
input.nt-tgl[type=checkbox]:checked{background-color:var(--h-ac)}
input.nt-tgl[type=checkbox]::after{content:"";position:absolute;left:3px;right:auto;top:3px;width:18px;height:18px;border-radius:50%;background:var(--h-card);transition:left .15s}
input.nt-tgl[type=checkbox]:checked::after{left:19px}
.nt-go{border:0;width:100%;background:var(--h-fill);color:var(--h-on);text-decoration:none}

/* balance reveal + goals manage row */
.hm-bal{height:auto;min-height:48px;padding:8px 8px 8px 14px}
.hm-dots:has(small){font-size:18px;line-height:1.15;letter-spacing:0}
.hm-two .hm-c{flex:1 1 0}
.hm .gw .db{gap:10px}

/* file20: spacing, shadow, centered icons, invoice, pad edit */
.hm-f{gap:12px}
.hm-two{gap:10px}
.hm .cd{margin-top:12px}
.nt-page{gap:12px}
.hm-c,.hm .xc,.hm .cd,.hm .sc,.hm .hero,.nt-c{box-shadow:var(--sh1)}
.bt{box-shadow:var(--sh1)}

/* header icons centered inside the summary */
.hm .xp{top:50%;margin-top:-19px;right:14px}
.hm .xc:has(details[data-fixed]) .xp{top:50%}
.hm .xc .chev{top:50%;margin-top:-11px}
.hm .xc:has(.xp.on) .chev{display:none}
.hm details[data-fixed]>.xh{padding:9px 70px 9px 16px}
.hm .xb:empty{display:none}
.hm .osum .ow .em{font:400 14px/1.4 var(--h-sans);color:var(--h-mu)}

/* balance card (home + profile) */
.hm-bal .hm-ba{grid-area:b;display:flex;align-items:center;justify-content:flex-end;gap:8px;align-self:center;height:100%}
.hm-bal .hm-ba .ib{grid-area:auto;align-self:center}
.hm-balc{padding:0;overflow:hidden}
.hm-bedit{padding:0 14px 14px}

/* exoclick invoice */
.inv{display:flex;align-items:center;gap:10px;padding:8px 8px 8px 14px;margin-bottom:12px}
.inv>div:first-child{flex:1;min-width:0}
.inv-a{font-size:20px;font-weight:700;line-height:1.2}
.inv-st{font:600 12px/1 var(--h-mono);padding:5px 10px;border-radius:12px;background:var(--h-chip);color:var(--h-mu);flex:none}
.inv-st.pending{background:rgba(166,106,0,.14);color:var(--h-earn)}
.inv-st.processing{background:rgba(109,79,214,.14);color:var(--h-pur)}
.inv-st.paid{background:rgba(18,161,80,.14);color:var(--pos)}
.inv .ub svg.ic{transform:rotate(45deg)}

/* pad: tap copies, long press edits */
.nt-b{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;cursor:pointer}
.nt-it,.nt-q{flex-wrap:wrap}
.nt-q .nt-b p{margin:0 0 10px}
.nt-edit{flex:1 1 0;min-width:0;display:flex;flex-direction:column;gap:8px;margin:0}
.nt-edit textarea{width:100%;margin:0;padding:8px 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font:15px/1.35 var(--h-sans);resize:none}
.nt-eb{display:flex;gap:8px;justify-content:flex-end}
.nt-edit .nt-cin{padding:4px 6px 4px 14px}
.nt-xc{flex:none;width:30px;height:30px;border:0;background:none;color:var(--mu);padding:0;display:flex;align-items:center;justify-content:center;border-radius:50%}
.nt-xc svg.ic{width:18px;height:18px;transform:rotate(45deg)}
.nt-mn{position:relative;flex:none;align-self:flex-start}
.nt-mn[hidden],.nt-dd[hidden]{display:none!important}
.nt-mn .nt-x svg.ic{transform:none}
.nt-dd{position:absolute;right:0;top:calc(100% + 4px);z-index:40;min-width:150px;padding:4px;background:var(--s1);border:1px solid var(--ln);border-radius:14px;box-shadow:0 10px 28px rgba(0,0,0,.28)}
.nt-dd form{display:block;margin:0}
.nt-dd button{position:relative;display:flex;align-items:center;gap:10px;width:100%;padding:10px 12px;border:0;border-radius:10px;background:none;color:var(--ink);font:inherit;font-size:14px;text-align:left;cursor:pointer}
.nt-dd button:hover{background:var(--s2)}
.nt-dd button.dg{color:var(--neg)}
.nt-dd svg.ic{width:16px;height:16px;flex:none}
.nt-list:has(.nt-dd:not([hidden])),.nt-q:has(.nt-dd:not([hidden])){overflow:visible}
.nt-toast{position:fixed;left:50%;bottom:96px;transform:translateX(-50%);background:var(--h-ink);color:var(--h-card);padding:8px 16px;border-radius:18px;font-size:13px;z-index:60}
GOAT_EOF
echo "updated app/client/app.css"

mkdir -p "$(dirname app/screens.tsx)"
cat > app/screens.tsx <<'GOAT_EOF'
import { BuysDesktop, BuysExpand, Hero, TodayCards } from "./components/buys.tsx"
import { OweDesktop, OweMobile, RoadCard } from "./components/debts.tsx"
import { GoalsExpand } from "./components/goals.tsx"
import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"
import { HomeBalance, HomeToday } from "./components/home.tsx"
import { HomeIncome, IncomeDesktop, IncomeExpand, InvoiceCard } from "./components/income.tsx"
import { AppLayout, AuthLayout } from "./components/layout.tsx"
import { ChatHead, Composer, NoteCard, NoteList } from "./components/notes.tsx"
import { PadBody, PadComposer, type PadTab } from "./components/pad.tsx"
import type { PadData } from "./lib/padmeta.ts"
import type { User } from "./lib/users.ts"
import { BalanceCard, EditProfileMobile, ProfileMobile, SettingsDesktop, SettingsMobile } from "./components/profile.tsx"
import { TradingBody } from "./components/trading.tsx"
import { ErrorBanner, FloatField, GoogleMark, Logo, PageHeader, Section, Submit, view } from "./components/ui.tsx"
import type { State } from "./lib/data.ts"
import { fmt } from "./lib/money.ts"
import { calc } from "./lib/view.ts"

export const HomeScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Home"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="home"
		mobile={
			<div class="hm hm-f">
				<ErrorBanner s={s} />
				<HomeBalance s={s} />
				<HomeToday s={s} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</div>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<Hero s={s} />
				<div class="g2">
					<div>
						<BuysDesktop s={s} />
					</div>
					<div>
						<OweDesktop s={s} open={false} storeKey="owe" />
						<IncomeDesktop s={s} bare />
						<NoteCard s={s} />
					</div>
				</div>
			</>
		}
	/>
))

export const DebtsScreen = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<AppLayout
			title="Debts"
			theme={s.user.theme}
			mobileTab="home"
			desktopTab="home"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={s.debts.map((d) => d.person).slice(0, 2).join(" + ")} />
					<RoadCard s={s} />
					<OweMobile s={s} open storeKey="owe-page" manage />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`} />
					<div class="g3">
						<div>
							<OweDesktop s={s} open storeKey="owe-page" manage />
						</div>
						<div>
							<Section title="How it works">
								<div class="rw">
									<span>+ left of a name</span>
									<span class="mu">adds to that person</span>
								</div>
								<div class="rw">
									<span>Pay</span>
									<span class="mu">counts as a buy today</span>
								</div>
								<div class="rw">
									<span>Paid to 0</span>
									<span class="mu">hidden, kept in history</span>
								</div>
								<div class="rw">
									<span>Type old name</span>
									<span class="mu">brings them back</span>
								</div>
							</Section>
						</div>
					</div>
				</>
			}
		/>
	)
})

export const GoalsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Goals"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="plan"
		mobile={
			<>
				<PageHeader title="Goals" right="add, edit, remove" />
				<ErrorBanner s={s} />
				<GoalsExpand s={s} open storeKey="goals-page" manage />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<PageHeader title="Plan" right="goals + income" />
				<div class="g3">
					<div>
						<GoalsExpand s={s} open storeKey="goals-d" manage />
					</div>
					<div>
						<IncomeDesktop s={s} />
					</div>
				</div>
			</>
		}
	/>
))

export const HistoryScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="History"
		theme={s.user.theme}
		mobileTab="history"
		desktopTab="history"
		mobile={
			<>
				<PageHeader title="History" right="last 30 days" />
				<HistoryMobile s={s} />
			</>
		}
		desktop={<HistoryDesktop s={s} />}
	/>
))

export const IncomeScreen = view<{ s: State }>(({ s }) => {
	const earned = calc(s).earned
	return (
		<AppLayout
			title="Income"
			theme={s.user.theme}
			mobileTab="income"
			desktopTab="income"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Income" right={earned ? `+${fmt(earned)} today` : ""} />
					<InvoiceCard s={s} />
<IncomeExpand s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<div class="hd">
						<h1 class="t">Income</h1>
						<span></span>
					</div>
					<InvoiceCard s={s} />
<IncomeExpand s={s} />
				</>
			}
		/>
	)
})

export const NotesScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Notes"
		theme={s.user.theme}
		mobileTab="notes"
		desktopTab="notes"
		mobile={
			<>
				<ChatHead />
				<NoteList s={s} listKey="m" />
			</>
		}
		dock={<Composer s={s} listKey="m" />}
		desktop={
			<div class="chat" data-x>
				<ChatHead />
				<NoteList s={s} listKey="d" />
				<div style={{ margin: "30px 0 0" }}>
					<Composer s={s} listKey="d" />
				</div>
			</div>
		}
	/>
))

export const PadScreen = view<{ u: User; d: PadData; tab: PadTab; f: string; error: string }>(({ u, d, tab, f, error }) => (
	<AppLayout
		title="Pad"
		theme={u.theme}
		mobileTab="pad"
		desktopTab="pad"
		mobile={<PadBody d={d} tab={tab} f={f} error={error} />}
		dock={<PadComposer d={d} tab={tab} f={f} />}
		desktop={
			<div class="chat">
				<PadBody d={d} tab={tab} f={f} error={error} />
				<PadComposer d={d} tab={tab} f={f} />
			</div>
		}
	/>
))

export const ProfileScreen = view<{ s: State }>(({ s }) => (
	<AppLayout title="Profile" theme={s.user.theme} mobileTab="profile" desktopTab="settings" mobile={<ProfileMobile s={s} />} desktop={<SettingsDesktop s={s} />} />
))

export const ProfileEditScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Edit profile"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="Edit profile" back="/profile" />
				<EditProfileMobile s={s} />
			</>
		}
		desktop={<SettingsDesktop s={s} />}
	/>
))

export const SettingsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Settings"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="Settings" back="/profile" />
				<SettingsMobile s={s} />
			</>
		}
		desktop={<SettingsDesktop s={s} />}
	/>
))

export const TradingScreen = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.user.usdt_rate)} ${s.user.currency}`
	return (
		<AppLayout
			title="Trading"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
		/>
	)
})

const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-center-wrap">
		<div class="auth-glass-box">
			<div class="auth-logo-center">
				<Logo href="/login" />
			</div>
			<h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1>
			<div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>
			<form class="au" method="post" action={up ? "/signup" : "/login"}>
				<a class="gbtn" href="/login/google">
					<GoogleMark />
					<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
				</a>
				<div class="or">or</div>
				{error ? (
					<div class="auth-err-banner" role="alert">
						{error}
					</div>
				) : null}
				{up ? <FloatField label="Name" name="name" auto="name" /> : null}
				<FloatField label="Email" type="email" name="email" auto="email" />
				<FloatField label="Password" type="password" name="password" auto={up ? "new-password" : "current-password"} />
				<Submit class="btn full">{up ? "Create account" : "Sign in"}</Submit>
				<div class="auth-switch-wrap">
					<a class="lnk-switch" href={up ? "/login" : "/signup"}>
						{up ? (
							<>
								Already have an account? <b>Sign in</b>
							</>
						) : (
							<>
								Don't have an account? <b>Create account</b>
							</>
						)}
					</a>
				</div>
			</form>
		</div>
	</div>
))

export const LoginScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker.">
		<AuthCard up={false} error={error} />
	</AuthLayout>
))

export const SignupScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals.">
		<AuthCard up error={error} />
	</AuthLayout>
))
GOAT_EOF
echo "updated app/screens.tsx"

mkdir -p "$(dirname app/components/buys.tsx)"
cat > app/components/buys.tsx <<'GOAT_EOF'
import type { Buy, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Back, Card, Empty, ExpandCard, Icon, ListCard, NameChips, Submit, view } from "./ui.tsx"

export const buyName = (b: Buy) => (b.qty > 1 ? `${b.name} ×${b.qty}` : b.name)

export const SpendRow = view<{ s: State; id: string; name: string; sub: string; amount: string }>(({ s, id, name, sub, amount }) => (
	<div class="by">
		<div>
			<div>{name}</div>
			<div class="lb">{sub}</div>
		</div>
		<span class="rt">
			<b class="sp">{amount}</b>
			<form method="post" action="/buy/delete" style={{ display: "contents" }} data-confirm="Undo this buy? The money comes back.">
				<Back s={s} />
				<input type="hidden" name="id" value={id} />
				<Submit class="ub" aria-label="Undo buy">
					<Icon name="undo" />
				</Submit>
			</form>
		</span>
	</div>
))

const BuyRows = view<{ s: State }>(({ s }) => (
	<div>
		{s.buys.length ? (
			s.buys.map((b) => <SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={`${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`} amount={`−${fmt(b.total)}`} />)
		) : (
			<Empty>Nothing bought today.</Empty>
		)}
	</div>
))

const SpendFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.names} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Item" autocomplete="off" required />
			<input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required />
		</div>
		<Submit class="btn full">Add a spend</Submit>
	</>
))

export const BuysExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="buys"
		open
		fixed
		title="Today's buys"
		label="Add a spend"
		head={s.buys.length ? undefined : <span class="em">Nothing bought today.</span>}
		form={
			<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>
				<SpendFields s={s} />
			</form>
		}
	>
		{s.buys.length ? <BuyRows s={s} /> : null}
	</ExpandCard>
))

export const BuysDesktop = view<{ s: State }>(({ s }) => (
	<>
		<form method="post" action="/buy" id="f-buy-d" class="sc spf" data-sp data-adp hidden>
			<SpendFields s={s} />
		</form>
		<ListCard title="Today's buys" right={`${s.buys.length}`} target="f-buy-d" label="Add a spend">
			<BuyRows s={s} />
		</ListCard>
	</>
))

export const TodayCards = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="two">
			<Card title="Earned today">
				<div class="big2" style={{ whiteSpace: "nowrap" }}>
					+{fmt(c.earned)} <small>{s.user.currency}</small>
				</div>
			</Card>
			<Card title="Bought today">
				<div class="big2" style={{ whiteSpace: "nowrap" }}>
					−{fmt(c.bought)} <small>{s.user.currency}</small>
				</div>
			</Card>
		</div>
	)
})

export const EarnedTop = view<{ s: State }>(({ s }) => (
	<div class="earn-top">
		<div class="lb">Earned today</div>
		<b class="ea">
			+{fmt(calc(s).earned)} <small>{s.user.currency}</small>
		</b>
	</div>
))

export const Hero = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hero">
			<div>
				<div class="lb">Earned today</div>
				<div class="v">+{fmt(c.earned)}</div>
				{c.earnedLine ? <div class="lb">{c.earnedLine}</div> : null}
			</div>
			<div>
				<div class="lb">Bought today</div>
				<div class="v">−{fmt(c.bought)}</div>
				<div class="lb">{s.buys.length} buys</div>
			</div>
			<div>
				<div class="lb">Road to goals</div>
				<div class="v">{c.pct}%</div>
				<div class="mt">
					<i style={{ width: `${c.pct}%` }}></i>
				</div>
			</div>
			<div>
				<div class="lb">I owe</div>
				<div class="v sp">{fmt(c.oweMoney)}</div>
				<div class="lb">
					{s.user.currency} {c.oweExtra}
				</div>
			</div>
		</div>
	)
})
GOAT_EOF
echo "updated app/components/buys.tsx"

mkdir -p "$(dirname app/components/debts.tsx)"
cat > app/components/debts.tsx <<'GOAT_EOF'
import type { DebtView, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { dayLabel, dayOf, hhmm, timeAgo } from "../lib/time.ts"
import { calc, debtPct, peopleCount, pctOf } from "../lib/view.ts"
import { Back, BigAdd, Empty, ExpandCard, Icon, NameChips, Submit, view } from "./ui.tsx"

type DebtProps = { s: State; d: DebtView; manage: boolean }

const lastLine = (s: State, d: DebtView) => {
	const when = `${dayLabel(dayOf(d.at))} · ${hhmm(d.at)}`
	if (!d.delta) return `Started ${timeAgo(d.at)}`
	const unit = d.kind === "money" ? s.user.currency : d.item
	const n = d.kind === "money" ? fmt(Math.abs(d.delta)) : String(Math.abs(d.delta))
	return `${d.delta > 0 ? "Added" : "Paid"} ${n} ${unit} · ${when}`
}

const DebtPanel = view<DebtProps & { kind: "add" | "pay" }>(({ s, d, kind, manage }) => {
	const pay = kind === "pay"
	const unit = d.kind === "money" ? s.user.currency : d.item
	const all = d.kind === "money" ? plain(d.owed) : String(d.owed)
	return (
		<form method="post" action={pay ? "/debts/pay" : "/debts"} class="ad" data-addp={pay ? undefined : true} data-payp={pay ? true : undefined} hidden>
			<input type="hidden" name="debt_id" value={d.id} />
			<Back s={s} />
			<label>
				{pay ? "Pay" : "Add to"} {d.person}
			</label>
			<div class="ln">
				<div class="iw">
					<input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off" />
					{pay ? (
						<button type="button" class="all" data-all={all} aria-label="Fill the full amount">
							All
						</button>
					) : null}
					<span class="mu">{unit}</span>
				</div>
				<Submit class="btn xs">{pay ? "Pay" : "Add"}</Submit>
				{manage ? (
					<Submit class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn={`Remove ${d.person} from the list without marking it paid?`} aria-label="Remove without paying" title="Remove without paying">
						<Icon name="trash" />
					</Submit>
				) : null}
			</div>
		</form>
	)
})

const DebtRow = view<DebtProps>(({ s, d, manage }) => {
	const label = d.kind === "money" ? `${fmt(d.owed)} ${s.user.currency}` : `${d.owed} ${d.item}`
	return (
		<div class="dbw">
			<div class="db">
				<button type="button" class="ib sm hi" data-tg aria-label={`Add debt to ${d.person}`}>
					<Icon name="plus" />
				</button>
				<div class="dn">
					<div class="l1">
						<b>{d.person}</b>
						<span>{label}</span>
					</div>
					<div class="lb dl">{lastLine(s, d)}</div>
					<div class="mt s n">
						<i style={{ width: `${debtPct(d)}%` }}></i>
					</div>
				</div>
				<button type="button" class="btn xs o" data-pay>
					Pay
				</button>
			</div>
			<DebtPanel s={s} d={d} manage={manage} kind="add" />
			<DebtPanel s={s} d={d} manage={manage} kind="pay" />
		</div>
	)
})

const DebtList = view<{ s: State; manage: boolean }>(({ s, manage }) => (s.debts.length ? <>{s.debts.map((d) => <DebtRow key={d.id} s={s} d={d} manage={manage} />)}</> : <Empty>Nobody to pay. All clear.</Empty>))

const AddDebtPanel = view<{ s: State }>(({ s }) => (
	<form method="post" action="/debts" class="sf adp" data-adp hidden>
		<Back s={s} />
		<NameChips names={[...new Set(s.debts.map((d) => d.person))]} />
		<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required />
		<div class="iw">
			<input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required />
			<span class="mu">{s.user.currency}</span>
		</div>
		<Submit class="btn full">Add</Submit>
	</form>
))

type OweProps = { s: State; open: boolean; storeKey: string; manage?: boolean }

export const OweMobile = view<OweProps>(({ s, open, storeKey, manage = false }) => {
	const c = calc(s)
	const n = peopleCount(s)
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="I owe"
			label="Add debt"
			head={
				<>
					<b class="big2 sp">
						{fmt(c.oweMoney)} <small>{s.user.currency}</small>
					</b>
					<span class="sp sm">{c.oweExtra}</span>
				</>
			}
			foot={
				<div class="xl">
					<span>{n === 1 ? "1 person" : `${n} people`}</span>
				</div>
			}
			form={<AddDebtPanel s={s} />}
		>
			<DebtList s={s} manage={manage} />
		</ExpandCard>
	)
})

export const OweDesktop = view<OweProps>(({ s, open, storeKey, manage = false }) => {
	const c = calc(s)
	return (
		<div class="sc bgc">
			<BigAdd label="Add debt" />
			<div class="ct">
				<details data-keep-open={storeKey} open={open ? true : undefined}>
					<summary class="sh">
						<span>I owe</span>
						<span class="rr">
							<span class="lb">{`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`}</span>
							<span class="chev">
								<Icon name="chev" />
							</span>
						</span>
					</summary>
					<DebtList s={s} manage={manage} />
				</details>
				<AddDebtPanel s={s} />
			</div>
		</div>
	)
})

export const RoadCard = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	const chips = [
		...s.goals.map((g) => ({ key: `g${g.id}`, text: `${g.title} ${pctOf(s, g)}%` })),
		...s.debts.filter((d) => d.kind === "money").map((d) => ({ key: `d${d.id}`, text: `${d.person} ${debtPct(d)}%` })),
	]
	return (
		<div class="cd jarc">
			<i class="jar" style={{ width: `${c.pct}%` }}></i>
			<div class="jin">
				<div class="tg">Road to goals</div>
				<div class="cb">
					<div class="gl">
						<span class="big">
							{c.pct}
							<small>%</small>
						</span>
						<span class="lb">{`${fmt(c.toGo)} ${s.user.currency} to go`}</span>
					</div>
					{chips.length ? (
						<div class="chips">
							{chips.map((x) => (
								<span key={x.key} class="chip">
									{x.text}
								</span>
							))}
						</div>
					) : null}
				</div>
			</div>
		</div>
	)
})
GOAT_EOF
echo "updated app/components/debts.tsx"

mkdir -p "$(dirname app/components/goals.tsx)"
cat > app/components/goals.tsx <<'GOAT_EOF'
import type { Goal, GoalItem, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { canAfford, goalLeft, goalStat, pctOf } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const ItemRow = view<{ s: State; it: GoalItem; manage: boolean }>(({ s, it, manage }) => {
	const ok = canAfford(s, it)
	const cls = it.done ? "gi gdone" : "gi"
	const hid = () => (
		<>
			<Back s={s} />
			<input type="hidden" name="id" value={it.id} />
		</>
	)
	const name = (
		<>
			<span class="gn">{it.name}</span>
			<span class="lb">{fmt(it.price)}</span>
		</>
	)

	if (!manage) {
		return (
			<div class={cls}>
				{name}
				<span class="wb">
					{it.done ? null : (
						<form method="post" action="/goals/buy" style={contents} data-confirm={`Mark ${it.name} as bought? It will be added as a spend.`}>
							{hid()}
							<Submit class={ok ? "btn xs" : "btn xs off"} disabled={ok ? undefined : true}>
								Bought
							</Submit>
						</form>
					)}
				</span>
			</div>
		)
	}

	return (
		<div class="dbw">
			<div class={cls}>
				{name}
				<span class="wb">
					{it.done ? null : (
						<button type="button" class="ub" data-pay aria-label={`Edit ${it.name}`}>
							<Icon name="edit" />
						</button>
					)}
					<form method="post" action="/goals/item/delete" style={contents} data-confirm={`Remove ${it.name} from this goal?`}>
						{hid()}
						<Submit class="ub" aria-label={`Remove ${it.name}`}>
							<Icon name="trash" />
						</Submit>
					</form>
				</span>
			</div>
			{it.done ? null : (
				<form method="post" action="/goals/item/edit" class="ad" data-payp hidden>
					{hid()}
					<label>Edit {it.name}</label>
					<div class="ln">
						<input class="in f" name="name" value={it.name} autocomplete="off" required />
						<input class="in pr2" name="price" value={plain(it.price)} placeholder="Price" inputmode="decimal" autocomplete="off" required />
						<Submit class="btn xs">Save</Submit>
					</div>
				</form>
			)}
		</div>
	)
})

const GoalRow = view<{ s: State; g: Goal; manage: boolean }>(({ s, g, manage }) => {
	const pct = pctOf(s, g)
	const info = (
		<div class="dn">
			<div class="l1">
				<b>{g.title}</b>
				<span class="lb">{goalLeft(s, g)}</span>
			</div>
			<div class={pct >= 100 ? "mt s full" : "mt s"}>
				<i style={{ width: `${pct}%` }}></i>
			</div>
		</div>
	)
	const items = g.items.map((it) => <ItemRow key={it.id} s={s} it={it} manage={manage} />)

	if (!manage) {
		return (
			<div class="gw">
				<div class="db">{info}</div>
				{items}
			</div>
		)
	}

	return (
		<div class="gw">
			<div class="dbw">
				<div class="db">
					<button type="button" class="ib sm hi" data-tg aria-label={`Add item to ${g.title}`}>
						<Icon name="plus" />
					</button>
					{info}
					<span class="wb">
						<button type="button" class="ub" data-pay aria-label={`Rename ${g.title}`}>
							<Icon name="edit" />
						</button>
						<form method="post" action="/goals/delete" style={contents} data-confirm={`Delete ${g.title} and all its items?`}>
							<Back s={s} />
							<input type="hidden" name="id" value={g.id} />
							<Submit class="ub" aria-label={`Delete ${g.title}`}>
								<Icon name="trash" />
							</Submit>
						</form>
					</span>
				</div>
				<form method="post" action="/goals/item" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="goal_id" value={g.id} />
					<label>Add item to {g.title}</label>
					<div class="ln">
						<input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required />
						<input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required />
						<Submit class="btn xs">Add</Submit>
					</div>
				</form>
				<form method="post" action="/goals/edit" class="ad" data-payp hidden>
					<Back s={s} />
					<input type="hidden" name="id" value={g.id} />
					<label>Rename goal</label>
					<div class="ln">
						<input class="in f" name="name" value={g.title} autocomplete="off" required />
						<Submit class="btn xs">Save</Submit>
					</div>
				</form>
			</div>
			{items}
		</div>
	)
})

const GoalList = view<{ s: State; manage: boolean }>(({ s, manage }) =>
	s.goals.length ? (
		<>{s.goals.map((g) => <GoalRow key={g.id} s={s} g={g} manage={manage} />)}</>
	) : (
		<Empty>{manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</Empty>
	),
)

const GoalForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/goals" class="sf xfm" data-adp hidden>
		<Back s={s} />
		<input class="in" name="name" placeholder="Goal name" autocomplete="off" required />
		<Submit class="btn full">Add goal</Submit>
	</form>
))

export const GoalsExpand = view<{ s: State; open: boolean; storeKey: string; manage: boolean }>(({ s, open, storeKey, manage }) => {
	const g = goalStat(s)
	const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${s.user.currency} to go`
	const head = (
		<>
			<b class="big2">
				{g.pct}
				<small>%</small>
			</b>
			<span class="lb">{sub}</span>
		</>
	)
	if (manage) {
		return (
			<ExpandCard
				storeKey={storeKey}
				open={open}
				title="Goals"
				head={head}
				jar={g.pct}
				label="Add goal"
				foot={
					<div class="xl">
						<span>Pencil edits, bin removes</span>
					</div>
				}
				form={<GoalForm s={s} />}
			>
				<GoalList s={s} manage />
			</ExpandCard>
		)
	}
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="Goals"
			head={head}
			jar={g.pct}
			foot={
				<div class="xl">
					<span>{`Left to buy ${fmt(g.target)} ${s.user.currency}`}</span>
					<a class="lnk" href="/goals">
						Manage
					</a>
				</div>
			}
		>
			<GoalList s={s} manage={false} />
		</ExpandCard>
	)
})
GOAT_EOF
echo "updated app/components/goals.tsx"

mkdir -p "$(dirname app/components/history.tsx)"
cat > app/components/history.tsx <<'GOAT_EOF'
import type { DayRow, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { dayNet } from "../lib/view.ts"
import { buyName, SpendRow } from "./buys.tsx"
import { IncomeRow } from "./income.tsx"
import { Back, Card, ErrorBanner, PageHeader, Section, Submit, view } from "./ui.tsx"

const DayItems = view<{ s: State; d: DayRow }>(({ s, d }) => (
	<>
		{d.incomes.map((i) => (
			<IncomeRow key={i.id} s={s} i={i} />
		))}
		{d.buys.map((b) => (
			<SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : ""} amount={`−${fmt(b.total)}`} />
		))}
	</>
))

const DayForms = view<{ s: State; wide: boolean }>(({ s, wide }) => {
	const t = today(s.user.day_start)
	const body = (
		<>
			<form method="post" action="/buy">
				<Back s={s} />
				<div class="ln">
					<input class="in" name="label" placeholder="Item" autocomplete="off" required />
					<input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required />
				</div>
				<div class="ln" style={{ marginTop: "8px" }}>
					<input class="in" type="date" name="day" value={t} max={t} required />
					<Submit class="btn xs">Add buy</Submit>
				</div>
			</form>
			<form method="post" action="/history/income" style={{ marginTop: "14px" }}>
				<Back s={s} />
				<div class="ln">
					<input class="in" name="label" placeholder="Name (optional)" autocomplete="off" />
					<input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required />
				</div>
				<div class="ln" style={{ marginTop: "8px" }}>
					<input class="in" type="date" name="day" value={t} max={t} required />
					<Submit class="btn xs">Add income</Submit>
				</div>
			</form>
		</>
	)
	return wide ? <Section title="Add to any day">{body}</Section> : <Card title="Add to any day">{body}</Card>
})

export const HistoryMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<DayForms s={s} wide={false} />
		{s.days.map((d) => (
			<Card key={d.day} title={d.label}>
				<div class="l1">
					<span>
						<span class="lb">Earned</span> <b class="ea">+{fmt(d.earned)}</b>
					</span>
					<span>
						<span class="lb">Bought</span> <b class="sp">−{fmt(d.bought)}</b>
					</span>
					<b>{dayNet(d.earned, d.bought)}</b>
				</div>
				<DayItems s={s} d={d} />
			</Card>
		))}
	</>
))

export const HistoryDesktop = view<{ s: State }>(({ s }) => {
	const earned = s.days.reduce((a, d) => a + d.earned, 0)
	const bought = s.days.reduce((a, d) => a + d.bought, 0)
	return (
		<>
			<PageHeader title="History" right="last 30 days" />
			<ErrorBanner s={s} />
			<DayForms s={s} wide />
			<Section title="Last 30 days" right={`+${fmt(earned)} earned · −${fmt(bought)} bought`}>
				<div class="th">
					<span>Day</span>
					<span>Earned</span>
					<span>Bought</span>
					<span>Net</span>
					<span>What</span>
				</div>
				{s.days.map((d) => (
					<div key={d.day} class="tr">
						<b>{d.label}</b>
						<b class="ea">+{fmt(d.earned)}</b>
						<b class="sp">−{fmt(d.bought)}</b>
						<b>{dayNet(d.earned, d.bought)}</b>
						<div>
							<DayItems s={s} d={d} />
						</div>
					</div>
				))}
			</Section>
		</>
	)
})
GOAT_EOF
echo "updated app/components/history.tsx"

mkdir -p "$(dirname app/components/home.tsx)"
cat > app/components/home.tsx <<'GOAT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export const HomeBalance = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<div class="hm-ba">
			<button type="button" class="ib" data-eye aria-label="Show balance">
				<Icon name="eye" />
			</button>
		</div>
		<div class="hm-m">Total balance</div>
	</div>
))

export const HomeToday = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hm-two">
			<div class="hm-c">
				<div class="hm-m">Earned today</div>
				<div class="hm-big">
					+{fmt(c.earned)} <small>{s.user.currency}</small>
				</div>
			</div>
			<div class="hm-c">
				<div class="hm-m">Bought today</div>
				<div class="hm-big">
					−{fmt(c.bought)} <small>{s.user.currency}</small>
				</div>
			</div>
		</div>
	)
})
GOAT_EOF
echo "updated app/components/home.tsx"

mkdir -p "$(dirname app/components/income.tsx)"
cat > app/components/income.tsx <<'GOAT_EOF'
import type { Income, Source, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { isFixed } from "../lib/util.ts"
import { calc, gotToday, srcAmount } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }
const rateOf = (x: Source) => Number(x.config.rate_minor) || 0
const tagOf = (x: Source) => (!x.active ? "paused" : x.type === "exoclick" ? "exoclick" : isFixed(x.type) ? "fixed" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "daily") : "manual")
const usdTxt = (n: number) => `$${fmt(n)}`
const exoSub = (s: State, x: Source) => s.exo[x.id] || `${usdTxt(s.exoToday[x.id] ?? 0)} today`

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
))

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`incl. ${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">
				+{fmt(i.amount)} <small>{s.user.currency}</small>
			</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<Submit class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</Submit>
			</form>
		</span>
	</div>
))

const HoursPanel = view<{ s: State; x: Source; row: Income }>(({ s, x, row }) => {
	const rate = rateOf(x)
	const h = row.hours
	const cur = s.user.currency
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))} ${cur}` : `${fmt(rate)} ${cur} / hour`}</span>
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
							<Submit class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</Submit>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<Submit class="btn xs o">Set</Submit>
					<button type="button" class="btn xs o" data-close>
						Close
					</button>
				</form>
			</div>
		</details>
	)
})

const HomeAct = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const amt = (n: number) => (
		<b class="ea">
			+{fmt(n)} <small>{cur}</small>
		</b>
	)
	if (x.type === "exoclick") {
		return (
			<>
				{amt(sum)}
				<span></span>
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				{amt(x.amount)}
				<span></span>
			</>
		)
	}
	if (got.length) {
		return (
			<>
				{amt(sum)}
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<Submit class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="revert" />
					</Submit>
				</form>
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<Submit class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</Submit>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan hadd" data-tg>
			Add
		</button>
	)
})

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<Submit class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</Submit>
	</form>
))

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const all = gotToday(s, x)
	const got = fixedSrc ? all[0] : undefined
	const cur = s.user.currency
	const exo = x.type === "exoclick"
	const sub = exo ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} ${cur} + ${fmt(rateOf(x))} / hour`) : ""
	const manual = !fixedSrc && !exo && x.mode !== "auto" && !all.length
	return (
		<div class="sw dbw" data-exo={exo ? "1" : undefined}>
			<div class="hr">
				<div class="hn">
					<div>{x.name}</div>
					{sub ? <div class={exo && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
					{exo && s.exo[x.id] ? (
						<a class="lnk" href="/income">
							Fix
						</a>
					) : null}
				</div>
				<HomeAct s={s} x={x} />
			</div>
			{manual ? (
				<form method="post" action="/income/add" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<div class="ln">
						<input class="in" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
						<Submit class="btn xs">Add</Submit>
					</div>
				</form>
			) : null}
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	)
})

const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<Submit class="btn full">Add income</Submit>
	</>
))

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
	["exoclick", "ExoClick"],
]

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
		<Submit class="btn full">Add source</Submit>
	</>
))

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-kind="fixed" data-adp hidden>
		<SourceFields s={s} />
	</form>
))

const TodayRows = view<{ s: State }>(({ s }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return sources.length || others.length ? (
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
	)
})

export const IncomeDesktop = view<{ s: State; title?: string; id?: string; bare?: boolean }>(({ s, title = "Income today", id = "f-inc-d", bare = false }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	if (bare) {
		return (
			<div class="sc incbare">
				<TodayRows s={s} />
			</div>
		)
	}
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
	)
})

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : ""
	return (
		<div class="dbw" data-exo={x.type === "exoclick" ? "1" : undefined}>
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
						<Submit class="btn xs o">{x.active ? "Pause" : "Resume"}</Submit>
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
				<Submit class="btn xs" style={{ marginTop: "10px" }}>
					Save
				</Submit>
			</form>
		</div>
	)
})

export const InvoiceCard = view<{ s: State }>(({ s }) => {
	const v = s.invoice
	if (!v) return null
	const label = v.status === "paid" ? "Paid" : v.status === "processing" ? "Processing" : "Pending"
	const sub = v.status === "paid" ? (v.paid ? `paid ${v.paid}` : "paid") : v.due ? `due ${v.due}` : v.date ? `issued ${v.date}` : ""
	return (
		<div class="hm-c inv" data-inv={`${v.id}:${v.status}`}>
			<div>
				<div class="hm-m">{`ExoClick invoice${v.period ? ` · ${v.period}` : ""}`}</div>
				<div class="inv-a">{`$${v.usd.toFixed(2)}`}</div>
				{sub ? <div class="hm-m">{sub}</div> : null}
			</div>
			<span class={`inv-st ${v.status}`}>{label}</span>
			<button type="button" class="ub" data-inv-x aria-label="Close">
				<Icon name="plus" />
			</button>
		</div>
	)
})

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
))

export const HomeIncome = view<{ s: State }>(({ s }) => (
	<div class="xc xbare">
		<div class="xb">
			<TodayRows s={s} />
		</div>
	</div>
))
GOAT_EOF
echo "updated app/components/income.tsx"

mkdir -p "$(dirname app/components/layout.tsx)"
cat > app/components/layout.tsx <<'GOAT_EOF'
import type { RemixNode } from "remix/component"
import { env } from "../env.ts"
import { SITE } from "../lib/assets.ts"
import { liveClockNow } from "../lib/time.ts"
import { V } from "../lib/static.ts"
import { Icon, Logo, Submit, ThemeIcons, view } from "./ui.tsx"

type DocumentProps = {
	title: string
	user?: boolean
	theme?: string
	desc?: string
	path?: string
	auth?: boolean
	children?: RemixNode
}

const THEME_BOOT = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`
const REGISTER_SW = `if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))`
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Noto+Sans+Arabic:wght@500;600&display=swap"

export const Document = view<DocumentProps>(({ title, user = true, theme, desc, path, auth, children }) => {
	const description = desc ?? SITE.desc
	const origin = env.APP_ORIGIN.replace(/\/$/, "")
	const fullTitle = `${title} · ${SITE.name}`
	const ld = JSON.stringify({
		"@context": "https://schema.org",
		"@type": "WebApplication",
		name: SITE.name,
		url: origin,
		description: SITE.desc,
		applicationCategory: "FinanceApplication",
		operatingSystem: "Any",
	}).replace(/</g, "\\u003c")

	return (
		<html lang="en" data-theme={theme === "light" ? "light" : "dark"}>
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="theme-color" content={SITE.color} />
				<title>{fullTitle}</title>
				<meta name="description" content={description} />
				<meta name="robots" content={user ? "noindex,nofollow" : "index,follow"} />
				<meta name="application-name" content={SITE.name} />
				<meta name="apple-mobile-web-app-title" content={SITE.name} />
				<meta name="mobile-web-app-capable" content="yes" />
				<meta name="apple-mobile-web-app-capable" content="yes" />
				<meta name="apple-mobile-web-app-status-bar-style" content="black" />
				<meta name="format-detection" content="telephone=no" />
				<link rel="manifest" href="/manifest.webmanifest" />
				<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
				<link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png" />
				<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
				<meta property="og:type" content="website" />
				<meta property="og:site_name" content={SITE.name} />
				<meta property="og:title" content={fullTitle} />
				<meta property="og:description" content={description} />
				<meta property="og:image" content={`${origin}/icon-512.png`} />
				<meta name="twitter:card" content="summary" />
				<meta name="twitter:title" content={fullTitle} />
				<meta name="twitter:description" content={description} />
				{path && !user ? <link rel="canonical" href={`${origin}${path}`} /> : null}
				{path && !user ? <meta property="og:url" content={`${origin}${path}`} /> : null}
				{user ? null : <script type="application/ld+json">{ld}</script>}
				<link rel="preconnect" href="https://fonts.googleapis.com" />
				<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
				<link rel="stylesheet" href={FONTS} />
				<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2.1.1/css/pico.min.css" />
				<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />
				{auth ? <link rel="stylesheet" href={`/assets/auth.css?v=${V.auth}`} /> : null}
				{theme ? null : <script>{THEME_BOOT}</script>}
			</head>
			<body>
				{children}
				<script src={`/assets/app.js?v=${V.js}`} defer></script>
				<script>{REGISTER_SW}</script>
			</body>
		</html>
	)
})

type Parts = { numDate: string; arabicDay: string }

const SubDate = view<Parts>(({ numDate, arabicDay }) => (
	<>
		<span class="clock-num">{numDate}</span> <span class="clock-dot">·</span> <span class="clock-ar">{arabicDay}</span>
	</>
))

export const ClockWidget = view(() => {
	const { timeStr, dateStr, numDate, arabicDay } = liveClockNow()
	return (
		<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time">
			<div class="clock-time" data-clock-time>
				{timeStr}
			</div>
			<div class="clock-date" data-clock-date>
				{dateStr}
			</div>
			<div class="clock-subdate" data-clock-subdate dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})

export const TopBar = view<{ split?: boolean; left?: RemixNode }>(({ split, left }) => {
	if (!split) {
		return (
			<div class="top-status-bar">
				<ClockWidget />
			</div>
		)
	}
	const { numDate, arabicDay } = liveClockNow()
	return (
		<div class="top-status-bar tsplit">
			{left}
			<ClockWidget />
			<div class="clock-subdate" dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})

export type DesktopTab = "home" | "notes" | "plan" | "income" | "trading" | "pad" | "history" | "settings" | ""

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "history", label: "History", icon: "hist", href: "/history" },
	{ key: "settings", label: "Settings", icon: "gear", href: "/settings" },
] as const

export const Sidebar = view<{ active: DesktopTab }>(({ active }) => (
	<aside class="sb d">
		<Logo href="/home" />
		{LINKS.map((l) => (
			<a key={l.key} class={active === l.key ? "sbl on" : "sbl"} href={l.href}>
				<Icon name={l.icon} />
				{l.label}
			</a>
		))}
		<div class="sp"></div>
		<button type="button" class="sbl" data-theme-toggle>
			<ThemeIcons />
			<span>Theme</span>
		</button>
		<form method="post" action="/logout">
			<Submit class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</Submit>
		</form>
	</aside>
))

export type MobileTab = "home" | "notes" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "bhome", href: "/home" },
	{ key: "trading", label: "Trading", icon: "btrade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "bdoc", href: "/pad" },
	{ key: "income", label: "Income", icon: "bsun", href: "/income" },
	{ key: "notes", label: "Notes", icon: "bchat", href: "/notes" },
	{ key: "profile", label: "Profile", icon: "buser", href: "/profile" },
] as const

export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label}>
				<Icon name={t.icon} />
			</a>
		))}
	</nav>
))

type AppLayoutProps = {
	title: string
	theme?: string
	mobile: RemixNode
	desktop: RemixNode
	mobileTab?: MobileTab
	desktopTab?: DesktopTab
	dock?: RemixNode
	full?: boolean
	topLeft?: RemixNode
}

export const AppLayout = view<AppLayoutProps>(({ title, theme, mobile, desktop, mobileTab = "", desktopTab = "", dock, full, topLeft }) => (
	<Document title={title} theme={theme}>
		<div class="app">
			<Sidebar active={desktopTab} />
			<main>
				<div class="m">
					<TopBar split left={topLeft} />
				</div>
				<div class="m mm hm">{mobile}</div>
				<div class="d">
					<TopBar />
				</div>
				<div class={full ? "d pg full" : "d pg"}>{desktop}</div>
			</main>
			<div class="dock m">
				{dock}
				<BottomBar active={mobileTab} />
			</div>
		</div>
	</Document>
))

type AuthLayoutProps = { title: string; path: string; desc: string; children?: RemixNode }

export const AuthLayout = view<AuthLayoutProps>(({ title, path, desc, children }) => (
	<Document title={title} path={path} desc={desc} user={false} auth>
		<div class="app">
			<main class="auth-main">{children}</main>
		</div>
	</Document>
))
GOAT_EOF
echo "updated app/components/layout.tsx"

mkdir -p "$(dirname app/components/notes.tsx)"
cat > app/components/notes.tsx <<'GOAT_EOF'
import type { RemixNode } from "remix/component"
import type { State } from "../lib/data.ts"
import { dayLabel, dayOf, hhmm } from "../lib/time.ts"
import { Back, Empty, Icon, Section, Submit, view } from "./ui.tsx"

export const NoteList = view<{ s: State; listKey: string }>(({ s, listKey }) => {
	if (listKey === "dash") {
		const latest = s.notes.slice(-2).reverse()
		return (
			<div data-list="dash">
				{latest.length ? (
					latest.map((n) => (
						<div key={n.id} class="rw">
							<span>{n.body}</span>
							<span class="lb">{hhmm(n.at)}</span>
						</div>
					))
				) : (
					<Empty>No notes yet.</Empty>
				)}
			</div>
		)
	}

	const items: RemixNode[] = []
	let last = ""
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at))
		if (label !== last) {
			items.push(
				<div key={`day-${n.id}`} class="day">
					<span>{label}</span>
				</div>,
			)
			last = label
		}
		items.push(
			<div key={n.id} class="msg" data-id={n.id}>
				<div class="bub">{n.body}</div>
				<div class="meta">
					{n.edited ? "edited · " : ""}
					{hhmm(n.at)}
				</div>
				<div class="acts" hidden>
					<button type="button" class="btn xs o" data-act="copy">
						Copy
					</button>
					<button type="button" class="btn xs o" data-act="edit">
						Edit
					</button>
					<form method="post" action="/notes/delete" style={{ display: "contents" }} data-confirm="Delete this note?">
						<Back s={s} />
						<input type="hidden" name="id" value={n.id} />
						<Submit class="btn xs dng">Delete</Submit>
					</form>
				</div>
			</div>,
		)
	}
	return <div data-list={listKey}>{items}</div>
})

export const ChatHead = view(() => (
	<div class="ch">
		<div class="av s">S</div>
		<div>
			<b>Message yourself</b>
			<div class="lb">only you can see this</div>
		</div>
	</div>
))

export const Composer = view<{ s: State; listKey: string }>(({ s, listKey }) => (
	<form class="cm" data-comp={listKey} method="post" action="/notes">
		<Back s={s} />
		<input type="hidden" name="id" data-eid />
		<div class="eb" hidden>
			<span>
				<b>Editing</b> message
			</span>
			<button type="button" data-cancel>
				✕
			</button>
		</div>
		<div class="cin">
			<textarea rows="1" name="text" placeholder="Message yourself"></textarea>
			<Submit class="send" aria-label="Send">
				<Icon name="send" />
			</Submit>
		</div>
	</form>
))

export const NoteCard = view<{ s: State }>(({ s }) => (
	<Section title="Note to yourself" right={`${s.notes.length} saved`}>
		<form class="cin" data-comp="dash" method="post" action="/notes" style={{ margin: "14px 0" }}>
			<Back s={s} />
			<input type="hidden" name="id" data-eid />
			<textarea rows="1" name="text" placeholder="Message yourself"></textarea>
			<Submit class="send" aria-label="Send">
				<Icon name="send" />
			</Submit>
		</form>
		<NoteList s={s} listKey="dash" />
	</Section>
))
GOAT_EOF
echo "updated app/components/notes.tsx"

mkdir -p "$(dirname app/components/pad.tsx)"
cat > app/components/pad.tsx <<'GOAT_EOF'
import { COLORS, type Entry, type PadData } from "../lib/padmeta.ts"
import { timeAgo } from "../lib/time.ts"
import { Icon, Submit, view } from "./ui.tsx"

export type PadTab = "projects" | "said" | "home" | "new"

type Props = { d: PadData; tab: PadTab; f: string }

const SEG = [
	{ key: "projects", label: "Projects", href: "/pad" },
	{ key: "said", label: "Said", href: "/pad/said" },
	{ key: "home", label: "Home", href: "/pad/home" },
]

export const padBack = (d: PadData, tab: PadTab, f: string) =>
	tab === "said" ? `/pad/said${f ? `?f=${f}` : ""}` : tab === "home" ? "/pad/home" : d.space ? `/pad?p=${d.space.id}${f ? `&f=${f}` : ""}` : "/pad"

const Seg = view<{ tab: PadTab }>(({ tab }) => (
	<div class="nt-seg">
		{SEG.map((x) => (
			<a key={x.key} href={x.href} class={x.key === tab || (tab === "new" && x.key === "projects") ? "on" : ""}>
				{x.label}
			</a>
		))}
	</div>
))

const Filters = view<{ base: string; f: string; items: [string, string][] }>(({ base, f, items }) => (
	<div class="nt-fl">
		{items.map(([label, key]) => (
			<a key={key} href={key ? `${base}${base.includes("?") ? "&" : "?"}f=${key}` : base} class={f === key ? "on" : ""}>
				{label}
			</a>
		))}
	</div>
))

const Bar = view<{ pct: number }>(({ pct }) => (
	<div class="nt-bar2">
		<i style={{ width: `${pct}%` }}></i>
	</div>
))

const Hid = view<{ id: string; back: string }>(({ id, back }) => (
	<>
		<input type="hidden" name="id" value={id} />
		<input type="hidden" name="back" value={back} />
	</>
))

// Edit uses the same look as the add bar, pre-filled with the current text.
const EditForm = view<{ e: Entry; back: string }>(({ e, back }) => (
	<form method="post" action="/pad/edit" class="nt-edit" data-edit hidden>
		<Hid id={e.id} back={back} />
		<div class="nt-c nt-cin">
			<input name="body" value={e.body} maxlength="2000" aria-label="Edit" autocomplete="off" required />
			<button type="button" class="nt-xc" data-edit-x aria-label="Cancel edit">
				<Icon name="plus" />
			</button>
			<Submit class="nt-sd" aria-label="Save">
				<Icon name="send" />
			</Submit>
		</div>
	</form>
))

// Settings icon with a dropdown: Edit and Delete.
const RowMenu = view<{ e: Entry; back: string }>(({ e, back }) => (
	<div class="nt-mn">
		<button type="button" class="nt-x" data-menu aria-label="Options" aria-haspopup="menu" aria-expanded="false">
			<Icon name="gear" />
		</button>
		<div class="nt-dd" role="menu" hidden>
			<button type="button" role="menuitem" data-menu-edit>
				<Icon name="edit" />
				Edit
			</button>
			<form method="post" action="/pad/delete" class="nt-f" data-confirm="Delete this?">
				<Hid id={e.id} back={back} />
				<Submit role="menuitem" class="dg">
					<Icon name="trash" />
					Delete
				</Submit>
			</form>
		</div>
	</div>
))

const Row = view<{ e: Entry; back: string }>(({ e, back }) => {
	const note = e.kind === "note"
	const done = e.kind === "done"
	return (
		<div class={done ? "nt-it dn" : note ? "nt-it nt" : "nt-it"} data-pad-item>
			{note ? null : (
				<form method="post" action="/pad/toggle" class="nt-f">
					<Hid id={e.id} back={back} />
					<Submit class={done ? "nt-ck d" : "nt-ck"} aria-label={done ? "Mark as open" : "Mark as done"}>
						{done ? <Icon name="check" /> : null}
					</Submit>
				</form>
			)}
			<div class="nt-b" data-copy>
				<p>{e.body}</p>
				{note ? <div class="nt-m">{`note · ${timeAgo(e.at)}`}</div> : null}
			</div>
			<EditForm e={e} back={back} />
			<RowMenu e={e} back={back} />
		</div>
	)
})

const Empty = view<{ children?: unknown }>(({ children }) => <div class="nt-m nt-em">{children as never}</div>)

const Projects = view<Props>(({ d, f }) => {
	const sp = d.space
	if (!sp) {
		return (
			<div class="nt-c nt-ph">
				<b>No projects yet</b>
				<div class="nt-m" style={{ margin: "4px 0 10px" }}>
					Make one for each thing you work on.
				</div>
				<a class="nt-go" href="/pad/new">
					New project
				</a>
			</div>
		)
	}
	const all = d.entries.filter((e) => e.space === sp.id && e.kind !== "said").reverse()
	const open = all.filter((e) => e.kind === "task").length
	const done = all.filter((e) => e.kind === "done").length
	const list = all.filter((e) => (f === "tasks" ? e.kind !== "note" : f === "notes" ? e.kind === "note" : true))
	const back = padBack(d, "projects", f)
	return (
		<>
			<div class="nt-pj">
				{d.spaces.map((x) => (
					<a key={x.id} class={x.id === sp.id ? "nt-pc on" : "nt-pc"} href={`/pad?p=${x.id}`}>
						<i class="nt-dot" style={{ background: x.color }}></i>
						{x.title} <small>{d.entries.filter((e) => e.space === x.id && e.kind === "task").length}</small>
					</a>
				))}
				<a class="nt-pc" href="/pad/new">
					+ New
				</a>
			</div>
			<div class="nt-c nt-ph">
				<div class="nt-spread">
					<b>{sp.title}</b>
					<span class="nt-m">{`${open} open · ${done} done`}</span>
				</div>
				{sp.bar && sp.type !== "notes" ? <Bar pct={open + done ? Math.round((done / (open + done)) * 100) : 0} /> : null}
			</div>
			{sp.type === "mix" ? <Filters base={`/pad?p=${sp.id}`} f={f} items={[["All", ""], ["Tasks", "tasks"], ["Notes", "notes"]]} /> : null}
			<div class="nt-c nt-list">{list.length ? list.map((e) => <Row key={e.id} e={e} back={back} />) : <Empty>{sp.type === "notes" ? "No notes yet. Write one below." : "Nothing here yet. Add one below."}</Empty>}</div>
			<form method="post" action="/pad/space/delete" class="nt-del" data-confirm={`Delete ${sp.title} and everything in it?`}>
				<Hid id={sp.id} back="/pad" />
				<Submit type="submit">Delete this project</Submit>
			</form>
		</>
	)
})

const Said = view<Props>(({ d, f }) => {
	const all = d.entries.filter((e) => e.kind === "said")
	const list = all.filter((e) => !f || e.tag.toLowerCase() === f)
	const back = padBack(d, "said", f)
	const title = (id: string) => d.spaces.find((x) => x.id === id)?.title
	return (
		<>
			<Filters base="/pad/said" f={f} items={[["All", ""], ["Tips", "tip"], ["Info", "info"]]} />
			<div class="nt-c nt-list">
				{list.length ? (
					list.map((e) => (
						<div key={e.id} class="nt-q" data-pad-item>
							<div class="nt-b" data-copy>
								<p>{e.body}</p>
							</div>
							<EditForm e={e} back={back} />
							<div class="nt-who">
								<span class="nt-av">{(e.who[0] ?? "?").toUpperCase()}</span>
								<div>
									<b>{e.who}</b>
									<span class="nt-m">{timeAgo(e.at)}</span>
								</div>
								<span class="nt-tag t">{e.tag}</span>
								<RowMenu e={e} back={back} />
							</div>
							{title(e.space) ? <div class="nt-m" style={{ marginTop: "8px" }}>{`→ ${title(e.space)}`}</div> : null}
						</div>
					))
				) : (
					<Empty>Nothing yet. Write what someone told you below.</Empty>
				)}
			</div>
		</>
	)
})

const HomeTasks = view<Props>(({ d }) => {
	const all = d.entries.filter((e) => !e.space && (e.kind === "task" || e.kind === "done")).reverse()
	const done = all.filter((e) => e.kind === "done").length
	const back = padBack(d, "home", "")
	const group = (label: string, rows: Entry[]) =>
		rows.length ? (
			<>
				<div class="nt-gl">{label}</div>
				<div class="nt-c nt-list">{rows.map((e) => <Row key={e.id} e={e} back={back} />)}</div>
			</>
		) : null
	return (
		<>
			<div class="nt-c nt-ph">
				<div class="nt-spread">
					<b>Home</b>
					<span class="nt-m">{`${done} of ${all.length} done`}</span>
				</div>
				<Bar pct={all.length ? Math.round((done / all.length) * 100) : 0} />
			</div>
			{group("Today", all.filter((e) => e.today))}
			{group("Later", all.filter((e) => !e.today))}
			{all.length ? null : <Empty>No home tasks yet. Add one below.</Empty>}
		</>
	)
})

const TYPE_OPTS = [
	{ key: "mix", title: "Mixed", sub: "Notes and tasks together in one list", rows: ["o", "x"] },
	{ key: "notes", title: "Notes only", sub: "Just writing, no checkboxes", rows: ["x", "x"] },
	{ key: "tasks", title: "Tasks only", sub: "A clean checklist with progress, like Home", rows: ["o", "o"] },
]

const Sheet = view(() => {
	const nid = crypto.randomUUID()
	return (
		<>
			<a class="nt-ov" href="/pad" aria-label="Close"></a>
			<form class="nt-sht" method="post" action="/pad/space">
				<input type="hidden" name="nid" value={nid} />
				<input type="hidden" name="back" value={`/pad?p=${nid}`} />
				<span class="nt-gr"></span>
				<div class="nt-shh">
					<b>New project</b>
					<a class="nt-m" href="/pad">
						Cancel
					</a>
				</div>
				<label class="nt-fi">
					<span class="nt-m">Name</span>
					<input name="title" placeholder="Library website" maxlength="60" autocomplete="off" required />
				</label>
				<div class="nt-cl">
					{COLORS.map((c, i) => (
						<label key={c}>
							<input type="radio" name="color" value={c} checked={i === 0 ? true : undefined} />
							<i style={{ background: c }}></i>
						</label>
					))}
				</div>
				<div class="nt-m">What is it for?</div>
				{TYPE_OPTS.map((o, i) => (
					<label key={o.key} class="nt-op">
						<input type="radio" name="type" value={o.key} checked={i === 0 ? true : undefined} />
						<span class="nt-pv">
							{o.rows.map((r, j) => (
								<div key={j} class="nt-pr2">
									{r === "o" ? <u></u> : null}
									<i></i>
								</div>
							))}
						</span>
						<div>
							<b>{o.title}</b>
							<span class="d">{o.sub}</span>
						</div>
						<span class="nt-rd"></span>
					</label>
				))}
				<label class="nt-tr2">
					<span>Progress bar</span>
					<input type="checkbox" name="bar" value="1" checked class="nt-tgl" />
				</label>
				<Submit class="nt-go">Create project</Submit>
				<div class="nt-m" style={{ textAlign: "center" }}>
					You can delete it any time
				</div>
			</form>
		</>
	)
})

export const PadBody = view<Props & { error?: string }>(({ d, tab, f, error }) => (
	<div class="nt-page">
		<Seg tab={tab} />
		{error ? (
			<div class="neg" role="alert" style={{ fontSize: "13px" }}>
				{error}
			</div>
		) : null}
		{tab === "said" ? <Said d={d} tab={tab} f={f} /> : tab === "home" ? <HomeTasks d={d} tab={tab} f={f} /> : <Projects d={d} tab={tab} f={f} />}
		{tab === "new" ? <Sheet /> : null}
	</div>
))

const Mode = view<{ opts: [string, string][] }>(({ opts }) => (
	<div class="nt-tg2">
		{opts.map(([k, label], i) => (
			<label key={k}>
				<input type="radio" name="mode" value={k} checked={i === 0 ? true : undefined} />
				<span>{label}</span>
			</label>
		))}
	</div>
))

export const PadComposer = view<Props>(({ d, tab, f }) => {
	if ((tab === "projects" || tab === "new") && !d.space) return null
	const said = tab === "said"
	const home = tab === "home"
	const type = d.space?.type
	return (
		<form class="nt-cmp" method="post" action="/pad/add">
			<input type="hidden" name="tab" value={said ? "said" : home ? "home" : "projects"} />
			<input type="hidden" name="back" value={padBack(d, tab, f)} />
			{said || home ? null : <input type="hidden" name="space" value={d.space!.id} />}
			<div class="nt-c nt-cin">
				{said ? <input class="nt-who-i" name="who" placeholder="Who" maxlength="40" autocomplete="off" /> : null}
				<input name="body" placeholder={said ? "What did they say…" : home ? "Add a home task…" : type === "notes" ? "Write a note…" : "Write a note or task…"} aria-label="Add" autocomplete="off" required />
				{said ? <Mode opts={[["tip", "Tip"], ["info", "Info"]]} /> : home ? <Mode opts={[["today", "Today"], ["later", "Later"]]} /> : type === "mix" ? <Mode opts={[["task", "Task"], ["note", "Note"]]} /> : null}
				<Submit class="nt-sd" aria-label="Add">
					<Icon name="send" />
				</Submit>
			</div>
			{said && d.spaces.length ? (
				<select name="space" class="nt-sel" aria-label="Project">
					<option value="">No project</option>
					{d.spaces.map((x) => (
						<option key={x.id} value={x.id}>
							{x.title}
						</option>
					))}
				</select>
			) : null}
		</form>
	)
})
GOAT_EOF
echo "updated app/components/pad.tsx"

mkdir -p "$(dirname app/components/profile.tsx)"
cat > app/components/profile.tsx <<'GOAT_EOF'
import type { State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { LANG } from "../lib/view.ts"
import { Avatar, Back, Card, ErrorBanner, Field, Icon, PageHeader, Section, Submit, ThemeSwitch, view } from "./ui.tsx"

const BalanceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/profile/balance">
		<Back s={s} />
		<div class="fl">
			<label>Balance ({s.user.currency})</label>
			<input class="in f" name="balance" inputmode="decimal" value={plain(s.balance)} autocomplete="off" required />
		</div>
		<Submit class="btn full" style={{ marginTop: "14px" }}>
			Update balance
		</Submit>
	</form>
))

export const BalanceCard = view<{ s: State; edit?: boolean }>(({ s, edit = false }) => (
	<div class="cd hm-balc">
		<div class="hm-bal">
			<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
				••••••
			</b>
			<div class="hm-ba">
				<button type="button" class="ib" data-eye aria-label="Show balance">
					<Icon name="eye" />
				</button>
				{edit ? (
					<button type="button" class="ib" data-edit-bal aria-label="Edit balance">
						<Icon name="edit" />
					</button>
				) : null}
			</div>
			<div class="hm-m">Total balance</div>
		</div>
		{edit ? (
			<div class="hm-bedit" data-balf hidden>
				<BalanceForm s={s} />
			</div>
		) : null}
	</div>
))

const ProfileForm = view<{ s: State; cancel: string; showError?: boolean }>(({ s, cancel, showError = false }) => (
	<form method="post" action="/profile/edit">
		{showError ? <ErrorBanner s={s} /> : null}
		<Field label="Name" value={s.user.name} name="name" first />
		<Field label="Email" value={s.user.email} type="email" name="email" />
		<div style={{ display: "flex", gap: "10px", marginTop: "18px" }}>
			<Submit class="btn" style={{ flex: "1" }}>
				Save
			</Submit>
			<a class="btn o" style={{ flex: "1" }} href={cancel}>
				Cancel
			</a>
		</div>
	</form>
))

const PrefsForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/settings">
		<Field label="Currency" value={s.user.currency} name="currency" />
		<Field label={`1 USDT costs (${s.user.currency})`} value={plain(s.user.usdt_rate)} name="usdt" />
		<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />
		<div class="fl">
			<label>Day resets at</label>
			<select class="in" name="day_start" style={{ width: "100%" }}>
				{Array.from({ length: 24 }, (_, h) => (
					<option key={h} value={String(h)} selected={h === s.user.day_start ? true : undefined}>
						{String(h).padStart(2, "0")}:00
					</option>
				))}
			</select>
		</div>
		<Field label="1 USD in MAD (ExoClick)" value={plain(s.user.usd_rate_minor)} name="usd_rate" />
		<Field label="Week starts" value={s.user.week_start} name="week" />
		<Submit class="btn" style={{ marginTop: "14px" }}>
			Save
		</Submit>
	</form>
))

const DataButtons = view(() => (
	<div style={{ display: "flex", gap: "10px", marginTop: "6px" }}>
		<a class="btn o" style={{ flex: "1" }} href="/export.csv">
			Export CSV
		</a>
		<form method="post" action="/account/delete" style={{ flex: "1", display: "flex" }} data-confirm="Delete your account and all your data? This cannot be undone.">
			<Submit class="btn dng" style={{ flex: "1" }}>
				Delete account
			</Submit>
		</form>
	</div>
))

const LinkRow = view<{ href: string; label: string }>(({ href, label }) => (
	<a class="li" href={href}>
		<span>{label}</span>
		<span class="mu">›</span>
	</a>
))

export const ProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "10px", margin: "20px 0 6px" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
			<div style={{ textAlign: "center" }}>
				<div style={{ fontSize: "22px", fontWeight: "700", letterSpacing: "-.04em" }}>{s.user.name}</div>
				<div class="lb">{s.user.email}</div>
				<div class="chips" style={{ justifyContent: "center", marginTop: "10px" }}>
					<span class="chip" style={{ cursor: "default" }}>
						{s.user.currency}
					</span>
					<span class="chip" style={{ cursor: "default" }}>
						{LANG}
					</span>
				</div>
			</div>
		</div>
		<BalanceCard s={s} edit />
		<Card title="Appearance">
			<ThemeSwitch />
		</Card>
		<Card title="Account">
			<LinkRow href="/profile/edit" label="Edit profile" />
			<LinkRow href="/settings" label="Settings" />
			<LinkRow href="/history" label="History" />
			<form method="post" action="/logout">
				<Submit class="li">
					<span class="neg">Log out</span>
					<span class="mu">›</span>
				</Submit>
			</form>
		</Card>
	</>
))

export const EditProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<div style={{ display: "flex", justifyContent: "center", margin: "14px 0 0" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
		</div>
		<Card title="Profile">
			<ProfileForm s={s} cancel="/profile" showError />
		</Card>
	</>
))

export const SettingsMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<Card title="Money & income">
			<PrefsForm s={s} />
		</Card>
		<Card title="Data">
			<DataButtons />
		</Card>
		<div class="lb" style={{ textAlign: "center", margin: "18px 0" }}>
			Moneytracker v1.0 · stable
		</div>
	</>
))

export const SettingsDesktop = view<{ s: State }>(({ s }) => (
	<>
		<PageHeader title="Settings" right={`${s.user.currency} · ${LANG}`} />
		<ErrorBanner s={s} />
		<div class="g3">
			<div>
				<BalanceCard s={s} edit />
				<Section title="Profile">
					<ProfileForm s={s} cancel="/home" />
				</Section>
				<Section title="Account">
					<form method="post" action="/logout">
						<Submit class="btn o">Log out</Submit>
					</form>
				</Section>
			</div>
			<div>
				<Section title="Appearance">
					<ThemeSwitch />
				</Section>
				<Section title="Money & income">
					<PrefsForm s={s} />
				</Section>
				<Section title="Data">
					<DataButtons />
				</Section>
			</div>
		</div>
	</>
))
GOAT_EOF
echo "updated app/components/profile.tsx"

mkdir -p "$(dirname app/components/trading.tsx)"
cat > app/components/trading.tsx <<'GOAT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	BTC_STAKE,
	btcOf,
	btcWon,
	DEPOSIT,
	isDone,
	PICKS,
	PRED_COUNT,
	PRED_STAKE,
	predOf,
	strip,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "../lib/trade-math.ts"
import { Back, Card, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

type RowState = "result" | "active" | "wait" | "skip"

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const PredictRow = view<{ s: State; t: TradeSession; game: Game; idx: number; r: TradeResult | undefined; state: RowState; canUndo: boolean }>(
	({ s, t, game, idx, r, state, canUndo }) => {
		const meta = r && r.asset ? `${r.asset} ${r.tf}m` : ""
		if (r && isDone(r)) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						{meta ? <div class="lb">{meta}</div> : null}
					</div>
					<span class="rt">
						<span class={`tbs ${r.won ? "pos" : "mu"}`}>{r.won ? "Win" : "Missed"}</span>
						<b class={r.won ? tone(r.pnl) : "mu"}>{sg(r.pnl)}</b>
						{canUndo ? (
							<form method="post" action="/trading/undo" style={contents} data-confirm={`Move predict ${idx} back to waiting?`}>
								<SessionHid s={s} t={t} />
								<input type="hidden" name="result_id" value={r.id} />
								<Submit class="ub" aria-label={`Undo predict ${idx}`}>
									<Icon name="undo" />
								</Submit>
							</form>
						) : null}
					</span>
				</div>
			)
		}
		if (r) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						<div class="lb">{meta ? `${meta} · waiting` : "waiting"}</div>
					</div>
					<form method="post" action="/trading/result" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<input class="in" name="pnl" placeholder="PnL USDT" inputmode="decimal" autocomplete="off" />
						<Submit class="btn xs win" name="outcome" value="win">
							Win
						</Submit>
						<Submit class="btn xs miss" name="outcome" value="miss" formnovalidate>
							Miss
						</Submit>
					</form>
					{canUndo ? (
						<form method="post" action="/trading/undo" style={contents}>
							<SessionHid s={s} t={t} />
							<input type="hidden" name="result_id" value={r.id} />
							<Submit class="ub" aria-label={`Cancel predict ${idx}`}>
								<Icon name="undo" />
							</Submit>
						</form>
					) : null}
				</div>
			)
		}
		if (state === "active" && game === "btc") {
			return (
				<div class="tbr" style={{ flexDirection: "column", alignItems: "stretch" }}>
					<b>Predict {idx}</b>
					<form method="post" action="/trading/set" style={contents}>
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<div class="hxg" style={{ gridTemplateColumns: "repeat(2,1fr)" }}>
							{PICKS.map(([a, m]) => (
								<Submit key={`${a}-${m}`} class="chip hc" name="pick" value={`${a}-${m}`}>
									<b>{a}</b>
									<small>{m}m</small>
								</Submit>
							))}
						</div>
					</form>
				</div>
			)
		}
		if (state === "active") {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
					</div>
					<form method="post" action="/trading/set" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<Submit class="btn xs o">Set</Submit>
					</form>
				</div>
			)
		}
		return (
			<div class="tbr lock">
				<div>
					<b>Predict {idx}</b>
				</div>
				<span class="lb">{state === "skip" ? "skipped" : "waiting"}</span>
			</div>
		)
	},
)

const BtcCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = btcOf(t.results)
	const done = btcDone(t.results)
	const won = btcWon(t.results)
	const stake = fmt(BTC_STAKE)
	const left = fmt(BTC_STAKE * (BTC_ROUNDS - list.length))
	return (
		<Card title="Crypto · 5 min up or down">
			<div class="lb tbn">
				{`${stake} USDT each. Pick BTC or ETH (5 min) and wait for the result. Win on the first = stop here. Miss = one more try with the ${stake} USDT left.`}
			</div>
			{!done && list.length > 0 && list.every(isDone) ? <div class="lb tbn">{`Last try. ${left} USDT left from ${fmt(BTC_STAKE * BTC_ROUNDS)}.`}</div> : null}
			{Array.from({ length: BTC_ROUNDS }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx)
				const state: RowState = r ? "result" : done ? "skip" : idx === list.length + 1 && list.every(isDone) ? "active" : "wait"
				return <PredictRow key={idx} s={s} t={t} game="btc" idx={idx} r={r} state={state} canUndo={!!r && idx === list.length} />
			})}
			{done ? <div class="lb tbn">{won ? `Won on try ${list.findIndex((x) => x.won) + 1}. Stop trading today. Do your ${PRED_COUNT} predicts below.` : "Both tries missed. Done with crypto today."}</div> : null}
		</Card>
	)
})

const PredCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = predOf(t.results)
	return (
		<Card title={`${PRED_COUNT} match predicts · lol or sport`}>
			<div class="lb tbn">{`${fmt(PRED_STAKE)} USDT each. Play both whatever the crypto result was. Tap Set, then wait. Type the PnL and tap Win, or tap Miss.`}</div>
			{Array.from({ length: PRED_COUNT }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx)
				return <PredictRow key={idx} s={s} t={t} game="pred" idx={idx} r={r} state={r ? "result" : "active"} canUndo={!!r} />
			})}
		</Card>
	)
})

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency
	const pnl = totalPnl(t.results)
	const back = backUsdt(t.deposit, pnl)
	const net = toMad(pnl, t.rate)
	return (
		<Card title="Open trade">
			<div class="ow" style={{ margin: "0 0 8px" }}>
				<b class={`big2 ${t.results.some(isDone) ? tone(pnl) : ""}`}>
					{t.results.some(isDone) ? sg(pnl) : "0"} <small>USDT PnL</small>
				</b>
				<span class="lb">{dayLabel(t.day)}</span>
			</div>
			<div class="rw">
				<span class="mu">Deposit</span>
				<span>{`${fmt(t.deposit)} USDT · ${fmt(toMad(t.deposit, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">You get back</span>
				<span>{`${fmt(back)} USDT · ${fmt(toMad(back, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">Net for your balance</span>
				<b class={tone(net)}>{`${sg(net)} ${cur}`}</b>
			</div>
			{t.results.some(isDone) && !allDone(t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the predicts that are left?">
					<SessionHid s={s} t={t} />
					<Submit class="btn o full">Finish now</Submit>
				</form>
			) : null}
			<div class="lb tbn">When every predict has a result, the money is added to your balance by itself.</div>
		</Card>
	)
})

const LockedCard = view<{ s: State }>(({ s }) => (
	<Card title="Today's trade">
		<div class="lb tbn">{`Done for today. One trade a day. The next one opens at ${String(s.user.day_start).padStart(2, "0")}:00.`}</div>
	</Card>
))

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency
	const rate = s.user.usdt_rate
	const cost = toMad(DEPOSIT, rate)
	return (
		<Card title="Today's trade">
			<div class="ow" style={{ margin: "0 0 6px" }}>
				<b class="big2">
					{fmt(DEPOSIT)} <small>USDT</small>
				</b>
				<span class="lb">{`${fmt(cost)} ${cur}`}</span>
			</div>
			<div class="lb">{`1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
			<form method="post" action="/trading/deposit" data-confirm={`Deposit ${fmt(DEPOSIT)} USDT? It counts as a buy of ${fmt(cost)} ${cur}.`}>
				<Back s={s} />
				<Submit class="btn full">Deposit {fmt(DEPOSIT)} USDT</Submit>
			</form>
			<div class="lb tbn">{`Then 1 crypto predict of ${fmt(BTC_STAKE)} USDT (a second try only if the first misses) and ${PRED_COUNT} match predicts of ${fmt(PRED_STAKE)} USDT. One trade a day.`}</div>
		</Card>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const btc = strip(btcOf(t.results))
	const pred = strip(predOf(t.results))
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{`${btc ? `BTC ${btc}` : ""}${btc && pred ? " · " : ""}${pred ? `P ${pred}` : ""}`}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this trade again? The money it added is taken back.">
						<SessionHid s={s} t={t} />
						<Submit class="ub" aria-label="Open this trade again">
							<Icon name="undo" />
						</Submit>
					</form>
				) : null}
			</span>
		</div>
	)
})

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0)
	return (
		<Card title={`Past trades · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	const day = today(s.user.day_start)
	const tradedToday = s.trades.some((t) => t.day === day)
	return (
		<div class="trd">
			{open ? (
				<>
					<OpenSummary s={s} t={open} />
					<BtcCard s={s} t={open} />
					<PredCard s={s} t={open} />
				</>
			) : tradedToday ? (
				<LockedCard s={s} />
			) : (
				<StartCard s={s} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	)
})
GOAT_EOF
echo "updated app/components/trading.tsx"

mkdir -p "$(dirname app/components/ui.tsx)"
cat > app/components/ui.tsx <<'GOAT_EOF'
import { unsafeHTML, type Handle, type RemixNode } from "remix/component"
import type { State } from "../lib/data.ts"

export function view<P extends Record<string, any> = {}>(render: (props: P) => RemixNode) {
	return function View(handle: Handle<P>) {
		return () => render(handle.props)
	}
}

const ICONS: Record<string, string> = {
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
	moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
	pad: '<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h7M9 17h5"/>',
	trade: '<path d="M3 17l5-6 4 3 8-9"/><path d="M15 5h5v5"/>',
	coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
	undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	chev: '<path d="M6 9l6 6 6-6"/>',
	check: '<path d="m5 12 5 5 9-9"/>',
	bhome: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
	btrade: '<path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/>',
	bdoc: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h8"/>',
	bsun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
	bchat: '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22z"/>',
	buser: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
	revert: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
	eyeoff: '<path d="M3 3l18 18M10.6 6.1A9.8 9.8 0 0 1 12 6c6 0 10 6 10 6a17 17 0 0 1-3.2 3.9M6.6 7.6A17 17 0 0 0 2 12s4 7 10 7a9.6 9.6 0 0 0 4.2-1M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
	Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
	Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
	Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
	Other: '<path d="M12 5v14M5 12h14"/>',
	Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
	Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
	Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
	Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
	Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
	Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
}

/**
 * Shared submit button. Use it for every button that submits a form.
 * While its form is submitting, the page script marks it data-busy and CSS shows
 * only the rotate icon (label and icons are hidden, size stays the same).
 */
export const Submit = view<Record<string, any>>(({ children, ...rest }) => (
	<button {...rest}>
		<span class="sb-l">{children}</span>
		<span class="sb-i" aria-hidden="true">
			<Icon name="revert" />
		</span>
	</button>
))

export const Icon = view<{ name: string }>(({ name }) => <svg class="ic" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS[name] ?? "")} />)

export const ThemeIcons = view(() => (
	<>
		<svg class="ic t-sun" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.sun!)} />
		<svg class="ic t-moon" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.moon!)} />
	</>
))

const GOOGLE_INNER =
	'<path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/>'

export const GoogleMark = view(() => <svg width="18" height="18" viewBox="0 0 48 48" innerHTML={unsafeHTML(GOOGLE_INNER)} />)

const GOAT_INNER =
	'<rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/>'

const GoatMark = view(() => <svg viewBox="0 0 24 24" innerHTML={unsafeHTML(GOAT_INNER)} />)

export const Logo = view<{ href: string }>(({ href }) => (
	<a class="logo" href={href}>
		<GoatMark />
		<span>moneytracker</span>
	</a>
))

export const Card = view<{ title: RemixNode; children?: RemixNode }>(({ title, children }) => (
	<div class="cd">
		<div class="tg">{title}</div>
		<div class="cb">{children}</div>
	</div>
))

export const Section = view<{ title: RemixNode; right?: RemixNode; children?: RemixNode }>(({ title, right = "", children }) => (
	<div class="sc">
		<div class="sh">
			<span>{title}</span>
			<span class="lb">{right}</span>
		</div>
		{children}
	</div>
))

export const PageHeader = view<{ title: string; right?: RemixNode; back?: string }>(({ title, right = "", back }) => (
	<div class="hd">
		{back ? (
			<a class="back" href={back}>
				<Icon name="back" />
				<h1 class="t">{title}</h1>
			</a>
		) : (
			<h1 class="t">{title}</h1>
		)}
		<span class="lb">{right}</span>
	</div>
))

type FieldProps = { label: string; value?: string; name?: string; type?: string; placeholder?: string; first?: boolean }

export const Field = view<FieldProps>(({ label, value = "", name, type, placeholder = "", first }) => (
	<div class="fl">
		<label>{label}</label>
		<input class={first ? "in f" : "in"} name={name} type={type} value={value} placeholder={value ? undefined : placeholder} autocomplete="off" />
	</div>
))

export const FloatField = view<{ label: string; name: string; type?: string; auto?: string }>(({ label, name, type = "text", auto }) => (
	<div class="of">
		<input name={name} type={type} placeholder=" " autocomplete={auto} />
		<label>{label}</label>
	</div>
))

export const Back = view<{ s: State }>(({ s }) => <input type="hidden" name="back" value={s.back} />)

export const ErrorBanner = view<{ s: State }>(({ s }) =>
	s.error ? (
		<div class="neg" role="alert" style={{ margin: "10px 0", fontSize: "13px" }}>
			{s.error}
		</div>
	) : null,
)

export const Empty = view<{ children?: RemixNode }>(({ children }) => (
	<div class="lb" style={{ padding: "8px 0" }}>
		{children}
	</div>
))

export const Avatar = view<{ avatar: string | null; name: string }>(({ avatar, name }) => {
	const url = avatar ? encodeURI(avatar).replace(/'/g, "%27") : ""
	return (
		<div class="av" style={url ? { background: `url('${url}') center/cover` } : undefined}>
			{url ? "" : (name.trim()[0] ?? "?").toUpperCase()}
		</div>
	)
})

export const ThemeSwitch = view(() => (
	<div class="sg">
		<button type="button" data-set-theme="dark">
			<Icon name="moon" />
			Dark
		</button>
		<button type="button" data-set-theme="light">
			<Icon name="sun" />
			White
		</button>
	</div>
))

export const NameChips = view<{ names: string[] }>(({ names }) =>
	names.length ? (
		<div class="chips nm">
			{names.map((n) => (
				<span key={n} class="chip" data-nm={n}>
					{n}
				</span>
			))}
		</div>
	) : null,
)

export const BigAdd = view<{ label: string; target?: string; right?: boolean }>(({ label, target = "", right = false }) => (
	<button type="button" class={right ? "addb r" : "addb"} data-bigadd data-for={target || undefined} aria-label={label}>
		<Icon name="plus" />
	</button>
))

export const ListCard = view<{ title: RemixNode; right: RemixNode; target: string; label: string; children?: RemixNode }>(({ title, right, target, label, children }) => (
	<div class="sc bgc rgt">
		<div class="ct">
			<div class="sh">
				<span>{title}</span>
				<span class="lb">{right}</span>
			</div>
			{children}
		</div>
		<BigAdd label={label} target={target} right />
	</div>
))

type ExpandProps = {
	storeKey: string
	open: boolean
	title: string
	head?: RemixNode
	foot?: RemixNode
	form?: RemixNode
	label?: string
	jar?: number
	fixed?: boolean
	children?: RemixNode
}

export const ExpandCard = view<ExpandProps>(({ storeKey, open, title, head, foot, form, label = "", jar = -1, fixed = false, children }) => (
	<div class={label ? "xc" : "xc xn"}>
		<details class="xd" data-keep-open={fixed ? undefined : storeKey} data-fixed={fixed ? "1" : undefined} open={open || fixed ? true : undefined}>
			<summary class="xh osum">
				{jar >= 0 ? <i class={jar >= 100 ? "xj full" : "xj"} style={{ width: `${jar}%` }}></i> : null}
				<div>
					<div class="tg0">{title}</div>
					{head ? <div class="ow">{head}</div> : null}
				</div>
				{fixed ? null : (
					<span class="chev">
						<Icon name="chev" />
					</span>
				)}
				{label ? (
					<button type="button" class="xp" data-xplus aria-label={label}>
						<Icon name="plus" />
					</button>
				) : null}
			</summary>
			<div class="xb">{children}</div>
			<div class={foot ? "xf" : "xf xo"}>
				{foot}
				{form}
			</div>
		</details>
	</div>
))
GOAT_EOF
echo "updated app/components/ui.tsx"

echo "Done. Now run: bun run db:migrate  (once, so your day resets at 05:00)"
