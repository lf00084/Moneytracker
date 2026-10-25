import { asyncContext } from "remix/middleware/async-context"
import { formData } from "remix/middleware/form-data"
import { logger } from "remix/middleware/logger"
import { render } from "remix/middleware/render"
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router"
import { Session } from "remix/session"
import assetsController from "./controllers/assets.ts"
import authController from "./controllers/auth.tsx"
import commandsController from "./controllers/commands.ts"
import pagesController from "./controllers/pages.tsx"
import { authMiddleware, sessionMiddleware } from "./lib/auth.ts"
import { routes } from "./routes.ts"

const appMiddleware = createMiddleware(asyncContext(), render(), sessionMiddleware, formData(), authMiddleware)

type AppContext = MiddlewareContext<typeof appMiddleware>

declare module "remix" {
	interface RouterTypes {
		context: AppContext
	}
}

const clearStaleCookie = async (context: any, next: () => Promise<Response>) => {
	const res = await next()
	if (!/(^|;\s*)__session=/.test(context.request.headers.get("cookie") ?? "")) return res
	let empty = false
	try {
		empty = context.get(Session).size === 0
	} catch { }
	if (!empty) return res
	const headers = new Headers(res.headers)
	headers.append("Set-Cookie", `__session=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax${import.meta.env.PROD ? "; Secure" : ""}`)
	return new Response(res.body, { status: res.status, statusText: res.statusText, headers })
}

export const router = createRouter<AppContext>({
	middleware: [...(import.meta.env.DEV ? [logger()] : []), ...appMiddleware, clearStaleCookie],
})

router.map(routes.pages, pagesController)
router.map(routes.auth, authController)
router.map(routes.commands, commandsController)
router.map(routes.assets, assetsController)
