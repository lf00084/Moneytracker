#!/usr/bin/env bash
set -e
[ -f bootstrap/worker.ts ] || { echo "Run this inside the Moneytracker folder"; exit 1; }
cat > bootstrap/worker.ts <<'GOAT_EOF'
import { missingEnv } from "../app/env.ts"

const page = (message: string, status: number) =>
	new Response(
		`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Moneytracker</title><body style="font:16px system-ui;background:#111;color:#eee;display:grid;place-items:center;min-height:100vh;margin:0;padding:16px;text-align:center"><p>${message}</p>`,
		{ status, headers: { "Content-Type": "text/html; charset=utf-8" } },
	)

const run = async (request: Request) => {
	const { router } = await import("../app/router.ts")
	return router.fetch(request)
}

export default {
	async fetch(request: Request) {
		const missing = missingEnv()
		if (missing.length) return page(`Missing config: ${missing.join(", ")}`, 500)
		const safe = request.method === "GET" || request.method === "HEAD"
		try {
			return await run(safe ? request.clone() : request)
		} catch (e) {
			console.error(e)
			if (safe) {
				try {
					return await run(request)
				} catch (e2) {
					console.error(e2)
				}
			}
			return page("Something went wrong. Please try again.", 500)
		}
	},
}
GOAT_EOF
echo "file27 done"
