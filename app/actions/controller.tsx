import { completeAuth, finishExternalAuth, startExternalAuth } from "remix/auth";
import { Auth } from "remix/middleware/auth";
import { createController } from "remix/router";
import { Session } from "remix/session";
import * as act from "../lib/actions.ts";
import { assets } from "../lib/assets.ts";
import { googleProvider } from "../lib/auth.ts";
import { env } from "../env.ts";
import { loadState, type Part, type State } from "../lib/data.ts";
import {
	setTheme,
	signInWithPassword,
	signUpWithPassword,
	updatePrefs,
	updateProfile,
	upsertFromGoogle,
	type User,
} from "../lib/users.ts";
import { loginPage, signupPage } from "../pages/auth.ts";
import {
	debtsPage,
	goalsPage,
	historyPage,
	homePage,
	incomePage,
	notesPage,
	padPage,
	profileEditPage,
	profilePage,
	settingsPage,
} from "../pages/screens.ts";
import { routes } from "../routes.ts";
const html = (body: string) => new Response(body, { headers: { "Content-Type": "text/html; charset=utf-8" } });
const go = (href: string) => new Response(null, { status: 303, headers: { Location: href } });
type Ctx = Parameters<typeof completeAuth>[0] & { get: (key: any) => any };
const userOf = (ctx: Ctx): User | null => {
	const a = ctx.get(Auth);
	return a?.ok ? (a.identity as User) : null;
};
const formOf = (ctx: Ctx) => (ctx.get(FormData) as FormData | null) ?? new FormData();
const backTo = (f: FormData, fallback: string) => {
	const b = String(f.get("back") ?? "");
	return /^\/(?![/\\])/.test(b) ? b : fallback;
};
function takeError(ctx: Ctx) {
	const session = ctx.get(Session);
	const e = session.get("error");
	return typeof e === "string" ? e : "";
}
const view =
	(path: string, parts: Part[], render: (s: State) => string) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		return html(render(await loadState(user, parts, { back: path, error: takeError(ctx) })));
	};
const mutate =
	(fallback: string, run: (user: User, f: FormData, ctx: Ctx) => Promise<unknown>) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		const f = formOf(ctx);
		await run(user, f, ctx);
		return go(backTo(f, fallback));
	};
const attempt =
	(fallback: string, run: (user: User, f: FormData) => Promise<string | void>) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		const f = formOf(ctx);
		const to = backTo(f, fallback);
		const error = await run(user, f);
		return error ? fail(ctx, to, error) : go(to);
	};
function fail(ctx: Ctx, to: string, message: string) {
	ctx.get(Session).flash("error", message);
	return go(to);
}
function signInAs(ctx: Ctx, userId: string) {
	const session = completeAuth(ctx);
	session.set("auth", { userId });
}
export default createController(routes, {
	actions: {
		root(ctx: Ctx) {
			return go(userOf(ctx) ? "/home" : "/login");
		},
		manifest: () => assets.manifest(),
		favicon: () => assets.favicon(),
		faviconIco: () => assets.icon192(),
		icon192: () => assets.icon192(),
		icon512: () => assets.icon512(),
		iconMaskable: () => assets.iconMaskable(),
		appleIcon: () => assets.appleIcon(),
		sw: () => assets.sw(),
		robots: () => assets.robots(),
		sitemap: () => assets.sitemap(),
		login(ctx: Ctx) {
			if (userOf(ctx)) return go("/home");
			return html(loginPage(takeError(ctx)));
		},
		async signIn(ctx: Ctx) {
			const f = formOf(ctx);
			const user = await signInWithPassword(String(f.get("email") ?? ""), String(f.get("password") ?? ""));
			if (!user) return fail(ctx, "/login", "Wrong email or password.");
			signInAs(ctx, user.id);
			return go("/home");
		},
		signup(ctx: Ctx) {
			if (userOf(ctx)) return go("/home");
			return html(signupPage(takeError(ctx)));
		},
		async signUp(ctx: Ctx) {
			const f = formOf(ctx);
			const result = await signUpWithPassword({
				name: String(f.get("name") ?? ""),
				email: String(f.get("email") ?? ""),
				password: String(f.get("password") ?? ""),
			});
			if (!result.ok) return fail(ctx, "/signup", result.error);
			signInAs(ctx, result.user.id);
			return go("/home");
		},
		logout(ctx: Ctx) {
			const session = ctx.get(Session);
			session.unset("auth");
			session.regenerateId(true);
			return go("/login");
		},
		googleLogin(ctx: Ctx) {
			if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
				return fail(ctx, "/login", "Google login is not configured. Please sign in with email and password.");
			}
			return startExternalAuth(googleProvider, ctx as never, { returnTo: "/home" });
		},
		async googleCallback(ctx: Ctx) {
			try {
				const { result, returnTo } = await finishExternalAuth(googleProvider, ctx as never);
				const user = await upsertFromGoogle(result.account, result.profile as never);
				signInAs(ctx, user.id);
				return go(returnTo ?? "/home");
			} catch (err) {
				console.error("google sign-in failed", err);
				return fail(ctx, "/login", "Google sign-in failed. Try again.");
			}
		},
		home: view("/home", ["today", "sources", "names", "debts", "goals", "notes", "balance"], homePage),
		debts: view("/debts", ["debts", "goals", "balance"], debtsPage),
		notes: view("/notes", ["notes"], notesPage),
		goals: view("/goals", ["goals", "debts", "balance"], goalsPage),
		income: view("/income", ["sources", "today"], incomePage),
		plan: view("/plan", ["goals", "debts", "sources", "today", "balance"], goalsPage),
		history: view("/history", ["history"], historyPage),
		profile: view("/profile", ["avatar", "balance"], profilePage),
		profileEdit: view("/profile/edit", ["avatar"], profileEditPage),
		settings: view("/settings", [], settingsPage),
		pad: view("/pad", [], padPage),
		buy: attempt("/home", (u, f) => act.addBuy(u.id, f)),
		setBalance: attempt("/profile", (u, f) => act.setBalance(u.id, f)),
		historyIncome: attempt("/history", (u, f) => act.addDayIncome(u.id, f)),
		deleteBuy: attempt("/home", (u, f) => act.deleteBuy(u.id, f)),
		addDebt: attempt("/debts", (u, f) => act.addDebt(u.id, f)),
		payDebt: attempt("/debts", (u, f) => act.payDebt(u.id, f)),
		clearDebt: attempt("/debts", (u, f) => act.clearDebt(u.id, f)),
		addNote: mutate("/notes", (u, f) => act.saveNote(u.id, f)),
		deleteNote: mutate("/notes", (u, f) => act.deleteNote(u.id, f)),
		addWish: attempt("/goals", (u, f) => act.addGoal(u.id, f)),
		buyWish: attempt("/goals", (u, f) => act.buyWish(u.id, f)),
		deleteWish: attempt("/goals", (u, f) => act.deleteWish(u.id, f)),
		editGoal: attempt("/goals", (u, f) => act.editGoal(u.id, f)),
		editGoalItem: attempt("/goals", (u, f) => act.editGoalItem(u.id, f)),
		addGoalItem: attempt("/goals", (u, f) => act.addGoalItem(u.id, f)),
		deleteGoalItem: attempt("/goals", (u, f) => act.deleteGoalItem(u.id, f)),
		addSource: attempt("/income", (u, f) => act.addSource(u.id, f)),
		addIncome: attempt("/income", (u, f) => act.addIncome(u.id, f)),
		deleteIncome: attempt("/income", (u, f) => act.deleteIncome(u.id, f)),
		toggleSource: attempt("/income", (u, f) => act.toggleSource(u.id, f)),
		editSource: attempt("/income", (u, f) => act.editSource(u.id, f)),
		deleteSource: attempt("/income", (u, f) => act.deleteSource(u.id, f)),
		addPlan: mutate("/plan", async () => {}),
		quickBuy: mutate("/settings", (u, f) => act.quickOp(u.id, f)),
		async saveProfile(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			const f = formOf(ctx);
			const error = await updateProfile(user.id, {
				name: String(f.get("name") ?? ""),
				email: String(f.get("email") ?? ""),
			});
			return error ? fail(ctx, "/profile/edit", error) : go("/profile");
		},
		saveSettings: mutate("/settings", (u, f) =>
			updatePrefs(u.id, {
				currency: String(f.get("currency") ?? ""),
				run_at: String(f.get("run_at") ?? ""),
				week_start: String(f.get("week") ?? ""),
			}),
		),
		async setTheme(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return new Response(null, { status: 401 });
			await setTheme(user.id, String(formOf(ctx).get("theme") ?? ""));
			return new Response(null, { status: 204 });
		},
		async setBackground(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			const f = formOf(ctx);
			const url = String(f.get("url") ?? "");
			const error = await act.validateAndSetBackground(user.id, url);
			return error ? fail(ctx, "/settings", error) : go("/settings");
		},
		async resetBackground(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			await act.resetUserBackground(user.id);
			return go("/settings");
		},
		async exportCsv(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			return new Response(await act.exportCsv(user.id), {
				headers: {
					"Content-Type": "text/csv; charset=utf-8",
					"Content-Disposition": 'attachment; filename="moneytracker.csv"',
				},
			});
		},
		async deleteAccount(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			await act.deleteAccount(user.id);
			const session = ctx.get(Session);
			session.unset("auth");
			session.regenerateId(true);
			return go("/signup");
		},
	},
});
