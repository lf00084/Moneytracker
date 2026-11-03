import { createSession, type Session, type SessionStorage } from "remix/session"
import { sql } from "remix/data-table"
import { db } from "./index.ts"
import { sessions as sessionsTable } from "./tables.ts"
const TTL_MS = 30 * 24 * 60 * 60 * 1000
export async function retry<T>(fn: () => Promise<T>, tries = 3): Promise<T> {
	let err: unknown
	for (let i = 0; i < tries; i++) {
		try {
			return await fn()
		} catch (e) {
			err = e
			await new Promise((r) => setTimeout(r, 150 * (i + 1)))
		}
	}
	throw err
}
export function createDbSessionStorage(): SessionStorage {
	return {
		async read(cookie) {
			if (!cookie) return createSession()
			let row
			try {
				row = await retry(() => db.find(sessionsTable, cookie))
			} catch (e) {
				console.error("session read failed", e)
				throw e
			}
			if (!row || row.expires_at < Date.now()) return createSession()
			try {
				return createSession(row.id, JSON.parse(row.data))
			} catch {
				return createSession()
			}
		},
		async save(session: Session) {
			if (session.deleteId) await db.delete(sessionsTable, session.deleteId)
			if (session.destroyed) {
				await db.delete(sessionsTable, session.id)
				return null
			}
			if (session.size === 0 && !session.dirty) return null
			const auth = session.get("auth") as { userId?: string } | undefined
			const now = Date.now()
			await db.exec(sql`
insert into sessions (id, user_id, data, created_at, expires_at)
values (${session.id}, ${auth?.userId ?? null}, ${JSON.stringify(session.data)}, ${now}, ${now + TTL_MS})
on conflict(id) do update set
user_id = excluded.user_id,
data = excluded.data,
expires_at = excluded.expires_at
`)
			return session.id
		},
	}
}
