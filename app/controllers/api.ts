import { createController } from "remix/router"
import { commands, errorOf, isCommand } from "../commands.ts"
import { isScreen, loadScreen } from "../loaders.ts"
import { routes } from "../routes.ts"
import { formOf, json, userOf, type Ctx } from "../utils/request.ts"
const body = async (ctx: Ctx) => {
if (!(ctx.request.headers.get("content-type") ?? "").includes("application/json")) return formOf(ctx)
const data = (await ctx.request.json().catch(() => ({}))) as Record<string, unknown>
const f = new FormData()
for (const [k, v] of Object.entries(data ?? {})) if (v !== null && v !== undefined) f.set(k, String(v))
return f
}
export default createController(routes.api, {
actions: {
me(ctx: Ctx) {
const user = userOf(ctx)
return user ? json({ user }) : json({ error: "unauthorized" }, 401)
},
async screen(ctx: Ctx) {
const user = userOf(ctx)
if (!user) return json({ error: "unauthorized" }, 401)
const key = String((ctx as any).params?.screen ?? "")
if (!isScreen(key)) return json({ error: "unknown screen" }, 404)
return json({ screen: key, data: await loadScreen(user, key) })
},
async command(ctx: Ctx) {
const user = userOf(ctx)
if (!user) return json({ error: "unauthorized" }, 401)
const name = String((ctx as any).params?.name ?? "")
if (!isCommand(name)) return json({ error: "unknown command" }, 404)
const error = errorOf(await commands[name].run(user, await body(ctx)))
return error ? json({ ok: false, error }, 422) : json({ ok: true })
},
},
})
