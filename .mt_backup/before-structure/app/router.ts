import { asyncContext } from "remix/middleware/async-context";
import { formData } from "remix/middleware/form-data";
import { logger } from "remix/middleware/logger";
import { render } from "remix/middleware/render";
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router";
import { Session } from "remix/session";
import rootController from "./actions/controller.tsx";
import { authMiddleware, sessionMiddleware } from "./lib/auth.ts";
import { routes } from "./routes.ts";
const appMiddleware = createMiddleware(asyncContext(), render(), sessionMiddleware, formData(), authMiddleware);
type AppContext = MiddlewareContext<typeof appMiddleware>;
declare module "remix" {
interface RouterTypes {
context: AppContext;
}
}
const clearStaleCookie = async (context: any, next: () => Promise<Response>) => {
const res = await next();
const sent = /(^|;\s*)__session=/.test(context.request.headers.get("cookie") ?? "");
if (!sent) return res;
let empty = false;
try {
empty = context.get(Session).size === 0;
} catch {}
if (!empty) return res;
const headers = new Headers(res.headers);
headers.append("Set-Cookie", `__session=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax${import.meta.env.PROD ? "; Secure" : ""}`);
return new Response(res.body, { status: res.status, statusText: res.statusText, headers });
};
const middleware = [];
if (import.meta.env.DEV) middleware.push(logger());
middleware.push(...appMiddleware, clearStaleCookie);
export const router = createRouter<AppContext>({ middleware });
router.map(routes, rootController);
