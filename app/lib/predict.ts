import { sql } from "remix/data-table"
import { banks, db, moveHints, payMaps, predictAccount, predictDays, predictMoves, users } from "../db/index.ts"
import { bankResolver } from "./banks.ts"
import { decryptSecret, encryptSecret } from "./crypto.ts"
import { toMinor } from "./money.ts"
import { addDays, dayOf, today } from "./time.ts"
import { toMad } from "./trade-math.ts"
import { todayFor, type User } from "./users.ts"
import { id, rowsOf, text } from "./util.ts"

const BASE = "https://api.binance.com"
const ADS = "https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search"
const EVERY = 3 * 60000
const RETRY = 20000
const DAY = 86400000
const WINDOW = 29 * DAY
const WINDOWS = 6
const PAGE = 100
const PAGES = 5
const lastTry = new Map<string, number>()
const rates = new Map<string, { v: number; exp: number; at: number }>()

export type WalletMove = {
	id: string
	kind: "buy" | "sell" | "in" | "to_predict" | "to_funding"
	usdt: number
	mad: number
	fee: number
	bankId: string
	pay: string
	day: string
	at: number
	profit?: number
}

export type WalletDay = {
	day: string
	profit: number
	predictProfitMad?: number
	p2pProfitMad?: number
	totalEarnedMad?: number
	totalEarnedUsdt?: number
	balance: number
	transfersUsdt?: number
}

export type MoveHintView = {
	id: string
	kind: "to_predict" | "to_funding"
	usdt: number
	foundAt: number
	status: string
}

export type WalletView = {
	connected: boolean
	error: string
	p2pError: string
	usdt: number
	predictUsdt: number
	fundingUsdt: number
	predictMad: number
	fundingMad: number
	syncedAt: number
	rate: number
	rateAt: number
	live: boolean
	feePct: number
	valueMad: number
	today: number
	total: number
	p2pToday: number
	p2pTotal: number
	fees: number
	earnedToday: number
	earnedTotal: number
	netToday: number
	netTotal: number
	boughtUsdt: number
	soldUsdt: number
	madSpent: number
	madGot: number
	days: WalletDay[]
	moves: WalletMove[]
	openHints: MoveHintView[]
}

const cents = (v: unknown) => Math.round((Number(v) || 0) * 100)

const col = (r: any, n: string, i: number) => r[n] ?? r[i]

const scalar = (r: unknown) => {
	const row = rowsOf(r)[0]
	return Number(row?.s ?? row?.[0] ?? 0) || 0
}

const pct = (v: unknown) => {
	const n = parseFloat(String(v ?? "").replace(",", "."))
	return Number.isFinite(n) && n >= 0 && n <= 5 ? Math.round(n * 100) : -1
}

const hex = (b: ArrayBuffer) => Array.from(new Uint8Array(b), (x) => x.toString(16).padStart(2, "0")).join("")

let timeOffset = 0
let lastTimeSync = 0
async function syncServerTime() {
	const now = Date.now()
	if (now - lastTimeSync < 300000 && lastTimeSync > 0) return
	try {
		const c = new AbortController()
		const timer = setTimeout(() => c.abort(), 4000)
		const r = await fetch(`${BASE}/api/v3/time`, { signal: c.signal })
		clearTimeout(timer)
		if (r.ok) {
			const data: any = await r.json()
			if (data?.serverTime) {
				timeOffset = Number(data.serverTime) - Date.now()
				lastTimeSync = Date.now()
			}
		}
	} catch {}
}

async function sign(secret: string, query: string) {
	const enc = new TextEncoder()
	const key = await crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"])
	return hex(await crypto.subtle.sign("HMAC", key, enc.encode(query)))
}

async function call(apiKey: string, secret: string, path: string, params: Record<string, string> = {}, method: "GET" | "POST" = "GET"): Promise<{ data: any } | { error: string }> {
	await syncServerTime()
	const timestamp = String(Date.now() + timeOffset)
	const query = new URLSearchParams({ ...params, recvWindow: "60000", timestamp }).toString()
	const signature = await sign(secret, query)
	const c = new AbortController()
	const timer = setTimeout(() => c.abort(), 8000)
	try {
		const fullQuery = `${query}&signature=${signature}`
		const url = method === "GET" ? `${BASE}${path}?${fullQuery}` : `${BASE}${path}`
		const init: RequestInit = {
			method,
			headers: { "X-MBX-APIKEY": apiKey, ...(method === "POST" ? { "Content-Type": "application/x-www-form-urlencoded" } : {}) },
			signal: c.signal,
			...(method === "POST" ? { body: fullQuery } : {}),
		}
		const r = await fetch(url, init)
		const body: any = await r.json().catch(() => null)
		if (!r.ok) return { error: String(body?.msg ?? `Binance error ${r.status}`).slice(0, 280) }
		return { data: body }
	} catch {
		return { error: "Could not reach Binance" }
	} finally {
		clearTimeout(timer)
	}
}

async function ads(fiat: string, side: "BUY" | "SELL", payTypes: string[] = []): Promise<number[]> {
	const c = new AbortController()
	const timer = setTimeout(() => c.abort(), 4000)
	try {
		const r = await fetch(ADS, {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ fiat, page: 1, rows: 10, tradeType: side, asset: "USDT", countries: [], proMerchantAds: false, shieldMerchantAds: false, filterType: "all", periods: [], additionalKycVerifyFilter: 0, publisherType: null, payTypes, classifies: ["mass", "profession"] }),
			signal: c.signal,
		})
		if (!r.ok) return []
		const b: any = await r.json().catch(() => null)
		return (Array.isArray(b?.data) ? b.data : []).map((x: any) => Number(x?.adv?.price)).filter((n: number) => Number.isFinite(n) && n > 0)
	} catch {
		return []
	} finally {
		clearTimeout(timer)
	}
}

export async function marketRate(fiat: string, fallback: number, payTypes: string[] = []): Promise<{ rate: number; live: boolean; at: number }> {
	const cacheKey = `${fiat}:${payTypes.slice().sort().join(",")}`
	const hit = rates.get(cacheKey)
	const now = Date.now()
	if (hit && hit.exp > now) return { rate: hit.v || fallback, live: hit.v > 0, at: hit.at }
	let sellAds = payTypes.length ? await ads(fiat, "BUY", payTypes) : []
	if (!sellAds.length) {
		sellAds = await ads(fiat, "BUY", [])
	}
	const firstPrice = sellAds.length && sellAds[0] ? Math.round(sellAds[0] * 100) : 0
	const v = firstPrice > 0 ? firstPrice : 0
	const rateObj = { v: v || fallback, exp: now + (v ? 60000 : 30000), at: now }
	rates.set(cacheKey, rateObj)
	rates.set(fiat, rateObj)
	return { rate: rateObj.v, live: v > 0, at: now }
}

type Row = { id?: string; kind: string; usdt_minor: number; mad_minor: number; fee_minor: number; day: string; created_at: number }

const payOf = (o: any) => {
	if (!o) return ""
	const direct = o.payMethodName || o.payMethod || o.payType || o.paymentMethod || o.tradeMethodName
	if (direct) return String(direct).trim().slice(0, 60)
	if (Array.isArray(o.payMethods) && o.payMethods.length) {
		const pm = o.payMethods[0]
		const n = pm?.tradeMethodName || pm?.payMethodName || pm?.identifier || pm?.payType
		if (n) return String(n).trim().slice(0, 60)
	}
	if (Array.isArray(o.tradeMethods) && o.tradeMethods.length) {
		const tm = o.tradeMethods[0]
		const n = tm?.tradeMethodName || tm?.payMethodName || tm?.identifier || tm?.payType
		if (n) return String(n).trim().slice(0, 60)
	}
	return ""
}

export function p2pStats(moves: Row[], t: string, firstSellRate = 1100) {
	let heldUsdt = 0
	let heldMad = 0
	let transferredOutUsdt = 0
	let transferredOutMad = 0
	let totalProfit = 0
	let todayProfit = 0
	let totalFees = 0
	const profitPerSell = new Map<string, number>()
	const p2pProfitByDay = new Map<string, number>()
	const transfersByDay = new Map<string, number>()

	const sorted = [...moves].sort((a, b) => a.created_at - b.created_at)

	for (const m of sorted) {
		totalFees += m.fee_minor || 0
		if (m.kind === "buy") {
			heldUsdt += m.usdt_minor
			heldMad += m.mad_minor
		} else if (m.kind === "in") {
			heldUsdt += m.usdt_minor
			heldMad += m.mad_minor
		} else if (m.kind === "to_predict") {
			const avg = heldUsdt > 0 ? heldMad / heldUsdt : 0
			const takeUsdt = Math.min(m.usdt_minor, heldUsdt)
			const takeMad = Math.round(takeUsdt * avg)
			heldUsdt -= takeUsdt
			heldMad -= takeMad
			transferredOutUsdt += m.usdt_minor
			transferredOutMad += takeMad
			transfersByDay.set(m.day, (transfersByDay.get(m.day) || 0) + m.usdt_minor)
		} else if (m.kind === "to_funding") {
			const returnUsdt = Math.min(m.usdt_minor, transferredOutUsdt)
			const extraUsdt = Math.max(0, m.usdt_minor - transferredOutUsdt)
			const avgReturnMad = transferredOutUsdt > 0 ? Math.round((returnUsdt * transferredOutMad) / transferredOutUsdt) : 0
			const extraMad = Math.round((extraUsdt * firstSellRate) / 100)
			heldUsdt += m.usdt_minor
			heldMad += avgReturnMad + extraMad
			transferredOutUsdt -= returnUsdt
			transferredOutMad -= avgReturnMad
			transfersByDay.set(m.day, (transfersByDay.get(m.day) || 0) + m.usdt_minor)
		} else if (m.kind === "sell") {
			const avg = heldUsdt > 0 ? heldMad / heldUsdt : 0
			const coveredUsdt = Math.min(m.usdt_minor, heldUsdt)
			const costBasis = Math.round(coveredUsdt * avg)
			const revenue = m.mad_minor
			const profit = revenue - costBasis
			if (m.id) profitPerSell.set(m.id, profit)
			p2pProfitByDay.set(m.day, (p2pProfitByDay.get(m.day) || 0) + profit)
			totalProfit += profit
			if (m.day === t) todayProfit += profit
			heldUsdt -= coveredUsdt
			heldMad -= costBasis
		}
	}

	return { profit: totalProfit, today: todayProfit, fees: totalFees, profitPerSell, p2pProfitByDay, transfersByDay }
}

async function fetchWallet(apiKey: string, secret: string, known: string): Promise<{ usdt: number; wallet: string } | string> {
	let wallet = known
	if (!wallet) {
		const w = await call(apiKey, secret, "/sapi/v1/w3w/wallet/prediction/wallet/list")
		if ("error" in w) return w.error
		wallet = String(w.data?.wallets?.[0]?.walletAddress ?? w.data?.data?.wallets?.[0]?.walletAddress ?? "")
		if (!wallet) return "No prediction wallet found on this Binance account"
	}
	const p = await call(apiKey, secret, "/sapi/v1/w3w/wallet/prediction/position/list", { walletAddress: wallet, limit: "100" })
	if ("error" in p) return p.error
	// Binance nests the payload differently across API revisions: try the summary
	// first, then sum the position values, then fall back to the portfolio view.
	const body = p.data?.data ?? p.data
	const pick = (v: unknown) => (v !== undefined && v !== null && Number.isFinite(Number(v)) ? cents(v) : null)
	let total = pick(body?.summary?.totalValue) ?? pick(body?.totalValue) ?? pick(body?.summary?.totalUsdtValue)
	if (total === null && Array.isArray(body?.positions)) {
		const sum = body.positions.reduce((a: number, x: any) => a + (Number(x?.value) || Number(x?.notional) || 0), 0)
		if (Number.isFinite(sum) && sum > 0) total = cents(sum)
	}
	if (total === null) {
		const pf = await call(apiKey, secret, "/sapi/v1/w3w/wallet/prediction/pnl/portfolio", { walletAddress: wallet })
		if (!("error" in pf)) {
			const b = pf.data?.data ?? pf.data
			total = pick(b?.portfolioValue) ?? pick(b?.totalValue) ?? pick(b?.summary?.totalValue) ?? pick(b?.portfolio?.totalValue)
		}
	}
	if (total === null) return "Binance did not return the wallet value"
	return { usdt: total, wallet }
}

async function fetchFunding(apiKey: string, secret: string): Promise<number | string> {
	// Try 1: /sapi/v1/asset/get-funding-asset with asset filter
	let res = await call(apiKey, secret, "/sapi/v1/asset/get-funding-asset", { asset: "USDT", needBtcValuation: "false" }, "POST")
	if ("error" in res) {
		res = await call(apiKey, secret, "/sapi/v1/asset/get-funding-asset", { needBtcValuation: "false" }, "POST")
	}
	if (!("error" in res)) {
		const list: any[] = Array.isArray(res.data) ? res.data : Array.isArray(res.data?.data) ? res.data.data : []
		const usdt = list.find((x: any) => String(x.asset).toUpperCase() === "USDT")
		if (usdt) {
			const free = Number(usdt.free) || 0
			const freeze = Number(usdt.freeze) || 0
			return cents(free + freeze)
		}
	}
	// Try 2: /sapi/v3/asset/getUserAsset
	const userAsset = await call(apiKey, secret, "/sapi/v3/asset/getUserAsset", { asset: "USDT" }, "POST")
	if (!("error" in userAsset)) {
		const list: any[] = Array.isArray(userAsset.data) ? userAsset.data : []
		const usdt = list.find((x: any) => String(x.asset).toUpperCase() === "USDT")
		if (usdt) {
			const free = Number(usdt.free) || 0
			const freeze = Number(usdt.freeze) || 0
			const locked = Number(usdt.locked) || 0
			return cents(free + freeze + locked)
		}
	}
	// Try 3: /api/v3/account spot balance
	const spot = await call(apiKey, secret, "/api/v3/account")
	if (!("error" in spot)) {
		const balances: any[] = Array.isArray(spot.data?.balances) ? spot.data.balances : []
		const usdt = balances.find((x: any) => String(x.asset).toUpperCase() === "USDT")
		if (usdt) {
			const free = Number(usdt.free) || 0
			const locked = Number(usdt.locked) || 0
			return cents(free + locked)
		}
	}
	if ("error" in res) return res.error
	return 0
}

async function importOrders(uid: string, apiKey: string, secret: string, from: number, bps: number, fiat: string, dayStart: number): Promise<{ upto: number } | string> {
	const now = Date.now()
	const have = new Set((await db.findMany(predictMoves, { where: { user_id: uid }, limit: 20000 })).map((m) => m.order_no).filter(Boolean))
	const bankFor = await bankResolver(uid)
	let start = from
	for (let w = 0; w < WINDOWS && start < now; w++) {
		const end = Math.min(start + WINDOW, now)
		for (const side of ["BUY", "SELL"] as const) {
			for (let page = 1; page <= PAGES; page++) {
				const r = await call(apiKey, secret, "/sapi/v1/c2c/orderMatch/listUserOrderHistory", { tradeType: side, startTimestamp: String(start), endTimestamp: String(end), page: String(page), rows: String(PAGE) })
				if ("error" in r) return r.error
				const list: any[] = Array.isArray(r.data?.data) ? r.data.data : []
				for (const o of list) {
					const no = String(o?.orderNumber ?? "")
					if (!no || have.has(no) || o?.orderStatus !== "COMPLETED" || o?.asset !== "USDT" || String(o?.fiat ?? "").toUpperCase() !== fiat) continue
					const usdt = cents(o.amount)
					const total = cents(o.totalPrice)
					if (!usdt || !total) continue
					const price = Number(o.unitPrice) || total / usdt
					const real = (Number(o.commission) || 0) + (Number(o.takerCommission) || 0)
					const feeMad = Math.round((real > 0 ? real : (Number(o.amount) * bps) / 10000) * price * 100)
					const at = Number(o.createTime) || now
					let pay = payOf(o)
					if (!pay) {
						const det = await call(apiKey, secret, "/sapi/v1/c2c/orderMatch/getUserOrderDetail", { orderNumber: no })
						if (!("error" in det)) pay = payOf(det.data?.data ?? det.data)
					}
					try {
						await db.create(predictMoves, {
							id: id(),
							user_id: uid,
							kind: side === "BUY" ? "buy" : "sell",
							usdt_minor: usdt,
							mad_minor: side === "BUY" ? total + feeMad : Math.max(1, total - feeMad),
							order_no: no,
							fee_minor: feeMad,
							bank_id: bankFor(pay),
							pay,
							day: dayOf(at, dayStart),
							created_at: at,
						})
						have.add(no)
					} catch {}
				}
				if (list.length < PAGE) break
			}
		}
		start = end
	}
	return { upto: start }
}

export async function rebuild(uid: string) {
	const [days, moves, hints, user] = await Promise.all([
		db.findMany(predictDays, { where: { user_id: uid }, orderBy: ["day", "asc"], limit: 800 }),
		db.findMany(predictMoves, { where: { user_id: uid }, limit: 5000 }),
		db.findMany(moveHints, { where: { user_id: uid, status: "open" } }),
		db.find(users, uid),
	])
	const dayStart = typeof user?.day_start === "number" && Number.isInteger(user.day_start) ? user.day_start : 5
	// A detected-but-unconfirmed wallet transfer has already moved the balance.
	// Adjust for open hints so a transfer never counts as earnings — confirming
	// the hint swaps the adjustment for a real move, denying it drops the
	// adjustment and lets the true profit/loss show.
	const hintAdj = new Map<string, number>()
	for (const h of hints) {
		const hd = dayOf(h.found_at, dayStart)
		const signed = h.kind === "to_funding" ? h.usdt_minor : -h.usdt_minor
		hintAdj.set(hd, (hintAdj.get(hd) ?? 0) + signed)
	}
	let prevDay = ""
	let prevBal = 0
	for (const d of days) {
		if (d.locked === 1) {
			prevDay = d.day
			prevBal = d.balance_minor
			continue
		}
		const ms = moves.filter((m) => m.day <= d.day && (prevDay ? m.day > prevDay : m.day === d.day))
		const toPredict = ms.filter((m) => m.kind === "to_predict").reduce((a, m) => a + m.usdt_minor, 0)
		const toFunding = ms.filter((m) => m.kind === "to_funding").reduce((a, m) => a + m.usdt_minor, 0)
		const open = prevDay ? prevBal : d.balance_minor - toPredict + toFunding
		const profit = d.balance_minor - open - toPredict + toFunding + (hintAdj.get(d.day) ?? 0)
		if (d.open_minor !== open || d.profit_minor !== profit) {
			await db.update(predictDays, d.id, { open_minor: open, profit_minor: profit })
		}
		prevDay = d.day
		prevBal = d.balance_minor
	}
}

// Every day since the first balance snapshot needs a row, otherwise a day
// without a sync would fold its earnings into the next visited day. Missing
// days are filled with the last known balance (profit 0) so each day's change
// lands on the day it actually happened.
async function fillDays(uid: string) {
	const user = await db.find(users, uid)
	const dayStart = typeof user?.day_start === "number" && Number.isInteger(user.day_start) ? user.day_start : 5
	const t = today(dayStart)
	const rows = await db.findMany(predictDays, { where: { user_id: uid }, orderBy: ["day", "asc"], limit: 800 })
	if (!rows.length) return
	const byDay = new Map(rows.map((r) => [r.day, r]))
	const first = rows[0]!.day
	let prev = rows[0]!
	let created = 0
	for (let d = addDays(first, 1); d <= t && created < 400; d = addDays(d, 1)) {
		const have = byDay.get(d)
		if (have) {
			prev = have
			continue
		}
		await db.create(predictDays, {
			id: `${uid}:${d}`,
			user_id: uid,
			day: d,
			open_minor: prev.balance_minor,
			balance_minor: prev.balance_minor,
			bought_minor: 0,
			sold_minor: 0,
			profit_minor: 0,
			locked: 0,
			saved_at: prev.saved_at,
		})
		created++
	}
}

async function checkMoveHints(uid: string, dPredict: number, dFunding: number, now: number) {
	const tol = 50
	if (dPredict < -tol && dFunding > tol && Math.abs(dPredict + dFunding) < 200) {
		const amt = Math.abs(dPredict)
		await db.create(moveHints, { id: id(), user_id: uid, kind: "to_funding", usdt_minor: amt, found_at: now, status: "open", resolved_at: 0 })
	} else if (dPredict > tol && dFunding < -tol && Math.abs(dPredict + dFunding) < 200) {
		const amt = dPredict
		await db.create(moveHints, { id: id(), user_id: uid, kind: "to_predict", usdt_minor: amt, found_at: now, status: "open", resolved_at: 0 })
	}
}

async function saveDay(uid: string, balance: number, now: number) {
	const t = await todayFor(uid)
	const key = `${uid}:${t}`
	const row = await db.find(predictDays, key)
	if (row) await db.update(predictDays, key, { balance_minor: balance, saved_at: now })
	else await db.create(predictDays, { id: key, user_id: uid, day: t, open_minor: 0, balance_minor: balance, bought_minor: 0, sold_minor: 0, profit_minor: 0, locked: 0, saved_at: now })
	await fillDays(uid)
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
		const u = await db.find(users, uid)
		const since = a.p2p_since || now
		const from = Math.max(since, a.p2p_synced_at - 2 * DAY)
		const imp = await importOrders(uid, key, secret, from, a.fee_bps, String(u?.currency || "MAD").toUpperCase(), Number.isInteger(u?.day_start) ? Number(u?.day_start) : 5)
		const p2p = typeof imp === "string" ? { p2p_error: imp } : { p2p_error: "", p2p_since: since, p2p_synced_at: imp.upto }

		const [rPredict, rFunding] = await Promise.all([
			fetchWallet(key, secret, a.wallet),
			fetchFunding(key, secret),
		])

		const predictUsdt = typeof rPredict === "object" ? rPredict.usdt : (a.usdt_minor || 0)
		const predictWallet = typeof rPredict === "object" ? rPredict.wallet : (a.wallet || "")
		const fundingMinor = typeof rFunding === "number" ? rFunding : (a.funding_minor || 0)

		const prevP = a.prev_predict_minor || a.usdt_minor || predictUsdt
		const prevF = a.prev_funding_minor || a.funding_minor || fundingMinor
		const dP = predictUsdt - prevP
		const dF = fundingMinor - prevF

		await checkMoveHints(uid, dP, dF, now)

		const lastError = [
			typeof rFunding === "string" && rFunding ? `Funding: ${rFunding}` : "",
			typeof rPredict === "string" && rPredict ? `Predict: ${rPredict}` : "",
		]
			.filter(Boolean)
			.join(" · ")

		await db.update(predictAccount, uid, {
			...p2p,
			wallet: predictWallet,
			usdt_minor: predictUsdt,
			funding_minor: fundingMinor,
			prev_predict_minor: predictUsdt,
			prev_funding_minor: fundingMinor,
			synced_at: now,
			last_error: lastError,
			updated_at: now,
		})
		await saveDay(uid, predictUsdt, now)
	} catch {}
}

export async function syncAllPredict(): Promise<void> {
	const rows = rowsOf(await db.exec(sql`select user_id as u from predict_account where key_enc <> ''`))
	for (const r of rows) {
		await syncPredict(String(col(r, "u", 0)), true)
	}
}

export async function usdtValueMad(uid: string): Promise<number> {
	const [a, u] = await Promise.all([db.findOne(predictAccount, { where: { user_id: uid } }), db.find(users, uid)])
	if (!a) return 0
	const fallback = Number(u?.usdt_rate_minor) > 0 ? Number(u?.usdt_rate_minor) : 1100
	const { rate } = await marketRate(String(u?.currency || "MAD").toUpperCase(), fallback)
	const totalUsdt = (a.usdt_minor || 0) + (a.funding_minor || 0)
	return toMad(totalUsdt, rate)
}

export async function predictTotal(uid: string): Promise<number> {
	const [v, r] = await Promise.all([
		usdtValueMad(uid),
		db.exec(sql`select coalesce(sum(case when kind = 'buy' then 0 - mad_minor when kind = 'sell' then mad_minor else 0 end), 0) as s from predict_moves where user_id = ${uid}`),
	])
	return scalar(r) + v
}

export async function loadWallet(user: User): Promise<WalletView> {
	const uid = user.id
	await syncPredict(uid)
	const [maps, userBanks] = await Promise.all([
		db.findMany(payMaps, { where: { user_id: uid } }),
		db.findMany(banks, { where: { user_id: uid } }),
	])
	const payTypes: string[] = []
	for (const m of maps) {
		const norm = m.method.toUpperCase().replace(/\s+/g, "")
		if (norm && !payTypes.includes(norm)) payTypes.push(norm)
	}
	for (const b of userBanks) {
		if (b.kind === "cash") continue
		const norm = b.name.toUpperCase().replace(/\s+/g, "")
		if (norm && !payTypes.includes(norm)) payTypes.push(norm)
		if (norm.includes("CIH") && !payTypes.includes("CIH")) payTypes.push("CIH")
		if ((norm.includes("BMCE") || norm.includes("AFRICA")) && !payTypes.includes("BMCE")) payTypes.push("BMCE")
	}

	const [a, days, moves, market, hints] = await Promise.all([
		db.findOne(predictAccount, { where: { user_id: uid } }),
		db.findMany(predictDays, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 400 }),
		db.findMany(predictMoves, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 5000 }),
		marketRate(user.currency.toUpperCase(), user.usdt_rate, payTypes),
		db.findMany(moveHints, { where: { user_id: uid, status: "open" }, orderBy: ["found_at", "desc"] }),
	])
	const t = today(user.day_start)
	const buys = moves.filter((m) => m.kind === "buy")
	const sells = moves.filter((m) => m.kind === "sell")
	const ins = moves.filter((m) => m.kind === "in")
	const predictUsdt = a?.usdt_minor ?? 0
	const fundingUsdt = a?.funding_minor ?? 0
	const totalUsdt = predictUsdt + fundingUsdt

		const st = p2pStats(moves, t, market.rate)
		// Open (unconfirmed) transfer hints are already excluded from profit in
		// rebuild(); show them in the transfers column so the daily view matches.
		const hintTransfers = new Map<string, number>()
		for (const h of hints) {
			const hd = dayOf(h.found_at, user.day_start)
			hintTransfers.set(hd, (hintTransfers.get(hd) ?? 0) + h.usdt_minor)
		}
	const predictToday = days.find((d) => d.day === t)?.profit_minor ?? 0
	const predictAll = days.reduce((x, d) => x + d.profit_minor, 0)
	const predictTodayMad = toMad(predictToday, market.rate)
	const predictAllMad = toMad(predictAll, market.rate)

	// Build daily earnings for all days with activity
	const allDayKeys = new Set<string>()
	for (const d of days) allDayKeys.add(d.day)
	for (const m of moves) {
		if (m.day) allDayKeys.add(m.day)
	}
	allDayKeys.add(t)

	const sortedDayKeys = [...allDayKeys].sort().reverse().slice(0, 30)
	const daysMap = new Map(days.map((d) => [d.day, d]))

	const walletDays: WalletDay[] = sortedDayKeys.map((dayKey) => {
		const d = daysMap.get(dayKey)
		const p2pProfitMad = st.p2pProfitByDay.get(dayKey) || 0
		const predictProfitUsdt = d?.profit_minor ?? 0
		const predictProfitMad = toMad(predictProfitUsdt, market.rate)
		const totalEarnedMad = predictProfitMad + p2pProfitMad
		const totalEarnedUsdt = predictProfitUsdt + (market.rate > 0 ? Math.round((p2pProfitMad * 100) / market.rate) : 0)
			const transfersUsdt = (st.transfersByDay.get(dayKey) || 0) + (hintTransfers.get(dayKey) || 0)
		return {
			day: dayKey,
			profit: predictProfitUsdt,
			predictProfitMad,
			p2pProfitMad,
			totalEarnedMad,
			totalEarnedUsdt,
			balance: d?.balance_minor ?? (dayKey === t ? predictUsdt : 0),
			transfersUsdt,
		}
	})

	return {
		connected: !!a && !!a.key_enc,
		error: a?.last_error ?? "",
		p2pError: a?.p2p_error ?? "",
		usdt: totalUsdt,
		predictUsdt,
		fundingUsdt,
		predictMad: toMad(predictUsdt, market.rate),
		fundingMad: toMad(fundingUsdt, market.rate),
		syncedAt: a?.synced_at ?? 0,
		rate: market.rate,
		rateAt: market.at,
		live: market.live,
		feePct: (a?.fee_bps ?? 20) / 100,
		valueMad: toMad(totalUsdt, market.rate),
		today: predictToday,
		total: predictAll,
		p2pToday: st.today,
		p2pTotal: st.profit,
		fees: st.fees,
		earnedToday: predictTodayMad + st.today,
		earnedTotal: predictAllMad + st.profit,
		netToday: predictTodayMad + st.today,
		netTotal: predictAllMad + st.profit,
		boughtUsdt: buys.concat(ins).reduce((x, m) => x + m.usdt_minor, 0),
		soldUsdt: sells.reduce((x, m) => x + m.usdt_minor, 0),
		madSpent: buys.reduce((x, m) => x + m.mad_minor, 0),
		madGot: sells.reduce((x, m) => x + m.mad_minor, 0),
		days: walletDays,
		moves: moves.slice(0, 40).map((m) => ({
			id: m.id,
			kind: m.kind as any,
			usdt: m.usdt_minor,
			mad: m.mad_minor,
			fee: m.fee_minor,
			bankId: m.bank_id,
			pay: m.pay,
			day: m.day,
			at: m.created_at,
			profit: st.profitPerSell.get(m.id),
		})),
		openHints: hints.map((h) => ({ id: h.id, kind: h.kind as any, usdt: h.usdt_minor, foundAt: h.found_at, status: h.status })),
	}
}

export async function addMove(uid: string, f: FormData, kind: "buy" | "sell"): Promise<string | void> {
	const usdt = toMinor(f.get("usdt"))
	const mad = toMinor(f.get("mad"))
	if (!usdt) return "Enter how many USDT"
	if (!mad) return kind === "buy" ? "Enter how much MAD you paid" : "Enter how much MAD you got"
	const pick = text(f.get("bank"), 36)
	const bank = pick ? await db.findOne(banks, { where: { id: pick, user_id: uid } }) : null
	await db.create(predictMoves, { id: id(), user_id: uid, kind, usdt_minor: usdt, mad_minor: mad, order_no: "", fee_minor: 0, bank_id: bank?.id ?? "", pay: "", day: await todayFor(uid), created_at: Date.now() })
	await rebuild(uid)
}

export async function moveToPredict(uid: string, f: FormData): Promise<string | void> {
	const usdt = toMinor(f.get("usdt"))
	if (!usdt || usdt <= 0) return "Enter USDT amount to move to Predict"
	const u = await db.find(users, uid)
	const { rate } = await marketRate(String(u?.currency || "MAD").toUpperCase(), Number(u?.usdt_rate_minor) || 1100)
	await db.create(predictMoves, {
		id: id(),
		user_id: uid,
		kind: "to_predict",
		usdt_minor: usdt,
		mad_minor: toMad(usdt, rate),
		order_no: "",
		fee_minor: 0,
		bank_id: "",
		pay: "",
		day: await todayFor(uid),
		created_at: Date.now(),
	})
	await rebuild(uid)
}

export async function moveToFunding(uid: string, f: FormData): Promise<string | void> {
	const usdt = toMinor(f.get("usdt"))
	if (!usdt || usdt <= 0) return "Enter USDT amount to move back to Funding"
	const u = await db.find(users, uid)
	const { rate } = await marketRate(String(u?.currency || "MAD").toUpperCase(), Number(u?.usdt_rate_minor) || 1100)
	await db.create(predictMoves, {
		id: id(),
		user_id: uid,
		kind: "to_funding",
		usdt_minor: usdt,
		mad_minor: toMad(usdt, rate),
		order_no: "",
		fee_minor: 0,
		bank_id: "",
		pay: "",
		day: await todayFor(uid),
		created_at: Date.now(),
	})
	await rebuild(uid)
}

export async function resolveHint(uid: string, f: FormData): Promise<string | void> {
	const hid = text(f.get("id"), 36)
	const yes = f.get("action") === "yes"
	const hint = await db.findOne(moveHints, { where: { id: hid, user_id: uid } })
	if (!hint) return
	if (yes) {
		const u = await db.find(users, uid)
		const { rate } = await marketRate(String(u?.currency || "MAD").toUpperCase(), Number(u?.usdt_rate_minor) || 1100)
		await db.create(predictMoves, {
			id: id(),
			user_id: uid,
			kind: hint.kind,
			usdt_minor: hint.usdt_minor,
			mad_minor: toMad(hint.usdt_minor, rate),
			order_no: "",
			fee_minor: 0,
			bank_id: "",
			pay: "",
			day: await todayFor(uid),
			created_at: Date.now(),
		})
		await db.update(moveHints, hint.id, { status: "yes", resolved_at: Date.now() })
		await rebuild(uid)
	} else {
		await db.update(moveHints, hint.id, { status: "no", resolved_at: Date.now() })
	}
}

export async function fetchMethods(uid: string): Promise<Array<{ method: string; count: number; bankId: string }>> {
	await syncPredict(uid, true)
	const [moves, maps] = await Promise.all([
		db.findMany(predictMoves, { where: { user_id: uid } }),
		db.findMany(payMaps, { where: { user_id: uid } }),
	])
	const map = new Map(maps.map((m) => [m.method.toLowerCase(), m.bank_id]))
	const countMap = new Map<string, number>()
	for (const m of moves) {
		const p = m.pay.trim()
		if (p) countMap.set(p, (countMap.get(p) ?? 0) + 1)
	}
	return [...countMap.entries()].map(([method, count]) => ({
		method,
		count,
		bankId: map.get(method.toLowerCase()) ?? "",
	}))
}

export async function linkMethod(uid: string, f: FormData): Promise<string | void> {
	const method = text(f.get("method"), 60).trim().toLowerCase()
	const bankId = text(f.get("bank"), 36)
	if (!method || !bankId) return "Pick a method and a bank"
	const key = `${uid}:${method}`
	const had = await db.find(payMaps, key)
	if (had) await db.update(payMaps, key, { bank_id: bankId })
	else await db.create(payMaps, { id: key, user_id: uid, method, bank_id: bankId, created_at: Date.now() })
	await db.exec(sql`update predict_moves set bank_id = ${bankId} where user_id = ${uid} and lower(pay) = ${method} and bank_id = ''`)
}

export async function deleteMove(uid: string, f: FormData): Promise<string | void> {
	const m = await db.findOne(predictMoves, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (m?.kind === "in") return "Undo this from the payments list on the Banks page"
	await db.deleteMany(predictMoves, { where: { id: text(f.get("id"), 36), user_id: uid } })
	await rebuild(uid)
}

export async function saveKeys(uid: string, f: FormData): Promise<string | void> {
	const key = text(f.get("api_key"), 200)
	const secret = text(f.get("api_secret"), 200)
	if (!key || !secret) return "Enter the API key and the secret"
	const raw = text(f.get("fee"), 8)
	const bps = raw ? pct(raw) : 20
	if (bps < 0) return "Fee must be between 0 and 5 percent"
	const days = Math.min(90, Math.max(0, Math.floor(Number(text(f.get("days"), 4)) || 0)))
	const now = Date.now()
	const had = await db.findOne(predictAccount, { where: { user_id: uid } })
	const row = {
		key_enc: await encryptSecret(key),
		secret_enc: await encryptSecret(secret),
		wallet: "",
		last_error: "",
		synced_at: 0,
		fee_bps: raw || !had ? bps : had.fee_bps,
		p2p_since: had && !days ? had.p2p_since : now - days * DAY,
		p2p_synced_at: 0,
		p2p_error: "",
		updated_at: now,
	}
	if (had) await db.update(predictAccount, uid, row)
	else await db.create(predictAccount, { user_id: uid, usdt_minor: 0, funding_minor: 0, prev_funding_minor: 0, prev_predict_minor: 0, ...row })
	lastTry.delete(uid)
	await syncPredict(uid, true)
	const a = await db.findOne(predictAccount, { where: { user_id: uid } })
	if (a?.last_error) return a.last_error
}

export async function saveFee(uid: string, f: FormData): Promise<string | void> {
	const bps = pct(f.get("fee"))
	if (bps < 0) return "Fee must be between 0 and 5 percent"
	const a = await db.findOne(predictAccount, { where: { user_id: uid } })
	if (!a) return "Connect Binance first"
	await db.update(predictAccount, uid, { fee_bps: bps, updated_at: Date.now() })
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
