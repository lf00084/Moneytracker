import { AsyncLocalStorage } from "node:async_hooks"
import { createClient } from "@libsql/client/web"
import { createTursoDatabase } from "@remix-kbn/data-table-sqlite-turso"
import { env } from "../env.ts"

export * from "./tables.ts"
export * from "./predict-tables.ts"

type Db = ReturnType<typeof createTursoDatabase>

const TIMEOUT_MS = 15000

const timedFetch = async (input: RequestInfo | URL, init?: RequestInit) => {
	const c = new AbortController()
	const t = setTimeout(() => c.abort(), TIMEOUT_MS)
	try {
		const res = await fetch(input, { ...init, signal: c.signal })
		const body = await res.arrayBuffer()
		return new Response(res.status === 204 || res.status === 205 || res.status === 304 ? null : body, res)
	} finally {
		clearTimeout(t)
	}
}

const make = (): Db => createTursoDatabase(createClient({ url: env.TURSO_DATABASE_URL, authToken: env.TURSO_AUTH_TOKEN, fetch: timedFetch, concurrency: 5 }))

const store = new AsyncLocalStorage<{ db?: Db }>()

let fallback: Db | undefined

export const withDb = <T>(fn: () => T): T => store.run({}, fn)

const current = (): Db => {
	const s = store.getStore()
	if (!s) return (fallback ??= make())
	return (s.db ??= make())
}

export const db: Db = new Proxy({} as Db, {
	get(_, key) {
		const target = current() as any
		const v = target[key]
		return typeof v === "function" ? v.bind(target) : v
	},
})
