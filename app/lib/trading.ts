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
