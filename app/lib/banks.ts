import { sql } from "remix/data-table"
import { bankMoves, banks, db, incomeSources, moneySetup, payMaps, predictMoves, sourceAdjusts, sourcePayments } from "../db/index.ts"
import { fmt, toMinor, toSigned } from "./money.ts"
import { addDays, today } from "./time.ts"
import { todayFor, type User } from "./users.ts"
import { id, parseJson, rowsOf, text } from "./util.ts"

type Result = Promise<string | void>

export type BankView = { id: string; name: string; balance: number; isDefault: boolean; cash: boolean; iconUrl: string }
export type PendingView = { id: string; name: string; usd: boolean; earned: number; paid: number; left: number; madLeft: number; due: string; overdue: number; payDays: number; today: number; hours: number }
export type BankMoveView = { id: string; bank: string; amount: number; kind: string; note: string; day: string; at: number; ref: string }
export type PaymentView = { id: string; source: string; amount: number; usd: boolean; bank: string; day: string; at: number }
export type LooseMove = { id: string; kind: string; usdt: number; mad: number; pay: string; day: string; fee: number }
export type MoneyView = {
	banks: BankView[]
	cash: number
	banksTotal: number
	unmatchedMad: number
	unmatchedCount: number
	usdtMad: number
	total: number
	pending: PendingView[]
	pendingMad: number
	overdueMad: number
	moves: BankMoveView[]
	payments: PaymentView[]
	loose: LooseMove[]
}

type Setup = NonNullable<Awaited<ReturnType<typeof getSetup>>>

const num = (v: unknown) => Number(v) || 0

const pairs = (r: unknown): [string, number][] => rowsOf(r).map((x) => [String(x.b ?? x[0] ?? ""), num(x.s ?? x[1])])

export const getSetup = (uid: string) => db.findOne(moneySetup, { where: { user_id: uid } })

const bankList = (uid: string) => db.findMany(banks, { where: { user_id: uid }, orderBy: ["sort", "asc"] })

const cashFirst = <T extends { kind: string; sort: number }>(list: T[]) =>
	[...list].sort((a, b) => Number(b.kind === "cash") - Number(a.kind === "cash") || a.sort - b.sort)

export async function ensureCash(uid: string) {
	const list = await bankList(uid)
	const existing = list.find((b) => b.kind === "cash" || b.name.trim().toLowerCase() === "cash")
	if (existing) {
		if (existing.kind !== "cash" || existing.name !== "Cash") {
			await db.update(banks, existing.id, { kind: "cash", name: "Cash" })
		}
		return cashFirst(await bankList(uid))
	}
	try {
		await db.create(banks, { id: id(), user_id: uid, name: "Cash", kind: "cash", icon_url: "", opening_minor: 0, sort: 0, created_at: Date.now() })
	} catch {}
	return cashFirst(await bankList(uid))
}

const isInstant = (config: string) => Number(parseJson(config).instant) === 1

export const defaultOf = (setup: Setup | null, list: { id: string; kind: string }[]) => {
	if (setup?.default_bank && list.some((b) => b.id === setup.default_bank)) return setup.default_bank
	const cash = list.find((b) => b.kind === "cash")
	return cash?.id ?? list[0]?.id ?? ""
}

export async function bankBalances(uid: string, setup: Setup | null) {
	const list = await ensureCash(uid)
	const def = defaultOf(setup, list)
	const cashId = list.find((b) => b.kind === "cash")?.id ?? ""

	const [mv, p2p, rec, spent, inst] = await Promise.all([
		db.exec(sql`select bank_id as b, coalesce(sum(amount_minor), 0) as s from bank_moves where user_id = ${uid} group by bank_id`),
		db.exec(sql`select bank_id as b, kind as k, coalesce(mad_minor, 0) as m from predict_moves where user_id = ${uid} and (kind = 'buy' or kind = 'sell')`),
		db.exec(sql`select coalesce(json_extract(meta, '$.to'), '') as b, coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid} and source_id is null and coalesce(json_extract(meta, '$.paid'), 0) = 0 group by 1`),
		db.exec(sql`select coalesce(bank_id, '') as b, coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid} group by 1`),
		db.exec(sql`select coalesce(json_extract(meta, '$.to'), '') as b, coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid} and json_extract(meta, '$.instant') = 1 group by 1`),
	])

	const bal = new Map(list.map((b) => [b.id, b.opening_minor]))
	const add = (k: string, v: number) => {
		if (bal.has(k)) bal.set(k, bal.get(k)! + v)
	}

	for (const [b, s] of pairs(mv)) add(b, s)

	let unmatchedMad = 0
	let unmatchedCount = 0
	for (const r of rowsOf(p2p)) {
		const bid = String(r.b ?? r[0] ?? "")
		const kind = String(r.k ?? r[1] ?? "")
		const mad = num(r.m ?? r[2])
		const signedMad = kind === "buy" ? -mad : mad
		if (bid && bal.has(bid)) add(bid, signedMad)
		else {
			unmatchedMad += signedMad
			unmatchedCount++
		}
	}

	const fallbackDest = (b: string) => (bal.has(b) ? b : cashId || def)
	for (const [b, s] of pairs(rec)) add(fallbackDest(b), s)
	for (const [b, s] of pairs(inst)) add(fallbackDest(b), s)

	for (const [b, s] of pairs(spent)) {
		const target = b && bal.has(b) ? b : cashId || def
		add(target, -s)
	}

	const cash = bal.get(cashId) ?? 0
	const banksTotal = [...bal.values()].reduce((a, v) => a + v, 0)
	return { list, def, bal, cash, banksTotal, unmatchedMad, unmatchedCount }
}

export async function bankTotal(uid: string, setup: Setup | null) {
	return (await bankBalances(uid, setup)).banksTotal
}

export async function pendingList(uid: string, usdRate: number, t: string): Promise<PendingView[]> {
	const [srcs, rows, pays, adjusts] = await Promise.all([
		db.findMany(incomeSources, { where: { user_id: uid } }),
		db.exec(sql`select source_id as k, day, amount_minor as m, usd_minor as u, cast(coalesce(json_extract(meta, '$.hours'), 0) as real) as h from incomes where user_id = ${uid} and source_id is not null order by day asc`),
		db.exec(sql`select source_id as b, coalesce(sum(amount_minor), 0) as s from source_payments where user_id = ${uid} group by source_id`),
		db.exec(sql`select source_id as b, coalesce(sum(amount_minor), 0) as s from source_adjusts where user_id = ${uid} group by source_id`),
	])

	const paid = new Map(pairs(pays))
	const adj = new Map(pairs(adjusts))
	const by = new Map<string, { day: string; m: number; u: number; h: number }[]>()
	for (const r of rowsOf(rows)) {
		const k = String(r.k ?? r[0] ?? "")
		const list = by.get(k) ?? []
		list.push({ day: String(r.day ?? r[1] ?? ""), m: num(r.m ?? r[2]), u: num(r.u ?? r[3]), h: num(r.h) })
		by.set(k, list)
	}

	const out: PendingView[] = []
	for (const s of srcs) {
		if (isInstant(s.config)) continue
		const usd = s.type === "exoclick"
		const list = (by.get(s.id) ?? []).map((x) => ({ day: x.day, v: usd ? x.u : x.m, h: x.h }))
		const earned = list.reduce((a, x) => a + x.v, 0)
		const done = paid.get(s.id) ?? 0
		const netAdj = adj.get(s.id) ?? 0
		const payDays = Math.max(0, Math.min(90, Math.floor(num(parseJson(s.config).pay_days))))
		let pool = done
		let due = ""
		let overdue = 0
		for (const x of list) {
			const take = Math.min(pool, x.v)
			pool -= take
			const rem = x.v - take
			if (rem <= 0) continue
			const d = addDays(x.day, payDays)
			if (!due || d < due) due = d
			if (payDays > 0 && d <= t) overdue += rem
		}
		const left = Math.max(0, earned - done + netAdj)
		out.push({
			id: s.id,
			name: s.name,
			usd,
			earned,
			paid: done,
			left,
			madLeft: usd ? Math.round((left * usdRate) / 100) : left,
			due: payDays > 0 ? due : "",
			overdue,
			payDays,
			today: list.find((x) => x.day === t)?.v ?? 0,
			hours: list.find((x) => x.day === t)?.h ?? 0,
		})
	}
	return out.sort((a, b) => b.madLeft - a.madLeft)
}

export async function loadMoney(user: User, setup: Setup | null, usdtMad: number): Promise<MoneyView> {
	const uid = user.id
	const t = today(user.day_start)
	const [b, pending, mv, pays, loose] = await Promise.all([
		bankBalances(uid, setup),
		pendingList(uid, user.usd_rate_minor, t),
		db.findMany(bankMoves, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 40 }),
		db.findMany(sourcePayments, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 40 }),
		db.findMany(predictMoves, { where: { user_id: uid, bank_id: "" }, orderBy: ["created_at", "desc"], limit: 60 }),
	])

	const name = new Map(b.list.map((x) => [x.id, x.name]))
	const exoIds = new Set((await db.findMany(incomeSources, { where: { user_id: uid, type: "exoclick" } })).map((x) => x.id))
	const banksView: BankView[] = b.list.map((x) => ({
		id: x.id,
		name: x.name,
		balance: b.bal.get(x.id) ?? 0,
		isDefault: x.id === b.def,
		cash: x.kind === "cash",
		iconUrl: x.icon_url || "",
	}))

	const grandTotal = b.banksTotal + b.unmatchedMad + usdtMad

	return {
		banks: banksView,
		cash: b.cash,
		banksTotal: b.banksTotal,
		unmatchedMad: b.unmatchedMad,
		unmatchedCount: b.unmatchedCount,
		usdtMad,
		total: grandTotal,
		pending,
		pendingMad: pending.reduce((a, p) => a + p.madLeft, 0),
		overdueMad: pending.reduce((a, p) => a + (p.usd ? Math.round((p.overdue * user.usd_rate_minor) / 100) : p.overdue), 0),
		moves: mv
			.filter((m) => m.kind !== "paid" && name.has(m.bank_id))
			.slice(0, 20)
			.map((m) => ({ id: m.id, bank: name.get(m.bank_id) ?? "", amount: m.amount_minor, kind: m.kind, note: m.note, day: m.day, at: m.created_at, ref: m.ref || "" })),
		payments: pays.slice(0, 20).map((p) => ({ id: p.id, source: p.source_name, amount: p.amount_minor, usd: exoIds.has(p.source_id), bank: name.get(p.bank_id) ?? "", day: p.day, at: p.created_at })),
		loose: loose
			.filter((m) => m.kind === "buy" || m.kind === "sell")
			.slice(0, 20)
			.map((m) => ({ id: m.id, kind: m.kind, usdt: m.usdt_minor, mad: m.mad_minor, pay: m.pay, day: m.day, fee: m.fee_minor })),
	}
}

export async function bankResolver(uid: string) {
	const [all, maps] = await Promise.all([bankList(uid), db.findMany(payMaps, { where: { user_id: uid } })])
	const list = all.filter((b) => b.kind !== "cash")
	const map = new Map(maps.map((m) => [m.method.toLowerCase(), m.bank_id]))

	const ALIASES: Record<string, string[]> = {
		cih: ["cih", "cih bank"],
		bmce: ["bmce", "bmce bank", "bank of africa", "boa"],
		attijari: ["attijari", "attijariwafa", "attijariwafa bank", "attijariwafabank"],
		barid: ["barid", "al barid", "al barid bank", "barid bank", "poste"],
		cashplus: ["cash plus", "cashplus"],
	}

	return (method: string) => {
		const m = method.trim().toLowerCase()
		if (!m || !list.length) return ""
		const hit = map.get(m)
		if (hit && all.some((b) => b.id === hit)) return hit
		const by = list.find((b) => {
			const n = b.name.trim().toLowerCase()
			if (n.length >= 2 && (m === n || m.includes(n) || n.includes(m))) return true
			for (const [, aliases] of Object.entries(ALIASES)) {
				const bankMatches = aliases.some((a) => n.includes(a) || a.includes(n))
				const methodMatches = aliases.some((a) => m.includes(a) || a.includes(m))
				if (bankMatches && methodMatches) return true
			}
			return false
		})
		return by?.id ?? ""
	}
}

export async function setupBanks(user: User, f: FormData): Result {
	const uid = user.id
	if (await getSetup(uid)) return "Banks are already set up"
	const rows: { name: string; open: number; icon: string }[] = []
	for (const i of [1, 2, 3]) {
		const name = text(f.get(`name${i}`), 40)
		if (!name) continue
		if (name.toLowerCase() === "cash") return "Cash is built in. Use another name"
		if (rows.some((r) => r.name.toLowerCase() === name.toLowerCase())) return `${name} is listed twice`
		const icon = text(f.get(`icon${i}`), 300)
		if (icon && !validateIconUrl(icon)) return `Icon for ${name} must be a valid image URL`
		rows.push({ name, open: toSigned(f.get(`amount${i}`)) ?? 0, icon })
	}
	if (!rows.length) return "Enter at least one bank"
	const now = Date.now()
	const ids = rows.map(() => id())
	const cashId = id()
	const cash = toSigned(f.get("cash")) ?? 0
	await db.transaction(async (tx) => {
		await tx.create(banks, { id: cashId, user_id: uid, name: "Cash", kind: "cash", icon_url: "", opening_minor: cash, sort: 0, created_at: now })
		for (const [i, r] of rows.entries()) {
			await tx.create(banks, { id: ids[i]!, user_id: uid, name: r.name, kind: "bank", icon_url: r.icon, opening_minor: r.open, sort: i + 1, created_at: now })
		}
		await tx.create(moneySetup, { user_id: uid, from_day: "", default_bank: cashId, all_time: 1, created_at: now })
	})
}

export function validateIconUrl(url: string): boolean {
	const trimmed = url.trim()
	if (!trimmed) return true
	try {
		const u = new URL(trimmed)
		return u.protocol === "https:" || u.protocol === "http:"
	} catch {
		return trimmed.startsWith("data:image/")
	}
}

export async function addBank(uid: string, f: FormData): Result {
	if (!(await getSetup(uid))) return "Set up your banks first"
	const name = text(f.get("name"), 40)
	if (!name) return "Enter a bank name"
	if (name.toLowerCase() === "cash") return "Cash is built in already"
	const list = await bankList(uid)
	if (list.some((b) => b.name.toLowerCase() === name.toLowerCase())) return `You already have ${name}`
	const icon = text(f.get("icon_url"), 300)
	if (icon && !validateIconUrl(icon)) return "Icon URL must be a valid image URL"
	await db.create(banks, { id: id(), user_id: uid, name, kind: "bank", icon_url: icon, opening_minor: toSigned(f.get("amount")) ?? 0, sort: (list.at(-1)?.sort ?? -1) + 1, created_at: Date.now() })
}

export async function renameBank(uid: string, f: FormData): Result {
	const b = await db.findOne(banks, { where: { id: text(f.get("bank"), 36), user_id: uid } })
	if (!b) return "Unknown bank"
	if (b.kind === "cash") return "Cash keeps its name"
	const name = text(f.get("name"), 40)
	if (!name) return "Enter a bank name"
	if (name.toLowerCase() === "cash") return "Cash is built in already"
	const list = await bankList(uid)
	if (list.some((x) => x.id !== b.id && x.name.toLowerCase() === name.toLowerCase())) return `You already have ${name}`
	await db.update(banks, b.id, { name })
}

export async function updateBankIcon(uid: string, f: FormData): Result {
	const b = await db.findOne(banks, { where: { id: text(f.get("bank"), 36), user_id: uid } })
	if (!b) return "Unknown bank"
	const icon = text(f.get("icon_url"), 300)
	if (icon && !validateIconUrl(icon)) return "Icon URL must be a valid image URL"
	await db.update(banks, b.id, { icon_url: icon })
}

export async function defaultBank(uid: string, f: FormData): Result {
	const b = await db.findOne(banks, { where: { id: text(f.get("bank"), 36), user_id: uid } })
	if (!b) return "Unknown bank"
	await db.update(moneySetup, uid, { default_bank: b.id })
}

export async function deleteBank(uid: string, f: FormData): Result {
	const setup = await getSetup(uid)
	const b = await db.findOne(banks, { where: { id: text(f.get("bank"), 36), user_id: uid } })
	if (!setup || !b) return "Unknown bank"
	if (b.kind === "cash") return "Cash can't be deleted"
	const cur = await bankBalances(uid, setup)
	if (cur.def === b.id) return "Pick another bank for spending first"
	if (cur.list.filter((x) => x.kind !== "cash").length < 2) return "Keep at least one bank"
	if (cur.bal.get(b.id) !== 0) return `${b.name} still holds ${fmt(cur.bal.get(b.id) ?? 0)}. Set its balance to 0 first`
	await db.transaction(async (tx) => {
		await tx.exec(sql`update predict_moves set bank_id = '' where user_id = ${uid} and bank_id = ${b.id}`)
		await tx.exec(sql`delete from pay_maps where user_id = ${uid} and bank_id = ${b.id}`)
		await tx.exec(sql`delete from bank_moves where user_id = ${uid} and bank_id = ${b.id}`)
		await tx.exec(sql`delete from banks where id = ${b.id} and user_id = ${uid}`)
	})
}

export async function setBankBalance(uid: string, f: FormData): Result {
	const setup = await getSetup(uid)
	const b = await db.findOne(banks, { where: { id: text(f.get("bank"), 36), user_id: uid } })
	if (!setup || !b) return "Unknown bank"
	const target = toSigned(f.get("balance"))
	if (target === null) return "Enter the balance"
	const cur = await bankBalances(uid, setup)
	const diff = target - (cur.bal.get(b.id) ?? 0)
	if (!diff) return
	await db.create(bankMoves, { id: id(), user_id: uid, bank_id: b.id, amount_minor: diff, kind: "correction", note: "Balance correction", ref: "", day: await todayFor(uid), created_at: Date.now() })
}

export async function bankEntry(uid: string, f: FormData): Result {
	await ensureCash(uid)
	const list = await ensureCash(uid)
	const raw = text(f.get("bank") || f.get("bank_id") || f.get("to") || f.get("from"), 36)
	let b = raw ? list.find((x) => x.id === raw || x.name.toLowerCase() === raw.toLowerCase()) : null
	if (!b) {
		if (!raw || raw.toLowerCase() === "cash") {
			b = list.find((x) => x.kind === "cash") ?? list[0]
		} else {
			b = await db.findOne(banks, { where: { id: raw, user_id: uid } })
			if (!b) b = list.find((x) => x.kind === "cash") ?? list[0]
		}
	}
	if (!b) return "Unknown bank"
	const amount = toMinor(f.get("amount"))
	if (!amount || amount <= 0) return "Enter a valid amount"
	await db.create(bankMoves, { id: id(), user_id: uid, bank_id: b.id, amount_minor: amount, kind: "added", note: text(f.get("note"), 80) || "Money added", ref: "", day: await todayFor(uid), created_at: Date.now() })
}

export async function transferMoney(uid: string, f: FormData): Result {
	await ensureCash(uid)
	const list = await ensureCash(uid)
	const cash = list.find((b) => b.kind === "cash")
	const cashId = cash?.id ?? ""

	let fromId = text(f.get("from") || f.get("from_bank"), 36)
	let toId = text(f.get("to") || f.get("to_bank"), 36)

	if (!fromId || fromId.toLowerCase() === "cash") fromId = cashId
	if (!toId || toId.toLowerCase() === "cash") toId = cashId

	if (!fromId || !toId) return "Pick From and To places"
	if (fromId === toId) return "From and To cannot be the same bank"

	let [fromBank, toBank] = await Promise.all([
		db.findOne(banks, { where: { id: fromId, user_id: uid } }),
		db.findOne(banks, { where: { id: toId, user_id: uid } }),
	])

	if (!fromBank) fromBank = list.find((x) => x.id === fromId || x.name.toLowerCase() === fromId.toLowerCase()) as any
	if (!toBank) toBank = list.find((x) => x.id === toId || x.name.toLowerCase() === toId.toLowerCase()) as any

	if (!fromBank || !toBank) return "Unknown bank"
	if (fromBank.id === toBank.id) return "From and To cannot be the same bank"

	const amount = toMinor(f.get("amount"))
	if (!amount || amount <= 0) return "Enter a valid amount to transfer"

	const setup = await getSetup(uid)
	const cur = await bankBalances(uid, setup)
	const fromBal = cur.bal.get(fromBank.id) ?? 0
	if (amount > fromBal) {
		return `Not enough balance in ${fromBank.name}. Available: ${fmt(Math.max(0, fromBal))}`
	}

	const ref = id()
	const now = Date.now()
	const day = await todayFor(uid)
	const note = text(f.get("note"), 80)
	const fromNote = note ? `To ${toBank.name}: ${note}` : `To ${toBank.name}`
	const toNote = note ? `From ${fromBank.name}: ${note}` : `From ${fromBank.name}`

	await db.transaction(async (tx) => {
		await tx.create(bankMoves, { id: id(), user_id: uid, bank_id: fromBank.id, amount_minor: -amount, kind: "transfer", note: fromNote, ref, day, created_at: now })
		await tx.create(bankMoves, { id: id(), user_id: uid, bank_id: toBank.id, amount_minor: amount, kind: "transfer", note: toNote, ref, day, created_at: now + 1 })
	})
}

export async function deleteBankMove(uid: string, f: FormData): Result {
	const m = await db.findOne(bankMoves, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (!m) return
	if (m.kind === "paid") return "Undo this payment from the payments list"
	if (m.ref && m.kind === "transfer") {
		await db.deleteMany(bankMoves, { where: { ref: m.ref, user_id: uid } })
	} else {
		await db.deleteMany(bankMoves, { where: { id: m.id, user_id: uid } })
	}
}

export async function assignBank(uid: string, f: FormData): Result {
	const m = await db.findOne(predictMoves, { where: { id: text(f.get("id"), 36), user_id: uid } })
	const b = await db.findOne(banks, { where: { id: text(f.get("bank"), 36), user_id: uid } })
	if (!m || !b) return "Pick a bank"
	await db.update(predictMoves, m.id, { bank_id: b.id })
	const customLabel = text(f.get("label"), 60)
	const method = (customLabel || m.pay).trim().toLowerCase()
	if (customLabel && customLabel !== m.pay) {
		await db.update(predictMoves, m.id, { pay: customLabel })
	}
	if (!method || !f.get("remember")) return
	const key = `${uid}:${method}`
	const had = await db.find(payMaps, key)
	if (had) await db.update(payMaps, key, { bank_id: b.id })
	else await db.create(payMaps, { id: key, user_id: uid, method, bank_id: b.id, created_at: Date.now() })
	await db.exec(sql`update predict_moves set bank_id = ${b.id} where user_id = ${uid} and lower(pay) = ${method}`)
}

export async function pendingOf(user: User, sourceId: string) {
	const list = await pendingList(user.id, user.usd_rate_minor, today(user.day_start))
	return list.find((p) => p.id === sourceId) ?? null
}

export const markIncomesPaid = (uid: string, sourceId: string) =>
	db.exec(sql`update incomes set meta = json_set(meta, '$.paid', 1) where source_id = ${sourceId} and user_id = ${uid}`)
