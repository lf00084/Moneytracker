import { missingEnv } from "../app/env.ts"

const LIMIT_MS = 30000
const slow = new Error("slow")

const page = (message: string, status: number) =>
	new Response(
		`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Moneytracker</title><body style="font:16px system-ui;background:#111;color:#eee;display:grid;place-items:center;min-height:100vh;margin:0;padding:16px;text-align:center"><p>${message}</p>`,
		{ status, headers: { "Content-Type": "text/html; charset=utf-8" } },
	)

const run = async (request: Request) => {
	const { router } = await import("../app/router.ts")
	const { withDb } = await import("../app/db/index.ts")
	return withDb(() => router.fetch(request))
}

const guard = <T>(p: Promise<T>) =>
	new Promise<T>((resolve, reject) => {
		const t = setTimeout(() => reject(slow), LIMIT_MS)
		p.then(resolve, reject).finally(() => clearTimeout(t))
	})

export default {
	async scheduled(_event: unknown, _env: unknown, ctx: { waitUntil: (p: Promise<unknown>) => void }) {
		if (missingEnv().length) return
		const { withDb } = await import("../app/db/index.ts")
		const { syncAllPredict } = await import("../app/lib/predict.ts")
		ctx.waitUntil(withDb(() => syncAllPredict()))
	},
	async fetch(request: Request) {
		const missing = missingEnv()
		if (missing.length) return page(`Missing config: ${missing.join(", ")}`, 500)
		const safe = request.method === "GET" || request.method === "HEAD"
		try {
			return await guard(run(safe ? request.clone() : request))
		} catch (e) {
			console.error(e)
			if (e === slow) return page("This is taking too long. Please try again.", 504)
			if (safe) {
				try {
					return await guard(run(request))
				} catch (e2) {
					console.error(e2)
					if (e2 === slow) return page("This is taking too long. Please try again.", 504)
				}
			}
			return page("Something went wrong. Please try again.", 500)
		}
	},
}
