import { sql } from "remix/data-table"
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases } from "../db/index.ts"
import { balanceOf } from "./data.ts"
import { fmt, toMinor, toSigned } from "./money.ts"
import { todayFor } from "./users.ts"
import { extKey, id, isFixed, parseJson, text } from "./util.ts"

type Result = Promise<string | void>

const count = (v: unknown) => {
	const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")))
	return Number.isFinite(n) && n > 0 ? Math.min(n, 100000) : 0
}

const realDay = (v: string) => {
	const t = Date.parse(`${v}T12:00:00Z`)
	return /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(t) && new Date(t).toISOString().slice(0, 10) === v
}

const pickDay = (f: FormData, t: string) => {
	const d = text(f.get("day"), 10) || t
	return realDay(d) && d <= t ? d : null
}

const own = (f: FormData, key = "id", max = 36) => text(f.get(key), max)

export async function addBuy(uid: string, f: FormData): Result {
	const unit = toMinor(f.get("price"))
	if (!unit) return "Enter a price"
	const day = pickDay(f, await todayFor(uid))
	if (!day) return "Pick a day that is not in the future"
	const qty = count(f.get("qty")) || 1
	await db.create(purchases, { id: id(), user_id: uid, name: text(f.get("label"), 120) || "Item", qty, unit_minor: unit, total_minor: unit * qty, day, created_at: Date.now() })
}

export async function addDayIncome(uid: string, f: FormData): Result {
	const amount = toMinor(f.get("amount"))
	if (!amount) return "Enter an amount"
	const day = pickDay(f, await todayFor(uid))
	if (!day) return "Pick a day that is not in the future"
	const label = text(f.get("label"), 60)
	await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day, created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: "" })
}

export async function setBalance(uid: string, f: FormData): Result {
	const target = toSigned(f.get("balance"))
	if (target === null) return "Enter your balance"
	const diff = target - (await balanceOf(uid))
	if (!diff) return
	const now = Date.now()
	const t = await todayFor(uid)
	if (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: t, created_at: now, meta: '{"adjust":1}', ext_key: "" })
	else await db.create(purchases, { id: id(), user_id: uid, name: "Balance adjustment", qty: 1, unit_minor: -diff, total_minor: -diff, day: t, created_at: now })
}

export async function deleteBuy(uid: string, f: FormData): Result {
	const p = await db.findOne(purchases, { where: { id: own(f), user_id: uid } })
	if (!p) return
	await db.transaction(async (tx) => {
		if (p.debt_id) {
			const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } })
			const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor
			const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } })
			if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back, updated_at: Date.now(), last_delta: back })
			await tx.exec(sql`delete from debt_payments where purchase_id = ${p.id} and user_id = ${uid}`)
		}
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key in (select 'trade:' || id from trade_sessions where purchase_id = ${p.id} and user_id = ${uid})`)
		await tx.exec(sql`delete from trade_results where user_id = ${uid} and session_id in (select id from trade_sessions where purchase_id = ${p.id} and user_id = ${uid})`)
		await tx.exec(sql`delete from trade_sessions where purchase_id = ${p.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from purchases where id = ${p.id} and user_id = ${uid}`)
	})
}

export async function addDebt(uid: string, f: FormData): Result {
	const debtId = own(f, "debt_id")
	if (debtId) {
		const d = await db.findOne(debts, { where: { id: debtId, user_id: uid } })
		if (!d) return
		if (d.kind === "item") {
			const n = count(f.get("amount"))
			if (!n) return "Enter an amount"
			await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n, updated_at: Date.now(), last_delta: n })
		} else {
			const m = toMinor(f.get("amount"))
			if (!m) return "Enter an amount"
			await db.update(debts, d.id, { amount_minor: d.amount_minor + m, updated_at: Date.now(), last_delta: m })
		}
		return
	}
	const name = text(f.get("name"), 80)
	const cig = count(f.get("cig"))
	const money = toMinor(f.get("amount"))
	if (!name) return "Enter a name"
	if (!cig && !money) return "Enter an amount"
	await db.transaction(async (tx) => {
		const all = await tx.findMany(people, { where: { user_id: uid } })
		const person = all.find((p) => p.name.toLowerCase() === name.toLowerCase()) ?? (await tx.create(people, { id: id(), user_id: uid, name }, { returnRow: true }))
		const mine = await tx.findMany(debts, { where: { user_id: uid, person_id: person.id } })
		if (money) {
			const row = mine.find((d) => d.kind === "money")
			if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money, updated_at: Date.now(), last_delta: money })
			else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, updated_at: Date.now(), last_delta: money, created_at: Date.now() })
		}
		if (cig) {
			const row = mine.find((d) => d.kind === "item")
			if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig, updated_at: Date.now(), last_delta: cig })
			else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "item", item_name: "cig", item_qty: cig, amount_minor: 0, updated_at: Date.now(), last_delta: cig, created_at: Date.now() })
		}
	})
}

export async function clearDebt(uid: string, f: FormData) {
	const d = await db.findOne(debts, { where: { id: own(f, "debt_id"), user_id: uid } })
	if (d) await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0, updated_at: Date.now(), last_delta: -(d.item_qty ?? 0) } : { amount_minor: 0, updated_at: Date.now(), last_delta: -d.amount_minor })
}

export async function payDebt(uid: string, f: FormData): Result {
	const d = await db.findOne(debts, { where: { id: own(f, "debt_id"), user_id: uid } })
	if (!d) return
	if (d.kind === "item") {
		const n = Math.min(count(f.get("amount")), d.item_qty ?? 0)
		if (!n) return "Enter an amount"
		await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n, updated_at: Date.now(), last_delta: -n })
		return
	}
	const pay = Math.min(toMinor(f.get("amount")), d.amount_minor)
	if (!pay) return "Enter an amount"
	const person = await db.find(people, d.person_id)
	const purchaseId = id()
	const now = Date.now()
	const t = await todayFor(uid)
	await db.transaction(async (tx) => {
		await tx.create(purchases, { id: purchaseId, user_id: uid, name: `Paid ${person?.name ?? ""}`.trim(), qty: 1, unit_minor: pay, total_minor: pay, day: t, debt_id: d.id, created_at: now })
		await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now })
		await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay, updated_at: now, last_delta: -pay })
	})
}

export async function addGoal(uid: string, f: FormData): Result {
	const title = text(f.get("name"), 120)
	if (!title) return "Enter a goal name"
	await db.create(goals, { id: id(), user_id: uid, title, target_minor: 0, saved_minor: 0, is_wish: 1, created_at: Date.now() })
}

export async function addGoalItem(uid: string, f: FormData): Result {
	const g = await db.findOne(goals, { where: { id: own(f, "goal_id"), user_id: uid } })
	if (!g) return "Goal not found"
	const name = text(f.get("name"), 120)
	if (!name) return "Enter an item"
	const price = toMinor(f.get("price"))
	if (!price) return "Enter a price"
	await db.create(goalItems, { id: id(), user_id: uid, goal_id: g.id, name, price_minor: price, created_at: Date.now() })
}

export async function editGoal(uid: string, f: FormData): Result {
	const name = text(f.get("name"), 120)
	if (!name) return "Enter a goal name"
	await db.exec(sql`update goals set title = ${name} where id = ${own(f)} and user_id = ${uid}`)
}

export async function editGoalItem(uid: string, f: FormData): Result {
	const name = text(f.get("name"), 120)
	if (!name) return "Enter an item"
	const price = toMinor(f.get("price"))
	if (!price) return "Enter a price"
	await db.exec(sql`update goal_items set name = ${name}, price_minor = ${price} where id = ${own(f)} and user_id = ${uid} and done_at is null`)
}

export async function deleteGoalItem(uid: string, f: FormData) {
	await db.exec(sql`delete from goal_items where id = ${own(f)} and user_id = ${uid}`)
}

export async function deleteWish(uid: string, f: FormData) {
	const gid = own(f)
	await db.exec(sql`delete from goal_items where goal_id = ${gid} and user_id = ${uid}`)
	await db.exec(sql`delete from goals where id = ${gid} and user_id = ${uid}`)
}

export async function buyWish(uid: string, f: FormData): Result {
	const it = await db.findOne(goalItems, { where: { id: own(f), user_id: uid } })
	if (!it || it.done_at) return
	const t = await todayFor(uid)
	const bal = await balanceOf(uid)
	if (it.price_minor > bal) return `Not enough balance for ${it.name}. You have ${fmt(Math.max(0, bal))}`
	await db.transaction(async (tx) => {
		await tx.create(purchases, { id: id(), user_id: uid, name: it.name, qty: 1, unit_minor: it.price_minor, total_minor: it.price_minor, day: t, created_at: Date.now() })
		await tx.update(goalItems, it.id, { done_at: Date.now() })
	})
}

export async function addIncome(uid: string, f: FormData): Result {
	const s = await db.findOne(incomeSources, { where: { id: own(f, "source_id"), user_id: uid } })
	if (!s) return "Unknown source"
	if (s.type === "exoclick") return "ExoClick income is added automatically"
	const day = await todayFor(uid)
	const key = extKey(s.id, day)
	if (await db.findOne(incomes, { where: { user_id: uid, ext_key: key } })) return `${s.name} is already added today`
	let amount = 0
	let meta: Record<string, number> = {}
	if (isFixed(s.type)) {
		const cfg = parseJson(s.config)
		amount = Number(cfg.fixed_minor) || 0
		meta = { fixed_minor: amount, hours: 0, rate_minor: Number(cfg.rate_minor) || 0 }
	} else amount = toMinor(f.get("amount")) || s.amount_minor
	if (amount <= 0) return "Amount must be more than 0"
	await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, amount_minor: amount, day, created_at: Date.now(), meta: JSON.stringify(meta), ext_key: key })
}

export async function toggleSource(uid: string, f: FormData) {
	const s = await db.findOne(incomeSources, { where: { id: own(f), user_id: uid } })
	if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 })
}

export async function deleteSource(uid: string, f: FormData) {
	const s = await db.findOne(incomeSources, { where: { id: own(f), user_id: uid } })
	if (!s) return
	await db.transaction(async (tx) => {
		await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`)
	})
}

export async function deleteIncome(uid: string, f: FormData): Result {
	const row = await db.findOne(incomes, { where: { id: own(f, "id", 80), user_id: uid } })
	if (!row) return
	if (row.ext_key.startsWith("trade:")) return "Undo this from the Trading page"
	if (row.ext_key) {
		const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null
		if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead"
	}
	await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } })
}

export async function saveNote(uid: string, f: FormData) {
	const body = text(f.get("text"), 5000)
	if (!body) return
	const noteId = own(f)
	const now = Date.now()
	if (noteId) await db.updateMany(notes, { body, updated_at: now }, { where: { id: noteId, user_id: uid } })
	else await db.create(notes, { id: id(), user_id: uid, body, created_at: now, updated_at: now })
}

export async function deleteNote(uid: string, f: FormData) {
	await db.deleteMany(notes, { where: { id: own(f), user_id: uid } })
}

export async function deleteAccount(uid: string) {
	await db.transaction(async (tx) => {
		for (const stmt of [
			sql`delete from debt_payments where user_id = ${uid}`,
			sql`delete from debts where user_id = ${uid}`,
			sql`delete from people where user_id = ${uid}`,
			sql`delete from purchases where user_id = ${uid}`,
			sql`delete from incomes where user_id = ${uid}`,
			sql`delete from income_sources where user_id = ${uid}`,
			sql`delete from trade_results where user_id = ${uid}`,
			sql`delete from trade_sessions where user_id = ${uid}`,
			sql`delete from goal_items where user_id = ${uid}`,
			sql`delete from goals where user_id = ${uid}`,
			sql`delete from pad_entries where user_id = ${uid}`,
			sql`delete from pad_spaces where user_id = ${uid}`,
			sql`delete from notes where user_id = ${uid}`,
			sql`delete from quick_buys where user_id = ${uid}`,
			sql`delete from user_images where user_id = ${uid}`,
			sql`delete from oauth_accounts where user_id = ${uid}`,
			sql`delete from passwords where user_id = ${uid}`,
			sql`delete from sessions where user_id = ${uid}`,
			sql`delete from users where id = ${uid}`,
		])
			await tx.exec(stmt)
	})
}

const cell = (v: string | number) => {
	let s = String(v)
	if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`
	return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
}

export async function exportCsv(uid: string) {
	const [bs, is, ss] = await Promise.all([
		db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
		db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
		db.findMany(incomeSources, { where: { user_id: uid } }),
	])
	const names = new Map(ss.map((s) => [s.id, s.name]))
	const num = (minor: number) => fmt(minor).replace(/,/g, "")
	const lines = ["date,type,name,qty,amount"]
	for (const i of is) {
		const m = parseJson(i.meta)
		lines.push([i.day, "income", cell(names.get(i.source_id ?? "") ?? (String(m.label ?? m.name ?? "").trim() || "Other")), 1, num(i.amount_minor)].join(","))
	}
	for (const b of bs) lines.push([b.day, "buy", cell(b.name), b.qty, num(b.total_minor)].join(","))
	return lines.join("\n")
}
