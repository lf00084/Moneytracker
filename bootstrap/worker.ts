import { missingEnv } from "../app/env.ts"

const page = (message: string, status: number) =>
	new Response(
		`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Moneytracker</title><body style="font:16px system-ui;background:#111;color:#eee;display:grid;place-items:center;min-height:100vh;margin:0;padding:16px;text-align:center"><p>${message}</p>`,
		{ status, headers: { "Content-Type": "text/html; charset=utf-8" } },
	)

export default {
	async fetch(request: Request) {
		const missing = missingEnv()
		if (missing.length) return page(`Missing config: ${missing.join(", ")}`, 500)
		try {
			const { router } = await import("../app/router.ts")
			return await router.fetch(request)
		} catch (e) {
			console.error(e)
			return page("Something went wrong. Please try again.", 500)
		}
	},
}
