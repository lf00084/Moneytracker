import { sql } from "remix/data-table"
import { bankMoves, db, incomeSources, predictAccount, predictMoves, sourcePayments } from "../db/index.ts"
import { bankBalances, ensureCash, getSetup, pendingList, pendingOf } from "./banks.ts"
import { fmt, toMinor } from "./money.ts"
import { marketRate, rebuild } from "./predict.ts"
import { today } from "./time.ts"
import { toMad } from "./trade-math.ts"
import { todayFor, type User } from "./users.ts"
import { id, text } from "./util.ts"

type Result = Promise<string | void>

export async function paySource(user: User, f: FormData): Result {
	const uid = user.id
	await ensureCash(uid)
	let srcId = text(f.get("source_id"), 36)
	if (!srcId) {
		const pendings = await pendingList(uid, user.usd_rate_minor, today(user.day_start))
		if (pendings.length === 1 && pendings[0]) {
			srcId = pendings[0].id
		} else if (pendings.length > 1) {
			return "Select which source paid you"
		} else {
			return "No pending sources on hold"
		}
	}
	const src = await db.findOne(incomeSources, { where: { id: srcId, user_id: uid } })
	if (!src) return "Unknown source"
	const p = await pendingOf(user, src.id)
	if (!p) return `${src.name} has nothing pending`
	const usd = src.type === "exoclick" || src.currency === "USD" || p.usd
	const raw = text(f.get("amount"), 16)
	const amount = raw ? toMinor(raw) : p.left
	if (!amount || amount <= 0) return "Enter how much was paid"
	const credited = Math.min(amount, p.left)
	const now = Date.now()
	const day = await todayFor(uid)
	const payId = id()

	const pick = text(f.get("bank") || f.get("to") || f.get("bank_id"), 36)
	if (usd && (pick === "usdt" || pick === "predict")) {
		const acc = await db.findOne(predictAccount, { where: { user_id: uid } })
		if (!acc || !acc.key_enc) return "Connect Binance in API connections first, so the USDT lands in your wallet"
		const { rate } = await marketRate(user.currency.toUpperCase(), user.usdt_rate)
		const costBasisMad = toMad(amount, rate)
		const moveId = id()
		await db.transaction(async (tx) => {
			await tx.create(predictMoves, {
				id: moveId,
				user_id: uid,
				kind: "in",
				usdt_minor: amount,
				mad_minor: costBasisMad,
				order_no: "",
				fee_minor: 0,
				bank_id: "",
				pay: "",
				day,
				created_at: now,
			})
			await tx.create(sourcePayments, {
				id: payId,
				user_id: uid,
				source_id: src.id,
				source_name: src.name,
				amount_minor: credited,
				bank_id: "",
				move_id: moveId,
				day,
				created_at: now,
			})
		})
		await rebuild(uid)
		return
	}

	const list = await ensureCash(uid)
	const bank = pick ? list.find((b) => b.id === pick) : list.find((b) => b.kind === "cash") ?? list[0]
	if (!bank) return "Pick the bank or Cash that got the money"

	const creditedMad = usd ? Math.round((amount * (user.usd_rate_minor || 1000)) / 100) : amount

	await db.transaction(async (tx) => {
		await tx.create(sourcePayments, {
			id: payId,
			user_id: uid,
			source_id: src.id,
			source_name: src.name,
			amount_minor: credited,
			bank_id: bank.id,
			move_id: "",
			day,
			created_at: now,
		})
		await tx.create(bankMoves, {
			id: id(),
			user_id: uid,
			bank_id: bank.id,
			amount_minor: creditedMad,
			kind: "paid",
			note: src.name,
			ref: payId,
			day,
			created_at: now,
		})
	})
}

export async function deletePayment(uid: string, f: FormData): Result {
	const p = await db.findOne(sourcePayments, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (!p) return
	await db.transaction(async (tx) => {
		if (p.move_id) await tx.exec(sql`delete from predict_moves where id = ${p.move_id} and user_id = ${uid}`)
		await tx.exec(sql`delete from bank_moves where ref = ${p.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from source_payments where id = ${p.id} and user_id = ${uid}`)
	})
	if (p.move_id) await rebuild(uid)
}
