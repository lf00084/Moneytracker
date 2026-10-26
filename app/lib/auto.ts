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
