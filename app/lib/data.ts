import { sql } from "remix/data-table"
import { dailySnapshots, db, debtPayments, debts, goalItems, goals, incomes, incomeSources, people, purchases, sourcePayments } from "../db/index.ts"
import { settleAuto } from "./auto.ts"
import { exoStatus, latestInvoice, liveExo, settleExo, type Invoice } from "./exoclick.ts"
import type { TradeSession } from "./trade-math.ts"
import { bankTotal, getSetup, loadMoney, type MoneyView } from "./banks.ts"
import { loadWallet, marketRate, predictTotal, syncPredict, usdtValueMad, usdtValueMadText, type WalletView } from "./predict.ts"
import { loadTrades } from "./trading.ts"
import { addDays, dayLabel, today } from "./time.ts"
import { getActiveAvatar, type User } from "./users.ts"
import { parseJson, rowsOf, type Json } from "./util.ts"
import { addMad, minorToMad, showMad } from "./usdt.ts"

export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number; bankId: string }
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; hours: number; locked: boolean; at: number }
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number }
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number; at: number; delta: number }
export type GoalItem = { id: string; name: string; price: number; done: boolean }
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] }
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] }
export type Part = "today" | "sources" | "debts" | "goals" | "history" | "balance" | "avatar" | "invoice" | "names" | "incnames" | "trading" | "wallet" | "money"

export type SnapshotView = {
	startRate: number
	currentRate: number
	priceEffectMad: number
}

export type State = {
	user: User
	back: string
	error: string
	avatar: string | null
	names: string[]
	incNames: string[]
	exo: Record<string, string>
	exoToday: Record<string, number>
	trades: TradeSession[]
	wallet: WalletView | null
	money: MoneyView | null
	buys: Buy[]
	incomesToday: Income[]
	sources: Source[]
	debts: DebtView[]
	goals: Goal[]
	days: DayRow[]
	balance: number
	// Same balance as a decimal string: bank money + the exact MAD value of the
	// Binance USDT wallets (down to a millionth), already added together.
	balanceText: string
	invoice: Invoice | null
	snapshot: SnapshotView | null
}

const settleAll = async (uid: string) => void (await Promise.all([settleAuto(uid), settleExo(uid), syncPredict(uid)]))

const scalar = (r: unknown) => {
	const row = rowsOf(r)[0]
	return Number(row?.s ?? row?.[0] ?? 0) || 0
}

const total = async (uid: string) => {
	const setup = await getSetup(uid)
	if (setup) {
		const [b, v] = await Promise.all([bankTotal(uid, setup), usdtValueMad(uid)])
		return b + v
	}
	const [i, p, w] = await Promise.all([
		db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
		db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
		predictTotal(uid),
	])
	return scalar(i) - scalar(p) + w
}

const names = (r: unknown) => rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean)

export async function balanceOf(uid: string) {
	await settleAll(uid)
	return total(uid)
}

const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number; bank_id?: string }): Buy => ({
	id: r.id,
	name: r.name,
	qty: r.qty,
	unit: r.unit_minor,
	total: r.total_minor,
	day: r.day,
	at: r.created_at,
	bankId: r.bank_id || "",
})

async function loadDebts(uid: string): Promise<DebtView[]> {
	const [pe, de, pay] = await Promise.all([
		db.findMany(people, { where: { user_id: uid } }),
		db.findMany(debts, { where: { user_id: uid } }),
		db.findMany(debtPayments, { where: { user_id: uid } }),
	])
	const who = new Map(pe.map((p) => [p.id, p.name]))
	const paid = new Map<string, number>()
	for (const p of pay) paid.set(p.debt_id, (paid.get(p.debt_id) ?? 0) + p.amount_minor)
	return de
		.map((d): DebtView => {
			const kind = d.kind === "item" ? "item" : "money"
			return {
				id: d.id,
				person: who.get(d.person_id) ?? "?",
				kind,
				item: d.item_name || "cig",
				owed: kind === "item" ? (d.item_qty ?? 0) : d.amount_minor,
				paid: paid.get(d.id) ?? 0,
				at: d.updated_at || d.created_at,
				delta: d.last_delta || 0,
			}
		})
		.filter((d) => d.owed > 0)
		.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1))
}

async function recordSnapshot(user: User, money: number, usdt: number, onhold: number, grandTotal: number, rate: number): Promise<SnapshotView> {
	const uid = user.id
	const t = today(user.day_start)
	const snapId = `${uid}:${t}`
	const now = Date.now()
	const existing = await db.findOne(dailySnapshots, { where: { id: snapId } })

	let startRate = rate
	if (existing) {
		startRate = existing.start_rate_minor || rate
		await db.update(dailySnapshots, existing.id, {
			money_minor: money,
			usdt_minor: usdt,
			onhold_minor: onhold,
			total_minor: grandTotal,
			rate_minor: rate,
			updated_at: now,
		})
	} else {
		try {
			await db.create(dailySnapshots, {
				id: snapId,
				user_id: uid,
				day: t,
				money_minor: money,
				usdt_minor: usdt,
				onhold_minor: onhold,
				total_minor: grandTotal,
				rate_minor: rate,
				start_rate_minor: rate,
				created_at: now,
				updated_at: now,
			})
		} catch {}
	}

	const priceEffectMad = Math.round((usdt * (rate - startRate)) / 10000)
	return { startRate, currentRate: rate, priceEffectMad }
}

export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
	const need = new Set(parts)
	const uid = user.id
	const t = today(user.day_start)
	const s: State = {
		user,
		back: extra.back,
		error: extra.error ?? "",
		avatar: null,
		names: [],
		incNames: [],
		exo: {},
		exoToday: {},
		trades: [],
		wallet: null,
		money: null,
		buys: [],
		incomesToday: [],
		sources: [],
		debts: [],
		goals: [],
		days: [],
		balance: 0,
		balanceText: "0",
		invoice: null,
		snapshot: null,
	}

	const needSources = need.has("sources") || need.has("today") || need.has("history")
	if (needSources || need.has("balance") || need.has("money")) await settleAll(uid)

	const jobs: Promise<void>[] = []
	if (need.has("invoice")) jobs.push(latestInvoice(uid).then((v) => void (s.invoice = v)))
	if (need.has("avatar")) jobs.push(getActiveAvatar(uid).then((a) => void (s.avatar = a)))

	let sourceRows: Source[] = []
	if (needSources) {
		const rows = await db.findMany(incomeSources, { where: { user_id: uid }, orderBy: ["created_at", "asc"] })
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
			.sort((a, b) => a.sort - b.sort)
		s.sources = sourceRows
		jobs.push(exoStatus(sourceRows).then((e) => void (s.exo = e)))
	}

	const byId = new Map(sourceRows.map((x) => [x.id, x.name]))
	const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string; meta: string; created_at?: number; usd_minor?: number }): Income => {
		const m = parseJson(r.meta)
		const rate = Number(m.rate_minor) || user.usd_rate_minor || 1000
		const amt = r.amount_minor || (r.usd_minor ? Math.round((r.usd_minor * rate) / 100) : 0)
		return {
			id: r.id,
			sourceId: r.source_id ?? "",
			source: byId.get(r.source_id ?? "") ?? (String(m.label ?? m.name ?? "").trim() || "Other"),
			amount: amt,
			day: r.day,
			hours: Number(m.hours) || 0,
			locked: !!m.trade,
			at: r.created_at || Date.now(),
		}
	}

	if (need.has("today")) {
		const exoIds = sourceRows.filter((x) => x.type === "exoclick")
		jobs.push(
			db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
				s.buys = rows.map(toBuy)
			}),
			Promise.all([
				db.findMany(incomes, { where: { user_id: uid, day: t } }),
				db.findMany(sourcePayments, { where: { user_id: uid, day: t } }),
				liveExo(uid, exoIds.filter((x) => x.active).map((x) => x.id), user.usd_rate_minor),
			]).then(([rows, payments, exoMap]) => {
				s.exoToday = {}
				for (const [xid, data] of Object.entries(exoMap ?? {})) {
					s.exoToday[xid] = data.usd
				}

				const instantEntries = rows
					.filter((r) => {
						const m = parseJson(r.meta)
						if (Number(m.instant) === 1) return true
						if (!r.source_id) return !m.adjust && !m.trade
						const src = sourceRows.find((s) => s.id === r.source_id)
						if (src?.type === "exoclick") return true
						return src && Number(parseJson(String(src.config ?? "")).instant) === 1
					})
					.map(toIncome)

				for (const exSrc of exoIds) {
					if (!exSrc.active) continue
					const already = instantEntries.some((i) => i.sourceId === exSrc.id)
					const exoInfo = exoMap?.[exSrc.id]
					if (!already && exoInfo && exoInfo.mad > 0) {
						instantEntries.push({
							id: `exo-${exSrc.id}-${t}`,
							sourceId: exSrc.id,
							source: exSrc.name,
							amount: exoInfo.mad,
							day: t,
							hours: 0,
							locked: true,
							at: Date.now(),
						})
					}
				}

				const paymentsToday: Income[] = payments.map((p) => ({
					id: p.id,
					sourceId: p.source_id,
					source: p.source_name,
					amount: p.amount_minor,
					day: p.day,
					hours: 0,
					locked: true,
					at: p.created_at || Date.now(),
				}))

				s.incomesToday = [...instantEntries, ...paymentsToday]
			}),
		)
	}

	if (need.has("names"))
		jobs.push(
			db
				.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null and name not like 'Deposit % USDT' group by lower(name) order by c desc, max(created_at) desc`)
				.then((r) => void (s.names = names(r))),
		)

	if (need.has("incnames"))
		jobs.push(
			db
				.exec(sql`select min(json_extract(meta, '$.label')) as n, count(*) as c from incomes where user_id = ${uid} and json_extract(meta, '$.label') is not null and json_extract(meta, '$.label') <> '' group by lower(json_extract(meta, '$.label')) order by c desc, max(created_at) desc limit 12`)
				.then((r) => void (s.incNames = names(r))),
		)

	if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)))
	if (need.has("trading")) jobs.push(loadTrades(uid).then((x) => void (s.trades = x)))
	if (need.has("wallet")) jobs.push(loadWallet(user).then((x) => void (s.wallet = x)))

	if (need.has("goals"))
		jobs.push(
			Promise.all([
				db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
				db.findMany(goalItems, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
			]).then(([rows, its]) => {
				s.goals = rows.map((g) => {
					const items: GoalItem[] = its.filter((i) => i.goal_id === g.id).map((i) => ({ id: i.id, name: i.name, price: i.price_minor, done: !!i.done_at }))
					const left = items.filter((i) => !i.done)
					return { id: g.id, title: g.title, target: left.reduce((a, i) => a + i.price, 0), saved: g.saved_minor, done: items.length > 0 && left.length === 0, items }
				})
			}),
		)

	if (need.has("history"))
		jobs.push(
			Promise.all([
				db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
				db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
				db.findMany(sourcePayments, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
			]).then(([bs, is, sps]) => {
				s.days = Array.from({ length: 30 }, (_, i) => {
					const day = addDays(t, -i)
					const b = bs.filter((x) => x.day === day)
					const inc = is.filter((x) => x.day === day)
					const paymentsOnDay = sps.filter((p) => p.day === day)
					const mappedIncomes = inc.map(toIncome).filter((x) => x.amount > 0)
					const mappedPayments: Income[] = paymentsOnDay.map((p) => ({
						id: p.id,
						sourceId: p.source_id,
						source: `${p.source_name} (Paid)`,
						amount: p.amount_minor,
						day: p.day,
						hours: 0,
						locked: false,
						at: p.created_at || Date.now(),
					}))
					const allIncomes = [...mappedIncomes, ...mappedPayments]
					return {
						day,
						label: dayLabel(day, t),
						earned: allIncomes.reduce((a, x) => a + x.amount, 0),
						bought: b.reduce((a, x) => a + x.total_minor, 0),
						buys: b.map(toBuy),
						incomes: allIncomes,
					}
				}).filter((d, i) => i === 0 || d.buys.length || d.incomes.length)
			}),
		)

	if (need.has("balance") || need.has("money"))
		jobs.push(
			(async () => {
				const setup = await getSetup(uid)
				const [usdt, market] = await Promise.all([
					usdtValueMadText(uid),
					marketRate(user.currency.toUpperCase(), user.usdt_rate),
				])
				const usdtMad = Math.round(Number(usdt.text) * 100)
				if (!setup) {
					s.balance = await total(uid)
					s.balanceText = addMad(minorToMad(s.balance), "0")
					return
				}
				s.money = await loadMoney(user, setup, usdtMad)
				s.balance = s.money.total
				// Bank money in cents + USDT value at 1e-10 precision: a 0.000001 MAD
				// remainder from the wallets still moves the balance.
				s.balanceText = addMad(minorToMad(s.money.banksTotal + s.money.unmatchedMad), usdt.text)
				const usdtMinor = s.wallet?.usdt ?? 0
				s.snapshot = await recordSnapshot(user, s.money.banksTotal, usdtMinor, s.money.pendingMad, s.balance, market.rate)
			})(),
		)

	await Promise.all(jobs)
	return s
}
