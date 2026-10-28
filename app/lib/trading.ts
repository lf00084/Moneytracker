import { sql } from "remix/data-table"
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts"
import { today } from "./time.ts"
import { todayFor } from "./users.ts"
import { allDone, backUsdt, DEPOSIT, doneOf, flowOf, GAME, gameOf, hasGames, toMad, totalPnl, type TradeResult, type TradeSession } from "./trade-math.ts"
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
	game: r.game === "step" || r.game === "ga" || r.game === "gb" ? r.game : "res",
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
			results: (by.get(s.id) ?? []).sort((a, b) => (a.game === b.game ? a.idx - b.idx : a.game === "step" ? -1 : 1)),
		}),
	)
}

export async function startTrade(user: User): Promise<string | void> {
	const uid = user.id
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open predict first"
	const day = today(user.day_start)
	const already = await db.findOne(tradeSessions, { where: { user_id: uid, day } })
	if (already) return `One predict a day. The next one opens at ${String(user.day_start).padStart(2, "0")}:00`
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
				meta: JSON.stringify({ trade: 1, name: "Predict", usdt_minor: back }),
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

const openOf = async (uid: string, f: FormData) => db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })

const pnlFor = (outcome: string, amount: number | null, base: number): { pnl: number } | { error: string } => {
	if (outcome === "win") return amount ? { pnl: amount } : { error: "Enter how much you won in USDT" }
	if (outcome === "lose") return amount ? { pnl: 0 - Math.min(amount, base) } : { error: "Enter how much you lost in USDT" }
	if (outcome === "miss") return { pnl: 0 - base }
	return { error: "Pick Won, Lost or Miss" }
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const rows = await resultsOf(uid, s.id)
	const fl = flowOf(s.deposit_minor, rows)
	if (fl.over) return "This predict is finished"
	if (fl.base <= 0) return "Nothing is left to predict with"
	const outcome = text(f.get("outcome"), 4)
	const r = pnlFor(outcome, usdtMinor(f.get("pnl")), fl.base)
	if ("error" in r) return r.error
	const coin = text(f.get("coin"), 3).toLowerCase()
	const row = { id: id(), user_id: uid, session_id: s.id, game: "res", idx: fl.tryNo, won: outcome === "win" ? 1 : 0, pnl_minor: r.pnl, state: "done", asset: coin === "btc" || coin === "eth" ? coin : "", tf: fl.base, created_at: Date.now() }
	await db.create(tradeResults, row)
	const next = [...rows, toResult(row)]
	if (allDone(s.deposit_minor, next)) await settle(uid, s, doneOf(next))
}

export async function saveGame(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	if (!hasGames(s.deposit_minor)) return "This predict has no games"
	const g = text(f.get("game"), 2)
	if (g !== "ga" && g !== "gb") return "Pick a game"
	const rows = await resultsOf(uid, s.id)
	if (gameOf(rows, g)) return "That game already has a result"
	const outcome = text(f.get("outcome"), 4)
	const r = pnlFor(outcome, usdtMinor(f.get("pnl")), GAME)
	if ("error" in r) return r.error
	const row = { id: id(), user_id: uid, session_id: s.id, game: g, idx: 1, won: outcome === "win" ? 1 : 0, pnl_minor: r.pnl, state: "done", asset: "", tf: GAME, created_at: Date.now() }
	await db.create(tradeResults, row)
	const next = [...rows, toResult(row)]
	if (allDone(s.deposit_minor, next)) await settle(uid, s, doneOf(next))
}

export async function undoResult(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const last = (await resultsOf(uid, s.id)).at(-1)
	if (!last) return
	await db.deleteMany(tradeResults, { where: { id: last.id, user_id: uid } })
}

export async function finishTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const done = doneOf(await resultsOf(uid, s.id))
	if (!done.length) return "Add at least one result first"
	await settle(uid, s, done)
}

export async function reopenTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s || s.status !== "settled") return
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open predict first"
	const key = `trade:${s.id}`
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key = ${key}`)
		await tx.exec(
			sql`update trade_sessions set status = 'open', income_id = '', settled_at = null, pnl_minor = 0, return_usdt_minor = 0, return_mad_minor = 0 where id = ${s.id} and user_id = ${uid}`,
		)
	})
}
