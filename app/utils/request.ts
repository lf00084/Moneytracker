/** Small helpers shared by every controller: who is asking, the posted form, redirects, JSON. */
import { completeAuth } from "remix/auth";
import { Auth } from "remix/middleware/auth";
import { Session } from "remix/session";
import type { User } from "../lib/users.ts";

export type Ctx = Parameters<typeof completeAuth>[0] & {
	get: (key: any) => any;
	render: (node: unknown, init?: ResponseInit) => Response;
};

export const go = (href: string) => new Response(null, { status: 303, headers: { Location: href } });

export const json = (data: unknown, status = 200) =>
	new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } });

export const userOf = (ctx: Ctx): User | null => {
	const a = ctx.get(Auth);
	return a?.ok ? (a.identity as User) : null;
};

export const formOf = (ctx: Ctx) => (ctx.get(FormData) as FormData | null) ?? new FormData();

/** Only ever go back to a path on this site. */
export const backTo = (f: FormData, fallback: string) => {
	const b = String(f.get("back") ?? "");
	return /^\/(?![/\\])/.test(b) ? b : fallback;
};

/** Reads the one-shot error message left by `fail()` on the previous request. */
export function takeError(ctx: Ctx) {
	const e = ctx.get(Session).get("error");
	return typeof e === "string" ? e : "";
}

export function fail(ctx: Ctx, to: string, message: string) {
	ctx.get(Session).flash("error", message);
	return go(to);
}

export function signInAs(ctx: Ctx, userId: string) {
	const session = completeAuth(ctx);
	session.set("auth", { userId });
}

export function signOut(ctx: Ctx) {
	const session = ctx.get(Session);
	session.unset("auth");
	session.regenerateId(true);
}
