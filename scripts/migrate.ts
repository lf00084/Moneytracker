import { createClient } from "@libsql/client"
import { readFileSync } from "node:fs"

let url = process.env.TURSO_DATABASE_URL
let authToken = process.env.TURSO_AUTH_TOKEN
if (!url) {
	try {
		const raw = readFileSync(new URL("../wrangler.jsonc", import.meta.url), "utf8")
		const mUrl = raw.match(/"TURSO_DATABASE_URL":\s*"([^"]+)"/)
		const mTok = raw.match(/"TURSO_AUTH_TOKEN":\s*"([^"]+)"/)
		if (mUrl) url = mUrl[1]
		if (mTok) authToken = mTok[1]
	} catch {}
}
if (!url) throw new Error("TURSO_DATABASE_URL is not set")

const client = createClient({ url, authToken })
const schema = readFileSync(new URL("../database/schema.sql", import.meta.url), "utf8")

await client.executeMultiple(schema)

const addColumns = [
	"ALTER TABLE users ADD COLUMN day_start INTEGER NOT NULL DEFAULT 5",
	"ALTER TABLE banks ADD COLUMN icon_url TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE purchases ADD COLUMN bank_id TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE predict_account ADD COLUMN funding_minor INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE predict_account ADD COLUMN predict_text TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE predict_account ADD COLUMN funding_text TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE predict_account ADD COLUMN prev_funding_minor INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE predict_account ADD COLUMN prev_predict_minor INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE predict_days ADD COLUMN locked INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE money_setup ADD COLUMN all_time INTEGER NOT NULL DEFAULT 0",
]
for (const statement of addColumns) {
	try {
		await client.execute(statement)
	} catch (err) {
		if (!/duplicate column/i.test(String(err))) throw err
	}
}

await client.execute("UPDATE predict_days SET locked = 1 WHERE locked = 0")

const setups = await client.execute("SELECT user_id, from_day, default_bank, all_time FROM money_setup WHERE all_time = 0")
for (const s of setups.rows) {
	const uid = String(s.user_id)
	const from = String(s.from_day)
	const def = String(s.default_bank || "")
	const bList = (await client.execute({ sql: "SELECT id, name, kind, opening_minor FROM banks WHERE user_id = ? ORDER BY sort ASC", args: [uid] })).rows

	const [mvOld, p2pOld, recOld, spentOld, instOld] = await Promise.all([
		client.execute({ sql: "SELECT bank_id as b, coalesce(sum(amount_minor), 0) as s FROM bank_moves WHERE user_id = ? GROUP BY bank_id", args: [uid] }),
		client.execute({ sql: "SELECT bank_id as b, coalesce(sum(case when kind = 'buy' then 0 - mad_minor when kind = 'sell' then mad_minor else 0 end), 0) as s FROM predict_moves WHERE user_id = ? AND day >= ? GROUP BY bank_id", args: [uid, from] }),
		client.execute({ sql: "SELECT coalesce(json_extract(meta, '$.to'), '') as b, coalesce(sum(amount_minor), 0) as s FROM incomes WHERE user_id = ? AND source_id IS NULL AND day >= ? AND coalesce(json_extract(meta, '$.paid'), 0) = 0 GROUP BY 1", args: [uid, from] }),
		client.execute({ sql: "SELECT coalesce(sum(total_minor), 0) as s FROM purchases WHERE user_id = ? AND day >= ?", args: [uid, from] }),
		client.execute({ sql: "SELECT coalesce(json_extract(s.config, '$.to'), '') as b, coalesce(sum(i.amount_minor), 0) as s FROM incomes i JOIN income_sources s ON s.id = i.source_id WHERE i.user_id = ? AND i.day >= ? AND coalesce(json_extract(s.config, '$.instant'), 0) = 1 GROUP BY 1", args: [uid, from] }),
	])

	const oldBal = new Map<string, number>()
	for (const b of bList) oldBal.set(String(b.id), Number(b.opening_minor) || 0)
	const addOld = (k: string, v: number) => { if (oldBal.has(k)) oldBal.set(k, (oldBal.get(k) || 0) + v) }
	for (const r of mvOld.rows) addOld(String(r.b || ""), Number(r.s) || 0)
	for (const r of p2pOld.rows) addOld(String(r.b || def), Number(r.s) || 0)
	for (const r of recOld.rows) addOld(oldBal.has(String(r.b)) ? String(r.b) : def, Number(r.s) || 0)
	for (const r of instOld.rows) addOld(oldBal.has(String(r.b)) ? String(r.b) : def, Number(r.s) || 0)
	const spentVal = Number(spentOld.rows[0]?.s) || 0
	addOld(def, -spentVal)

	const cashRow = bList.find((b) => b.kind === "cash") || bList.find((b) => String(b.name).toLowerCase() === "cash")
	const cashId = cashRow ? String(cashRow.id) : ""

	const [mvNew, p2pNew, recNew, instNew, spentNew] = await Promise.all([
		client.execute({ sql: "SELECT bank_id as b, coalesce(sum(amount_minor), 0) as s FROM bank_moves WHERE user_id = ? GROUP BY bank_id", args: [uid] }),
		client.execute({ sql: "SELECT bank_id as b, coalesce(sum(case when kind = 'buy' then 0 - mad_minor when kind = 'sell' then mad_minor else 0 end), 0) as s FROM predict_moves WHERE user_id = ? AND bank_id <> '' GROUP BY bank_id", args: [uid] }),
		client.execute({ sql: "SELECT coalesce(json_extract(meta, '$.to'), '') as b, coalesce(sum(amount_minor), 0) as s FROM incomes WHERE user_id = ? AND (json_extract(meta, '$.instant') = 1 OR (source_id IS NULL AND coalesce(json_extract(meta, '$.paid'), 0) = 0)) GROUP BY 1", args: [uid] }),
		client.execute({ sql: "SELECT coalesce(json_extract(s.config, '$.to'), '') as b, coalesce(sum(i.amount_minor), 0) as s FROM incomes i JOIN income_sources s ON s.id = i.source_id WHERE i.user_id = ? AND coalesce(json_extract(s.config, '$.instant'), 0) = 1 AND coalesce(json_extract(i.meta, '$.instant'), 0) = 0 GROUP BY 1", args: [uid] }),
		client.execute({ sql: "SELECT bank_id as b, coalesce(sum(total_minor), 0) as s FROM purchases WHERE user_id = ? GROUP BY bank_id", args: [uid] }),
	])

	const newSum = new Map<string, number>()
	for (const b of bList) newSum.set(String(b.id), 0)
	const addNew = (k: string, v: number) => { if (newSum.has(k)) newSum.set(k, (newSum.get(k) || 0) + v) }
	for (const r of mvNew.rows) addNew(String(r.b || ""), Number(r.s) || 0)
	for (const r of p2pNew.rows) addNew(String(r.b || ""), Number(r.s) || 0)
	for (const r of recNew.rows) addNew(newSum.has(String(r.b)) ? String(r.b) : cashId || def, Number(r.s) || 0)
	for (const r of instNew.rows) addNew(newSum.has(String(r.b)) ? String(r.b) : cashId || def, Number(r.s) || 0)
	for (const r of spentNew.rows) {
		const target = String(r.b || "") ? String(r.b) : cashId || def
		addNew(target, -(Number(r.s) || 0))
	}

	for (const b of bList) {
		const bid = String(b.id)
		const targetBal = oldBal.get(bid) || 0
		const sumVal = newSum.get(bid) || 0
		const newOpening = targetBal - sumVal
		await client.execute({ sql: "UPDATE banks SET opening_minor = ? WHERE id = ?", args: [newOpening, bid] })
	}

	await client.execute({
		sql: "UPDATE incomes SET meta = json_set(meta, '$.instant', 1, '$.to', (SELECT coalesce(json_extract(config, '$.to'), '') FROM income_sources WHERE id = incomes.source_id)) WHERE user_id = ? AND source_id IS NOT NULL AND EXISTS (SELECT 1 FROM income_sources WHERE id = incomes.source_id AND coalesce(json_extract(config, '$.instant'), 0) = 1)",
		args: [uid],
	})

	await client.execute({ sql: "UPDATE money_setup SET all_time = 1 WHERE user_id = ?", args: [uid] })
}

client.close()
