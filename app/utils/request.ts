import { completeAuth } from "remix/auth"
import { Auth } from "remix/middleware/auth"
import { Session } from "remix/session"
import type { User } from "../lib/users.ts"
export type Ctx = Parameters<typeof completeAuth>[0] & { get: (key: any) => any }
export const userOf = (ctx: Ctx): User | null => {
const a = ctx.get(Auth)
return a?.ok ? (a.identity as User) : null
}
export const formOf = (ctx: Ctx) => (ctx.get(FormData) as FormData | null) ?? new FormData()
export const backTo = (f: FormData, fallback: string) => {
const b = String(f.get("back") ?? "")
return /^\/(?![/\\])/.test(b) ? b : fallback
}
export const takeError = (ctx: Ctx) => {
const e = ctx.get(Session).get("error")
return typeof e === "string" ? e : ""
}
export const go = (href: string) => new Response(null, { status: 303, headers: { Location: href } })
export const fail = (ctx: Ctx, to: string, message: string) => {
ctx.get(Session).flash("error", message)
return go(to)
}
export const signInAs = (ctx: Ctx, userId: string) => {
completeAuth(ctx).set("auth", { userId })
}
export const signOut = (ctx: Ctx) => {
const session = ctx.get(Session)
session.unset("auth")
session.regenerateId(true)
}
export const json = (data: unknown, status = 200) => Response.json(data, { status })
