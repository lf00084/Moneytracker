import { sql } from "remix/data-table"
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases } from "../db/index.ts"
import { settleAuto } from "./auto.ts"
import { exoStatus, liveExo, settleExo } from "./exoclick.ts"
import type { TradeSession } from "./trade-math.ts"
import { loadTrades } from "./trading.ts"
import { addDays, dayLabel, today } from "./time.ts"
import { getActiveAvatar, type User } from "./users.ts"
import { parseJson, rowsOf, type Json } from "./util.ts"

export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number }
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; hours: number; locked: boolean }
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number }
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number; at: number; delta: number }
export type GoalItem = { id: string; name: string; price: number; done: boolean }
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] }
export type Note = { id: string; body: string; at: number; edited: boolean }
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] }
export type Part = "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar" | "names" | "incnames" | "trading"

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
	buys: Buy[]
	incomesToday: Income[]
	sources: Source[]
	debts: DebtView[]
	goals: Goal[]
	notes: Note[]
	days: DayRow[]
	balance: number
}

const settleAll = async (uid: string) => void (await Promise.all([settleAuto(uid), settleExo(uid)]))

const scalar = (r: unknown) => {
	const row = rowsOf(r)[0]
	return Number(row?.s ?? row?.[0] ?? 0) || 0
}

const total = async (uid: string) => {
	const [i, p] = await Promise.all([
		db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
		db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
	])
	return scalar(i) - scalar(p)
}

const names = (r: unknown) => rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean)

export async function balanceOf(uid: string) {
	await settleAll(uid)
	return total(uid)
}

const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number }): Buy => ({
	id: r.id,
	name: r.name,
	qty: r.qty,
	unit: r.unit_minor,
	total: r.total_minor,
	day: r.day,
	at: r.created_at,
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

export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
	const need = new Set(parts)
	const uid = user.id
	const t = today()
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
		buys: [],
		incomesToday: [],
		sources: [],
		debts: [],
		goals: [],
		notes: [],
		days: [],
		balance: 0,
	}

	const needSources = need.has("sources") || need.has("today") || need.has("history")
	if (needSources || need.has("balance")) await settleAll(uid)

	const jobs: Promise<void>[] = []
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
	const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string; meta: string }): Income => {
		const m = parseJson(r.meta)
		return {
			id: r.id,
			sourceId: r.source_id ?? "",
			source: byId.get(r.source_id ?? "") ?? (String(m.label ?? m.name ?? "").trim() || "Other"),
			amount: r.amount_minor,
			day: r.day,
			hours: Number(m.hours) || 0,
			locked: !!m.trade,
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
				liveExo(uid, exoIds.filter((x) => x.active).map((x) => x.id), user.usd_rate_minor),
			]).then(([rows, live]) => {
				const exo = new Set(exoIds.map((x) => x.id))
				s.incomesToday = rows.filter((r) => !(r.source_id && exo.has(r.source_id))).map(toIncome)
				for (const x of sourceRows) {
					const v = live[x.id]
					if (!v) continue
					s.exoToday[x.id] = v.usd
					s.incomesToday.push({ id: `exo-${x.id}`, sourceId: x.id, source: x.name, amount: v.mad, day: v.day, hours: 0, locked: true })
				}
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

	if (need.has("notes"))
		jobs.push(
			db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
				s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }))
			}),
		)

	if (need.has("history"))
		jobs.push(
			Promise.all([
				db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
				db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
			]).then(([bs, is]) => {
				s.days = Array.from({ length: 30 }, (_, i) => {
					const day = addDays(t, -i)
					const b = bs.filter((x) => x.day === day)
					const inc = is.filter((x) => x.day === day && parseJson(x.meta).final !== 0)
					return {
						day,
						label: dayLabel(day),
						earned: inc.reduce((a, x) => a + x.amount_minor, 0),
						bought: b.reduce((a, x) => a + x.total_minor, 0),
						buys: b.map(toBuy),
						incomes: inc.map(toIncome),
					}
				}).filter((d, i) => i === 0 || d.buys.length || d.incomes.length)
			}),
		)

	if (need.has("balance")) jobs.push(total(uid).then((b) => void (s.balance = b)))

	await Promise.all(jobs)
	return s
}
