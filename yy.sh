#!/usr/bin/env bash
set -e
cd "${1:-.}"
for f in app/actions/controller.tsx app/pages/screens.ts app/pages/auth.ts app/ui/css.ts app/ui/script.ts app/ui/parts.ts app/ui/shell.ts app/lib/actions.ts app/routes.ts app/router.ts vite.config.ts tsconfig.json; do [ -f "$f" ] || { echo "missing $f, run this from the project root"; exit 1; }; done
[ -f app/screens/index.tsx ] && { echo "already restructured"; exit 1; }
B=.mt_backup/before-structure
mkdir -p "$B/app/ui" "$B/app/lib"
cp vite.config.ts tsconfig.json "$B/"
cp app/routes.ts app/router.ts "$B/app/"
cp app/lib/actions.ts "$B/app/lib/actions.ts.orig"
mv app/actions "$B/app/actions"
mv app/pages "$B/app/pages"
for f in shell css script parts; do mv "app/ui/$f.ts" "$B/app/ui/$f.ts"; done
[ -f app/lib/actions.ts.bak ] && mv app/lib/actions.ts.bak "$B/app/lib/actions.ts.bak"
mkdir -p "app/actions" "app/client" "app" "app/controllers" "app/db" "app/lib" "app/lib/sources" "app/pages" "app/screens" "app/ui" "app/utils" "."
cat > "app/actions/controller.tsx" <<'MT_EOF'
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
MT_EOF
cat > "app/client/app.css" <<'MT_EOF'
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}

/* one look for every surface: login box, cards, hero. Radius and shadow come from the tokens on html. */
.cd,.sc,.xc,.hero,.auth-glass-box{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}

a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}button{cursor:pointer}
.mu,.lb{color:var(--mu)}.lb{font-size:11px;font-family:var(--mono)}.pos{color:var(--pos)!important}.neg{color:var(--neg)!important}.ea{color:var(--earn)!important}.sp{color:var(--spend)!important}.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}summary::-webkit-details-marker{display:none}

button,input[type=button],input[type=submit],.btn,.sbl,.qk button,.qk4 button,.chip,.ib,.pl{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.qk button:active,.qk4 button:active,.chip:active,.ib:active,.pl:active{transform:scale(.97);opacity:.88}

.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
.tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}
.tf-clock .clock-date,.tf-clock .clock-subdate{display:none}

.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;padding:38px 32px 34px}
@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px}}
.auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
.auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
.auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
.auth-err-banner{background:rgba(255,90,77,0.12);border:1px solid rgba(255,90,77,0.3);border-radius:12px;padding:10px 14px;color:var(--neg);font-size:13px;font-weight:500;text-align:center;margin:12px 0}
.auth-switch-wrap{display:flex;justify-content:center;margin-top:22px;text-align:center}
.lnk-switch{font-size:14px;color:var(--mu);text-decoration:none}
.lnk-switch b{color:var(--ac);text-decoration:underline;text-underline-offset:3px}
.lnk-switch:hover{color:var(--ink)}

@media(min-width:900px){.m{display:none!important}}
@media(max-width:899px){.d{display:none!important}}

.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){.app{flex-direction:column}}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}

.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg,.bt .lg svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib{flex:none;aspect-ratio:1}.ib.sm{width:28px;height:28px;min-width:28px}.ib svg.ic{width:16px;height:16px}.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}

.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:var(--rc) var(--rc) 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}.bt .on svg.ic{stroke-width:2}
.bt .lg svg{opacity:.55;width:26px;height:26px;border-radius:7px}.bt .lg.on svg{opacity:1}

.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}

h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}

.cd{margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}.two .cb{padding:3px 12px 10px}.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}

.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:var(--rm);padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
.btn:hover{filter:brightness(1.06)}
.btn.o{background:var(--s1);color:var(--ink);border:1px solid var(--ln);box-shadow:var(--sh1)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
.btn.full{width:100%;padding:14px 20px;font-size:16px;font-weight:700;border-radius:var(--rm);margin-top:20px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}

.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:var(--rm);padding:13px 16px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
.in:focus,.in.f:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.in::placeholder{color:var(--mu);opacity:.6}
.ln{display:flex;gap:10px;align-items:center}

.stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
.stp button{width:34px;height:34px;border:1px solid var(--ln);background:var(--s1);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;color:var(--ink)}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:13px 18px;border-radius:var(--rm);border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}

.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}

.qk{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:12px}
.qk button{display:flex;flex-direction:column;align-items:center;gap:6px;padding:14px 6px 12px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);color:var(--ink)}
.qk button svg.ic{color:var(--spend)}
.qk button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}.qk button.on small{color:var(--spend);opacity:.8}
.qk span{font-weight:600;font-size:13px}.qk small{font-size:11px;color:var(--mu);font-family:var(--mono)}
.pn{display:flex;gap:16px;align-items:flex-end;flex-wrap:wrap}
.pn2{display:flex;gap:12px;align-items:flex-end}
.pn2 .pf{flex:1;min-width:0}
.pn2 .pq{flex:none}
.pn2 label{display:block;margin-bottom:6px}
.pn2 .stp{gap:6px}.pn2 .stp .in{width:46px;padding:10px 4px}
.th2{display:flex;justify-content:space-between;align-items:center;padding:10px 10px 0 14px!important}
.pl{width:32px;height:32px;border-radius:10px;border:1px solid var(--ln);background:var(--s2);color:var(--ink);display:flex;align-items:center;justify-content:center;padding:0;flex:none;box-shadow:var(--sh1)}
.pl svg.ic{width:18px;height:18px;transition:transform .18s ease}
.pl.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}.pl.on svg.ic{transform:rotate(45deg)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.tt{display:flex;align-items:center;gap:12px;margin-top:16px}.tt b{flex:1;font-size:26px;letter-spacing:-.04em}

.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ln3{display:flex;gap:12px;align-items:center}.n3{width:76px;flex:none}

.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}.cm .eb b{font-weight:600}.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}

.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}.li:hover{background:var(--s2)}.li:last-child{border:0}.li:first-child{padding-top:14px}

.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:16px}
.qk4 button{display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;color:var(--ink);text-align:left;box-shadow:var(--sh1)}
.qk4 button svg.ic{color:var(--spend)}
.qk4 button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}
.qk4 b{display:block;font-size:14px}.qk4 small{font-size:12px;opacity:.65;font-family:var(--mono)}
.qrow{display:flex;align-items:center;gap:16px;margin-top:16px;padding:16px 18px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);flex-wrap:wrap}
.qrow .eq{font-size:22px;font-weight:600;letter-spacing:-.04em}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
.sl{background:var(--ac);color:var(--on);padding:48px;display:flex;flex-direction:column;justify-content:space-between}
.sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
.sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
.wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.gbtn:hover{background:var(--s2)}
.au .or{margin:18px 0 6px}

details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s ease}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}

.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:var(--bg);border:1px solid var(--ln);color:var(--ink)}
.qe{display:flex;gap:10px;align-items:center;padding:10px 0;border-bottom:1px solid var(--ln)}
.qe .in{font-size:14px;padding:8px 12px}
.qadd{display:flex;gap:10px;align-items:center;margin-top:14px}
.qadd .in{font-size:14px;padding:8px 12px}
.sf .in{display:block;margin-bottom:10px}
.sf .btn.full{margin-top:0}
.chips.nm{flex-wrap:nowrap;overflow-x:auto;margin:0 0 10px;padding-bottom:2px;scrollbar-width:none}
.chips.nm::-webkit-scrollbar{display:none}
.chips.nm .chip{flex:none;white-space:nowrap}
.bgc{display:flex;overflow:hidden;padding:0}
.bgc>.ct{flex:1;min-width:0}
.sc.bgc>.ct{padding:18px 22px 20px}
.addb{flex:none;width:64px;border:0;border-right:1px solid var(--acl);border-radius:0;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0}
.addb svg.ic{width:30px;height:30px;stroke-width:2;transition:transform .18s ease}
.addb.on svg.ic{transform:rotate(45deg)}
.addb:active{transform:none;opacity:.8}
.bgc .adp{margin:6px 14px 14px}
.sc.bgc .adp{margin:14px 0 0}
details.dd>summary{padding:14px 16px;display:block;position:relative}
details.dd[open]>summary{padding-bottom:4px}
details.dd>.cb{padding-top:6px}
details.dd .chev{position:absolute;right:16px;top:14px}
.sc.bgc summary.sh{cursor:pointer}
.wi{padding:12px 0;border-top:1px solid var(--ln)}
.wi:first-child{border-top:0;padding-top:0}
.wa{display:flex;gap:8px;justify-content:flex-end;align-items:center;margin-top:10px}
.l1{gap:12px}.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.tl{display:block;font-weight:400;margin-top:3px;font-size:11px;color:var(--mu);font-family:var(--mono)}
.th2>span{min-width:0}
.pnl.top{margin:0 0 12px;padding:0 0 12px;border-top:0;border-bottom:1px solid var(--ln)}
.sh .pl{margin-left:10px}
.ok{color:var(--earn)}


.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}.spf .ln .in{flex:1 1 0}.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.srcf{margin-top:14px}.srcf .ln{gap:10px}.srcf .in.pr{flex:0 0 96px;width:96px}.srcf .btn.full{margin-top:10px}
.in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
.rw>.rt{max-width:62%;justify-content:flex-end}
.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
.xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
.xh::-webkit-details-marker{display:none}
.xh>div{min-width:0}
.xc .chev{position:absolute;right:66px;top:50%;margin-top:-10px}
.xp{position:absolute;right:12px;top:18px;width:46px;height:44px;border-radius:13px;border:1px solid var(--acl);background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0;z-index:2}
.xp svg.ic{width:24px;height:24px;stroke-width:2;transition:transform .18s ease}
.xp.on svg.ic{transform:rotate(45deg)}
.xb{padding:4px 16px 8px;border-top:1px solid var(--ln)}
.xf{padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.xl{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:12px;color:var(--mu);font-family:var(--mono)}
.xl b{color:var(--ink);font-weight:600;white-space:nowrap}
.xf form{margin:12px 0 0}
.xfm .ln{gap:10px;margin:0}.xfm .ln .in{flex:1 1 0;margin:0}.xfm .ln .in.pr{flex:0 0 96px;width:96px}.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}.gw:last-child{border-bottom:0}.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
.top-status-bar.tsplit{justify-content:space-between}.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}
MT_EOF
cat > "app/client/app.js" <<'MT_EOF'
(function(){
var d=document,r=d.documentElement;
function all(sel,root){return [].slice.call((root||d).querySelectorAll(sel))}
function money(n){return (Math.round(n*100)/100).toLocaleString('en-US')}

function setTheme(t){
  r.setAttribute('data-theme',t);
  try{localStorage.setItem('mtheme',t)}catch(e){}
  try{fetch('/settings/theme',{method:'POST',body:new URLSearchParams({theme:t}),credentials:'same-origin',redirect:'manual'})}catch(e){}
}

/* ---------- quick buy ---------- */
function calc(f){
  var q=parseFloat(f.querySelector('[data-qty]').value)||0,p=parseFloat(String(f.querySelector('[data-price]').value).replace(',','.'))||0;
  var t=Math.round(q*p*100)/100,o=f.querySelector('[data-tot]');
  o.textContent=(o.getAttribute('data-pre')||'')+(t?'−':'')+money(t);
}
function pick(q,keep){
  var w=q.closest('[data-qb]'),f=w.querySelector('[data-qp]'),n=q.getAttribute('data-q');
  all('[data-q]',w).forEach(function(b){b.classList.toggle('on',b===q)});
  f.hidden=false;
  f.querySelector('[data-cat]').value=n;
  var ti=f.querySelector('[data-qt]');if(ti)ti.textContent=n;
  var lw=f.querySelector('[data-labelwrap]');if(lw)lw.hidden=!q.hasAttribute('data-o');
  if(!keep)f.querySelector('[data-qty]').value=1;
  f.querySelector('[data-price]').value=q.getAttribute('data-p')||'';
  calc(f);
}
all('.qk4').forEach(function(g){var first=g.querySelector('[data-q]');if(first)pick(first,false)});

/* ---------- notes ---------- */
function endEdit(c){
  var id=c.querySelector('[data-eid]');if(id)id.value='';
  var eb=c.querySelector('.eb');if(eb)eb.hidden=true;
  c.querySelector('textarea').value='';
}
all('[data-list]').forEach(function(L){
  var last=L.lastElementChild;
  if(L.getAttribute('data-list')!=='dash'&&last&&last.scrollIntoView)last.scrollIntoView({block:'end'});
});

/* ---------- "I owe" open or closed, kept in the browser ---------- */
var open={};try{open=JSON.parse(localStorage.getItem('mt:open')||'{}')}catch(e){}
all('details[data-keep-open]').forEach(function(x){var k=x.getAttribute('data-keep-open');if(k in open)x.open=!!open[k]});
d.addEventListener('toggle',function(e){
  var x=e.target;
  if(x.matches&&x.matches('details[data-keep-open]')){
    open[x.getAttribute('data-keep-open')]=x.open;
    try{localStorage.setItem('mt:open',JSON.stringify(open))}catch(err){}
  }
  if(x.matches&&x.matches('.xd')&&!x.open){var xf=x.querySelector('[data-adp]'),xb=x.parentNode.querySelector('[data-xplus]');if(xf)xf.hidden=true;if(xb)xb.classList.remove('on')}
},true);

/* ---------- clicks ---------- */
d.addEventListener('click',function(e){
  var t=e.target,q;
  if(t.closest('[data-theme-toggle]')){setTheme(r.getAttribute('data-theme')==='dark'?'light':'dark');return}
  if((q=t.closest('[data-set-theme]'))){setTheme(q.getAttribute('data-set-theme'));return}
  if((q=t.closest('[data-eye]'))){
    var v=q.parentNode.firstChild,hide=q.getAttribute('data-s')!=='1';
    q.setAttribute('data-s',hide?'1':'0');
    v.innerHTML=hide?(v.getAttribute('data-bal')+' <small>'+v.getAttribute('data-cur')+'</small>'):'••••••';
    return
  }
  if((q=t.closest('[data-edit-bal]'))){var bf=q.closest('.cd,.sc').querySelector('[data-balf]');bf.hidden=!bf.hidden;q.textContent=bf.hidden?'Edit balance':'Cancel';if(!bf.hidden){var bi=bf.querySelector('input:not([type=hidden])');if(bi){bi.focus();bi.select()}}return}
  if((q=t.closest('[data-all]'))){
    var af=q.closest('.iw').querySelector('input');
    af.value=q.getAttribute('data-all');af.focus();
    return
  }
  if((q=t.closest('[data-tg],[data-pay]'))){
    var w=q.closest('.dbw'),which=q.hasAttribute('data-tg')?'[data-addp]':'[data-payp]',other=q.hasAttribute('data-tg')?'[data-payp]':'[data-addp]';
    var p=w.querySelector(which),o=w.querySelector(other);
    if(o)o.hidden=true;
    p.hidden=!p.hidden;
    if(!p.hidden){var i=p.querySelector('input[name=amount]');if(i)i.focus()}
    return
  }
  if((q=t.closest('[data-plus]'))){
    var pn=q.closest('.cd,.sc').querySelector('[data-pnl]');
    if(pn){
      pn.hidden=!pn.hidden;
      q.classList.toggle('on',!pn.hidden);
      if(!pn.hidden){var fi=pn.querySelector('input:not([type=hidden])');if(fi)fi.focus()}
    }
    return
  }
  if((q=t.closest('[data-xplus]'))){
    var xc=q.closest('.xc'),xd=xc.querySelector('details'),xm=xc.querySelector('[data-adp]');
    if(xm){
      if(!xd.open){xd.open=true;xm.hidden=false}else xm.hidden=!xm.hidden;
      q.classList.toggle('on',!xm.hidden);
      if(!xm.hidden){var xi=xm.querySelector('input:not([type=hidden])');if(xi)xi.focus()}
    }
    return
  }
  if((q=t.closest('[data-nm]'))){
    var nf=q.closest('form'),nin=nf.querySelector('[data-name]'),pin=nf.querySelector('[data-price]');
    nin.value=q.getAttribute('data-nm');
    if(pin)pin.focus();
    return
  }
  if((q=t.closest('[data-bigadd]'))){
    var tf=q.getAttribute('data-for'),ap=tf?d.getElementById(tf):q.closest('.bgc').querySelector('[data-adp]');
    ap.hidden=!ap.hidden;
    q.classList.toggle('on',!ap.hidden);
    if(!ap.hidden){var ai=ap.querySelector('input:not([type=hidden])');if(ai)ai.focus()}
    return
  }
  if((q=t.closest('[data-q]'))){pick(q,false);return}
  if((q=t.closest('[data-step]'))){
    var f2=q.closest('[data-qp]'),i2=f2.querySelector('[data-qty]');
    i2.value=Math.max(1,(parseFloat(i2.value)||0)+parseInt(q.getAttribute('data-step'),10));calc(f2);return
  }
  if((q=t.closest('[data-mode]'))){
    var form=q.closest('form');
    all('[data-mode]',form).forEach(function(c){c.classList.toggle('on',c===q)});
    form.querySelector('[data-mode-input]').value=q.getAttribute('data-mode');
    return
  }
  if((q=t.closest('.bub'))){
    q.classList.toggle('sel');var a=q.parentNode.querySelector('.acts');a.hidden=!a.hidden;return
  }
  if((q=t.closest('[data-act]'))){
    var m=q.closest('.msg'),act=q.getAttribute('data-act'),body=m.querySelector('.bub').textContent;
    if(act==='copy'){try{navigator.clipboard.writeText(body)}catch(x){}return}
    if(act==='edit'){
      var key=m.parentNode.getAttribute('data-list'),c=d.querySelector('[data-comp="'+key+'"]');
      c.querySelector('[data-eid]').value=m.getAttribute('data-id');
      c.querySelector('.eb').hidden=false;
      var ta=c.querySelector('textarea');ta.value=body;ta.focus();
    }
    return
  }
  if((q=t.closest('[data-cancel]'))){endEdit(q.closest('[data-comp]'));return}
});

d.addEventListener('input',function(e){
  var f=e.target.closest&&e.target.closest('[data-qp]');
  if(f)calc(f);
});

d.addEventListener('click',function(e){
  var b=e.target.closest&&e.target.closest('[data-confirm-btn]');
  if(b&&!confirm(b.getAttribute('data-confirm-btn')))e.preventDefault();
},true);

d.addEventListener('submit',function(e){
  var f=e.target,msg=f.getAttribute&&f.getAttribute('data-confirm');
  if(msg&&!confirm(msg)){e.preventDefault();return}
  setTimeout(function(){if(e.defaultPrevented)return;all('button',f).forEach(function(b){if(!b.disabled){b.disabled=true;b.setAttribute('data-busy','1')}})},0);
});
window.addEventListener('pageshow',function(e){if(e.persisted)all('button[data-busy]').forEach(function(b){b.disabled=false;b.removeAttribute('data-busy')})});

d.addEventListener('keydown',function(e){
  if(e.key!=='Enter'||e.shiftKey)return;
  var t=e.target;
  if(t.matches&&t.matches('[data-comp] textarea')){
    e.preventDefault();
    if(t.value.trim()){var f=t.closest('form');if(f.requestSubmit)f.requestSubmit();else f.submit()}
  }
});

/* ---------- live clock (Africa/Casablanca) ---------- */
function updateLiveClock(){
  var tEls = all('[data-clock-time]');
  var dEls = all('[data-clock-date]');
  var sEls = all('[data-clock-subdate]');
  if(!tEls.length) return;
  var now = new Date();
  try{
    var tf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', hour: '2-digit', minute: '2-digit', hour12: false });
    var df = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', weekday: 'long', day: 'numeric', month: 'long' });
    var nf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', day: '2-digit', month: '2-digit', year: 'numeric' });
    var af = new Intl.DateTimeFormat('ar-MA', { timeZone: 'Africa/Casablanca', weekday: 'long' });
    var tStr = tf.format(now);
    var dStr = df.format(now);
    var sStr = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + '</span>';
    tEls.forEach(function(el){ el.textContent = tStr; });
    dEls.forEach(function(el){ el.textContent = dStr; });
    sEls.forEach(function(el){ el.innerHTML = sStr; });
  }catch(err){}
}
setInterval(updateLiveClock, 1000);

/* ---------- background fallback ---------- */
var bgCustomEl = d.querySelector('[data-bg-custom]');
if(bgCustomEl){
  var bgUrl = bgCustomEl.getAttribute('data-bg-custom');
  if(bgUrl){
    var testImg = new Image();
    testImg.onerror = function(){
      bgCustomEl.classList.add('bg-fallback-auto');
    };
    testImg.src = bgUrl;
  }
}
})();

if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))
MT_EOF
cat > "app/client/theme.js" <<'MT_EOF'
try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}
MT_EOF
cat > "app/commands.ts" <<'MT_EOF'
import * as act from "./lib/actions.ts"
import { setTheme, updatePrefs, updateProfile, type User } from "./lib/users.ts"
export type Command = { run: (user: User, f: FormData) => Promise<unknown>; to: string; back?: boolean; fail?: string; empty?: boolean }
const text = (f: FormData, key: string) => String(f.get(key) ?? "")
const quiet = (fn: (u: User, f: FormData) => Promise<unknown>) => async (u: User, f: FormData) => {
await fn(u, f)
}
export const commands = {
buy: { run: (u, f) => act.addBuy(u.id, f), to: "/home" },
deleteBuy: { run: (u, f) => act.deleteBuy(u.id, f), to: "/home" },
setBalance: { run: (u, f) => act.setBalance(u.id, f), to: "/profile" },
historyIncome: { run: (u, f) => act.addDayIncome(u.id, f), to: "/history" },
addDebt: { run: (u, f) => act.addDebt(u.id, f), to: "/debts" },
payDebt: { run: (u, f) => act.payDebt(u.id, f), to: "/debts" },
clearDebt: { run: (u, f) => act.clearDebt(u.id, f), to: "/debts" },
addNote: { run: quiet((u, f) => act.saveNote(u.id, f)), to: "/notes" },
deleteNote: { run: quiet((u, f) => act.deleteNote(u.id, f)), to: "/notes" },
addWish: { run: (u, f) => act.addGoal(u.id, f), to: "/goals" },
buyWish: { run: (u, f) => act.buyWish(u.id, f), to: "/goals" },
deleteWish: { run: (u, f) => act.deleteWish(u.id, f), to: "/goals" },
editGoal: { run: (u, f) => act.editGoal(u.id, f), to: "/goals" },
editGoalItem: { run: (u, f) => act.editGoalItem(u.id, f), to: "/goals" },
addGoalItem: { run: (u, f) => act.addGoalItem(u.id, f), to: "/goals" },
deleteGoalItem: { run: (u, f) => act.deleteGoalItem(u.id, f), to: "/goals" },
addSource: { run: (u, f) => act.addSource(u.id, f), to: "/income" },
addIncome: { run: (u, f) => act.addIncome(u.id, f), to: "/income" },
deleteIncome: { run: (u, f) => act.deleteIncome(u.id, f), to: "/income" },
toggleSource: { run: (u, f) => act.toggleSource(u.id, f), to: "/income" },
editSource: { run: (u, f) => act.editSource(u.id, f), to: "/income" },
deleteSource: { run: (u, f) => act.deleteSource(u.id, f), to: "/income" },
addPlan: { run: async () => {}, to: "/plan" },
saveProfile: { run: (u, f) => updateProfile(u.id, { name: text(f, "name"), email: text(f, "email") }), to: "/profile", back: false, fail: "/profile/edit" },
saveSettings: { run: quiet((u, f) => updatePrefs(u.id, { currency: text(f, "currency"), run_at: text(f, "run_at"), week_start: text(f, "week") })), to: "/settings" },
quickBuy: { run: quiet((u, f) => act.quickOp(u.id, f)), to: "/settings" },
setTheme: { run: quiet((u, f) => setTheme(u.id, text(f, "theme"))), to: "/settings", empty: true },
setBackground: { run: (u, f) => act.validateAndSetBackground(u.id, text(f, "url")), to: "/settings", back: false },
resetBackground: { run: quiet((u) => act.resetUserBackground(u.id)), to: "/settings", back: false },
} satisfies Record<string, Command>
export type CommandName = keyof typeof commands
export const isCommand = (name: string): name is CommandName => Object.hasOwn(commands, name)
export const errorOf = (r: unknown) => (typeof r === "string" && r ? r : "")
MT_EOF
cat > "app/controllers/api.ts" <<'MT_EOF'
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
MT_EOF
cat > "app/controllers/assets.ts" <<'MT_EOF'
import { createController } from "remix/router"
import { assets } from "../lib/assets.ts"
import { routes } from "../routes.ts"
import appCss from "../client/app.css?raw"
import appJs from "../client/app.js?raw"
import themeJs from "../client/theme.js?raw"
const hash = (s: string) => {
let h = 5381
for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
return (h >>> 0).toString(36)
}
const file = (body: string, type: string) => {
const etag = `"${hash(body)}"`
return (ctx: { request: Request }) =>
ctx.request.headers.get("if-none-match") === etag
? new Response(null, { status: 304, headers: { ETag: etag } })
: new Response(body, { headers: { "Content-Type": type, "Cache-Control": "no-cache", ETag: etag } })
}
export default createController(routes.assets, {
actions: {
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
css: file(appCss, "text/css; charset=utf-8"),
js: file(appJs, "application/javascript; charset=utf-8"),
theme: file(themeJs, "application/javascript; charset=utf-8"),
},
})
MT_EOF
cat > "app/controllers/auth.tsx" <<'MT_EOF'
import { finishExternalAuth, startExternalAuth } from "remix/auth"
import { createController } from "remix/router"
import { env } from "../env.ts"
import * as act from "../lib/actions.ts"
import { googleProvider } from "../lib/auth.ts"
import { signInWithPassword, signUpWithPassword, upsertFromGoogle } from "../lib/users.ts"
import { routes } from "../routes.ts"
import { LoginScreen, SignupScreen } from "../screens/index.tsx"
import { render } from "../utils/render.ts"
import { fail, formOf, go, signInAs, signOut, takeError, userOf, type Ctx } from "../utils/request.ts"
export default createController(routes.auth, {
actions: {
login(ctx: Ctx) {
if (userOf(ctx)) return go("/home")
return render(<LoginScreen error={takeError(ctx)} />)
},
async signIn(ctx: Ctx) {
const f = formOf(ctx)
const user = await signInWithPassword(String(f.get("email") ?? ""), String(f.get("password") ?? ""))
if (!user) return fail(ctx, "/login", "Wrong email or password.")
signInAs(ctx, user.id)
return go("/home")
},
signup(ctx: Ctx) {
if (userOf(ctx)) return go("/home")
return render(<SignupScreen error={takeError(ctx)} />)
},
async signUp(ctx: Ctx) {
const f = formOf(ctx)
const result = await signUpWithPassword({ name: String(f.get("name") ?? ""), email: String(f.get("email") ?? ""), password: String(f.get("password") ?? "") })
if (!result.ok) return fail(ctx, "/signup", result.error)
signInAs(ctx, result.user.id)
return go("/home")
},
logout(ctx: Ctx) {
signOut(ctx)
return go("/login")
},
googleLogin(ctx: Ctx) {
if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) return fail(ctx, "/login", "Google login is not configured. Please sign in with email and password.")
return startExternalAuth(googleProvider, ctx as never, { returnTo: "/home" })
},
async googleCallback(ctx: Ctx) {
try {
const { result, returnTo } = await finishExternalAuth(googleProvider, ctx as never)
const user = await upsertFromGoogle(result.account, result.profile as never)
signInAs(ctx, user.id)
return go(returnTo ?? "/home")
} catch (err) {
console.error("google sign-in failed", err)
return fail(ctx, "/login", "Google sign-in failed. Try again.")
}
},
async deleteAccount(ctx: Ctx) {
const user = userOf(ctx)
if (!user) return go("/login")
await act.deleteAccount(user.id)
signOut(ctx)
return go("/signup")
},
},
})
MT_EOF
cat > "app/controllers/commands.ts" <<'MT_EOF'
import { createController } from "remix/router"
import { commands, errorOf, type Command, type CommandName } from "../commands.ts"
import { routes } from "../routes.ts"
import { backTo, fail, formOf, go, userOf, type Ctx } from "../utils/request.ts"
const form = (name: CommandName) => async (ctx: Ctx) => {
const c: Command = commands[name]
const user = userOf(ctx)
if (!user) return c.empty ? new Response(null, { status: 401 }) : go("/login")
const f = formOf(ctx)
const error = errorOf(await c.run(user, f))
if (c.empty) return new Response(null, { status: 204 })
const to = c.back === false ? c.to : backTo(f, c.to)
return error ? fail(ctx, c.fail ?? to, error) : go(to)
}
export default createController(routes.commands, {
actions: Object.fromEntries((Object.keys(commands) as CommandName[]).map((name) => [name, form(name)])) as never,
})
MT_EOF
cat > "app/controllers/pages.tsx" <<'MT_EOF'
import { createController } from "remix/router"
import * as act from "../lib/actions.ts"
import { loadScreen } from "../loaders.ts"
import { routes } from "../routes.ts"
import { Screen, type ScreenKey } from "../screens/index.tsx"
import { render } from "../utils/render.ts"
import { go, takeError, userOf, type Ctx } from "../utils/request.ts"
const screen = (key: ScreenKey) => async (ctx: Ctx) => {
const user = userOf(ctx)
if (!user) return go("/login")
const s = await loadScreen(user, key, takeError(ctx))
return render(<Screen name={key} s={s} />)
}
export default createController(routes.pages, {
actions: {
root: (ctx: Ctx) => go(userOf(ctx) ? "/home" : "/login"),
home: screen("home"),
debts: screen("debts"),
notes: screen("notes"),
goals: screen("goals"),
pad: screen("pad"),
income: screen("income"),
plan: screen("plan"),
history: screen("history"),
profile: screen("profile"),
profileEdit: screen("profileEdit"),
settings: screen("settings"),
async exportCsv(ctx: Ctx) {
const user = userOf(ctx)
if (!user) return go("/login")
return new Response(await act.exportCsv(user.id), {
headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": 'attachment; filename="moneytracker.csv"' },
})
},
},
})
MT_EOF
cat > "app/db/index.ts" <<'MT_EOF'
import { createClient } from "@libsql/client/web";
import { createTursoDatabase } from "@remix-kbn/data-table-sqlite-turso";

import { env } from "../env.ts";

/** One Turso database for local dev and Cloudflare. The client is created once per isolate. */
const client = createClient({ url: env.TURSO_DATABASE_URL, authToken: env.TURSO_AUTH_TOKEN });

export const db = createTursoDatabase(client);

export * from "./tables.ts";
MT_EOF
cat > "app/db/session-storage.ts" <<'MT_EOF'
import { createSession, type Session, type SessionStorage } from "remix/session";
import { sql } from "remix/data-table";
import { db } from "./index.ts";
import { sessions as sessionsTable } from "./tables.ts";
const TTL_MS = 30 * 24 * 60 * 60 * 1000;
export function createDbSessionStorage(): SessionStorage {
return {
async read(cookie) {
if (!cookie) return createSession();
try {
const row = await db.find(sessionsTable, cookie);
if (!row || row.expires_at < Date.now()) return createSession();
return createSession(row.id, JSON.parse(row.data));
} catch {
return createSession();
}
},
async save(session: Session) {
if (session.deleteId) await db.delete(sessionsTable, session.deleteId);
if (session.destroyed) {
await db.delete(sessionsTable, session.id);
return null;
}
if (session.size === 0 && !session.dirty) return null;
const auth = session.get("auth") as { userId?: string } | undefined;
const now = Date.now();
await db.exec(sql`
insert into sessions (id, user_id, data, created_at, expires_at)
values (${session.id}, ${auth?.userId ?? null}, ${JSON.stringify(session.data)}, ${now}, ${now + TTL_MS})
on conflict(id) do update set
user_id = excluded.user_id,
data = excluded.data,
expires_at = excluded.expires_at
`);
return session.id;
},
};
}
MT_EOF
cat > "app/db/tables.ts" <<'MT_EOF'
import { column as c, table } from "remix/data-table";

// Typed mirrors of database/schema.sql. Money is integer minor units, times are unix ms.

export const users = table({
name: "users",
columns: {
id: c.varchar(36),
email: c.varchar(255),
name: c.varchar(255),
email_verified: c.integer(),
currency: c.varchar(8),
theme: c.varchar(8),
phone: c.varchar(64),
bio: c.varchar(500),
run_at: c.varchar(8),
week_start: c.varchar(16),
bg_mode: c.varchar(8),
bg_url: c.varchar(2048),
created_at: c.integer(),
updated_at: c.integer(),
},
});

export const passwords = table({
name: "passwords",
columns: { user_id: c.varchar(36), hash: c.varchar(255), updated_at: c.integer() },
primaryKey: "user_id",
});

export const sessions = table({
name: "sessions",
columns: {
id: c.varchar(64),
user_id: c.varchar(36),
data: c.varchar(65535),
created_at: c.integer(),
expires_at: c.integer(),
},
});

export const oauthAccounts = table({
name: "oauth_accounts",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
provider: c.varchar(32),
provider_account_id: c.varchar(255),
created_at: c.integer(),
},
});

export const userImages = table({
name: "user_images",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
kind: c.varchar(16),
source: c.varchar(16),
url: c.varchar(2048),
mime: c.varchar(64),
size_bytes: c.integer(),
is_active: c.integer(),
created_at: c.integer(),
},
});

export const quickBuys = table({
name: "quick_buys",
columns: { id: c.varchar(36), user_id: c.varchar(36), name: c.varchar(60), icon: c.varchar(16), price_minor: c.integer(), sort: c.integer() },
});

export const incomeSources = table({
name: "income_sources",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
name: c.varchar(80),
mode: c.varchar(8),
amount_minor: c.integer(),
every: c.varchar(8),
created_at: c.integer(),
type: c.varchar(16),
config: c.varchar(2000),
currency: c.varchar(8),
active: c.integer(),
sort: c.integer(),
},
});

export const incomes = table({
name: "incomes",
columns: {
id: c.varchar(80),
user_id: c.varchar(36),
source_id: c.varchar(36),
amount_minor: c.integer(),
day: c.varchar(10),
created_at: c.integer(),
meta: c.varchar(2000),
ext_key: c.varchar(120),
},
});

export const purchases = table({
name: "purchases",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
name: c.varchar(120),
qty: c.integer(),
unit_minor: c.integer(),
total_minor: c.integer(),
day: c.varchar(10),
debt_id: c.varchar(36),
created_at: c.integer(),
},
});

export const people = table({
name: "people",
columns: { id: c.varchar(36), user_id: c.varchar(36), name: c.varchar(80) },
});

export const debts = table({
name: "debts",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
person_id: c.varchar(36),
kind: c.varchar(8),
item_name: c.varchar(40),
item_qty: c.integer(),
amount_minor: c.integer(),
created_at: c.integer(),
},
});

export const debtPayments = table({
name: "debt_payments",
columns: {
id: c.varchar(36),
debt_id: c.varchar(36),
user_id: c.varchar(36),
amount_minor: c.integer(),
purchase_id: c.varchar(36),
created_at: c.integer(),
},
});

export const goals = table({
name: "goals",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
title: c.varchar(120),
target_minor: c.integer(),
saved_minor: c.integer(),
is_wish: c.integer(),
done_at: c.integer(),
created_at: c.integer(),
},
});

export const goalItems = table({
name: "goal_items",
columns: { id: c.varchar(36), user_id: c.varchar(36), goal_id: c.varchar(36), name: c.varchar(120), price_minor: c.integer(), done_at: c.integer(), created_at: c.integer() },
});

export const notes = table({
name: "notes",
columns: { id: c.varchar(36), user_id: c.varchar(36), body: c.varchar(5000), created_at: c.integer(), updated_at: c.integer() },
});
MT_EOF
cat > "app/lib/actions.ts" <<'MT_EOF'
import { sql } from "remix/data-table";
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { balanceOf } from "./data.ts";
import { fmt, toMinor, toSigned } from "./money.ts";
import { extKey, parseJson, typeOf } from "./sources/index.ts";
import { today } from "./time.ts";
import { updateBg } from "./users.ts";
import { ICON_KEYS } from "../ui/parts.ts";
const id = () => crypto.randomUUID();
const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max);
const count = (v: unknown) => {
const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")));
return Number.isFinite(n) && n > 0 ? Math.min(n, 100000) : 0;
};
const realDay = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T12:00:00Z`)) && new Date(`${v}T12:00:00Z`).toISOString().slice(0, 10) === v;
const pickDay = (f: FormData) => {
const d = text(f.get("day"), 10) || today();
return realDay(d) && d <= today() ? d : null;
};
export async function addBuy(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("label"), 120) || "Item";
const qty = count(f.get("qty")) || 1;
const unit = toMinor(f.get("price"));
if (!unit) return "Enter a price";
const day = pickDay(f);
if (!day) return "Pick a day that is not in the future";
await db.create(purchases, { id: id(), user_id: uid, name, qty, unit_minor: unit, total_minor: unit * qty, day, created_at: Date.now() });
}
export async function addDayIncome(uid: string, f: FormData): Promise<string | void> {
const amount = toMinor(f.get("amount"));
if (!amount) return "Enter an amount";
const day = pickDay(f);
if (!day) return "Pick a day that is not in the future";
await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day, created_at: Date.now(), meta: '{"manual":1}', ext_key: "" });
}
export async function setBalance(uid: string, f: FormData): Promise<string | void> {
const target = toSigned(f.get("balance"));
if (target === null) return "Enter your balance";
const diff = target - (await balanceOf(uid));
if (!diff) return;
const now = Date.now();
if (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: today(), created_at: now, meta: '{"adjust":1}', ext_key: "" });
else await db.create(purchases, { id: id(), user_id: uid, name: "Balance adjustment", qty: 1, unit_minor: -diff, total_minor: -diff, day: today(), created_at: now });
}
export async function deleteBuy(uid: string, f: FormData): Promise<string | void> {
const p = await db.findOne(purchases, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!p) return;
await db.transaction(async (tx) => {
if (p.debt_id) {
const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } });
const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor;
const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } });
if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back });
await tx.exec(sql`delete from debt_payments where purchase_id = ${p.id} and user_id = ${uid}`);
}
await tx.exec(sql`delete from purchases where id = ${p.id} and user_id = ${uid}`);
});
}
export async function addDebt(uid: string, f: FormData): Promise<string | void> {
const debtId = text(f.get("debt_id"), 36);
if (debtId) {
const d = await db.findOne(debts, { where: { id: debtId, user_id: uid } });
if (!d) return;
if (d.kind === "item") {
const n = count(f.get("amount"));
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n });
} else {
const m = toMinor(f.get("amount"));
if (!m) return "Enter an amount";
await db.update(debts, d.id, { amount_minor: d.amount_minor + m });
}
return;
}
const name = text(f.get("name"), 80);
const cig = count(f.get("cig"));
const money = toMinor(f.get("amount"));
if (!name) return "Enter a name";
if (!cig && !money) return "Enter an amount";
await db.transaction(async (tx) => {
const all = await tx.findMany(people, { where: { user_id: uid } });
let person = all.find((p) => p.name.toLowerCase() === name.toLowerCase());
if (!person) person = await tx.create(people, { id: id(), user_id: uid, name }, { returnRow: true });
const mine = await tx.findMany(debts, { where: { user_id: uid, person_id: person.id } });
if (money) {
const row = mine.find((d) => d.kind === "money");
if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money });
else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, created_at: Date.now() });
}
if (cig) {
const row = mine.find((d) => d.kind === "item");
if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig });
else
await tx.create(debts, {
id: id(),
user_id: uid,
person_id: person.id,
kind: "item",
item_name: "cig",
item_qty: cig,
amount_minor: 0,
created_at: Date.now(),
});
}
});
}
export async function clearDebt(uid: string, f: FormData) {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 });
}
export async function payDebt(uid: string, f: FormData): Promise<string | void> {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
if (d.kind === "item") {
const n = Math.min(count(f.get("amount")), d.item_qty ?? 0);
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n });
return;
}
const pay = Math.min(toMinor(f.get("amount")), d.amount_minor);
if (!pay) return "Enter an amount";
const person = await db.find(people, d.person_id);
const purchaseId = id();
const now = Date.now();
await db.transaction(async (tx) => {
await tx.create(purchases, {
id: purchaseId,
user_id: uid,
name: `Paid ${person?.name ?? ""}`.trim(),
qty: 1,
unit_minor: pay,
total_minor: pay,
day: today(),
debt_id: d.id,
created_at: now,
});
await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now });
await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay });
});
}
export async function addGoal(uid: string, f: FormData): Promise<string | void> {
const title = text(f.get("name"), 120);
if (!title) return "Enter a goal name";
await db.create(goals, { id: id(), user_id: uid, title, target_minor: 0, saved_minor: 0, is_wish: 1, created_at: Date.now() });
}
export async function addGoalItem(uid: string, f: FormData): Promise<string | void> {
const g = await db.findOne(goals, { where: { id: text(f.get("goal_id"), 36), user_id: uid } });
if (!g) return "Goal not found";
const name = text(f.get("name"), 120);
if (!name) return "Enter an item";
const price = toMinor(f.get("price"));
if (!price) return "Enter a price";
await db.create(goalItems, { id: id(), user_id: uid, goal_id: g.id, name, price_minor: price, created_at: Date.now() });
}
export async function editGoal(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("name"), 120);
if (!name) return "Enter a goal name";
await db.exec(sql`update goals set title = ${name} where id = ${text(f.get("id"), 36)} and user_id = ${uid}`);
}
export async function editGoalItem(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("name"), 120);
if (!name) return "Enter an item";
const price = toMinor(f.get("price"));
if (!price) return "Enter a price";
await db.exec(sql`update goal_items set name = ${name}, price_minor = ${price} where id = ${text(f.get("id"), 36)} and user_id = ${uid} and done_at is null`);
}
export async function deleteGoalItem(uid: string, f: FormData) {
await db.exec(sql`delete from goal_items where id = ${text(f.get("id"), 36)} and user_id = ${uid}`);
}
export async function deleteWish(uid: string, f: FormData) {
const gid = text(f.get("id"), 36);
await db.exec(sql`delete from goal_items where goal_id = ${gid} and user_id = ${uid}`);
await db.exec(sql`delete from goals where id = ${gid} and user_id = ${uid}`);
}
export async function buyWish(uid: string, f: FormData): Promise<string | void> {
const it = await db.findOne(goalItems, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!it || it.done_at) return;
const bal = await balanceOf(uid);
if (it.price_minor > bal) return `Not enough balance for ${it.name}. You have ${fmt(Math.max(0, bal))}`;
await db.transaction(async (tx) => {
await tx.create(purchases, { id: id(), user_id: uid, name: it.name, qty: 1, unit_minor: it.price_minor, total_minor: it.price_minor, day: today(), created_at: Date.now() });
await tx.update(goalItems, it.id, { done_at: Date.now() });
});
}
export async function addSource(uid: string, f: FormData) {
const name = text(f.get("name"), 80);
if (!name) return "Enter a name";
const kind = typeOf(text(f.get("type"), 16));
const config = kind.parseConfig(f);
if (typeof config === "string") return config;
const mode = text(f.get("mode"), 10);
const amount = toMinor(f.get("amount"));
if ((mode === "daily" || mode === "monthly") && !amount) return "Enter how much it pays";
const taken = await db.findMany(incomeSources, { where: { user_id: uid } });
if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`;
const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(incomeSources, {
id: id(),
user_id: uid,
name,
mode: mode === "daily" || mode === "monthly" ? "auto" : "manual",
amount_minor: amount,
every: mode === "daily" ? "day" : mode === "monthly" ? "month" : "",
created_at: Date.now(),
type: kind.key,
config: JSON.stringify(config),
currency: text(f.get("currency"), 8).toUpperCase() || "MAD",
active: 1,
sort: (last?.sort ?? -1) + 1,
});
}
export async function saveDay(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = text(f.get("day"), 10) || today();
if (!realDay(day) || day > today()) return "Pick a day that is not in the future";
const kind = typeOf(s.type);
const key = extKey(s.id, day);
if (text(f.get("op"), 10) === "delete") {
const rowId = text(f.get("income_id"), 80);
if (rowId) await db.deleteMany(incomes, { where: { id: rowId, user_id: uid, source_id: s.id } });
else if (kind.keyed) await db.deleteMany(incomes, { where: { user_id: uid, ext_key: key } });
return;
}
let last: ReturnType<typeof parseJson> | null = null;
if (!kind.keyed) {
const rows = await db.findMany(incomes, { where: { user_id: uid, source_id: s.id }, orderBy: ["day", "desc"], limit: 200 });
const prev = rows.filter((r) => r.day <= day).sort((a, b) => (a.day === b.day ? b.created_at - a.created_at : a.day < b.day ? 1 : -1))[0];
last = prev ? parseJson(prev.meta) : null;
}
const entry = kind.entry({ config: parseJson(s.config), form: f, fallback: s.amount_minor, last });
if (typeof entry === "string") return entry;
const values = { amount_minor: entry.amount, meta: JSON.stringify(entry.meta) };
if (kind.keyed) {
const existing = await db.findOne(incomes, { where: { user_id: uid, ext_key: key } });
if (existing) {
await db.update(incomes, existing.id, values);
return;
}
}
await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, day, created_at: Date.now(), ext_key: kind.keyed ? key : "", ...values });
}
export async function addIncome(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = today();
if (typeOf(s.type).keyed) {
const done = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, day) } });
if (done) return `${s.name} is already added today`;
}
f.set("day", day);
return saveDay(uid, f);
}
export async function editSource(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const name = text(f.get("name"), 80);
if (!name) return "Enter a name";
const taken = await db.findMany(incomeSources, { where: { user_id: uid } });
if (taken.some((x) => x.id !== s.id && x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`;
const amount = toMinor(f.get("amount"));
if (s.type === "job") {
await db.update(incomeSources, s.id, { name, config: amount ? JSON.stringify({ ...parseJson(s.config), fixed_minor: amount }) : s.config });
return;
}
if (s.type && s.type !== "manual") {
await db.update(incomeSources, s.id, { name });
return;
}
if (s.mode === "auto" && !amount) return "Enter how much it pays";
await db.update(incomeSources, s.id, { name, amount_minor: amount });
}
export async function toggleSource(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 });
}
export async function deleteSource(uid: string, f: FormData) {
const sid = text(f.get("id"), 36);
const s = await db.findOne(incomeSources, { where: { id: sid, user_id: uid } });
if (!s) return;
await db.transaction(async (tx) => {
await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`);
await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`);
});
}
export async function deleteIncome(uid: string, f: FormData): Promise<string | void> {
const row = await db.findOne(incomes, { where: { id: text(f.get("id"), 80), user_id: uid } });
if (!row) return;
if (row.ext_key) {
const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null;
if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead";
}
await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } });
}
export async function quickOp(uid: string, f: FormData) {
const op = text(f.get("op"), 10);
const qid = text(f.get("id"), 36);
const name = text(f.get("name"), 60);
const icon = ICON_KEYS.includes(String(f.get("icon"))) ? String(f.get("icon")) : "Tag";
const price = toMinor(f.get("price"));
if (op === "delete" && qid) {
await db.deleteMany(quickBuys, { where: { id: qid, user_id: uid } });
} else if (op === "save" && qid && name) {
await db.updateMany(quickBuys, { name, icon, price_minor: price }, { where: { id: qid, user_id: uid } });
} else if (op === "add" && name) {
const last = await db.findOne(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(quickBuys, { id: id(), user_id: uid, name, icon, price_minor: price, sort: (last?.sort ?? -1) + 1 });
}
}
export async function saveNote(uid: string, f: FormData) {
const body = text(f.get("text"), 5000);
if (!body) return;
const noteId = text(f.get("id"), 36);
const now = Date.now();
if (noteId) await db.updateMany(notes, { body, updated_at: now }, { where: { id: noteId, user_id: uid } });
else await db.create(notes, { id: id(), user_id: uid, body, created_at: now, updated_at: now });
}
export async function deleteNote(uid: string, f: FormData) {
await db.deleteMany(notes, { where: { id: text(f.get("id"), 36), user_id: uid } });
}
export async function deleteAccount(uid: string) {
await db.transaction(async (tx) => {
for (const stmt of [
sql`delete from debt_payments where user_id = ${uid}`,
sql`delete from debts where user_id = ${uid}`,
sql`delete from people where user_id = ${uid}`,
sql`delete from purchases where user_id = ${uid}`,
sql`delete from incomes where user_id = ${uid}`,
sql`delete from income_sources where user_id = ${uid}`,
sql`delete from goal_items where user_id = ${uid}`,
sql`delete from goals where user_id = ${uid}`,
sql`delete from notes where user_id = ${uid}`,
sql`delete from quick_buys where user_id = ${uid}`,
sql`delete from user_images where user_id = ${uid}`,
sql`delete from oauth_accounts where user_id = ${uid}`,
sql`delete from passwords where user_id = ${uid}`,
sql`delete from sessions where user_id = ${uid}`,
sql`delete from users where id = ${uid}`,
])
await tx.exec(stmt);
});
}
const cell = (v: string | number) => {
let s = String(v);
if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
export async function exportCsv(uid: string) {
const [bs, is, ss] = await Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomeSources, { where: { user_id: uid } }),
]);
const names = new Map(ss.map((s) => [s.id, s.name]));
const lines = ["date,type,name,qty,amount"];
for (const i of is) lines.push([i.day, "income", cell(names.get(i.source_id ?? "") ?? "Other"), 1, fmt(i.amount_minor).replace(/,/g, "")].join(","));
for (const b of bs) lines.push([b.day, "buy", cell(b.name), b.qty, fmt(b.total_minor).replace(/,/g, "")].join(","));
return lines.join("\n");
}
export async function validateAndSetBackground(uid: string, rawUrl: string): Promise<string | null> {
	const trimmed = rawUrl.trim();
	if (!trimmed) return "Please enter an image URL.";
	let parsed: URL;
	try {
		parsed = new URL(trimmed);
	} catch {
		return "Invalid address.";
	}
	if (parsed.protocol !== "https:") {
		return "URL must use https.";
	}
	const host = parsed.hostname.toLowerCase();
	if (
		host === "localhost" ||
		host === "127.0.0.1" ||
		host === "::1" ||
		host === "0.0.0.0" ||
		host.endsWith(".local") ||
		host.endsWith(".internal") ||
		host.startsWith("10.") ||
		host.startsWith("192.168.") ||
		/^172\.(1[6-9]|2\d|3[01])\./.test(host) ||
		host.startsWith("169.254.")
	) {
		return "Invalid address.";
	}
	let res: Response;
	try {
		const controller = new AbortController();
		const timeoutId = setTimeout(() => controller.abort(), 6000);
		res = await fetch(parsed.toString(), {
			signal: controller.signal,
			headers: { "User-Agent": "Moneytracker/1.0" },
		});
		clearTimeout(timeoutId);
	} catch {
		return "Cannot download.";
	}
	if (!res.ok) {
		return "Cannot download.";
	}
	const cl = res.headers.get("content-length");
	if (cl && parseInt(cl, 10) > 5 * 1024 * 1024) {
		return "Too large.";
	}
	const ct = (res.headers.get("content-type") || "").toLowerCase().trim();
	if (!ct.startsWith("image/png") && !ct.startsWith("image/jpeg") && !ct.startsWith("image/jpg")) {
		return "Not a PNG or JPEG.";
	}
	let buffer: ArrayBuffer;
	try {
		buffer = await res.arrayBuffer();
	} catch {
		return "Cannot download.";
	}
	if (buffer.byteLength > 5 * 1024 * 1024) {
		return "Too large.";
	}
	if (buffer.byteLength < 8) {
		return "Not a PNG or JPEG.";
	}
	const bytes = new Uint8Array(buffer.slice(0, 8));
	const isPng = bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47;
	const isJpg = bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
	if (!isPng && !isJpg) {
		return "Not a PNG or JPEG.";
	}
	await updateBg(uid, { mode: "url", url: trimmed });
	return null;
}
export async function resetUserBackground(uid: string) {
	await updateBg(uid, { mode: "auto", url: "" });
}
MT_EOF
cat > "app/lib/actions.ts.bak" <<'MT_EOF'
import { sql } from "remix/data-table";

import { db, debtPayments, debts, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { balanceOf } from "./data.ts";
import { fmt, toMinor } from "./money.ts";
import { extKey, parseJson, typeOf } from "./sources/index.ts";
import { today } from "./time.ts";
import { updateBg } from "./users.ts";
import { ICON_KEYS } from "../ui/parts.ts";

const id = () => crypto.randomUUID();
const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max);
const count = (v: unknown) => {
const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")));
return Number.isFinite(n) && n > 0 ? Math.min(n, 100000) : 0;
};

// ---------- buys ----------

export async function addBuy(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("label"), 120) || "Item";
const qty = count(f.get("qty")) || 1;
const unit = toMinor(f.get("price"));
if (!unit) return "Enter a price";
const total = unit * qty;
const bal = await balanceOf(uid);
if (total > bal) return `Not enough balance. You have ${fmt(bal)}`;
await db.create(purchases, { id: id(), user_id: uid, name, qty, unit_minor: unit, total_minor: total, day: today(), created_at: Date.now() });
}

/** Undo a buy. If it was a debt payment, the debt comes back too. */
export async function deleteBuy(uid: string, f: FormData): Promise<string | void> {
const p = await db.findOne(purchases, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!p) return;
await db.transaction(async (tx) => {
if (p.debt_id) {
const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } });
const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor;
const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } });
if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back });
await tx.exec(sql`delete from debt_payments where purchase_id = ${p.id} and user_id = ${uid}`);
}
await tx.exec(sql`delete from purchases where id = ${p.id} and user_id = ${uid}`);
});
}

// ---------- debts ----------

/** Adds to a person already on the list (debt_id), or creates / revives a person by name. */
export async function addDebt(uid: string, f: FormData): Promise<string | void> {
const debtId = text(f.get("debt_id"), 36);
if (debtId) {
const d = await db.findOne(debts, { where: { id: debtId, user_id: uid } });
if (!d) return;
if (d.kind === "item") {
const n = count(f.get("amount"));
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n });
} else {
const m = toMinor(f.get("amount"));
if (!m) return "Enter an amount";
await db.update(debts, d.id, { amount_minor: d.amount_minor + m });
}
return;
}

const name = text(f.get("name"), 80);
const cig = count(f.get("cig"));
const money = toMinor(f.get("amount"));
if (!name) return "Enter a name";
if (!cig && !money) return "Enter an amount";

await db.transaction(async (tx) => {
const all = await tx.findMany(people, { where: { user_id: uid } });
let person = all.find((p) => p.name.toLowerCase() === name.toLowerCase());
if (!person) person = await tx.create(people, { id: id(), user_id: uid, name }, { returnRow: true });

const mine = await tx.findMany(debts, { where: { user_id: uid, person_id: person.id } });
if (money) {
const row = mine.find((d) => d.kind === "money");
if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money });
else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, created_at: Date.now() });
}
if (cig) {
const row = mine.find((d) => d.kind === "item");
if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig });
else
await tx.create(debts, {
id: id(),
user_id: uid,
person_id: person.id,
kind: "item",
item_name: "cig",
item_qty: cig,
amount_minor: 0,
created_at: Date.now(),
});
}
});
}

/** Wipes a debt entered by mistake. History is kept, and typing the name again brings the person back. */
export async function clearDebt(uid: string, f: FormData) {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 });
}

/** Money paid also becomes a buy today ("Paid Youssef"). Items just count down. */
export async function payDebt(uid: string, f: FormData): Promise<string | void> {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;

if (d.kind === "item") {
const n = Math.min(count(f.get("amount")), d.item_qty ?? 0);
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n });
return;
}

const pay = Math.min(toMinor(f.get("amount")), d.amount_minor);
if (!pay) return "Enter an amount";
const bal = await balanceOf(uid);
if (pay > bal) return `Not enough balance to pay ${fmt(pay)}. You have ${fmt(Math.max(0, bal))}`;
const person = await db.find(people, d.person_id);
const purchaseId = id();
const now = Date.now();

await db.transaction(async (tx) => {
await tx.create(purchases, {
id: purchaseId,
user_id: uid,
name: `Paid ${person?.name ?? ""}`.trim(),
qty: 1,
unit_minor: pay,
total_minor: pay,
day: today(),
debt_id: d.id,
created_at: now,
});
await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now });
await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay });
});
}

// ---------- goals ----------

export async function addGoal(uid: string, f: FormData): Promise<string | void> {
const title = text(f.get("name"), 120);
if (!title) return "Enter what you want";
await db.create(goals, {
id: id(),
user_id: uid,
title,
target_minor: toMinor(f.get("price")),
saved_minor: 0,
is_wish: 1,
created_at: Date.now(),
});
}

export async function deleteWish(uid: string, f: FormData) {
await db.exec(sql`delete from goals where id = ${text(f.get("id"), 36)} and user_id = ${uid}`);
}

export async function buyWish(uid: string, f: FormData): Promise<string | void> {
const g = await db.findOne(goals, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!g) return;
const price = g.target_minor;
if (price > 0) {
const bal = await balanceOf(uid);
if (price > bal) return `Not enough balance for ${g.title}. You have ${fmt(Math.max(0, bal))}`;
}
await db.transaction(async (tx) => {
if (price > 0) await tx.create(purchases, { id: id(), user_id: uid, name: g.title, qty: 1, unit_minor: price, total_minor: price, day: today(), created_at: Date.now() });
await tx.exec(sql`delete from goals where id = ${g.id} and user_id = ${uid}`);
});
}

// ---------- income ----------

export async function addSource(uid: string, f: FormData) {
const name = text(f.get("name"), 80);
if (!name) return "Enter a name";
const kind = typeOf(text(f.get("type"), 16));
const config = kind.parseConfig(f);
if (typeof config === "string") return config;
const mode = text(f.get("mode"), 10);
const amount = toMinor(f.get("amount"));
if ((mode === "daily" || mode === "monthly") && !amount) return "Enter how much it pays";
const taken = await db.findMany(incomeSources, { where: { user_id: uid } });
if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`;
const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(incomeSources, {
id: id(),
user_id: uid,
name,
mode: mode === "daily" || mode === "monthly" ? "auto" : "manual",
amount_minor: amount,
every: mode === "daily" ? "day" : mode === "monthly" ? "month" : "",
created_at: Date.now(),
type: kind.key,
config: JSON.stringify(config),
currency: text(f.get("currency"), 8).toUpperCase() || "MAD",
active: 1,
sort: (last?.sort ?? -1) + 1,
});
}

const realDay = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T12:00:00Z`)) && new Date(`${v}T12:00:00Z`).toISOString().slice(0, 10) === v;

/** Saves, updates or clears one day of one source. Job and manual sources keep one row per day, balance keeps one row per update. */
export async function saveDay(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = text(f.get("day"), 10) || today();
if (!realDay(day) || day > today()) return "Pick a day that is not in the future";
const kind = typeOf(s.type);
const key = extKey(s.id, day);

if (text(f.get("op"), 10) === "delete") {
const rowId = text(f.get("income_id"), 80);
if (rowId) await db.deleteMany(incomes, { where: { id: rowId, user_id: uid, source_id: s.id } });
else if (kind.keyed) await db.deleteMany(incomes, { where: { user_id: uid, ext_key: key } });
return;
}

let last: ReturnType<typeof parseJson> | null = null;
if (!kind.keyed) {
const rows = await db.findMany(incomes, { where: { user_id: uid, source_id: s.id }, orderBy: ["day", "desc"], limit: 200 });
const prev = rows.filter((r) => r.day <= day).sort((a, b) => (a.day === b.day ? b.created_at - a.created_at : a.day < b.day ? 1 : -1))[0];
last = prev ? parseJson(prev.meta) : null;
}

const entry = kind.entry({ config: parseJson(s.config), form: f, fallback: s.amount_minor, last });
if (typeof entry === "string") return entry;
const values = { amount_minor: entry.amount, meta: JSON.stringify(entry.meta) };

if (kind.keyed) {
const existing = await db.findOne(incomes, { where: { user_id: uid, ext_key: key } });
if (existing) {
await db.update(incomes, existing.id, values);
return;
}
}
await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, day, created_at: Date.now(), ext_key: kind.keyed ? key : "", ...values });
}

/** The "Add 120" button on a source. A manual or job source can be added once per day. */
export async function addIncome(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = today();
if (typeOf(s.type).keyed) {
const done = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, day) } });
if (done) return `${s.name} is already added today`;
}
f.set("day", day);
return saveDay(uid, f);
}

/** Pause or resume a source. A paused auto source stops paying until resumed. */
export async function toggleSource(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 });
}

/** Deletes a source. What it already paid stays in your balance and history. */
export async function deleteSource(uid: string, f: FormData) {
const sid = text(f.get("id"), 36);
const s = await db.findOne(incomeSources, { where: { id: sid, user_id: uid } });
if (!s) return;
await db.transaction(async (tx) => {
await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`);
await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`);
});
}

/** Undo an income row. Blocked if the money is already spent and the balance would go below zero. */
export async function deleteIncome(uid: string, f: FormData): Promise<string | void> {
const row = await db.findOne(incomes, { where: { id: text(f.get("id"), 80), user_id: uid } });
if (!row) return;
if (row.ext_key) {
const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null;
if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead";
}
const bal = await balanceOf(uid);
if (bal - row.amount_minor < 0) return `Can't undo: you already spent it. Balance is ${fmt(Math.max(0, bal))}`;
await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } });
}

// ---------- quick buys ----------

export async function quickOp(uid: string, f: FormData) {
const op = text(f.get("op"), 10);
const qid = text(f.get("id"), 36);
const name = text(f.get("name"), 60);
const icon = ICON_KEYS.includes(String(f.get("icon"))) ? String(f.get("icon")) : "Tag";
const price = toMinor(f.get("price"));

if (op === "delete" && qid) {
await db.deleteMany(quickBuys, { where: { id: qid, user_id: uid } });
} else if (op === "save" && qid && name) {
await db.updateMany(quickBuys, { name, icon, price_minor: price }, { where: { id: qid, user_id: uid } });
} else if (op === "add" && name) {
const last = await db.findOne(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(quickBuys, { id: id(), user_id: uid, name, icon, price_minor: price, sort: (last?.sort ?? -1) + 1 });
}
}

// ---------- notes ----------

export async function saveNote(uid: string, f: FormData) {
const body = text(f.get("text"), 5000);
if (!body) return;
const noteId = text(f.get("id"), 36);
const now = Date.now();
if (noteId) await db.updateMany(notes, { body, updated_at: now }, { where: { id: noteId, user_id: uid } });
else await db.create(notes, { id: id(), user_id: uid, body, created_at: now, updated_at: now });
}

export async function deleteNote(uid: string, f: FormData) {
await db.deleteMany(notes, { where: { id: text(f.get("id"), 36), user_id: uid } });
}

// ---------- account ----------

/** Foreign keys are not relied on: every table is cleared by hand, children first. */
export async function deleteAccount(uid: string) {
await db.transaction(async (tx) => {
for (const stmt of [
sql`delete from debt_payments where user_id = ${uid}`,
sql`delete from debts where user_id = ${uid}`,
sql`delete from people where user_id = ${uid}`,
sql`delete from purchases where user_id = ${uid}`,
sql`delete from incomes where user_id = ${uid}`,
sql`delete from income_sources where user_id = ${uid}`,
sql`delete from goals where user_id = ${uid}`,
sql`delete from notes where user_id = ${uid}`,
sql`delete from quick_buys where user_id = ${uid}`,
sql`delete from user_images where user_id = ${uid}`,
sql`delete from oauth_accounts where user_id = ${uid}`,
sql`delete from passwords where user_id = ${uid}`,
sql`delete from sessions where user_id = ${uid}`,
sql`delete from users where id = ${uid}`,
])
await tx.exec(stmt);
});
}

// ---------- export ----------

const cell = (v: string | number) => {
let s = String(v);
if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`; // stops spreadsheet formulas
return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export async function exportCsv(uid: string) {
const [bs, is, ss] = await Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomeSources, { where: { user_id: uid } }),
]);
const names = new Map(ss.map((s) => [s.id, s.name]));
const lines = ["date,type,name,qty,amount"];
for (const i of is) lines.push([i.day, "income", cell(names.get(i.source_id ?? "") ?? "Other"), 1, fmt(i.amount_minor).replace(/,/g, "")].join(","));
for (const b of bs) lines.push([b.day, "buy", cell(b.name), b.qty, fmt(b.total_minor).replace(/,/g, "")].join(","));
return lines.join("\n");
}

// ---------- background ----------

export async function validateAndSetBackground(uid: string, rawUrl: string): Promise<string | null> {
	const trimmed = rawUrl.trim();
	if (!trimmed) return "Please enter an image URL.";

	let parsed: URL;
	try {
		parsed = new URL(trimmed);
	} catch {
		return "Invalid address.";
	}

	if (parsed.protocol !== "https:") {
		return "URL must use https.";
	}

	const host = parsed.hostname.toLowerCase();
	if (
		host === "localhost" ||
		host === "127.0.0.1" ||
		host === "::1" ||
		host === "0.0.0.0" ||
		host.endsWith(".local") ||
		host.endsWith(".internal") ||
		host.startsWith("10.") ||
		host.startsWith("192.168.") ||
		/^172\.(1[6-9]|2\d|3[01])\./.test(host) ||
		host.startsWith("169.254.")
	) {
		return "Invalid address.";
	}

	let res: Response;
	try {
		const controller = new AbortController();
		const timeoutId = setTimeout(() => controller.abort(), 6000);
		res = await fetch(parsed.toString(), {
			signal: controller.signal,
			headers: { "User-Agent": "Moneytracker/1.0" },
		});
		clearTimeout(timeoutId);
	} catch {
		return "Cannot download.";
	}

	if (!res.ok) {
		return "Cannot download.";
	}

	const cl = res.headers.get("content-length");
	if (cl && parseInt(cl, 10) > 5 * 1024 * 1024) {
		return "Too large.";
	}

	const ct = (res.headers.get("content-type") || "").toLowerCase().trim();
	if (!ct.startsWith("image/png") && !ct.startsWith("image/jpeg") && !ct.startsWith("image/jpg")) {
		return "Not a PNG or JPEG.";
	}

	let buffer: ArrayBuffer;
	try {
		buffer = await res.arrayBuffer();
	} catch {
		return "Cannot download.";
	}

	if (buffer.byteLength > 5 * 1024 * 1024) {
		return "Too large.";
	}

	if (buffer.byteLength < 8) {
		return "Not a PNG or JPEG.";
	}

	const bytes = new Uint8Array(buffer.slice(0, 8));
	const isPng = bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47;
	const isJpg = bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;

	if (!isPng && !isJpg) {
		return "Not a PNG or JPEG.";
	}

	await updateBg(uid, { mode: "url", url: trimmed });
	return null;
}

export async function resetUserBackground(uid: string) {
	await updateBg(uid, { mode: "auto", url: "" });
}
MT_EOF
cat > "app/lib/assets.ts" <<'MT_EOF'
import { env } from "../env.ts";
const SITE_DESC = "Moneytracker is a quiet personal money tracker. Log what you spend and earn, track debts and wishes, and watch your road to your goals.";
const bytes = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
const png = (s: string) => new Response(bytes(s), { headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=604800" } });
const text = (body: string, type: string, cache = "public, max-age=86400") => new Response(body, { headers: { "Content-Type": type, "Cache-Control": cache } });
const origin = () => env.APP_ORIGIN.replace(/\/$/, "");
const I192 = "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";
const I512 = "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";
const A180 = "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";
const M512 = "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";
const SVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><rect width=\"24\" height=\"24\" rx=\"5\" fill=\"#13181b\"/><g transform=\"translate(12 12) scale(.62) translate(-12 -12.2)\"><path fill=\"#6fb7c4\" d=\"M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z\"/><path d=\"M9.2 11.4l2 1M14.8 11.4l-2 1\" stroke=\"#13181b\" stroke-width=\"1.5\"/></g></svg>";
const SW = "self.addEventListener(\"install\",()=>self.skipWaiting());self.addEventListener(\"activate\",(e)=>e.waitUntil(self.clients.claim()));self.addEventListener(\"fetch\",(e)=>{if(e.request.mode===\"navigate\")e.respondWith(fetch(e.request).catch(()=>new Response(\"<!doctype html><meta name=viewport content='width=device-width,initial-scale=1'><body style='font:16px system-ui;background:#13181b;color:#e8edf0;display:grid;place-items:center;min-height:100vh;margin:0'><p>You are offline</p>\",{headers:{\"Content-Type\":\"text/html\"}})))});";
export const SITE = { name: "Moneytracker", desc: SITE_DESC, color: "#13181b" };
export const assets = {
manifest: () =>
text(
JSON.stringify({
id: "/",
name: "Moneytracker",
short_name: "Money",
description: SITE_DESC,
start_url: "/home",
scope: "/",
display: "standalone",
orientation: "portrait",
background_color: "#13181b",
theme_color: "#13181b",
categories: ["finance", "productivity"],
icons: [
{ src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
{ src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
{ src: "/icon-maskable.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
],
}),
"application/manifest+json",
),
favicon: () => text(SVG, "image/svg+xml; charset=utf-8"),
icon192: () => png(I192),
icon512: () => png(I512),
iconMaskable: () => png(M512),
appleIcon: () => png(A180),
sw: () => text(SW, "application/javascript; charset=utf-8", "no-cache"),
robots: () => text(`User-agent: *\nAllow: /login\nAllow: /signup\nDisallow: /\nSitemap: ${origin()}/sitemap.xml\n`, "text/plain; charset=utf-8"),
sitemap: () =>
text(
`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>${origin()}/login</loc></url><url><loc>${origin()}/signup</loc></url></urlset>`,
"application/xml; charset=utf-8",
),
};
MT_EOF
cat > "app/lib/auth.ts" <<'MT_EOF'
import { auth, createSessionAuthScheme } from "remix/middleware/auth";
import { createGoogleAuthProvider } from "remix/auth";
import { createCookie } from "remix/cookie";
import { session } from "remix/middleware/session";
import { createDbSessionStorage } from "../db/session-storage.ts";
import { env } from "../env.ts";
import { getUserById } from "./users.ts";
const sessionCookie = createCookie("__session", {
secrets: [env.SESSION_SECRET],
httpOnly: true,
secure: import.meta.env.PROD,
sameSite: "lax",
path: "/",
maxAge: 60 * 60 * 24 * 30,
});
export const sessionMiddleware = session(sessionCookie, createDbSessionStorage());
export const authMiddleware = auth({
schemes: [
createSessionAuthScheme({
read(s) {
const v = s.get("auth") as { userId?: string } | null;
return v && typeof v.userId === "string" ? (v as { userId: string }) : null;
},
async verify(value) {
try {
return await getUserById(value.userId);
} catch {
return null;
}
},
invalidate(s) {
s.unset("auth");
},
}),
],
});
export const googleProvider = createGoogleAuthProvider({
clientId: env.GOOGLE_CLIENT_ID,
clientSecret: env.GOOGLE_CLIENT_SECRET,
redirectUri: new URL("/auth/google/callback", env.APP_ORIGIN),
});
MT_EOF
cat > "app/lib/auto.ts" <<'MT_EOF'
import { sql } from "remix/data-table";

import { db, incomes, incomeSources, users } from "../db/index.ts";
import { extKey } from "./sources/index.ts";
import { addDays, dayOf, hhmm, today } from "./time.ts";

const hm = (v: string | null | undefined) => {
	const m = /^(\d{1,2}):(\d{2})$/.exec(v ?? "");
	return m ? `${m[1]!.padStart(2, "0")}:${m[2]}` : "06:00";
};

const pad = (n: number) => String(n).padStart(2, "0");
const lastDayOf = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).getUTCDate();

/**
 * Auto income (daily / monthly) has no background job, so it is settled whenever the user opens the app
 * or the balance is needed. It is safe to run many times: every payout has a key (source + day) and is
 * only created once. Catches up on days the app was not opened (up to 62 days).
 */
export async function settleAuto(uid: string): Promise<void> {
	const all = await db.findMany(incomeSources, { where: { user_id: uid, mode: "auto" } });
	const srcs = all.filter((s) => s.active !== 0 && s.amount_minor > 0);
	if (!srcs.length) return;

	const u = await db.find(users, uid);
	const runAt = hm(u?.run_at);
	const now = Date.now();
	const t = today();
	const nowHm = hhmm(now);

	const res: any = await db.exec(sql`select ext_key as k from incomes where user_id = ${uid} and ext_key <> ''`);
	const rows: any[] = Array.isArray(res) ? res : (res?.rows ?? []);
	const have = new Set(rows.map((r) => String(r.k ?? r[0] ?? "")));

	const due = (d: string) => d < t || (d === t && nowHm >= runAt);

	for (const s of srcs) {
		const created = dayOf(s.created_at);
		const createdHm = hhmm(s.created_at);
		const started = (d: string) => d > created || (d === created && createdHm < runAt);
		const days: string[] = [];

		if (s.every === "month") {
			const dom = Number(created.slice(8, 10));
			let y = Number(created.slice(0, 4));
			let m = Number(created.slice(5, 7));
			const endY = Number(t.slice(0, 4));
			const endM = Number(t.slice(5, 7));
			for (let i = 0; i < 36 && (y < endY || (y === endY && m <= endM)); i++) {
				days.push(`${y}-${pad(m)}-${pad(Math.min(dom, lastDayOf(y, m)))}`);
				if (++m > 12) (m = 1), y++;
			}
		} else {
			const from = created > addDays(t, -62) ? created : addDays(t, -62);
			for (let d = from; d <= t; d = addDays(d, 1)) days.push(d);
		}

		for (const d of days) {
			if (!due(d) || !started(d)) continue;
			const key = extKey(s.id, d);
			if (have.has(key)) continue;
			have.add(key);
			try {
				await db.create(incomes, { id: crypto.randomUUID(), user_id: uid, source_id: s.id, amount_minor: s.amount_minor, day: d, created_at: now, meta: '{"auto":1}', ext_key: key });
			} catch {
				// another request already paid this day (unique index) - fine
			}
		}
	}
}
MT_EOF
cat > "app/lib/data.ts" <<'MT_EOF'
import { sql } from "remix/data-table";
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { settleAuto } from "./auto.ts";
import { parseJson, type Json } from "./sources/index.ts";
import { addDays, dayLabel, today } from "./time.ts";
import { getActiveAvatar, type User } from "./users.ts";
export type Quick = { id: string; name: string; icon: string; price: number };
export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number };
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string };
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number };
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number };
export type GoalItem = { id: string; name: string; price: number; done: boolean };
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] };
export type Note = { id: string; body: string; at: number; edited: boolean };
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] };
export type Part = "quick" | "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar" | "names";
export type State = {
user: User;
back: string;
error: string;
avatar: string | null;
quick: Quick[];
names: string[];
buys: Buy[];
incomesToday: Income[];
sources: Source[];
debts: DebtView[];
goals: Goal[];
notes: Note[];
days: DayRow[];
balance: number;
};
const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []));
const scalar = (r: unknown) => {
const row = rowsOf(r)[0];
return Number(row?.s ?? row?.[0] ?? 0) || 0;
};
export async function balanceOf(uid: string): Promise<number> {
await settleAuto(uid);
const [i, p] = await Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]);
return scalar(i) - scalar(p);
}
export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
const need = new Set(parts);
const uid = user.id;
const t = today();
const s: State = {
user,
back: extra.back,
error: extra.error ?? "",
avatar: null,
quick: [],
names: [],
buys: [],
incomesToday: [],
sources: [],
debts: [],
goals: [],
notes: [],
days: [],
balance: 0,
};
if (need.has("today") || need.has("sources") || need.has("history") || need.has("balance")) await settleAuto(uid);
const jobs: Promise<void>[] = [];
if (need.has("avatar")) jobs.push(getActiveAvatar(uid).then((a) => void (s.avatar = a)));
if (need.has("quick"))
jobs.push(
db.findMany(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "asc"] }).then((rows) => {
s.quick = rows.map((r) => ({ id: r.id, name: r.name, icon: r.icon, price: r.price_minor }));
}),
);
const needSources = need.has("sources") || need.has("today") || need.has("history");
let sourceRows: Source[] = [];
if (needSources) {
const rows = await db.findMany(incomeSources, { where: { user_id: uid }, orderBy: ["created_at", "asc"] });
sourceRows = rows
.map((r) => ({
id: r.id,
name: r.name,
mode: r.mode,
every: r.every ?? "",
amount: r.amount_minor,
created: r.created_at,
type: r.type || "manual",
config: parseJson(r.config),
currency: r.currency || "MAD",
active: r.active !== 0,
sort: r.sort ?? 0,
}))
.sort((a, b) => a.sort - b.sort);
s.sources = sourceRows;
}
const byId = new Map(sourceRows.map((x) => [x.id, x.name]));
const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string }): Income => ({ id: r.id, sourceId: r.source_id ?? "", source: byId.get(r.source_id ?? "") ?? "Other", amount: r.amount_minor, day: r.day });
if (need.has("today")) {
jobs.push(
db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
s.buys = rows.map(toBuy);
}),
db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {
s.incomesToday = rows.map(toIncome);
}),
);
}
if (need.has("names"))
jobs.push(
db
.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null group by lower(name) order by c desc, max(created_at) desc`)
.then((r) => void (s.names = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
);
if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));
if (need.has("goals"))
jobs.push(
Promise.all([
db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
db.findMany(goalItems, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
]).then(([rows, its]) => {
s.goals = rows.map((g) => {
const items: GoalItem[] = its.filter((i) => i.goal_id === g.id).map((i) => ({ id: i.id, name: i.name, price: i.price_minor, done: !!i.done_at }));
const left = items.filter((i) => !i.done);
return { id: g.id, title: g.title, target: left.reduce((a, i) => a + i.price, 0), saved: g.saved_minor, done: items.length > 0 && left.length === 0, items };
});
}),
);
if (need.has("notes"))
jobs.push(
db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }));
}),
);
if (need.has("history")) {
jobs.push(
Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
]).then(([bs, is]) => {
s.days = Array.from({ length: 30 }, (_, i) => {
const day = addDays(t, -i);
const b = bs.filter((x) => x.day === day);
const inc = is.filter((x) => x.day === day);
return {
day,
label: dayLabel(day),
earned: inc.reduce((a, x) => a + x.amount_minor, 0),
bought: b.reduce((a, x) => a + x.total_minor, 0),
buys: b.map(toBuy),
incomes: inc.map(toIncome),
};
}).filter((d, i) => i === 0 || d.buys.length || d.incomes.length);
}),
);
}
if (need.has("balance"))
jobs.push(
Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]).then(([i, p]) => void (s.balance = scalar(i) - scalar(p))),
);
await Promise.all(jobs);
return s;
}
const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number }): Buy => ({
id: r.id,
name: r.name,
qty: r.qty,
unit: r.unit_minor,
total: r.total_minor,
day: r.day,
at: r.created_at,
});
async function loadDebts(uid: string): Promise<DebtView[]> {
const [pe, de, pay] = await Promise.all([
db.findMany(people, { where: { user_id: uid } }),
db.findMany(debts, { where: { user_id: uid } }),
db.findMany(debtPayments, { where: { user_id: uid } }),
]);
const names = new Map(pe.map((p) => [p.id, p.name]));
const paid = new Map<string, number>();
for (const p of pay) paid.set(p.debt_id, (paid.get(p.debt_id) ?? 0) + p.amount_minor);
return de
.map((d): DebtView => {
const kind = d.kind === "item" ? "item" : "money";
return {
id: d.id,
person: names.get(d.person_id) ?? "?",
kind,
item: d.item_name || "cig",
owed: kind === "item" ? (d.item_qty ?? 0) : d.amount_minor,
paid: paid.get(d.id) ?? 0,
};
})
.filter((d) => d.owed > 0)
.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1));
}
MT_EOF
cat > "app/lib/html.ts" <<'MT_EOF'
export const esc = (s: string) => s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);
MT_EOF
cat > "app/lib/money.ts" <<'MT_EOF'
export const toMinor = (s: unknown) => {
	const n = parseFloat(String(s ?? "").replace(",", "."));
	return Number.isFinite(n) && n > 0 && n <= 1e9 ? Math.round(n * 100) : 0;
};
export const fmt = (minor: number) => {
	const v = minor / 100;
	return v.toLocaleString("en-US", { maximumFractionDigits: 2, minimumFractionDigits: Number.isInteger(v) ? 0 : 2 });
};
export const toSigned = (s: unknown) => {
const raw = String(s ?? "").trim();
if (!raw) return null;
const n = parseFloat(raw.replace(",", "."));
return Number.isFinite(n) && Math.abs(n) <= 1e9 ? Math.round(n * 100) : null;
};
MT_EOF
cat > "app/lib/password.ts" <<'MT_EOF'
// PBKDF2-SHA256 through Web Crypto. Cloudflare Workers caps PBKDF2 at 100,000 iterations.
const ITERATIONS = 100_000;
const enc = new TextEncoder();

const b64 = (b: ArrayBuffer | Uint8Array) => btoa(String.fromCharCode(...new Uint8Array(b)));
const unb64 = (s: string) => Uint8Array.from(atob(s), (ch) => ch.charCodeAt(0));

async function derive(password: string, salt: Uint8Array, iterations: number) {
	const key = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"]);
	return crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt, iterations }, key, 256);
}

export async function hashPassword(password: string): Promise<string> {
	const salt = crypto.getRandomValues(new Uint8Array(16));
	const bits = await derive(password, salt, ITERATIONS);
	return `pbkdf2$${ITERATIONS}$${b64(salt)}$${b64(bits)}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
	const [scheme, iter, salt, hash] = stored.split("$");
	if (scheme !== "pbkdf2" || !iter || !salt || !hash) return false;
	const bits = new Uint8Array(await derive(password, unb64(salt), Number(iter)));
	const want = unb64(hash);
	if (bits.length !== want.length) return false;
	let diff = 0;
	for (let i = 0; i < bits.length; i++) diff |= bits[i]! ^ want[i]!;
	return diff === 0;
}

/** Spend the same time on unknown emails so response time does not reveal which emails exist. */
export async function fakeVerify(password: string) {
	await derive(password, new Uint8Array(16), ITERATIONS);
}
MT_EOF
cat > "app/lib/sources/balance.ts" <<'MT_EOF'
import { minor, minorOr, type SourceType } from "./types.ts"

export const balance: SourceType = {
key: "balance",
label: "Balance",
auto: false,
keyed: false,
fields: [],
dayFields: [
{ name: "balance", label: "New balance", kind: "money" },
{ name: "withdrawn", label: "Withdrawn since last time", kind: "money" },
{ name: "deposited", label: "Deposited since last time", kind: "money" },
],
parseConfig: () => ({}),
entry: ({ form, last }) => {
const now = minor(form.get("balance"))
if (now === null) return "Enter your new balance"
const withdrawn = minorOr(form.get("withdrawn"), 0)
const deposited = minorOr(form.get("deposited"), 0)
if (withdrawn === null || deposited === null) return "Enter valid withdrawn and deposited amounts"
const before = last && last.balance_minor !== undefined ? Number(last.balance_minor) : null
const amount = before === null ? 0 : now - before + withdrawn - deposited
return { amount, meta: { balance_minor: now, previous_minor: before ?? now, withdrawn_minor: withdrawn, deposited_minor: deposited } }
},
}
MT_EOF
cat > "app/lib/sources/index.ts" <<'MT_EOF'
import { balance } from "./balance.ts"
import { job } from "./job.ts"
import { manual } from "./manual.ts"
import type { Json, SourceType } from "./types.ts"

export type { Ctx, Entry, Field, Json, SourceType } from "./types.ts"

const registry: Record<string, SourceType> = { manual, job, balance }

export const typeList = Object.values(registry)

export const typeOf = (key: string | null | undefined): SourceType => (key && Object.hasOwn(registry, key) ? registry[key]! : manual)

export const extKey = (sourceId: string, day: string) => `${sourceId}:${day}`

export const parseJson = (s: string | null | undefined): Json => {
try {
const v = JSON.parse(s || "{}")
return v && typeof v === "object" && !Array.isArray(v) ? (v as Json) : {}
} catch {
return {}
}
}
MT_EOF
cat > "app/lib/sources/job.ts" <<'MT_EOF'
import { minor, minorOr, num, type SourceType } from "./types.ts"

export const job: SourceType = {
key: "job",
label: "Job",
auto: false,
keyed: true,
fields: [
{ name: "fixed", label: "Fixed pay per day", kind: "money" },
{ name: "rate", label: "Rate per extra hour", kind: "money" },
],
dayFields: [
{ name: "fixed", label: "Fixed pay", kind: "money" },
{ name: "hours", label: "Extra hours", kind: "number" },
],
parseConfig: (f) => {
const fixed = minor(f.get("fixed"))
if (!fixed) return "Enter the fixed pay per day"
const rate = minorOr(f.get("rate"), 0)
if (rate === null) return "Enter a valid rate per extra hour"
return { fixed_minor: fixed, rate_minor: rate }
},
entry: ({ config, form }) => {
const fixed = minorOr(form.get("fixed"), Number(config.fixed_minor) || 0)
if (fixed === null) return "Enter a valid fixed pay"
const raw = String(form.get("hours") ?? "").trim()
const hours = raw ? num(raw) : 0
if (hours === null || hours < 0 || hours > 24) return "Extra hours must be between 0 and 24"
const rate = Number(config.rate_minor) || 0
const amount = fixed + Math.round(hours * rate)
if (amount <= 0) return "Amount must be more than 0"
return { amount, meta: { fixed_minor: fixed, hours, rate_minor: rate } }
},
}
MT_EOF
cat > "app/lib/sources/manual.ts" <<'MT_EOF'
import { minorOr, type SourceType } from "./types.ts"

export const manual: SourceType = {
key: "manual",
label: "Manual",
auto: false,
keyed: true,
fields: [],
dayFields: [{ name: "amount", label: "Amount", kind: "money" }],
parseConfig: () => ({}),
entry: ({ form, fallback }) => {
const amount = minorOr(form.get("amount"), fallback)
if (amount === null) return "Enter a valid amount"
if (amount <= 0) return "Amount must be more than 0"
return { amount, meta: {} }
},
}
MT_EOF
cat > "app/lib/sources/types.ts" <<'MT_EOF'
export type Field = { name: string; label: string; kind: "text" | "money" | "number"; placeholder?: string }
export type Json = Record<string, number | string>
export type Entry = { amount: number; meta: Json }
export type Ctx = { config: Json; form: FormData; fallback: number; last: Json | null }
export type SourceType = {
key: string
label: string
auto: boolean
keyed: boolean
fields: Field[]
dayFields: Field[]
parseConfig: (f: FormData) => Json | string
entry: (c: Ctx) => Entry | string
}

export const num = (v: unknown) => {
const raw = String(v ?? "").trim().replace(",", ".")
if (!raw) return null
const n = Number(raw)
return Number.isFinite(n) ? n : null
}

export const minor = (v: unknown) => {
const n = num(v)
return n === null || n < 0 ? null : Math.round(n * 100)
}

export const minorOr = (v: unknown, fallback: number) => (String(v ?? "").trim() ? minor(v) : fallback)
MT_EOF
cat > "app/lib/time.ts" <<'MT_EOF'
/** Days are YYYY-MM-DD in this zone. Change it if you live somewhere else. */
export const TZ = "Africa/Casablanca";

const dayFmt = new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" });
const timeFmt = new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "2-digit", minute: "2-digit" });

export const dayOf = (ms: number) => dayFmt.format(ms);
export const today = () => dayOf(Date.now());
export const hhmm = (ms: number) => timeFmt.format(ms);

export function addDays(day: string, n: number) {
	const d = new Date(`${day}T12:00:00Z`);
	d.setUTCDate(d.getUTCDate() + n);
	return d.toISOString().slice(0, 10);
}

const nice = (day: string, withYear = false) =>
	new Date(`${day}T12:00:00Z`)
		.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC", ...(withYear ? { year: "numeric" } : {}) })
		.replace(",", "");

/** "Today", "Yesterday", or "Sat 10 Oct". */
export function dayLabel(day: string) {
	const t = today();
	if (day === t) return "Today";
	if (day === addDays(t, -1)) return "Yesterday";
	return nice(day);
}

/** "Tue 13 Oct" for the page header. */
export const longDay = (day: string) => nice(day);

export function liveClockNow() {
	const now = new Date();
	const timeStr = new Intl.DateTimeFormat("en-GB", {
		timeZone: TZ,
		hour: "2-digit",
		minute: "2-digit",
		hour12: false,
	}).format(now);
	const dateStr = new Intl.DateTimeFormat("en-GB", {
		timeZone: TZ,
		weekday: "long",
		day: "numeric",
		month: "long",
	}).format(now);
	const numDate = new Intl.DateTimeFormat("en-GB", {
		timeZone: TZ,
		day: "2-digit",
		month: "2-digit",
		year: "numeric",
	}).format(now);
	const arabicDay = new Intl.DateTimeFormat("ar-MA", {
		timeZone: TZ,
		weekday: "long",
	}).format(now);
	const subDateStr = `<span class="clock-num">${numDate}</span> <span class="clock-dot">·</span> <span class="clock-ar">${arabicDay}</span>`;
	return { timeStr, dateStr, subDateStr };
}

export function getTimePeriod(): "morning" | "day" | "evening" | "night" {
	const hour = parseInt(
		new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "numeric", hour12: false }).format(new Date()),
		10
	);
	if (hour >= 5 && hour < 12) return "morning";
	if (hour >= 12 && hour < 18) return "day";
	if (hour >= 18 && hour < 22) return "evening";
	return "night";
}
MT_EOF
cat > "app/lib/users.ts" <<'MT_EOF'
import { db, oauthAccounts, passwords, quickBuys, userImages, users } from "../db/index.ts";
import { fakeVerify, hashPassword, verifyPassword } from "./password.ts";

export type User = {
	id: string;
	email: string;
	name: string;
	currency: string;
	theme: string;
	phone: string;
	bio: string;
	run_at: string;
	week_start: string;
	bg_mode: string;
	bg_url: string;
};

const normEmail = (e: string) => e.trim().toLowerCase();
const toUser = (r: any): User => ({
	id: r.id,
	email: r.email,
	name: r.name,
	currency: r.currency || "MAD",
	theme: r.theme || "dark",
	phone: r.phone ?? "",
	bio: r.bio ?? "",
	run_at: r.run_at || "06:00",
	week_start: r.week_start || "Monday",
	bg_mode: r.bg_mode || "auto",
	bg_url: r.bg_url ?? "",
});

export async function getUserById(id: string): Promise<User | null> {
	const row = await db.find(users, id);
	return row ? toUser(row) : null;
}

const newUserRow = (id: string, email: string, name: string, verified: number, now: number) => ({
	id,
	email,
	name: name || email.split("@")[0]!,
	email_verified: verified,
	currency: "MAD",
	theme: "dark",
	phone: "",
	bio: "",
	run_at: "06:00",
	week_start: "Monday",
	bg_mode: "auto",
	bg_url: "",
	created_at: now,
	updated_at: now,
});

const DEFAULT_QUICK = [
	{ name: "Smoke", icon: "Smoke", price_minor: 200 },
	{ name: "Coffee", icon: "Coffee", price_minor: 1200 },
	{ name: "Bread", icon: "Bread", price_minor: 400 },
];

type Tx = Parameters<Parameters<typeof db.transaction>[0]>[0];
const seedQuick = (tx: Tx, userId: string) =>
	tx.createMany(
		quickBuys,
		DEFAULT_QUICK.map((q, i) => ({ id: crypto.randomUUID(), user_id: userId, ...q, sort: i })),
	);

export type SignUpResult = { ok: true; user: User } | { ok: false; error: string };

export async function signUpWithPassword(input: { name: string; email: string; password: string }): Promise<SignUpResult> {
	const email = normEmail(input.email);
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return { ok: false, error: "Enter a valid email." };
	if (input.password.length < 8) return { ok: false, error: "Password needs at least 8 characters." };
	if (input.password.length > 200) return { ok: false, error: "Password is too long." };
	if (await db.findOne(users, { where: { email } })) return { ok: false, error: "That email already has an account." };

	const hash = await hashPassword(input.password);
	const now = Date.now();
	const id = crypto.randomUUID();
	const row = newUserRow(id, email, input.name.trim().slice(0, 80), 0, now);

	try {
		await db.transaction(async (tx) => {
			await tx.create(users, row);
			await tx.create(passwords, { user_id: id, hash, updated_at: now });
			await seedQuick(tx, id);
		});
	} catch {
		// Two signups with the same email at the same moment hit the UNIQUE index.
		return { ok: false, error: "That email already has an account." };
	}
	return { ok: true, user: toUser(row as User) };
}

export async function signInWithPassword(emailRaw: string, password: string): Promise<User | null> {
	const user = await db.findOne(users, { where: { email: normEmail(emailRaw) } });
	const pw = user ? await db.findOne(passwords, { where: { user_id: user.id } }) : null;
	if (!user || !pw) {
		await fakeVerify(password);
		return null;
	}
	return (await verifyPassword(password, pw.hash)) ? toUser(user as User) : null;
}

type GoogleProfile = { id?: string; email?: string | null; name?: string | null; picture?: string | null };

/** Finds the user for this Google account, links it to an existing email, or creates a new user. */
export async function upsertFromGoogle(account: { providerAccountId: string }, profile: GoogleProfile): Promise<User> {
	const link = await db.findOne(oauthAccounts, { where: { provider: "google", provider_account_id: account.providerAccountId } });
	if (link) {
		const existing = await db.find(users, link.user_id);
		if (existing) return toUser(existing as User);
	}

	const email = normEmail(profile.email ?? "");
	if (!email) throw new Error("Google did not return an email.");
	const now = Date.now();

	return db.transaction(async (tx) => {
		let user = await tx.findOne(users, { where: { email } });
		if (!user) {
			user = await tx.create(users, newUserRow(crypto.randomUUID(), email, profile.name?.trim() ?? "", 1, now), { returnRow: true });
			await seedQuick(tx, user.id);
		}
		await tx.create(oauthAccounts, {
			id: crypto.randomUUID(),
			user_id: user.id,
			provider: "google",
			provider_account_id: account.providerAccountId,
			created_at: now,
		});
		if (profile.picture) {
			const hasAvatar = await tx.findOne(userImages, { where: { user_id: user.id, kind: "avatar", is_active: 1 } });
			if (!hasAvatar) {
				await tx.create(userImages, {
					id: crypto.randomUUID(),
					user_id: user.id,
					kind: "avatar",
					source: "google",
					url: profile.picture,
					mime: "",
					size_bytes: 0,
					is_active: 1,
					created_at: now,
				});
			}
		}
		return toUser(user as User);
	});
}

export async function getActiveAvatar(userId: string): Promise<string | null> {
	const img = await db.findOne(userImages, {
		where: { user_id: userId, kind: "avatar", is_active: 1 },
		orderBy: ["created_at", "desc"],
	});
	return img?.url ?? null;
}

export async function updateProfile(userId: string, input: { name: string; email: string }) {
	const email = normEmail(input.email);
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return "Enter a valid email.";
	const clash = await db.findOne(users, { where: { email } });
	if (clash && clash.id !== userId) return "That email belongs to another account.";
	await db.update(users, userId, {
		name: input.name.trim().slice(0, 80) || email.split("@")[0]!,
		email,
		updated_at: Date.now(),
	});
	return null;
}

export async function updatePrefs(userId: string, input: { currency: string; run_at: string; week_start: string }) {
	await db.update(users, userId, {
		currency: input.currency.trim().toUpperCase().slice(0, 8) || "MAD",
		run_at: /^([01]?\d|2[0-3]):[0-5]\d$/.test(input.run_at.trim()) ? input.run_at.trim().padStart(5, "0") : "06:00",
		week_start: input.week_start.trim().slice(0, 16) || "Monday",
		updated_at: Date.now(),
	});
}

export async function setTheme(userId: string, theme: string) {
	if (theme !== "dark" && theme !== "light") return;
	await db.update(users, userId, { theme, updated_at: Date.now() });
}

export async function updateBg(userId: string, input: { mode: "auto" | "url"; url?: string }) {
	await db.update(users, userId, {
		bg_mode: input.mode,
		bg_url: input.mode === "url" ? (input.url ?? "").trim() : "",
		updated_at: Date.now(),
	});
}
MT_EOF
cat > "app/loaders.ts" <<'MT_EOF'
import { loadState, type Part, type State } from "./lib/data.ts"
import type { User } from "./lib/users.ts"
import type { ScreenKey } from "./screens/index.tsx"
export const loaders: Record<ScreenKey, { path: string; parts: Part[] }> = {
home: { path: "/home", parts: ["today", "sources", "names", "debts", "goals", "notes", "balance"] },
debts: { path: "/debts", parts: ["debts", "goals", "balance"] },
notes: { path: "/notes", parts: ["notes"] },
goals: { path: "/goals", parts: ["goals", "debts", "balance"] },
income: { path: "/income", parts: ["sources", "today"] },
plan: { path: "/plan", parts: ["goals", "debts", "sources", "today", "balance"] },
history: { path: "/history", parts: ["history"] },
profile: { path: "/profile", parts: ["avatar", "balance"] },
profileEdit: { path: "/profile/edit", parts: ["avatar"] },
settings: { path: "/settings", parts: [] },
pad: { path: "/pad", parts: [] },
}
export const isScreen = (key: string): key is ScreenKey => Object.hasOwn(loaders, key)
export const loadScreen = (user: User, key: ScreenKey, error = ""): Promise<State> => loadState(user, loaders[key].parts, { back: loaders[key].path, error })
MT_EOF
cat > "app/pages/auth.ts" <<'MT_EOF'
import { fld, GOOGLE, logo } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";
const esc = (s: string) => s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);
const form = (up: boolean, error: string) =>
	`<div class="auth-center-wrap">` +
	`<div class="auth-glass-box">` +
	`<div class="auth-logo-center">${logo("/login")}</div>` +
	`<h1 class="auth-title">${up ? "Create account" : "Sign in"}</h1>` +
	`<div class="auth-sub">${up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>` +
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">` +
	`<a class="gbtn" href="/login/google">${GOOGLE}<span>${up ? "Sign up with Google" : "Continue with Google"}</span></a>` +
	`<div class="or">or</div>` +
	(error ? `<div class="auth-err-banner" role="alert">${esc(error)}</div>` : "") +
	(up ? fld("Name", "", { name: "name", p: "Your name" }) : "") +
	fld("Email", "", { t: "email", name: "email", p: "you@email.com" }) +
	fld("Password", "", { t: "password", name: "password", p: "••••••••" }) +
	`<button class="btn full">${up ? "Create account" : "Sign in"}</button>` +
	`<div class="auth-switch-wrap"><a class="lnk-switch" href="${up ? "/login" : "/signup"}">${
		up ? "Already have an account? <b>Sign in</b>" : "Don't have an account? <b>Create account</b>"
	}</a></div>` +
	`</form>` +
	`</div>` +
	`</div>`;
export const loginPage = (error = "") =>
	page({ title: "Sign in", path: "/login", desc: "Sign in to Moneytracker, your quiet personal money tracker.", user: false, full: true, mobile: form(false, error), desktop: form(false, error) });
export const signupPage = (error = "") =>
	page({ title: "Create account", path: "/signup", desc: "Create a free Moneytracker account and start tracking your spending, debts and goals.", user: false, full: true, mobile: form(true, error), desktop: form(true, error) });
MT_EOF
cat > "app/pages/screens.ts" <<'MT_EOF'
import { esc } from "../lib/html.ts";
import type { DayRow, DebtView, Goal, GoalItem, Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { fld, hd, ic, sec, tg, themeSwitch } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";
function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);
	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${esc(n)} ${fmt(a)}`).join(" · ") || "";
	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";
	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = Math.min(Math.max(0, s.balance), wishTarget);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;
	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}
const cur = (s: State) => esc(s.user.currency);
const LANG = "English";
const back = (s: State) => `<input type="hidden" name="back" value="${esc(s.back)}">`;
const err = (s: State) => (s.error ? `<div class="neg" role="alert" style="margin:10px 0;font-size:13px">${esc(s.error)}</div>` : "");
const covered = (s: State) => new Map(s.goals.map((g) => [g.id, Math.min(Math.max(0, s.balance), g.target)] as const));
const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round(((covered(s).get(g.id) ?? 0) / g.target) * 100)) : 0);
const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target;
const avatar = (s: State) => {
	const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : "";
	return `<div class="av"${url ? ` style="background:url('${esc(url)}') center/cover"` : ""}>${url ? "" : esc((s.user.name.trim()[0] ?? "?").toUpperCase())}</div>`;
};
const debtRow = (s: State, d: DebtView) => {
	const unit = d.kind === "money" ? cur(s) : esc(d.item);
	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
	const all = d.kind === "money" ? plain(d.owed) : String(d.owed);
	const panel = (flag: string, action: string, title: string, btn: string) =>
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off">${flag === "data-payp" ? `<button type="button" class="all" data-all="${all}" aria-label="Fill the full amount">All</button>` : ""}<span class="mu">${unit}</span></div><button class="btn xs">${btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove ${esc(d.person)} from the list without marking it paid?" aria-label="Remove without paying">${ic("trash")}</button></div></form>`;
	return (
		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span>${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
		panel("data-addp", "/debts", "Add to", "Add") +
		panel("data-payp", "/debts/pay", "Pay", "Pay") +
		`</div>`
	);
};
const debtList = (s: State) => s.debts.map((d) => debtRow(s, d)).join("") || '<div class="lb" style="padding:8px 0">Nobody to pay. All clear.</div>';
const nameChips = (names: string[]) =>
	names.length ? `<div class="chips nm">${names.map((n) => `<span class="chip" data-nm="${esc(n)}">${esc(n)}</span>`).join("")}</div>` : "";
const bigAdd = (label: string, target = "", right = false) =>
	`<button type="button" class="addb${right ? " r" : ""}" data-bigadd${target ? ` data-for="${target}"` : ""} aria-label="${label}">${ic("plus")}</button>`;
const listCard = (wide: boolean, title: string, right: string, body: string, target: string, label: string) =>
	wide
		? `<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>${title}</span><span class="lb">${right}</span></div>${body}</div>${bigAdd(label, target, true)}</div>`
		: `<div class="cd bgc rgt"><div class="ct"><div class="tg">${title}</div><div class="cb">${body}</div></div>${bigAdd(label, target, true)}</div>`;
const addDebtPanel = (s: State) =>
	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><div class="iw"><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><span class="mu">${cur(s)}</span></div><button class="btn full">Add</button></form>`;
const owePair = (s: State) => {
	const c = calc(s);
	return `<div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>`;
};
const chev = `<span class="chev">${ic("chev")}</span>`;
const tgp = (t: string, key: string, b: string) =>
	`<div class="cd"><div class="tg th2"><span>${t}</span><button type="button" class="pl" data-plus="${key}" aria-label="Add">${ic("plus")}</button></div><div class="cb">${b}</div></div>`;
const spendRow = (s: State, id: string, n: string, sub: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${sub}</div></div><span class="rt"><b class="sp">${a}</b><form method="post" action="/buy/delete" style="display:contents" data-confirm="Undo this buy? The money comes back.">${back(s)}<input type="hidden" name="id" value="${id}"><button class="ub" aria-label="Undo buy">${ic("undo")}</button></form></span></div>`;
const oweM = (s: State, open: boolean, key: string) => {
const c = calc(s);
return xcard(key, open, "I owe", `<b class="big2 sp">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span>`, debtList(s), `<div class="xl"><span>${new Set(s.debts.map((d) => d.person)).size === 1 ? "1 person" : `${new Set(s.debts.map((d) => d.person)).size} people`}</span></div>`, addDebtPanel(s), "Add debt");
};
const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="sc bgc">${bigAdd("Add debt")}<div class="ct"><details data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>${addDebtPanel(s)}</div></div>`;
};
const roadChips = (s: State) =>
	[
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = roadChips(s);
	return `<div class="cd jarc"><i class="jar" style="width:${c.pct}%"></i><div class="jin"><div class="tg">Road to goals</div><div class="cb"><div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}</div></div></div>`;
};
const xcard = (key: string, open: boolean, title: string, head: string, body: string, foot: string, form: string, label: string, jar = -1) =>
`<div class="xc${label ? "" : " xn"}"><details class="xd" data-keep-open="${key}"${open ? " open" : ""}><summary class="xh osum">${jar >= 0 ? `<i class="xj${jar >= 100 ? " full" : ""}" style="width:${jar}%"></i>` : ""}<div><div class="tg0">${title}</div>${head ? `<div class="ow">${head}</div>` : ""}</div><span class="chev">${ic("chev")}</span></summary><div class="xb">${body}</div><div class="xf${foot ? "" : " xo"}">${foot}${form}</div></details>${label ? `<button type="button" class="xp" data-xplus aria-label="${label}">${ic("plus")}</button>` : ""}</div>`;
const goalLeft = (s: State, g: Goal) => (g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`);
const itemRow = (s: State, it: GoalItem, manage: boolean) => {
const ok = s.balance >= it.price;
const hid = `${back(s)}<input type="hidden" name="id" value="${it.id}">`;
const cls = `gi${it.done ? " gdone" : ""}`;
const name = `<span class="gn">${esc(it.name)}</span><span class="lb">${fmt(it.price)}</span>`;
if (!manage) return `<div class="${cls}">${name}<span class="wb">${it.done ? "" : `<form method="post" action="/goals/buy" style="display:contents" data-confirm="Mark ${esc(it.name)} as bought? It will be added as a spend.">${hid}<button class="btn xs${ok ? "" : " off"}"${ok ? "" : " disabled"}>Bought</button></form>`}</span></div>`;
const del = `<form method="post" action="/goals/item/delete" style="display:contents" data-confirm="Remove ${esc(it.name)} from this goal?">${hid}<button class="ub" aria-label="Remove ${esc(it.name)}">${ic("trash")}</button></form>`;
const edit = it.done ? "" : `<button type="button" class="ub" data-pay aria-label="Edit ${esc(it.name)}">${ic("edit")}</button>`;
const panel = it.done ? "" : `<form method="post" action="/goals/item/edit" class="ad" data-payp hidden>${hid}<label>Edit ${esc(it.name)}</label><div class="ln"><input class="in f" name="name" value="${esc(it.name)}" autocomplete="off" required><input class="in pr2" name="price" value="${plain(it.price)}" placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn xs">Save</button></div></form>`;
return `<div class="dbw"><div class="${cls}">${name}<span class="wb">${edit}${del}</span></div>${panel}</div>`;
};
const goalRow = (s: State, g: Goal, manage: boolean) => {
const pct = pctOf(s, g);
const info = `<div class="dn"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt s${pct >= 100 ? " full" : ""}"><i style="width:${pct}%"></i></div></div>`;
const items = g.items.map((it) => itemRow(s, it, manage)).join("");
if (!manage) return `<div class="gw"><div class="db">${info}</div>${items}</div>`;
const del = `<form method="post" action="/goals/delete" style="display:contents" data-confirm="Delete ${esc(g.title)} and all its items?">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="ub" aria-label="Delete ${esc(g.title)}">${ic("trash")}</button></form>`;
const add = `<form method="post" action="/goals/item" class="ad" data-addp hidden>${back(s)}<input type="hidden" name="goal_id" value="${g.id}"><label>Add item to ${esc(g.title)}</label><div class="ln"><input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required><input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn xs">Add</button></div></form>`;
const ren = `<form method="post" action="/goals/edit" class="ad" data-payp hidden>${back(s)}<input type="hidden" name="id" value="${g.id}"><label>Rename goal</label><div class="ln"><input class="in f" name="name" value="${esc(g.title)}" autocomplete="off" required><button class="btn xs">Save</button></div></form>`;
return `<div class="gw"><div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add item to ${esc(g.title)}">${ic("plus")}</button>${info}<span class="wb"><button type="button" class="ub" data-pay aria-label="Rename ${esc(g.title)}">${ic("edit")}</button>${del}</span></div>${add}${ren}</div>${items}</div>`;
};
const goalList = (s: State, manage: boolean) => s.goals.map((g) => goalRow(s, g, manage)).join("") || `<div class="lb" style="padding:8px 0">${manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</div>`;
const goalForm = (s: State) => `<form method="post" action="/goals" class="sf xfm" data-adp hidden>${back(s)}<input class="in" name="name" placeholder="Goal name" autocomplete="off" required><button class="btn full">Add goal</button></form>`;
const goalStat = (s: State) => {
const target = s.goals.reduce((a, g) => a + g.target, 0);
const saved = Math.min(Math.max(0, s.balance), target);
const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0;
return { target, pct, toGo: Math.max(0, target - saved) };
};
const goalsX = (s: State, open: boolean, key: string, manage: boolean) => {
const g = goalStat(s);
const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${cur(s)} to go`;
const head = `<b class="big2">${g.pct}<small>%</small></b><span class="lb">${sub}</span>`;
if (manage) return xcard(key, open, "Goals", head, goalList(s, true), '<div class="xl"><span>Pencil edits, bin removes</span></div>', goalForm(s), "Add goal", g.pct);
return xcard(key, open, "Goals", head, goalList(s, false), `<div class="xl"><span>Left to buy ${fmt(g.target)} ${cur(s)}</span><a class="lnk" href="/goals">Manage</a></div>`, "", "", g.pct);
};
const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);
const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id);
const srcRows = (s: State) =>
	s.sources
		.map((x) => {
			const got = gotToday(s, x);
			const sum = got.reduce((a, i) => a + i.amount, 0);
			const auto = x.mode === "auto";
			const tag = !x.active ? "paused" : auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
			const fixed = srcAmount(x);
			const hid = (v: string) => `${back(s)}<input type="hidden" name="id" value="${v}">`;
			const del = `<form method="post" action="/income/source/delete" style="display:contents" data-confirm="Delete ${esc(x.name)}? What it already paid stays in your balance.">${hid(x.id)}<button class="ub" aria-label="Delete ${esc(x.name)}">${ic("trash")}</button></form>`;
			let main: string;
			if (!x.active) main = `<form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Resume</button></form>`;
			else if (auto)
				main = `<b class="ea">+${fmt(x.amount)}</b><form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Pause</button></form>`;
			else if (got.length)
				main = `<button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${hid(got[0]!.id)}<button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form>`;
			else if (fixed)
				main = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(fixed)}</button></form>`;
			else
				main = `<form method="post" action="/income/add" class="ln" style="gap:6px">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required><button class="btn xs o">Add</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div></div><span class="rt">${main}${del}</span></div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';
const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips" style="margin:10px 0 4px"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div><div class="lb" style="margin-bottom:2px">Manual: you tap it, once a day. Auto: added for you.</div>`;
const addSourceForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/income" id="${id}" class="${wide ? "sc" : "cd"} spf" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off"></div>${modeChips}<button class="btn full">Add source</button></form>`;
const srcForm = (s: State) => `<form method="post" action="/income" class="sf xfm" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off"></div>${modeChips}<button class="btn full">Add source</button></form>`;
const plain = (n: number) => (n / 100).toFixed(2).replace(/\.00$/, "");
const manageRow = (s: State, x: Source) => {
const auto = x.mode === "auto";
const tag = !x.active ? "paused" : auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
const fixed = srcAmount(x);
const hid = `${back(s)}<input type="hidden" name="id" value="${x.id}">`;
const toggle = `<form method="post" action="/income/toggle" style="display:contents">${hid}<button class="btn xs o">${x.active ? "Pause" : "Resume"}</button></form>`;
const del = `<form method="post" action="/income/source/delete" style="display:contents" data-confirm="Delete ${esc(x.name)}? What it already paid stays in your balance.">${hid}<button class="ub" aria-label="Delete ${esc(x.name)}">${ic("trash")}</button></form>`;
const panel = `<form method="post" action="/income/edit" class="ad" data-addp hidden>${hid}<label>Edit ${esc(x.name)}</label><div class="ln"><input class="in f" name="name" value="${esc(x.name)}" autocomplete="off" required><input class="in pr2" name="amount" value="${fixed ? plain(fixed) : ""}" placeholder="Amount" inputmode="decimal" autocomplete="off"><button class="btn xs">Save</button></div></form>`;
return `<div class="dbw"><div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div>${fixed ? `<div class="lb">${fmt(fixed)} ${cur(s)}</div>` : ""}</div><span class="rt">${toggle}<button type="button" class="ub" data-tg aria-label="Edit ${esc(x.name)}">${ic("edit")}</button>${del}</span></div>${panel}</div>`;
};
const incomeX = (s: State) =>
xcard("income", true, "Income sources", `<b class="big2">${s.sources.length}</b><span class="lb">${s.sources.filter((x) => x.active).length} active</span>`, s.sources.map((x) => manageRow(s, x)).join("") || '<div class="lb" style="padding:8px 0">No sources yet. Tap + to add one.</div>', "", srcForm(s), "Add source");
const homeRow = (s: State, x: Source) => {
const got = gotToday(s, x);
const sum = got.reduce((a, i) => a + i.amount, 0);
const fixed = srcAmount(x);
const hid = (v: string) => `${back(s)}<input type="hidden" name="id" value="${v}">`;
let main: string;
if (x.mode === "auto") main = `<b class="ea">+${fmt(x.amount)}</b>`;
else if (got.length) main = `<button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${hid(got[0]!.id)}<button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form>`;
else if (fixed) main = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(fixed)}</button></form>`;
else main = `<form method="post" action="/income/add" class="ln" style="gap:6px">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required><button class="btn xs o">Add</button></form>`;
return `<div class="rw"><div><div>${esc(x.name)}</div></div><span class="rt">${main}</span></div>`;
};
const homeInc = (s: State) => {
const c = calc(s);
const rows = s.sources.filter((x) => x.active).map((x) => homeRow(s, x)).join("") + s.incomesToday.filter((i) => !i.sourceId).map((i) => incRow(s, i)).join("");
const form = `<form method="post" action="/history/income" class="sf xfm" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="amount" placeholder="Other income today" inputmode="decimal" autocomplete="off" required><button class="btn">Add</button></div></form>`;
return xcard("inc", true, "Income today", `<b class="big2">+${fmt(c.earned)} <small>${cur(s)}</small></b><span class="lb">${c.earnedLine}</span>`, rows || '<div class="lb" style="padding:8px 0">No sources yet.</div>', "", form, "Add other income");
};
const incD = (s: State, title = "Income sources", id = "f-src-d") => addSourceForm(s, true, id) + listCard(true, title, `+${fmt(calc(s).earned)} today`, srcRows(s), id, "Add source");
const cardsM = (s: State) => {
	const c = calc(s);
	const row = (cls: string, big: string) => `<div class="big2 ${cls}" style="white-space:nowrap">${big} <small>${cur(s)}</small></div>`;
	return `<div class="two">${tg("Earned today", row("", `+${fmt(c.earned)}`))}${tg("Bought today", row("", `−${fmt(c.bought)}`))}</div>`;
};
const buyRows = (s: State) =>
	`<div>${
		s.buys
			.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), `${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`, `−${fmt(b.total)}`))
			.join("") || '<div class="lb" style="padding:8px 0">Nothing bought today.</div>'
	}</div>`;
const spendForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/buy" id="${id}" class="${wide ? "sc" : "cd"} spf" data-sp data-adp hidden>${back(s)}${nameChips(s.names)}<div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required></div><button class="btn full">Add a spend</button></form>`;
const spendFoot = (s: State) => `<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>${back(s)}${nameChips(s.names)}<div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required></div><button class="btn full">Add a spend</button></form>`;
const buysX = (s: State) => xcard("buys", true, "Today's buys", "", buyRows(s), "", spendFoot(s), "Add a spend");
const buysD = (s: State) => spendForm(s, true, "f-buy-d") + listCard(true, "Today's buys", `${s.buys.length}`, buyRows(s), "f-buy-d", "Add a spend");
const hero = (s: State) => {
	const c = calc(s);
	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v">+${fmt(c.earned)}</div>${c.earnedLine ? `<div class="lb">${c.earnedLine}</div>` : ""}</div><div><div class="lb">Bought today</div><div class="v">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
};
const noteList = (s: State, key: string) => {
	if (key === "dash")
		return `<div data-list="dash">${
			s.notes
				.slice(-2)
				.reverse()
				.map((n) => `<div class="rw"><span>${esc(n.body)}</span><span class="lb">${hhmm(n.at)}</span></div>`)
				.join("") || '<div class="lb" style="padding:8px 0">No notes yet.</div>'
		}</div>`;
	let last = "";
	let out = "";
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at));
		if (label !== last) {
			out += `<div class="day"><span>${esc(label)}</span></div>`;
			last = label;
		}
		out +=
			`<div class="msg" data-id="${n.id}"><div class="bub">${esc(n.body)}</div><div class="meta">${n.edited ? "edited · " : ""}${hhmm(n.at)}</div>` +
			`<div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button>` +
			`<form method="post" action="/notes/delete" style="display:contents" data-confirm="Delete this note?">${back(s)}<input type="hidden" name="id" value="${n.id}"><button class="btn xs dng">Delete</button></form></div></div>`;
	}
	return `<div data-list="${key}">${out}</div>`;
};
const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';
const composer = (s: State, key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes">${back(s)}<input type="hidden" name="id" data-eid><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;
const noteD = (s: State) =>
	sec(
		"Note to yourself",
		`${s.notes.length} saved`,
		`<form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0">${back(s)}<input type="hidden" name="id" data-eid><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></form>${noteList(s, "dash")}`,
	);
const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`;
const incRow = (s: State, i: Income) =>
`<div class="by"><div><div>${esc(i.source)}</div></div><span class="rt"><b class="ea">+${fmt(i.amount)}</b><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(i.amount)} from ${esc(i.source)}?">${back(s)}<input type="hidden" name="id" value="${i.id}"><button class="ub" aria-label="Undo income">${ic("undo")}</button></form></span></div>`;
const dayItems = (s: State, d: DayRow) =>
d.incomes.map((i) => incRow(s, i)).join("") +
d.buys.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : "", `−${fmt(b.total)}`)).join("");
const dayForms = (s: State, wide: boolean) => {
const t = today();
const date = `<input class="in" type="date" name="day" value="${t}" max="${t}" required>`;
const body =
`<form method="post" action="/buy">${back(s)}<div class="ln"><input class="in" name="label" placeholder="Item" autocomplete="off" required><input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required></div><div class="ln" style="margin-top:8px">${date}<button class="btn xs">Add buy</button></div></form>` +
`<form method="post" action="/history/income" style="margin-top:14px">${back(s)}<div class="ln"><input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required>${date}<button class="btn xs">Add income</button></div></form>`;
return wide ? sec("Add to any day", "", body) : tg("Add to any day", body);
};
const histM = (s: State) =>
err(s) +
dayForms(s, false) +
s.days
.map((d) =>
tg(
esc(d.label),
`<div class="l1"><span><span class="lb">Earned</span> <b class="ea">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${dayItems(s, d)}`,
),
)
.join("");
const histD = (s: State) => {
const e = s.days.reduce((a, d) => a + d.earned, 0);
const b = s.days.reduce((a, d) => a + d.bought, 0);
return sec(
"Last 30 days",
`+${fmt(e)} earned · −${fmt(b)} bought`,
'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="ea">+${fmt(d.earned)}</b><b class="sp">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b><div>${dayItems(s, d)}</div></div>`).join(""),
);
};
const editFields = (s: State) =>
	fld("Name", esc(s.user.name), { f: true, name: "name" }) +
	fld("Email", esc(s.user.email), { t: "email", name: "email" });
const profileForm = (s: State, cancel: string) =>
	`<form method="post" action="/profile/edit">${err(s)}${editFields(s)}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="${cancel}">Cancel</a></div></form>`;
const prefsForm = (s: State) =>
	`<form method="post" action="/settings">${fld("Currency", esc(s.user.currency), { name: "currency" })}${fld("Auto income runs at", esc(s.user.run_at), { name: "run_at" })}${fld("Week starts", esc(s.user.week_start), { name: "week" })}<button class="btn" style="margin-top:14px">Save</button></form>`;
const dataButtons = `<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>`;
const balanceCard = (s: State, edit = false) =>
	`<div class="cd"><div class="tg">Total balance</div><div class="cb"><div class="ow" style="margin:0"><span style="display:flex;align-items:center;gap:10px"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></span>${edit ? '<button type="button" class="lnk" data-edit-bal>Edit balance</button>' : ""}</div>${edit ? `<div data-balf hidden>${balanceForm(s)}</div>` : ""}</div></div>`;
const plainBal = (s: State) => (s.balance / 100).toFixed(2).replace(/\.00$/, "");
const balanceForm = (s: State) =>
	`<form method="post" action="/profile/balance">${back(s)}<div class="fl"><label>Balance (${cur(s)})</label><input class="in f" name="balance" inputmode="decimal" value="${plainBal(s)}" autocomplete="off" required></div><button class="btn full" style="margin-top:14px">Update balance</button></form>`;
const profileM = (s: State) =>
	err(s) +
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div><div class="chips" style="justify-content:center;margin-top:10px"><span class="chip" style="cursor:default">${cur(s)}</span><span class="chip" style="cursor:default">${LANG}</span></div></div></div>` +
	balanceCard(s, true) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);
const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));
const settingsM = (s: State) =>
	err(s) +
	tg("Money & income", prefsForm(s)) +
	tg("Data", dataButtons) + '<div class="lb" style="text-align:center;margin:18px 0">Moneytracker v1.0 · stable</div>';
const settingsD = (s: State) =>
	`<div class="hd"><h1 class="t">Settings</h1><span class="lb">${cur(s)} · ${LANG}</span></div>` +
	err(s) +
	`<div class="g3"><div>${balanceCard(s, true)}${sec("Profile", "", profileForm(s, "/home"))}${sec(
		"Account",
		"",
		`<form method="post" action="/logout"><button class="btn o">Log out</button></form>`,
	)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Money & income", "", prefsForm(s))}${sec(
		"Data",
		"",
		dataButtons,
	)}</div></div>`;
const dashboardD = (s: State) =>
	hero(s) +
	`<div class="g2"><div>${buysD(s)}</div><div>${oweD(s, false, "owe")}${incD(s, "Income today")}${noteD(s)}</div></div>`;
const debtsD = (s: State) => {
	const c = calc(s);
	return (
		`<div class="hd"><h1 class="t">Debts</h1><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span></div>` +
		`<div class="g3"><div>${oweD(s, true, "owe-page")}</div><div>${sec(
			"How it works",
			"",
			'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div>',
		)}</div></div>`
	);
};
const notesD = (s: State) => `<div class="chat" data-x>${chatHead}${noteList(s, "d")}<div style="margin:30px 0 0">${composer(s, "d")}</div></div>`;
const planD = (s: State) => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${goalsX(s, true, "goals-d", true)}</div><div>${incD(s)}</div></div>`;
const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 30 days</span></div>${err(s)}${dayForms(s, true)}${histD(s)}`;
const base = (s: State) => ({
	theme: s.user.theme,
});
const homeBar = () => `<div style="text-align:right"><div style="font-size:14px;font-weight:600;letter-spacing:-.01em">Today</div><div class="lb">${longDay(today())}</div></div>`;
export const homePage = (s: State) =>
	page({
		...base(s),
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobileBar: homeBar(),
		mobile: err(s) + balanceCard(s) + cardsM(s) + homeInc(s) + buysX(s) + goalsX(s, false, "goals", false) + oweM(s, false, "owe"),
		desktop: err(s) + dashboardD(s),
	});
export const debtsPage = (s: State) =>
	page({
		...base(s),
		title: "Debts",
		mobileTab: "home",
		desktopTab: "home",
		mobile: err(s) + hd("Debts", s.debts.map((d) => esc(d.person)).slice(0, 2).join(" + ")) + goalM(s) + oweM(s, true, "owe-page"),
		desktop: err(s) + debtsD(s),
	});
export const notesPage = (s: State) =>
	page({ ...base(s), title: "Notes", mobileTab: "notes", desktopTab: "notes", mobile: chatHead + noteList(s, "m"), dock: composer(s, "m"), desktop: notesD(s) });
export const goalsPage = (s: State) =>
	page({ ...base(s), title: "Goals", mobileTab: "home", desktopTab: "plan", mobile: hd("Goals", "add, edit, remove") + err(s) + goalsX(s, true, "goals-page", true), desktop: err(s) + planD(s) });
export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "income", desktopTab: "income", mobile: err(s) + hd("Income", calc(s).earned ? `+${fmt(calc(s).earned)} today` : "") + incomeX(s), desktop: err(s) + '<div class="hd"><h1 class="t">Income</h1><span></span></div>' + incomeX(s) });
export const padPage = (s: State) => page({ ...base(s), title: "Pad", mobileTab: "pad", desktopTab: "pad", mobile: "", desktop: "" });
export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 30 days") + histM(s), desktop: historyD(s) });
export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });
export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });
export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
MT_EOF
cat > "app/pages/screens.ts.bak" <<'MT_EOF'
import { esc } from "../lib/html.ts";
import type { DebtView, Goal, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { chips, fld, hd, ic, sec, tg, themeSwitch } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";

function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);

	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${esc(n)} ${fmt(a)}`).join(" · ") || "nothing yet";

	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";

	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = Math.min(Math.max(0, s.balance), wishTarget);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;

	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}

const cur = (s: State) => esc(s.user.currency);
const back = (s: State) => `<input type="hidden" name="back" value="${esc(s.back)}">`;
const err = (s: State) => (s.error ? `<div class="neg" role="alert" style="margin:10px 0;font-size:13px">${esc(s.error)}</div>` : "");
/** How much of the balance covers each wish (each wish is compared with the whole balance). */
const covered = (s: State) => new Map(s.goals.map((g) => [g.id, Math.min(Math.max(0, s.balance), g.target)] as const));
const pctOf = (s: State, g: Goal) => (g.target ? Math.min(100, Math.round(((covered(s).get(g.id) ?? 0) / g.target) * 100)) : 0);
const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target;

const avatar = (s: State) => {
	const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : "";
	return `<div class="av"${url ? ` style="background:url('${esc(url)}') center/cover"` : ""}>${url ? "" : esc((s.user.name.trim()[0] ?? "?").toUpperCase())}</div>`;
};

const debtRow = (s: State, d: DebtView) => {
	const unit = d.kind === "money" ? cur(s) : esc(d.item);
	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
	const panel = (flag: string, action: string, title: string, btn: string) =>
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off"><span class="mu">${unit}</span><button class="btn xs">${btn}</button>${flag === "data-addp" ? `<button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove this debt from ${esc(d.person)}? Use it for a mistake." aria-label="Remove debt">${ic("trash")}</button>` : ""}</div></form>`;
	return (
		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="sp">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
		panel("data-addp", "/debts", "Add to", "Add") +
		panel("data-payp", "/debts/pay", "Pay", "Pay") +
		`</div>`
	);
};

const debtList = (s: State) => s.debts.map((d) => debtRow(s, d)).join("") || '<div class="lb" style="padding:8px 0">Nobody to pay. All clear.</div>';

const nameChips = (names: string[]) =>
	names.length ? `<div class="chips nm">${names.map((n) => `<span class="chip" data-nm="${esc(n)}">${esc(n)}</span>`).join("")}</div>` : "";

const bigAdd = (label: string, target = "", right = false) =>
	`<button type="button" class="addb${right ? " r" : ""}" data-bigadd${target ? ` data-for="${target}"` : ""} aria-label="${label}">${ic("plus")}</button>`;

/** A list card with the big + on its right. The + opens the form card that sits right above it. */
const listCard = (wide: boolean, title: string, right: string, body: string, target: string, label: string) =>
	wide
		? `<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>${title}</span><span class="lb">${right}</span></div>${body}</div>${bigAdd(label, target, true)}</div>`
		: `<div class="cd bgc rgt"><div class="ct"><div class="tg">${title}</div><div class="cb">${body}</div></div>${bigAdd(label, target, true)}</div>`;

const addDebtPanel = (s: State) =>
	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

const owePair = (s: State) => {
	const c = calc(s);
	return `<div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>`;
};

const chev = `<span class="chev">${ic("chev")}</span>`;

const tgp = (t: string, key: string, b: string) =>
	`<div class="cd"><div class="tg th2"><span>${t}</span><button type="button" class="pl" data-plus="${key}" aria-label="Add">${ic("plus")}</button></div><div class="cb">${b}</div></div>`;

const spendRow = (s: State, id: string, n: string, sub: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${sub}</div></div><span class="rt"><b class="sp">${a}</b><form method="post" action="/buy/delete" style="display:contents" data-confirm="Undo this buy? The money comes back.">${back(s)}<input type="hidden" name="id" value="${id}"><button class="ub" aria-label="Undo buy">${ic("undo")}</button></form></span></div>`;

const oweM = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="cd bgc">${bigAdd("Add debt")}<div class="ct"><details class="dd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">I owe</div><div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>${chev}</summary><div class="cb">${debtList(s)}</div></details>${addDebtPanel(s)}</div></div>`;
};

const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="sc bgc">${bigAdd("Add debt")}<div class="ct"><details data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>${addDebtPanel(s)}</div></div>`;
};

const roadChips = (s: State) =>
	[
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");

/** The whole card fills from the left, like a jar, as you get closer to your goals. */
const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = roadChips(s);
	return `<div class="cd jarc"><i class="jar" style="width:${c.pct}%"></i><div class="jin"><div class="tg">Road to goals</div><div class="cb"><div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}</div></div></div>`;
};

const goalFold = (s: State, key: string) => {
	const c = calc(s);
	const chipHtml = roadChips(s);
	return `<div class="cd jarc"><i class="jar" style="width:${c.pct}%"></i><details class="dd jin" data-keep-open="${key}"><summary class="osum"><div class="tg0">Road to goals</div><div class="ow"><b class="big2">${c.pct}<small>%</small></b><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chev}</summary><div class="cb">${chipHtml ? `<div class="chips">${chipHtml}</div>` : '<div class="lb">Add a wish or a debt to start.</div>'}</div></details></div>`;
};

const goalLeft = (s: State, g: Goal) => (g.target ? (canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`) : "no price");

const addWishPanel = (s: State) =>
	`<form method="post" action="/goals" class="sf adp" data-adp hidden>${back(s)}<input class="in" name="name" data-name placeholder="What do you want?" autocomplete="off" required><input class="in" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

const boughtBtn = (s: State, g: Goal) =>
	`<form method="post" action="/goals/buy" style="display:contents" data-confirm="Mark ${esc(g.title)} as bought? It will be added as a spend.">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="btn xs${canBuy(s, g) ? "" : " off"}"${canBuy(s, g) ? "" : " disabled"}>Bought</button></form>`;

const delWish = (s: State, g: Goal) =>
	`<form method="post" action="/goals/delete" style="display:contents" data-confirm="Delete ${esc(g.title)} from your wish list?">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="ub" aria-label="Delete ${esc(g.title)}">${ic("trash")}</button></form>`;

const wishRow = (s: State, g: Goal) =>
	`<div class="db"><div class="dn"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt s"><i style="width:${pctOf(s, g)}%"></i></div></div><span class="wb">${boughtBtn(s, g)}${delWish(s, g)}</span></div>`;

const wishList = (s: State) => s.goals.map((g) => wishRow(s, g)).join("") || '<div class="lb" style="padding:8px 0">Nothing on the list.</div>';

const wishTotal = (s: State) => `${fmt(s.goals.reduce((a, g) => a + g.target, 0))} ${cur(s)}`;

/** Wish list: add with the big +, expand to buy or delete each wish. Same idea as "I owe". */
const wishesM = (s: State, open: boolean, key: string) =>
	`<div class="cd bgc">${bigAdd("Add wish")}<div class="ct"><details class="dd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">Wish list</div><div class="ow"><b class="big2">${s.goals.length}</b><span class="lb">${wishTotal(s)}</span></div>${chev}</summary><div class="cb">${wishList(s)}</div></details>${addWishPanel(s)}</div></div>`;

const wishD = (s: State) =>
	`<div class="sc bgc">${bigAdd("Add wish")}<div class="ct"><details data-keep-open="wish-page" open><summary class="sh"><span>Wish list</span><span class="rr"><span class="lb">${s.goals.length} · ${wishTotal(s)}</span>${chev}</span></summary>${wishList(s)}</details>${addWishPanel(s)}</div></div>`;

const debtsM = (s: State) =>
	`<div class="cd bgc">${bigAdd("Add debt")}<div class="ct"><div class="tg">Debts</div><div class="cb">${owePair(s)}${debtList(s)}</div>${addDebtPanel(s)}</div></div>`;

const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);

const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id);

const srcRows = (s: State) =>
	s.sources
		.map((x) => {
			const got = gotToday(s, x);
			const sum = got.reduce((a, i) => a + i.amount, 0);
			const auto = x.mode === "auto";
			const tag = !x.active ? "paused" : auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
			const fixed = srcAmount(x);
			const hid = (v: string) => `${back(s)}<input type="hidden" name="id" value="${v}">`;
			const del = `<form method="post" action="/income/source/delete" style="display:contents" data-confirm="Delete ${esc(x.name)}? What it already paid stays in your balance.">${hid(x.id)}<button class="ub" aria-label="Delete ${esc(x.name)}">${ic("trash")}</button></form>`;
			let main: string;
			if (!x.active) main = `<form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Resume</button></form>`;
			else if (auto)
				main = `<b class="ea">+${fmt(x.amount)}</b><form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Pause</button></form>`;
			else if (got.length)
				main = `<button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${hid(got[0]!.id)}<button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form>`;
			else if (fixed)
				main = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(fixed)}</button></form>`;
			else
				main = `<form method="post" action="/income/add" class="ln" style="gap:6px">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required><button class="btn xs o">Add</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div></div><span class="rt">${main}${del}</span></div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';

const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips" style="margin:10px 0 4px"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div><div class="lb" style="margin-bottom:2px">Manual: you tap it, once a day. Auto: added for you.</div>`;

/** Always visible under the sources: name and amount on one line, then the button. */
const addSourceForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/income" id="${id}" class="${wide ? "sc" : "cd"} spf" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off"></div>${modeChips}<button class="btn full">Add source</button></form>`;

const todayLine = (s: State) => `<span class="tl">${calc(s).earned ? `+${fmt(calc(s).earned)} today · ${calc(s).earnedLine}` : "nothing earned today yet"}</span>`;

const incomeM = (s: State) => addSourceForm(s, false, "f-src-p") + listCard(false, `Sources${todayLine(s)}`, "", srcRows(s), "f-src-p", "Add source");

const incD = (s: State, title = "Income sources", id = "f-src-d") => addSourceForm(s, true, id) + listCard(true, title, `+${fmt(calc(s).earned)} today`, srcRows(s), id, "Add source");

const cardsM = (s: State) => {
	const c = calc(s);
	const row = (cls: string, big: string) => `<div class="big2 ${cls}" style="white-space:nowrap">${big} <small>${cur(s)}</small></div>`;
	return `<div class="two">${tg("Earned today", row("ea", `+${fmt(c.earned)}`))}${tg("Bought today", row("sp", `−${fmt(c.bought)}`))}</div>`;
};

const buyRows = (s: State) =>
	`<div>${
		s.buys
			.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), `${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`, `−${fmt(b.total)}`))
			.join("") || '<div class="lb" style="padding:8px 0">Nothing bought today.</div>'
	}</div>`;

const spendForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/buy" id="${id}" class="${wide ? "sc" : "cd"} spf" data-sp data-adp hidden>${back(s)}${nameChips(s.names)}<div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required></div><button class="btn full">Add a spend</button></form>`;

const buysCard = (s: State) => spendForm(s, false, "f-buy-m") + listCard(false, `Today's buys · ${s.buys.length}`, "", buyRows(s), "f-buy-m", "Add a spend");

const buysD = (s: State) => spendForm(s, true, "f-buy-d") + listCard(true, "Today's buys", `${s.buys.length}`, buyRows(s), "f-buy-d", "Add a spend");

const hero = (s: State) => {
	const c = calc(s);
	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v ea">+${fmt(c.earned)}</div><div class="lb">${c.earnedLine}</div></div><div><div class="lb">Bought today</div><div class="v sp">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
};

const noteList = (s: State, key: string) => {
	if (key === "dash")
		return `<div data-list="dash">${
			s.notes
				.slice(-2)
				.reverse()
				.map((n) => `<div class="rw"><span>${esc(n.body)}</span><span class="lb">${hhmm(n.at)}</span></div>`)
				.join("") || '<div class="lb" style="padding:8px 0">No notes yet.</div>'
		}</div>`;
	let last = "";
	let out = "";
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at));
		if (label !== last) {
			out += `<div class="day"><span>${esc(label)}</span></div>`;
			last = label;
		}
		out +=
			`<div class="msg" data-id="${n.id}"><div class="bub">${esc(n.body)}</div><div class="meta">${n.edited ? "edited · " : ""}${hhmm(n.at)}</div>` +
			`<div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button>` +
			`<form method="post" action="/notes/delete" style="display:contents" data-confirm="Delete this note?">${back(s)}<input type="hidden" name="id" value="${n.id}"><button class="btn xs dng">Delete</button></form></div></div>`;
	}
	return `<div data-list="${key}">${out}</div>`;
};

const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';

const composer = (s: State, key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes">${back(s)}<input type="hidden" name="id" data-eid><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;

const noteD = (s: State) =>
	sec(
		"Note to yourself",
		`${s.notes.length} saved`,
		`<form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0">${back(s)}<input type="hidden" name="id" data-eid><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></form>${noteList(s, "dash")}`,
	);

const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`;

const histM = (s: State) =>
	s.days
		.map((d) =>
			tg(
				esc(d.label),
				`<div class="l1"><span><span class="lb">Earned</span> <b class="ea">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${chips(d.items.map(esc))}`,
			),
		)
		.join("");

const histD = (s: State) => {
	const e = s.days.reduce((a, d) => a + d.earned, 0);
	const b = s.days.reduce((a, d) => a + d.bought, 0);
	return sec(
		"Last 30 days",
		`+${fmt(e)} earned · −${fmt(b)} bought`,
		'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
			s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="ea">+${fmt(d.earned)}</b><b class="sp">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b>${chips(d.items.map(esc))}</div>`).join(""),
	);
};

const editFields = (s: State) =>
	fld("Name", esc(s.user.name), { f: true, name: "name" }) +
	fld("Email", esc(s.user.email), { t: "email", name: "email" }) +
	fld("Phone", esc(s.user.phone), { t: "tel", name: "phone", p: "+212 6 00 00 00 00" }) +
	fld("Bio", esc(s.user.bio), { name: "bio", p: "A line about you" });

const profileForm = (s: State, cancel: string) =>
	`<form method="post" action="/profile/edit">${err(s)}${editFields(s)}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="${cancel}">Cancel</a></div></form>`;

const prefsForm = (s: State) =>
	`<form method="post" action="/settings">${fld("Currency", esc(s.user.currency), { name: "currency" })}${fld("Auto income runs at", esc(s.user.run_at), { name: "run_at" })}${fld("Week starts", esc(s.user.week_start), { name: "week" })}<button class="btn" style="margin-top:14px">Save</button></form>`;

const dataButtons = `<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>`;

const balanceCard = (s: State) =>
	tg(
		"Total balance",
		`<div class="ow" style="margin:0"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></div>`,
	);

const profileM = (s: State) =>
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div></div></div>` +
	balanceCard(s) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);

const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));

const settingsM = (s: State) =>
	err(s) +
	tg("Money & income", prefsForm(s)) +
	tg("Data", dataButtons) + '<div class="lb" style="text-align:center;margin:18px 0">Moneytracker v1.0 · stable</div>';

const settingsD = (s: State) =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	err(s) +
	`<div class="g3"><div>${sec("Profile", "", profileForm(s, "/home"))}${sec(
		"Account",
		"",
		`<form method="post" action="/logout"><button class="btn o">Log out</button></form>`,
	)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Money & income", "", prefsForm(s))}${sec(
		"Data",
		"",
		dataButtons,
	)}</div></div>`;

const dashboardD = (s: State) =>
	hero(s) +
	`<div class="g2"><div>${buysD(s)}</div><div>${oweD(s, false, "owe")}${incD(s, "Income today")}${noteD(s)}</div></div>`;

const debtsD = (s: State) => {
	const c = calc(s);
	return (
		`<div class="hd"><h1 class="t">Debts</h1><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span></div>` +
		`<div class="g3"><div>${oweD(s, true, "owe-page")}</div><div>${sec(
			"How it works",
			"",
			'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div>',
		)}</div></div>`
	);
};

const notesD = (s: State) => `<div class="chat" data-x>${chatHead}${noteList(s, "d")}<div style="margin:30px 0 0">${composer(s, "d")}</div></div>`;

const planD = (s: State) => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${wishD(s)}</div><div>${incD(s)}</div></div>`;

const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 30 days</span></div>${histD(s)}`;

const base = (s: State) => ({
	theme: s.user.theme,
});

const homeBar = () => `<div style="text-align:right"><div style="font-size:14px;font-weight:600;letter-spacing:-.01em">Today</div><div class="lb">${longDay(today())}</div></div>`;

export const homePage = (s: State) =>
	page({
		...base(s),
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobileBar: homeBar(),
		mobile: err(s) + balanceCard(s) + cardsM(s) + addSourceForm(s, false, "f-src-m") + listCard(false, `Income sources${todayLine(s)}`, "", srcRows(s), "f-src-m", "Add source") + buysCard(s) + goalFold(s, "goal") + wishesM(s, false, "wish") + oweM(s, false, "owe"),
		desktop: err(s) + dashboardD(s),
	});

export const debtsPage = (s: State) =>
	page({
		...base(s),
		title: "Debts",
		mobileTab: "home",
		desktopTab: "home",
		mobile: err(s) + hd("Debts", s.debts.map((d) => esc(d.person)).slice(0, 2).join(" + ")) + goalM(s) + oweM(s, true, "owe-page"),
		desktop: err(s) + debtsD(s),
	});

export const notesPage = (s: State) =>
	page({ ...base(s), title: "Notes", mobileTab: "notes", desktopTab: "notes", mobile: chatHead + noteList(s, "m"), dock: composer(s, "m"), desktop: notesD(s) });

export const goalsPage = (s: State) =>
	page({ ...base(s), title: "Goals", mobileTab: "goals", desktopTab: "plan", mobile: hd("Goals", "wishes + debts") + err(s) + goalM(s) + wishesM(s, true, "wish-page") + debtsM(s), desktop: err(s) + planD(s) });

export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "home", desktopTab: "plan", mobile: err(s) + hd("Income", `+${fmt(calc(s).earned)} today`) + incomeM(s), desktop: err(s) + planD(s) });

export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 30 days") + histM(s), desktop: historyD(s) });

export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });

export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });

export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
MT_EOF
cat > "app/router.ts" <<'MT_EOF'
import { asyncContext } from "remix/middleware/async-context"
import { formData } from "remix/middleware/form-data"
import { logger } from "remix/middleware/logger"
import { render } from "remix/middleware/render"
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router"
import { Session } from "remix/session"
import apiController from "./controllers/api.ts"
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
const sent = /(^|;\s*)__session=/.test(context.request.headers.get("cookie") ?? "")
if (!sent) return res
let empty = false
try {
empty = context.get(Session).size === 0
} catch {}
if (!empty) return res
const headers = new Headers(res.headers)
headers.append("Set-Cookie", `__session=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax${import.meta.env.PROD ? "; Secure" : ""}`)
return new Response(res.body, { status: res.status, statusText: res.statusText, headers })
}
const middleware = []
if (import.meta.env.DEV) middleware.push(logger())
middleware.push(...appMiddleware, clearStaleCookie)
export const router = createRouter<AppContext>({ middleware })
router.map(routes.assets, assetsController)
router.map(routes.auth, authController)
router.map(routes.api, apiController)
router.map(routes.commands, commandsController)
router.map(routes.pages, pagesController)
MT_EOF
cat > "app/routes.ts" <<'MT_EOF'
import { get, post, route } from "remix/routes"
export const routes = route({
pages: {
root: get("/"),
home: get("/home"),
debts: get("/debts"),
notes: get("/notes"),
goals: get("/goals"),
pad: get("/pad"),
income: get("/income"),
plan: get("/plan"),
history: get("/history"),
profile: get("/profile"),
profileEdit: get("/profile/edit"),
settings: get("/settings"),
exportCsv: get("/export.csv"),
},
auth: {
login: get("/login"),
signIn: post("/login"),
signup: get("/signup"),
signUp: post("/signup"),
logout: post("/logout"),
googleLogin: get("/login/google"),
googleCallback: get("/auth/google/callback"),
deleteAccount: post("/account/delete"),
},
commands: {
buy: post("/buy"),
deleteBuy: post("/buy/delete"),
setBalance: post("/profile/balance"),
historyIncome: post("/history/income"),
addDebt: post("/debts"),
payDebt: post("/debts/pay"),
clearDebt: post("/debts/clear"),
addNote: post("/notes"),
deleteNote: post("/notes/delete"),
addWish: post("/goals"),
buyWish: post("/goals/buy"),
deleteWish: post("/goals/delete"),
editGoal: post("/goals/edit"),
editGoalItem: post("/goals/item/edit"),
addGoalItem: post("/goals/item"),
deleteGoalItem: post("/goals/item/delete"),
addSource: post("/income"),
addIncome: post("/income/add"),
deleteIncome: post("/income/delete"),
toggleSource: post("/income/toggle"),
editSource: post("/income/edit"),
deleteSource: post("/income/source/delete"),
addPlan: post("/plan"),
saveProfile: post("/profile/edit"),
saveSettings: post("/settings"),
quickBuy: post("/settings/quick"),
setTheme: post("/settings/theme"),
setBackground: post("/settings/background"),
resetBackground: post("/settings/background/reset"),
},
api: {
me: get("/api/me"),
screen: get("/api/screens/:screen"),
command: post("/api/commands/:name"),
},
assets: {
manifest: get("/manifest.webmanifest"),
favicon: get("/favicon.svg"),
faviconIco: get("/favicon.ico"),
icon192: get("/icon-192.png"),
icon512: get("/icon-512.png"),
iconMaskable: get("/icon-maskable.png"),
appleIcon: get("/apple-touch-icon.png"),
sw: get("/sw.js"),
robots: get("/robots.txt"),
sitemap: get("/sitemap.xml"),
css: get("/assets/app.css"),
js: get("/assets/app.js"),
theme: get("/assets/theme.js"),
},
})
MT_EOF
cat > "app/screens/auth.tsx" <<'MT_EOF'
import { Field, Google, Logo } from "../ui/primitives.tsx"
import { AuthPage } from "../ui/layout.tsx"
const AuthForm = ({ up, error }: { up: boolean; error: string }) => (
<div class="auth-center-wrap"><div class="auth-glass-box"><div class="auth-logo-center"><Logo href="/login" /></div><h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1><div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div><form class="au" method="post" action={up ? "/signup" : "/login"}><a class="gbtn" href="/login/google"><Google /><span>{up ? "Sign up with Google" : "Continue with Google"}</span></a><div class="or">or</div>{error ? <div class="auth-err-banner" role="alert">{error}</div> : null}{up ? <Field label="Name" name="name" placeholder="Your name" /> : null}<Field label="Email" type="email" name="email" placeholder="you@email.com" /><Field label="Password" type="password" name="password" placeholder="••••••••" /><button class="btn full">{up ? "Create account" : "Sign in"}</button><div class="auth-switch-wrap"><a class="lnk-switch" href={up ? "/login" : "/signup"}>{up ? <>Already have an account? <b>Sign in</b></> : <>Don't have an account? <b>Create account</b></>}</a></div></form></div></div>
)
export const LoginScreen = ({ error = "" }: { error?: string }) => (
<AuthPage title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker."><AuthForm up={false} error={error} /></AuthPage>
)
export const SignupScreen = ({ error = "" }: { error?: string }) => (
<AuthPage title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals."><AuthForm up={true} error={error} /></AuthPage>
)
MT_EOF
cat > "app/screens/debts.tsx" <<'MT_EOF'
import type { DebtView, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Header, Section } from "../ui/primitives.tsx"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Back, BigAdd, calc, cur, Empty, Err, NameChips, pctOf, plain, XCard } from "./shared.tsx"
import { GoalRoad } from "./goals.tsx"
const DebtPanel = ({ s, d, flag, action, title, btn }: { s: State; d: DebtView; flag: string; action: string; title: string; btn: string }) => {
const unit = d.kind === "money" ? cur(s) : d.item
const all = d.kind === "money" ? plain(d.owed) : String(d.owed)
const attrs = { [flag]: true } as Record<string, boolean>
return (
<form method="post" action={action} class="ad" {...attrs} hidden><input type="hidden" name="debt_id" value={d.id} /><Back s={s} /><label>{title} {d.person}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off" />{flag === "data-payp" ? <button type="button" class="all" data-all={all} aria-label="Fill the full amount">All</button> : null}<span class="mu">{unit}</span></div><button class="btn xs">{btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn={`Remove ${d.person} from the list without marking it paid?`} aria-label="Remove without paying"><Icon name="trash" /></button></div></form>
)
}
const DebtRow = ({ s, d }: { s: State; d: DebtView }) => {
const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${d.item}`
const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0
return (
<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label={`Add debt to ${d.person}`}><Icon name="plus" /></button><div class="dn"><div class="l1"><b>{d.person}</b><span>{label}</span></div><div class="mt s n"><i style={`width:${pct}%`}></i></div></div><button type="button" class="btn xs o" data-pay>Pay</button></div><DebtPanel s={s} d={d} flag="data-addp" action="/debts" title="Add to" btn="Add" /><DebtPanel s={s} d={d} flag="data-payp" action="/debts/pay" title="Pay" btn="Pay" /></div>
)
}
const DebtList = ({ s }: { s: State }) => (s.debts.length ? <>{s.debts.map((d) => <DebtRow s={s} d={d} />)}</> : <Empty>Nobody to pay. All clear.</Empty>)
const AddDebtPanel = ({ s }: { s: State }) => (
<form method="post" action="/debts" class="sf adp" data-adp hidden><Back s={s} /><NameChips names={[...new Set(s.debts.map((d) => d.person))]} /><input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required /><div class="iw"><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required /><span class="mu">{cur(s)}</span></div><button class="btn full">Add</button></form>
)
const peopleCount = (s: State) => new Set(s.debts.map((d) => d.person)).size
export const OweMobile = ({ s, open, k }: { s: State; open: boolean; k: string }) => {
const c = calc(s)
return <XCard k={k} open={open} title="I owe" head={<><b class="big2 sp">{fmt(c.oweMoney)} <small>{cur(s)}</small></b><span class="sp sm">{c.oweExtra}</span></>} body={<DebtList s={s} />} foot={<div class="xl"><span>{peopleCount(s) === 1 ? "1 person" : `${peopleCount(s)} people`}</span></div>} form={<AddDebtPanel s={s} />} label="Add debt" />
}
export const OweDesktop = ({ s, open, k }: { s: State; open: boolean; k: string }) => {
const c = calc(s)
return (
<div class="sc bgc"><BigAdd label="Add debt" /><div class="ct"><details data-keep-open={k} open={open}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">{fmt(c.oweMoney)} {cur(s)} {c.oweExtra}</span><span class="chev"><Icon name="chev" /></span></span></summary><DebtList s={s} /></details><AddDebtPanel s={s} /></div></div>
)
}
const DebtsDesktop = ({ s }: { s: State }) => {
const c = calc(s)
return (
<><div class="hd"><h1 class="t">Debts</h1><span class="lb">{fmt(c.oweMoney)} {cur(s)} {c.oweExtra}</span></div><div class="g3"><div><OweDesktop s={s} open={true} k="owe-page" /></div><div><Section title="How it works"><div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div></Section></div></div></>
)
}
export const debts = (s: State): PageSpec => ({
title: "Debts",
mobileTab: "home",
desktopTab: "home",
mobile: <><Err s={s} /><Header title="Debts" right={s.debts.map((d) => d.person).slice(0, 2).join(" + ")} /><GoalRoad s={s} /><OweMobile s={s} open={true} k="owe-page" /></>,
desktop: <><Err s={s} /><DebtsDesktop s={s} /></>,
})
MT_EOF
cat > "app/screens/goals.tsx" <<'MT_EOF'
import type { Goal, GoalItem, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Header } from "../ui/primitives.tsx"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Back, calc, canBuy, covered, cur, Empty, Err, pctOf, plain, XCard } from "./shared.tsx"
import { IncomeSourcesDesktop } from "./income.tsx"
export const GoalRoad = ({ s }: { s: State }) => {
const c = calc(s)
const chips = [
...s.goals.map((g) => `${g.title} ${pctOf(s, g)}%`),
...s.debts.filter((d) => d.kind === "money").map((d) => `${d.person} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%`),
]
return (
<div class="cd jarc"><i class="jar" style={`width:${c.pct}%`}></i><div class="jin"><div class="tg">Road to goals</div><div class="cb"><div class="gl"><span class="big">{c.pct}<small>%</small></span><span class="lb">{fmt(c.toGo)} {cur(s)} to go</span></div>{chips.length ? <div class="chips">{chips.map((t) => <span class="chip">{t}</span>)}</div> : null}</div></div></div>
)
}
const goalLeft = (s: State, g: Goal) => (g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`)
const ItemRow = ({ s, it, manage }: { s: State; it: GoalItem; manage: boolean }) => {
const ok = s.balance >= it.price
const cls = `gi${it.done ? " gdone" : ""}`
const name = <><span class="gn">{it.name}</span><span class="lb">{fmt(it.price)}</span></>
if (!manage)
return (
<div class={cls}>{name}<span class="wb">{it.done ? null : <form method="post" action="/goals/buy" style="display:contents" data-confirm={`Mark ${it.name} as bought? It will be added as a spend.`}><Back s={s} /><input type="hidden" name="id" value={it.id} /><button class={`btn xs${ok ? "" : " off"}`} disabled={!ok}>Bought</button></form>}</span></div>
)
return (
<div class="dbw"><div class={cls}>{name}<span class="wb">{it.done ? null : <button type="button" class="ub" data-pay aria-label={`Edit ${it.name}`}><Icon name="edit" /></button>}<form method="post" action="/goals/item/delete" style="display:contents" data-confirm={`Remove ${it.name} from this goal?`}><Back s={s} /><input type="hidden" name="id" value={it.id} /><button class="ub" aria-label={`Remove ${it.name}`}><Icon name="trash" /></button></form></span></div>{it.done ? null : <form method="post" action="/goals/item/edit" class="ad" data-payp hidden><Back s={s} /><input type="hidden" name="id" value={it.id} /><label>Edit {it.name}</label><div class="ln"><input class="in f" name="name" value={it.name} autocomplete="off" required /><input class="in pr2" name="price" value={plain(it.price)} placeholder="Price" inputmode="decimal" autocomplete="off" required /><button class="btn xs">Save</button></div></form>}</div>
)
}
const GoalRow = ({ s, g, manage }: { s: State; g: Goal; manage: boolean }) => {
const pct = pctOf(s, g)
const info = <div class="dn"><div class="l1"><b>{g.title}</b><span class="lb">{goalLeft(s, g)}</span></div><div class={`mt s${pct >= 100 ? " full" : ""}`}><i style={`width:${pct}%`}></i></div></div>
const items = g.items.map((it) => <ItemRow s={s} it={it} manage={manage} />)
if (!manage) return <div class="gw"><div class="db">{info}</div>{items}</div>
return (
<div class="gw"><div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label={`Add item to ${g.title}`}><Icon name="plus" /></button>{info}<span class="wb"><button type="button" class="ub" data-pay aria-label={`Rename ${g.title}`}><Icon name="edit" /></button><form method="post" action="/goals/delete" style="display:contents" data-confirm={`Delete ${g.title} and all its items?`}><Back s={s} /><input type="hidden" name="id" value={g.id} /><button class="ub" aria-label={`Delete ${g.title}`}><Icon name="trash" /></button></form></span></div><form method="post" action="/goals/item" class="ad" data-addp hidden><Back s={s} /><input type="hidden" name="goal_id" value={g.id} /><label>Add item to {g.title}</label><div class="ln"><input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required /><input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required /><button class="btn xs">Add</button></div></form><form method="post" action="/goals/edit" class="ad" data-payp hidden><Back s={s} /><input type="hidden" name="id" value={g.id} /><label>Rename goal</label><div class="ln"><input class="in f" name="name" value={g.title} autocomplete="off" required /><button class="btn xs">Save</button></div></form></div>{items}</div>
)
}
const GoalList = ({ s, manage }: { s: State; manage: boolean }) => (s.goals.length ? <>{s.goals.map((g) => <GoalRow s={s} g={g} manage={manage} />)}</> : <Empty>{manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</Empty>)
const GoalForm = ({ s }: { s: State }) => (
<form method="post" action="/goals" class="sf xfm" data-adp hidden><Back s={s} /><input class="in" name="name" placeholder="Goal name" autocomplete="off" required /><button class="btn full">Add goal</button></form>
)
const goalStat = (s: State) => {
const target = s.goals.reduce((a, g) => a + g.target, 0)
const saved = Math.min(Math.max(0, s.balance), target)
const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0
return { target, pct, toGo: Math.max(0, target - saved) }
}
export const GoalsCard = ({ s, open, k, manage }: { s: State; open: boolean; k: string; manage: boolean }) => {
const g = goalStat(s)
const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${cur(s)} to go`
const head = <><b class="big2">{g.pct}<small>%</small></b><span class="lb">{sub}</span></>
if (manage) return <XCard k={k} open={open} title="Goals" head={head} body={<GoalList s={s} manage={true} />} foot={<div class="xl"><span>Pencil edits, bin removes</span></div>} form={<GoalForm s={s} />} label="Add goal" jar={g.pct} />
return <XCard k={k} open={open} title="Goals" head={head} body={<GoalList s={s} manage={false} />} foot={<div class="xl"><span>Left to buy {fmt(g.target)} {cur(s)}</span><a class="lnk" href="/goals">Manage</a></div>} form={null} label="" jar={g.pct} />
}
export const goals = (s: State): PageSpec => ({
title: "Goals",
mobileTab: "home",
desktopTab: "plan",
mobile: <><Header title="Goals" right="add, edit, remove" /><Err s={s} /><GoalsCard s={s} open={true} k="goals-page" manage={true} /></>,
desktop: <><Err s={s} /><PlanDesktop s={s} /></>,
})
const PlanDesktop = ({ s }: { s: State }) => (
<><div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div><GoalsCard s={s} open={true} k="goals-d" manage={true} /></div><div><IncomeSourcesDesktop s={s} /></div></div></>
)
MT_EOF
cat > "app/screens/history.tsx" <<'MT_EOF'
import type { DayRow, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import type { PageSpec } from "../ui/layout.tsx"
import { Card, Header, Section } from "../ui/primitives.tsx"
import { Back, Err, IncRow, SpendRow } from "./shared.tsx"
const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`
const DayItems = ({ s, d }: { s: State; d: DayRow }) => (
<>{d.incomes.map((i) => <IncRow s={s} i={i} />)}{d.buys.map((b) => <SpendRow s={s} id={b.id} name={b.qty > 1 ? `${b.name} ×${b.qty}` : b.name} sub={b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : ""} amount={`−${fmt(b.total)}`} />)}</>
)
const DayForms = ({ s, wide }: { s: State; wide: boolean }) => {
const t = today()
const body = (
<><form method="post" action="/buy"><Back s={s} /><div class="ln"><input class="in" name="label" placeholder="Item" autocomplete="off" required /><input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required /></div><div class="ln" style="margin-top:8px"><input class="in" type="date" name="day" value={t} max={t} required /><button class="btn xs">Add buy</button></div></form><form method="post" action="/history/income" style="margin-top:14px"><Back s={s} /><div class="ln"><input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required /><input class="in" type="date" name="day" value={t} max={t} required /><button class="btn xs">Add income</button></div></form></>
)
return wide ? <Section title="Add to any day">{body}</Section> : <Card title="Add to any day">{body}</Card>
}
const HistoryMobile = ({ s }: { s: State }) => (
<><Err s={s} /><DayForms s={s} wide={false} />{s.days.map((d) => <Card title={d.label}><div class="l1"><span><span class="lb">Earned</span> <b class="ea">+{fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−{fmt(d.bought)}</b></span><b>{dayNet(d.earned, d.bought)}</b></div><DayItems s={s} d={d} /></Card>)}</>
)
const HistoryTable = ({ s }: { s: State }) => {
const e = s.days.reduce((a, d) => a + d.earned, 0)
const b = s.days.reduce((a, d) => a + d.bought, 0)
return (
<Section title="Last 30 days" right={`+${fmt(e)} earned · −${fmt(b)} bought`}><div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>{s.days.map((d) => <div class="tr"><b>{d.label}</b><b class="ea">+{fmt(d.earned)}</b><b class="sp">−{fmt(d.bought)}</b><b>{dayNet(d.earned, d.bought)}</b><div><DayItems s={s} d={d} /></div></div>)}</Section>
)
}
export const history = (s: State): PageSpec => ({
title: "History",
mobileTab: "history",
desktopTab: "history",
mobile: <><Header title="History" right="last 30 days" /><HistoryMobile s={s} /></>,
desktop: <><div class="hd"><h1 class="t">History</h1><span class="lb">last 30 days</span></div><Err s={s} /><DayForms s={s} wide={true} /><HistoryTable s={s} /></>,
})
MT_EOF
cat > "app/screens/home.tsx" <<'MT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import type { PageSpec } from "../ui/layout.tsx"
import { Card } from "../ui/primitives.tsx"
import { OweDesktop, OweMobile } from "./debts.tsx"
import { GoalsCard } from "./goals.tsx"
import { HomeIncome, IncomeSourcesDesktop } from "./income.tsx"
import { NoteDash } from "./notes.tsx"
import { BalanceCard } from "./profile.tsx"
import { Back, calc, cur, Empty, Err, ListCard, NameChips, SpendRow, XCard } from "./shared.tsx"
const EarnedBought = ({ s }: { s: State }) => {
const c = calc(s)
return (
<div class="two"><Card title="Earned today"><div class="big2" style="white-space:nowrap">+{fmt(c.earned)} <small>{cur(s)}</small></div></Card><Card title="Bought today"><div class="big2" style="white-space:nowrap">−{fmt(c.bought)} <small>{cur(s)}</small></div></Card></div>
)
}
const BuyRows = ({ s }: { s: State }) => (
<div>{s.buys.length ? s.buys.map((b) => <SpendRow s={s} id={b.id} name={b.qty > 1 ? `${b.name} ×${b.qty}` : b.name} sub={`${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`} amount={`−${fmt(b.total)}`} />) : <Empty>Nothing bought today.</Empty>}</div>
)
const SpendFields = ({ s }: { s: State }) => (
<><Back s={s} /><NameChips names={s.names} /><div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required /><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required /></div><button class="btn full">Add a spend</button></>
)
const BuysMobile = ({ s }: { s: State }) => (
<XCard k="buys" open={true} title="Today's buys" head="" body={<BuyRows s={s} />} foot={null} form={<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden><SpendFields s={s} /></form>} label="Add a spend" />
)
const BuysDesktop = ({ s }: { s: State }) => (
<><form method="post" action="/buy" id="f-buy-d" class="sc spf" data-sp data-adp hidden><SpendFields s={s} /></form><ListCard wide={true} title="Today's buys" right={`${s.buys.length}`} body={<BuyRows s={s} />} target="f-buy-d" label="Add a spend" /></>
)
const Hero = ({ s }: { s: State }) => {
const c = calc(s)
return (
<div class="hero"><div><div class="lb">Earned today</div><div class="v">+{fmt(c.earned)}</div>{c.earnedLine ? <div class="lb">{c.earnedLine}</div> : null}</div><div><div class="lb">Bought today</div><div class="v">−{fmt(c.bought)}</div><div class="lb">{s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">{c.pct}%</div><div class="mt"><i style={`width:${c.pct}%`}></i></div></div><div><div class="lb">I owe</div><div class="v sp">{fmt(c.oweMoney)}</div><div class="lb">{cur(s)} {c.oweExtra}</div></div></div>
)
}
const Dashboard = ({ s }: { s: State }) => (
<><Hero s={s} /><div class="g2"><div><BuysDesktop s={s} /></div><div><OweDesktop s={s} open={false} k="owe" /><IncomeSourcesDesktop s={s} title="Income today" /><NoteDash s={s} /></div></div></>
)
export const home = (s: State): PageSpec => ({
title: "Home",
mobileTab: "home",
desktopTab: "home",
mobile: <><Err s={s} /><BalanceCard s={s} /><EarnedBought s={s} /><HomeIncome s={s} /><BuysMobile s={s} /><GoalsCard s={s} open={false} k="goals" manage={false} /><OweMobile s={s} open={false} k="owe" /></>,
desktop: <><Err s={s} /><Dashboard s={s} /></>,
})
MT_EOF
cat > "app/screens/income.tsx" <<'MT_EOF'
import type { Source, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Header } from "../ui/primitives.tsx"
import { Back, calc, cur, Empty, Err, IncRow, ListCard, plain, XCard } from "./shared.tsx"
const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount)
const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id)
const tagOf = (x: Source) => (!x.active ? "paused" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto") : "manual")
const Hid = ({ s, id }: { s: State; id: string }) => <><Back s={s} /><input type="hidden" name="id" value={id} /></>
const ToggleForm = ({ s, x, label }: { s: State; x: Source; label: string }) => (
<form method="post" action="/income/toggle" style="display:contents"><Hid s={s} id={x.id} /><button class="btn xs o">{label}</button></form>
)
const DeleteSource = ({ s, x }: { s: State; x: Source }) => (
<form method="post" action="/income/source/delete" style="display:contents" data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}><Hid s={s} id={x.id} /><button class="ub" aria-label={`Delete ${x.name}`}><Icon name="trash" /></button></form>
)
const AddedUndo = ({ s, x, got }: { s: State; x: Source; got: State["incomesToday"] }) => (
<><button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm={`Undo +${fmt(got.reduce((a, i) => a + i.amount, 0))} from ${x.name}?`}><Hid s={s} id={got[0]!.id} /><button class="ub" aria-label={`Undo ${x.name}`}><Icon name="undo" /></button></form></>
)
const AddFixed = ({ s, x, fixed }: { s: State; x: Source; fixed: number }) => (
<form method="post" action="/income/add" style="display:contents"><Back s={s} /><input type="hidden" name="source_id" value={x.id} /><button class="btn xs o">Add {fmt(fixed)}</button></form>
)
const AddAmount = ({ s, x }: { s: State; x: Source }) => (
<form method="post" action="/income/add" class="ln" style="gap:6px"><Back s={s} /><input type="hidden" name="source_id" value={x.id} /><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required /><button class="btn xs o">Add</button></form>
)
const SourceRow = ({ s, x }: { s: State; x: Source }) => {
const got = gotToday(s, x)
const fixed = srcAmount(x)
const main = !x.active ? <ToggleForm s={s} x={x} label="Resume" /> : x.mode === "auto" ? <><b class="ea">+{fmt(x.amount)}</b><ToggleForm s={s} x={x} label="Pause" /></> : got.length ? <AddedUndo s={s} x={x} got={got} /> : fixed ? <AddFixed s={s} x={x} fixed={fixed} /> : <AddAmount s={s} x={x} />
return <div class="rw"><div><div>{x.name}<span class="tag">{tagOf(x)}</span></div></div><span class="rt">{main}<DeleteSource s={s} x={x} /></span></div>
}
const SourceRows = ({ s }: { s: State }) => (s.sources.length ? <>{s.sources.map((x) => <SourceRow s={s} x={x} />)}</> : <Empty>No sources yet. Add one below.</Empty>)
const ModeChips = () => (
<><input type="hidden" name="mode" value="manual" data-mode-input /><div class="chips" style="margin:10px 0 4px"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div><div class="lb" style="margin-bottom:2px">Manual: you tap it, once a day. Auto: added for you.</div></>
)
const SourceFields = () => (
<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required /><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" /></div>
)
const AddSourceForm = ({ s, id }: { s: State; id: string }) => (
<form method="post" action="/income" id={id} class="sc spf" data-adp hidden><Back s={s} /><SourceFields /><ModeChips /><button class="btn full">Add source</button></form>
)
const SourceForm = ({ s }: { s: State }) => (
<form method="post" action="/income" class="sf xfm" data-adp hidden><Back s={s} /><SourceFields /><ModeChips /><button class="btn full">Add source</button></form>
)
const ManageRow = ({ s, x }: { s: State; x: Source }) => {
const fixed = srcAmount(x)
return (
<div class="dbw"><div class="rw"><div><div>{x.name}<span class="tag">{tagOf(x)}</span></div>{fixed ? <div class="lb">{fmt(fixed)} {cur(s)}</div> : null}</div><span class="rt"><ToggleForm s={s} x={x} label={x.active ? "Pause" : "Resume"} /><button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}><Icon name="edit" /></button><DeleteSource s={s} x={x} /></span></div><form method="post" action="/income/edit" class="ad" data-addp hidden><Hid s={s} id={x.id} /><label>Edit {x.name}</label><div class="ln"><input class="in f" name="name" value={x.name} autocomplete="off" required /><input class="in pr2" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Amount" inputmode="decimal" autocomplete="off" /><button class="btn xs">Save</button></div></form></div>
)
}
const IncomeCard = ({ s }: { s: State }) => (
<XCard k="income" open={true} title="Income sources" head={<><b class="big2">{s.sources.length}</b><span class="lb">{s.sources.filter((x) => x.active).length} active</span></>} body={s.sources.length ? <>{s.sources.map((x) => <ManageRow s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>} foot={null} form={<SourceForm s={s} />} label="Add source" />
)
const HomeRow = ({ s, x }: { s: State; x: Source }) => {
const got = gotToday(s, x)
const fixed = srcAmount(x)
const main = x.mode === "auto" ? <b class="ea">+{fmt(x.amount)}</b> : got.length ? <AddedUndo s={s} x={x} got={got} /> : fixed ? <AddFixed s={s} x={x} fixed={fixed} /> : <AddAmount s={s} x={x} />
return <div class="rw"><div><div>{x.name}</div></div><span class="rt">{main}</span></div>
}
export const HomeIncome = ({ s }: { s: State }) => {
const c = calc(s)
const active = s.sources.filter((x) => x.active)
const other = s.incomesToday.filter((i) => !i.sourceId)
const form = <form method="post" action="/history/income" class="sf xfm" data-adp hidden><Back s={s} /><div class="ln"><input class="in" name="amount" placeholder="Other income today" inputmode="decimal" autocomplete="off" required /><button class="btn">Add</button></div></form>
return <XCard k="inc" open={true} title="Income today" head={<><b class="big2">+{fmt(c.earned)} <small>{cur(s)}</small></b><span class="lb">{c.earnedLine}</span></>} body={active.length || other.length ? <>{active.map((x) => <HomeRow s={s} x={x} />)}{other.map((i) => <IncRow s={s} i={i} />)}</> : <Empty>No sources yet.</Empty>} foot={null} form={form} label="Add other income" />
}
export const IncomeSourcesDesktop = ({ s, title = "Income sources", id = "f-src-d" }: { s: State; title?: string; id?: string }) => (
<><AddSourceForm s={s} id={id} /><ListCard wide={true} title={title} right={`+${fmt(calc(s).earned)} today`} body={<SourceRows s={s} />} target={id} label="Add source" /></>
)
export const income = (s: State): PageSpec => ({
title: "Income",
mobileTab: "income",
desktopTab: "income",
mobile: <><Err s={s} /><Header title="Income" right={calc(s).earned ? `+${fmt(calc(s).earned)} today` : ""} /><IncomeCard s={s} /></>,
desktop: <><Err s={s} /><div class="hd"><h1 class="t">Income</h1><span></span></div><IncomeCard s={s} /></>,
})
MT_EOF
cat > "app/screens/index.tsx" <<'MT_EOF'
import { AppPage, type PageSpec } from "../ui/layout.tsx"
import type { State } from "../lib/data.ts"
import { debts } from "./debts.tsx"
import { goals } from "./goals.tsx"
import { history } from "./history.tsx"
import { home } from "./home.tsx"
import { income } from "./income.tsx"
import { notes } from "./notes.tsx"
import { pad, profile, profileEdit, settings } from "./profile.tsx"
export { LoginScreen, SignupScreen } from "./auth.tsx"
export const specs = { home, debts, notes, goals, income, plan: goals, history, profile, profileEdit, settings, pad: (_s: State) => pad() } satisfies Record<string, (s: State) => PageSpec>
export type ScreenKey = keyof typeof specs
export const Screen = ({ name, s }: { name: ScreenKey; s: State }) => <AppPage {...specs[name](s)} theme={s.user.theme} />
MT_EOF
cat > "app/screens/notes.tsx" <<'MT_EOF'
import type { State } from "../lib/data.ts"
import { dayLabel, dayOf, hhmm } from "../lib/time.ts"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Section } from "../ui/primitives.tsx"
import { Back, Empty } from "./shared.tsx"
const ChatHead = () => (
<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>
)
const NoteList = ({ s, k }: { s: State; k: string }) => {
if (k === "dash") {
const last = s.notes.slice(-2).reverse()
return <div data-list="dash">{last.length ? last.map((n) => <div class="rw"><span>{n.body}</span><span class="lb">{hhmm(n.at)}</span></div>) : <Empty>No notes yet.</Empty>}</div>
}
let prev = ""
const out: unknown[] = []
for (const n of s.notes) {
const label = dayLabel(dayOf(n.at))
if (label !== prev) {
out.push(<div class="day"><span>{label}</span></div>)
prev = label
}
out.push(
<div class="msg" data-id={n.id}><div class="bub">{n.body}</div><div class="meta">{n.edited ? "edited · " : ""}{hhmm(n.at)}</div><div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button><form method="post" action="/notes/delete" style="display:contents" data-confirm="Delete this note?"><Back s={s} /><input type="hidden" name="id" value={n.id} /><button class="btn xs dng">Delete</button></form></div></div>,
)
}
return <div data-list={k}>{out}</div>
}
const Composer = ({ s, k }: { s: State; k: string }) => (
<form class="cm" data-comp={k} method="post" action="/notes"><Back s={s} /><input type="hidden" name="id" data-eid /><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send"><Icon name="send" /></button></div></form>
)
export const NoteDash = ({ s }: { s: State }) => (
<Section title="Note to yourself" right={`${s.notes.length} saved`}><form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0"><Back s={s} /><input type="hidden" name="id" data-eid /><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send"><Icon name="send" /></button></form><NoteList s={s} k="dash" /></Section>
)
export const notes = (s: State): PageSpec => ({
title: "Notes",
mobileTab: "notes",
desktopTab: "notes",
mobile: <><ChatHead /><NoteList s={s} k="m" /></>,
dock: <Composer s={s} k="m" />,
desktop: <div class="chat" data-x><ChatHead /><NoteList s={s} k="d" /><div style="margin:30px 0 0"><Composer s={s} k="d" /></div></div>,
})
MT_EOF
cat > "app/screens/profile.tsx" <<'MT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Card, Field, Header, Section, ThemeSwitch } from "../ui/primitives.tsx"
import { Avatar, Back, cur, Err, LANG, plain } from "./shared.tsx"
const ProfileForm = ({ s, cancel }: { s: State; cancel: string }) => (
<form method="post" action="/profile/edit"><Err s={s} /><Field label="Name" value={s.user.name} f={true} name="name" /><Field label="Email" value={s.user.email} type="email" name="email" /><div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href={cancel}>Cancel</a></div></form>
)
const PrefsForm = ({ s }: { s: State }) => (
<form method="post" action="/settings"><Field label="Currency" value={s.user.currency} name="currency" /><Field label="Auto income runs at" value={s.user.run_at} name="run_at" /><Field label="Week starts" value={s.user.week_start} name="week" /><button class="btn" style="margin-top:14px">Save</button></form>
)
const DataButtons = () => (
<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>
)
const BalanceForm = ({ s }: { s: State }) => (
<form method="post" action="/profile/balance"><Back s={s} /><div class="fl"><label>Balance ({cur(s)})</label><input class="in f" name="balance" inputmode="decimal" value={plain(s.balance)} autocomplete="off" required /></div><button class="btn full" style="margin-top:14px">Update balance</button></form>
)
export const BalanceCard = ({ s, edit = false }: { s: State; edit?: boolean }) => (
<div class="cd"><div class="tg">Total balance</div><div class="cb"><div class="ow" style="margin:0"><span style="display:flex;align-items:center;gap:10px"><b class="big2" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={cur(s)}>••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance"><Icon name="eye" /></button></span>{edit ? <button type="button" class="lnk" data-edit-bal>Edit balance</button> : null}</div>{edit ? <div data-balf hidden><BalanceForm s={s} /></div> : null}</div></div>
)
const ProfileMobile = ({ s }: { s: State }) => (
<><Err s={s} /><div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px"><Avatar s={s} /><div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">{s.user.name}</div><div class="lb">{s.user.email}</div><div class="chips" style="justify-content:center;margin-top:10px"><span class="chip" style="cursor:default">{cur(s)}</span><span class="chip" style="cursor:default">{LANG}</span></div></div></div><BalanceCard s={s} edit={true} /><Card title="Appearance"><ThemeSwitch /></Card><Card title="Account"><a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form></Card></>
)
const EditMobile = ({ s }: { s: State }) => (
<><div style="display:flex;justify-content:center;margin:14px 0 0"><Avatar s={s} /></div><Card title="Profile"><ProfileForm s={s} cancel="/profile" /></Card></>
)
const SettingsMobile = ({ s }: { s: State }) => (
<><Err s={s} /><Card title="Money & income"><PrefsForm s={s} /></Card><Card title="Data"><DataButtons /></Card><div class="lb" style="text-align:center;margin:18px 0">Moneytracker v1.0 · stable</div></>
)
const SettingsDesktop = ({ s }: { s: State }) => (
<><div class="hd"><h1 class="t">Settings</h1><span class="lb">{cur(s)} · {LANG}</span></div><Err s={s} /><div class="g3"><div><BalanceCard s={s} edit={true} /><Section title="Profile"><ProfileForm s={s} cancel="/home" /></Section><Section title="Account"><form method="post" action="/logout"><button class="btn o">Log out</button></form></Section></div><div><Section title="Appearance"><ThemeSwitch /></Section><Section title="Money & income"><PrefsForm s={s} /></Section><Section title="Data"><DataButtons /></Section></div></div></>
)
export const profile = (s: State): PageSpec => ({ title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: <ProfileMobile s={s} />, desktop: <SettingsDesktop s={s} /> })
export const profileEdit = (s: State): PageSpec => ({ title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: <><Header title="Edit profile" back="/profile" /><EditMobile s={s} /></>, desktop: <SettingsDesktop s={s} /> })
export const settings = (s: State): PageSpec => ({ title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: <><Header title="Settings" back="/profile" /><SettingsMobile s={s} /></>, desktop: <SettingsDesktop s={s} /> })
export const pad = (): PageSpec => ({ title: "Pad", mobileTab: "pad", desktopTab: "pad", mobile: "", desktop: "" })
MT_EOF
cat > "app/screens/shared.tsx" <<'MT_EOF'
import type { Goal, Income, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon } from "../ui/icons.tsx"
type Kids = { children?: unknown }
export const LANG = "English"
export const cur = (s: State) => s.user.currency
export const plain = (n: number) => (n / 100).toFixed(2).replace(/\.00$/, "")
export function calc(s: State) {
const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0)
const bought = s.buys.reduce((a, b) => a + b.total, 0)
const bySource = new Map<string, number>()
for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount)
const earnedLine = [...bySource].map(([n, a]) => `${n} ${fmt(a)}`).join(" · ") || ""
const money = s.debts.filter((d) => d.kind === "money")
const oweMoney = money.reduce((a, d) => a + d.owed, 0)
const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0)
const oweExtra = oweItems ? `+ ${oweItems} cig` : ""
const wishTarget = s.goals.reduce((a, g) => a + g.target, 0)
const wishSaved = Math.min(Math.max(0, s.balance), wishTarget)
const debtPaid = money.reduce((a, d) => a + d.paid, 0)
const total = wishTarget + oweMoney + debtPaid
const done = wishSaved + debtPaid
const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0
return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) }
}
export const covered = (s: State) => new Map(s.goals.map((g) => [g.id, Math.min(Math.max(0, s.balance), g.target)] as const))
export const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round(((covered(s).get(g.id) ?? 0) / g.target) * 100)) : 0)
export const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target
export const Back = ({ s }: { s: State }) => <input type="hidden" name="back" value={s.back} />
export const Err = ({ s }: { s: State }) => (s.error ? <div class="neg" role="alert" style="margin:10px 0;font-size:13px">{s.error}</div> : null)
export const Empty = ({ children }: Kids) => <div class="lb" style="padding:8px 0">{children}</div>
export function Avatar({ s }: { s: State }) {
const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : ""
return <div class="av" style={url ? `background:url('${url}') center/cover` : undefined}>{url ? null : (s.user.name.trim()[0] ?? "?").toUpperCase()}</div>
}
export const BigAdd = ({ label, target = "", right = false }: { label: string; target?: string; right?: boolean }) => (
<button type="button" class={`addb${right ? " r" : ""}`} data-bigadd data-for={target || undefined} aria-label={label}><Icon name="plus" /></button>
)
export const NameChips = ({ names }: { names: string[] }) => (names.length ? <div class="chips nm">{names.map((n) => <span class="chip" data-nm={n}>{n}</span>)}</div> : null)
export const ListCard = ({ wide, title, right, body, target, label }: { wide: boolean; title: unknown; right: unknown; body: unknown; target: string; label: string }) =>
wide ? (
<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>{title}</span><span class="lb">{right}</span></div>{body}</div><BigAdd label={label} target={target} right={true} /></div>
) : (
<div class="cd bgc rgt"><div class="ct"><div class="tg">{title}</div><div class="cb">{body}</div></div><BigAdd label={label} target={target} right={true} /></div>
)
export const XCard = ({ k, open, title, head, body, foot, form, label, jar = -1 }: { k: string; open: boolean; title: unknown; head: unknown; body: unknown; foot: unknown; form: unknown; label: string; jar?: number }) => (
<div class={`xc${label ? "" : " xn"}`}><details class="xd" data-keep-open={k} open={open}><summary class="xh osum">{jar >= 0 ? <i class={`xj${jar >= 100 ? " full" : ""}`} style={`width:${jar}%`}></i> : null}<div><div class="tg0">{title}</div>{head ? <div class="ow">{head}</div> : null}</div><span class="chev"><Icon name="chev" /></span></summary><div class="xb">{body}</div><div class={`xf${foot ? "" : " xo"}`}>{foot}{form}</div></details>{label ? <button type="button" class="xp" data-xplus aria-label={label}><Icon name="plus" /></button> : null}</div>
)
export const SpendRow = ({ s, id, name, sub, amount }: { s: State; id: string; name: string; sub: string; amount: string }) => (
<div class="by"><div><div>{name}</div><div class="lb">{sub}</div></div><span class="rt"><b class="sp">{amount}</b><form method="post" action="/buy/delete" style="display:contents" data-confirm="Undo this buy? The money comes back."><Back s={s} /><input type="hidden" name="id" value={id} /><button class="ub" aria-label="Undo buy"><Icon name="undo" /></button></form></span></div>
)
export const IncRow = ({ s, i }: { s: State; i: Income }) => (
<div class="by"><div><div>{i.source}</div></div><span class="rt"><b class="ea">+{fmt(i.amount)}</b><form method="post" action="/income/delete" style="display:contents" data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}><Back s={s} /><input type="hidden" name="id" value={i.id} /><button class="ub" aria-label="Undo income"><Icon name="undo" /></button></form></span></div>
)
MT_EOF
cat > "app/ui/clock.tsx" <<'MT_EOF'
import { TZ } from "../lib/time.ts"
const at = (loc: string, o: Intl.DateTimeFormatOptions) => new Intl.DateTimeFormat(loc, { timeZone: TZ, ...o }).format(new Date())
export const SubDate = () => (
<><span class="clock-num">{at("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })}</span>{" "}<span class="clock-dot">·</span>{" "}<span class="clock-ar">{at("ar-MA", { weekday: "long" })}</span></>
)
export const ClockWidget = () => (
<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time"><div class="clock-time" data-clock-time>{at("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })}</div><div class="clock-date" data-clock-date>{at("en-GB", { weekday: "long", day: "numeric", month: "long" })}</div><div class="clock-subdate" data-clock-subdate dir="ltr"><SubDate /></div></div>
)
MT_EOF
cat > "app/ui/css.ts" <<'MT_EOF'
export const css = String.raw`
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}

/* one look for every surface: login box, cards, hero. Radius and shadow come from the tokens on html. */
.cd,.sc,.xc,.hero,.auth-glass-box{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}

a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}button{cursor:pointer}
.mu,.lb{color:var(--mu)}.lb{font-size:11px;font-family:var(--mono)}.pos{color:var(--pos)!important}.neg{color:var(--neg)!important}.ea{color:var(--earn)!important}.sp{color:var(--spend)!important}.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}summary::-webkit-details-marker{display:none}

button,input[type=button],input[type=submit],.btn,.sbl,.qk button,.qk4 button,.chip,.ib,.pl{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.qk button:active,.qk4 button:active,.chip:active,.ib:active,.pl:active{transform:scale(.97);opacity:.88}

.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
.tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}
.tf-clock .clock-date,.tf-clock .clock-subdate{display:none}

.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;padding:38px 32px 34px}
@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px}}
.auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
.auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
.auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
.auth-err-banner{background:rgba(255,90,77,0.12);border:1px solid rgba(255,90,77,0.3);border-radius:12px;padding:10px 14px;color:var(--neg);font-size:13px;font-weight:500;text-align:center;margin:12px 0}
.auth-switch-wrap{display:flex;justify-content:center;margin-top:22px;text-align:center}
.lnk-switch{font-size:14px;color:var(--mu);text-decoration:none}
.lnk-switch b{color:var(--ac);text-decoration:underline;text-underline-offset:3px}
.lnk-switch:hover{color:var(--ink)}

@media(min-width:900px){.m{display:none!important}}
@media(max-width:899px){.d{display:none!important}}

.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){.app{flex-direction:column}}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}

.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg,.bt .lg svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib{flex:none;aspect-ratio:1}.ib.sm{width:28px;height:28px;min-width:28px}.ib svg.ic{width:16px;height:16px}.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}

.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:var(--rc) var(--rc) 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}.bt .on svg.ic{stroke-width:2}
.bt .lg svg{opacity:.55;width:26px;height:26px;border-radius:7px}.bt .lg.on svg{opacity:1}

.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}

h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}

.cd{margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}.two .cb{padding:3px 12px 10px}.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}

.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:var(--rm);padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
.btn:hover{filter:brightness(1.06)}
.btn.o{background:var(--s1);color:var(--ink);border:1px solid var(--ln);box-shadow:var(--sh1)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
.btn.full{width:100%;padding:14px 20px;font-size:16px;font-weight:700;border-radius:var(--rm);margin-top:20px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}

.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:var(--rm);padding:13px 16px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
.in:focus,.in.f:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.in::placeholder{color:var(--mu);opacity:.6}
.ln{display:flex;gap:10px;align-items:center}

.stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
.stp button{width:34px;height:34px;border:1px solid var(--ln);background:var(--s1);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;color:var(--ink)}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:13px 18px;border-radius:var(--rm);border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}

.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}

.qk{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:12px}
.qk button{display:flex;flex-direction:column;align-items:center;gap:6px;padding:14px 6px 12px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);color:var(--ink)}
.qk button svg.ic{color:var(--spend)}
.qk button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}.qk button.on small{color:var(--spend);opacity:.8}
.qk span{font-weight:600;font-size:13px}.qk small{font-size:11px;color:var(--mu);font-family:var(--mono)}
.pn{display:flex;gap:16px;align-items:flex-end;flex-wrap:wrap}
.pn2{display:flex;gap:12px;align-items:flex-end}
.pn2 .pf{flex:1;min-width:0}
.pn2 .pq{flex:none}
.pn2 label{display:block;margin-bottom:6px}
.pn2 .stp{gap:6px}.pn2 .stp .in{width:46px;padding:10px 4px}
.th2{display:flex;justify-content:space-between;align-items:center;padding:10px 10px 0 14px!important}
.pl{width:32px;height:32px;border-radius:10px;border:1px solid var(--ln);background:var(--s2);color:var(--ink);display:flex;align-items:center;justify-content:center;padding:0;flex:none;box-shadow:var(--sh1)}
.pl svg.ic{width:18px;height:18px;transition:transform .18s ease}
.pl.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}.pl.on svg.ic{transform:rotate(45deg)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.tt{display:flex;align-items:center;gap:12px;margin-top:16px}.tt b{flex:1;font-size:26px;letter-spacing:-.04em}

.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ln3{display:flex;gap:12px;align-items:center}.n3{width:76px;flex:none}

.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}.cm .eb b{font-weight:600}.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}

.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}.li:hover{background:var(--s2)}.li:last-child{border:0}.li:first-child{padding-top:14px}

.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:16px}
.qk4 button{display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;color:var(--ink);text-align:left;box-shadow:var(--sh1)}
.qk4 button svg.ic{color:var(--spend)}
.qk4 button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}
.qk4 b{display:block;font-size:14px}.qk4 small{font-size:12px;opacity:.65;font-family:var(--mono)}
.qrow{display:flex;align-items:center;gap:16px;margin-top:16px;padding:16px 18px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);flex-wrap:wrap}
.qrow .eq{font-size:22px;font-weight:600;letter-spacing:-.04em}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
.sl{background:var(--ac);color:var(--on);padding:48px;display:flex;flex-direction:column;justify-content:space-between}
.sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
.sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
.wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.gbtn:hover{background:var(--s2)}
.au .or{margin:18px 0 6px}

details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s ease}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}

.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:var(--bg);border:1px solid var(--ln);color:var(--ink)}
.qe{display:flex;gap:10px;align-items:center;padding:10px 0;border-bottom:1px solid var(--ln)}
.qe .in{font-size:14px;padding:8px 12px}
.qadd{display:flex;gap:10px;align-items:center;margin-top:14px}
.qadd .in{font-size:14px;padding:8px 12px}
.sf .in{display:block;margin-bottom:10px}
.sf .btn.full{margin-top:0}
.chips.nm{flex-wrap:nowrap;overflow-x:auto;margin:0 0 10px;padding-bottom:2px;scrollbar-width:none}
.chips.nm::-webkit-scrollbar{display:none}
.chips.nm .chip{flex:none;white-space:nowrap}
.bgc{display:flex;overflow:hidden;padding:0}
.bgc>.ct{flex:1;min-width:0}
.sc.bgc>.ct{padding:18px 22px 20px}
.addb{flex:none;width:64px;border:0;border-right:1px solid var(--acl);border-radius:0;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0}
.addb svg.ic{width:30px;height:30px;stroke-width:2;transition:transform .18s ease}
.addb.on svg.ic{transform:rotate(45deg)}
.addb:active{transform:none;opacity:.8}
.bgc .adp{margin:6px 14px 14px}
.sc.bgc .adp{margin:14px 0 0}
details.dd>summary{padding:14px 16px;display:block;position:relative}
details.dd[open]>summary{padding-bottom:4px}
details.dd>.cb{padding-top:6px}
details.dd .chev{position:absolute;right:16px;top:14px}
.sc.bgc summary.sh{cursor:pointer}
.wi{padding:12px 0;border-top:1px solid var(--ln)}
.wi:first-child{border-top:0;padding-top:0}
.wa{display:flex;gap:8px;justify-content:flex-end;align-items:center;margin-top:10px}
.l1{gap:12px}.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.tl{display:block;font-weight:400;margin-top:3px;font-size:11px;color:var(--mu);font-family:var(--mono)}
.th2>span{min-width:0}
.pnl.top{margin:0 0 12px;padding:0 0 12px;border-top:0;border-bottom:1px solid var(--ln)}
.sh .pl{margin-left:10px}
.ok{color:var(--earn)}


.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}.spf .ln .in{flex:1 1 0}.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.srcf{margin-top:14px}.srcf .ln{gap:10px}.srcf .in.pr{flex:0 0 96px;width:96px}.srcf .btn.full{margin-top:10px}
.in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
.rw>.rt{max-width:62%;justify-content:flex-end}
.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
.xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
.xh::-webkit-details-marker{display:none}
.xh>div{min-width:0}
.xc .chev{position:absolute;right:66px;top:50%;margin-top:-10px}
.xp{position:absolute;right:12px;top:18px;width:46px;height:44px;border-radius:13px;border:1px solid var(--acl);background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0;z-index:2}
.xp svg.ic{width:24px;height:24px;stroke-width:2;transition:transform .18s ease}
.xp.on svg.ic{transform:rotate(45deg)}
.xb{padding:4px 16px 8px;border-top:1px solid var(--ln)}
.xf{padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.xl{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:12px;color:var(--mu);font-family:var(--mono)}
.xl b{color:var(--ink);font-weight:600;white-space:nowrap}
.xf form{margin:12px 0 0}
.xfm .ln{gap:10px;margin:0}.xfm .ln .in{flex:1 1 0;margin:0}.xfm .ln .in.pr{flex:0 0 96px;width:96px}.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}.gw:last-child{border-bottom:0}.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
`;
MT_EOF
cat > "app/ui/icons.tsx" <<'MT_EOF'
import { jsx } from "./jsx-runtime.ts"
export const P: Record<string, string> = {
sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
pad: '<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h7M9 17h5"/>',
coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
plus: '<path d="M12 5v14M5 12h14"/>',
trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
Other: '<path d="M12 5v14M5 12h14"/>',
back: '<path d="M15 5l-7 7 7 7"/>',
chev: '<path d="M6 9l6 6 6-6"/>',
Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
}
export const ICON_KEYS = ["Smoke", "Coffee", "Bread", "Food", "Bus", "Phone", "Gift", "Cart", "Tag"]
const parse = (s: string) => [...s.matchAll(/<(\w+)([^>]*?)\/>/g)].map((m) => ({ tag: m[1]!, attrs: Object.fromEntries([...m[2]!.matchAll(/([\w-]+)="([^"]*)"/g)].map((a) => [a[1]!, a[2]!])) }))
export function Icon({ name, class: cls = "ic" }: { name: string; class?: string }) {
return <svg class={cls} viewBox="0 0 24 24">{parse(P[name] ?? "").map((n) => jsx(n.tag, n.attrs))}</svg>
}
MT_EOF
cat > "app/ui/jsx-dev-runtime.ts" <<'MT_EOF'
export * from "./jsx-runtime.ts"
MT_EOF
cat > "app/ui/jsx-runtime.ts" <<'MT_EOF'
import * as base from "remix/component/jsx-runtime"
export type { JSX } from "remix/component/jsx-runtime"
const b = base as any
const wrap = (f: any) => (type: any, props: any, ...rest: any[]) => (typeof type === "function" ? type(props) : f(type, props, ...rest))
export const Fragment = b.Fragment
export const jsx = wrap(b.jsx)
export const jsxs = wrap(b.jsxs ?? b.jsx)
export const jsxDEV = wrap(b.jsxDEV ?? b.jsx)
MT_EOF
cat > "app/ui/layout.tsx" <<'MT_EOF'
import { SITE } from "../lib/assets.ts"
import { env } from "../env.ts"
import { ClockWidget, SubDate } from "./clock.tsx"
import { Icon } from "./icons.tsx"
import { Logo, ThemeIcons } from "./primitives.tsx"
type Kids = { children?: unknown }
export type MobileTab = "home" | "notes" | "goals" | "income" | "pad" | "history" | "profile" | ""
export type DesktopTab = "home" | "notes" | "plan" | "income" | "pad" | "history" | "settings" | ""
export type PageSpec = { title: string; mobileTab?: MobileTab; desktopTab?: DesktopTab; mobile: unknown; desktop: unknown; dock?: unknown; full?: boolean }
const origin = () => env.APP_ORIGIN.replace(/\/$/, "")
const ld = () => JSON.stringify({ "@context": "https://schema.org", "@type": "WebApplication", name: SITE.name, url: origin(), description: SITE.desc, applicationCategory: "FinanceApplication", operatingSystem: "Any" })
export function Document({ title, desc = SITE.desc, path, user, theme, children }: Kids & { title: string; desc?: string; path?: string; user: boolean; theme?: string }) {
const full = `${title} · ${SITE.name}`
return (
<html lang="en" data-theme={theme === "light" ? "light" : "dark"}>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<meta name="theme-color" content={SITE.color} />
<title>{full}</title>
<meta name="description" content={desc} />
<meta name="robots" content={user ? "noindex,nofollow" : "index,follow"} />
<meta name="application-name" content={SITE.name} />
<meta name="apple-mobile-web-app-title" content={SITE.name} />
<meta name="mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black" />
<meta name="format-detection" content="telephone=no" />
<link rel="manifest" href="/manifest.webmanifest" />
<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
<link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
<meta property="og:type" content="website" />
<meta property="og:site_name" content={SITE.name} />
<meta property="og:title" content={full} />
<meta property="og:description" content={desc} />
<meta property="og:image" content={`${origin()}/icon-512.png`} />
<meta name="twitter:card" content="summary" />
<meta name="twitter:title" content={full} />
<meta name="twitter:description" content={desc} />
{path && !user ? <link rel="canonical" href={`${origin()}${path}`} /> : null}
{path && !user ? <meta property="og:url" content={`${origin()}${path}`} /> : null}
{user ? null : <script type="application/ld+json">{ld()}</script>}
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap" />
<link rel="stylesheet" href="/assets/app.css" />
{theme ? null : <script src="/assets/theme.js"></script>}
{import.meta.env.DEV ? <script type="module" src="/@vite/client"></script> : null}
</head>
<body>
<div class="app">{children}</div>
<script src="/assets/app.js" defer></script>
</body>
</html>
)
}
const mobileTabs = [["home", "Home", "home", "/home"], ["notes", "Notes", "notes", "/notes"], ["income", "Income", "gear", "/income"], ["pad", "Pad", "pad", "/pad"], ["profile", "Profile", "user", "/profile"]] as const
const desktopTabs = [["home", "Home", "home", "/home"], ["notes", "Notes", "notes", "/notes"], ["plan", "Plan", "goal", "/plan"], ["income", "Income", "coin", "/income"], ["pad", "Pad", "pad", "/pad"], ["history", "History", "hist", "/history"], ["settings", "Settings", "gear", "/settings"]] as const
const BottomBar = ({ active }: { active: MobileTab }) => (
<nav class="bt" aria-label="Main">{mobileTabs.map(([key, label, icon, href]) => <a href={href} class={active === key ? "on" : ""} aria-label={label}><Icon name={icon} /></a>)}</nav>
)
const Sidebar = ({ active }: { active: DesktopTab }) => (
<aside class="sb d"><Logo href="/home" />{desktopTabs.map(([key, label, icon, href]) => <a class={`sbl${active === key ? " on" : ""}`} href={href}><Icon name={icon} />{label}</a>)}<div class="sp"></div><button type="button" class="sbl" data-theme-toggle><ThemeIcons /><span>Theme</span></button><form method="post" action="/logout"><button class="sbl"><Icon name="out" /><span class="neg">Log out</span></button></form></aside>
)
export const AppPage = ({ title, theme, mobileTab = "", desktopTab = "", mobile, desktop, dock, full }: PageSpec & { theme?: string }) => (
<Document title={title} user={true} theme={theme}>
<Sidebar active={desktopTab} />
<main>
<div class="m"><div class="top-status-bar tsplit"><ClockWidget /><div class="clock-subdate" dir="ltr"><SubDate /></div></div></div>
<div class="m mm">{mobile}</div>
<div class="d"><div class="top-status-bar"><ClockWidget /></div></div>
<div class={`d pg${full ? " full" : ""}`}>{desktop}</div>
</main>
<div class="dock m">{dock}<BottomBar active={mobileTab} /></div>
</Document>
)
export const AuthPage = ({ title, desc, path, children }: Kids & { title: string; desc: string; path: string }) => (
<Document title={title} desc={desc} path={path} user={false}>
<div class="tf-clock"><ClockWidget /><button type="button" class="ib" data-theme-toggle aria-label="Theme"><ThemeIcons /></button></div>
<main class="auth-viewport">{children}</main>
</Document>
)
MT_EOF
cat > "app/ui/parts.ts" <<'MT_EOF'
/** Small HTML builders shared by every screen. Everything is static sample markup. */

export const P: Record<string, string> = {
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
	moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
	pad: '<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h7M9 17h5"/>',
	coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
	undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
	Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
	Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
	Other: '<path d="M12 5v14M5 12h14"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	chev: '<path d="M6 9l6 6 6-6"/>',
	Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
	Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
	Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
	Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
	Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
	Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
};

export const ic = (k: string) => `<svg class="ic" viewBox="0 0 24 24">${P[k] ?? ""}</svg>`;

export const GOOGLE =
	'<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>';

export const GOAT =
	'<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/></svg>';

export const logo = (href: string) => `<a class="logo" href="${href}">${GOAT}<span>moneytracker</span></a>`;

export const themeIcons = `<svg class="ic t-sun" viewBox="0 0 24 24">${P.sun}</svg><svg class="ic t-moon" viewBox="0 0 24 24">${P.moon}</svg>`;

// ---------- building blocks ----------

export const tg = (t: string, b: string) => `<div class="cd"><div class="tg">${t}</div><div class="cb">${b}</div></div>`;

export const sec = (t: string, r: string, b: string) =>
	`<div class="sc"><div class="sh"><span>${t}</span><span class="lb">${r}</span></div>${b}</div>`;

type FieldOpts = { name?: string; t?: string; p?: string; f?: boolean; keep?: string };
export const fld = (label: string, value: string, o: FieldOpts = {}) =>
	`<div class="fl"><label>${label}</label><input class="in${o.f ? " f" : ""}"${o.name ? ` name="${o.name}"` : ""}${o.keep ? ` data-keep="${o.keep}"` : ""}${
		o.t ? ` type="${o.t}"` : ""
	} value="${value}"${value ? "" : ` placeholder="${o.p ?? ""}"`} autocomplete="off"></div>`;

export const hd = (t: string, r: string, back?: string) =>
	`<div class="hd">${
		back ? `<a class="back" href="${back}">${ic("back")}<h1 class="t">${t}</h1></a>` : `<h1 class="t">${t}</h1>`
	}<span class="lb">${r}</span></div>`;

export const clockWidget = (timeStr: string, dateStr: string, subDateStr = "") =>
	`<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time"><div class="clock-time" data-clock-time>${timeStr}</div><div class="clock-date" data-clock-date>${dateStr}</div><div class="clock-subdate" data-clock-subdate dir="ltr">${subDateStr}</div></div>`;

export const chips = (a: string[]) => `<div class="chips" style="margin:0">${a.map((i) => `<span class="chip">${i}</span>`).join("")}</div>`;

export const by = (n: string, s: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${s}</div></div><b class="neg">${a}</b></div>`;

/** A person I owe. The "+" button opens the add panel under the row. */
export const dbt = (n: string, l: string, p: number, add?: boolean) =>
	`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${n}">${ic("plus")}</button><div class="dn"><div class="l1"><b>${n}</b><span class="neg">${l}</span></div><div class="mt s n"><i style="width:${p}%"></i></div></div><button type="button" class="btn xs o">Pay</button></div>` +
	`<form method="post" action="/debts" class="ad"${add ? "" : " hidden"}><label>Add to ${n}</label><div class="ln"><input class="in f" name="amount" value="200"><span class="mu">MAD</span><button class="btn xs">Add</button></div><div class="lb">800 → 1,000 MAD · same person, no new row</div></form></div>`;

export const newPerson =
	'<div class="sub">New person</div><form method="post" action="/debts" class="ln3"><input class="in" name="name" placeholder="Name"><input class="in n3" name="cig" placeholder="3"><input class="in n3" name="cur" value="MAD"><button class="btn xs">Add</button></form><div class="lb" style="margin-top:10px">Cleared: Karim (hidden). Type his name to bring him back.</div>';

export const buyRows =
	'<div data-buys>' +
	by("Paid Youssef", "13:40", "−24") + by("Bread", "13:00", "−4") + by("Smoke ×3", "09:30 · 3 × 2", "−6") + by("Coffee", "08:10", "−12") + "</div>";

export const srcRows =
	'<div class="rw"><div><div>Ad revenue</div><div class="lb">auto · every day 06:00</div></div><b class="pos">+64</b></div><div class="rw"><div><div>Tips</div><div class="lb">manual · added today</div></div><button type="button" class="btn xs o" style="opacity:.5">Add 120</button></div><div class="rw"><div><div>Salary</div><div class="lb">monthly · Nov 1</div></div><b class="pos">+8,000</b></div>';

// ---------- notes ----------

const acts = (show: boolean) =>
	`<div class="acts"${show ? "" : " hidden"}><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button><button type="button" class="btn xs dng" data-act="del">Delete</button></div>`;

const bub = (t: string, tm: string, sel = false, ed = false) =>
	`<div class="msg"><div class="bub${sel ? " sel" : ""}">${t}</div><div class="meta">${ed ? "edited · " : ""}${tm}</div>${acts(sel)}</div>`;

export const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';

export const chatBody = (key: string, sel: boolean) =>
	`<div data-list="${key}"><div class="day"><span>Yesterday</span></div>${bub('Laptop: Lenovo 15"\n6,000 MAD — wait for Black Friday', "21:14")}<div class="day"><span>Today</span></div>${bub(
		"Call Youssef about the 800 on Friday",
		"09:02",
		sel,
	)}${bub("Bread 4 · Coffee 12 · Smoke 6", "13:05", false, true)}</div>`;

export const composer = (key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes"><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;

// ---------- history ----------

export type Day = { d: string; earned: string; bought: string; items: string[]; net: string };
export const H: Day[] = [
	{ d: "Today", earned: "+184", bought: "−46", items: ["Coffee 12", "Smoke ×3 6", "Bread 4", "Paid Youssef 24"], net: "+138" },
	{ d: "Yesterday", earned: "+64", bought: "−210", items: ["Groceries 150", "Taxi 28", "Smoke 20", "Coffee 12"], net: "−146" },
	{ d: "Sat 10 Oct", earned: "+64", bought: "−95", items: ["Lunch 60", "Smoke 20", "Coffee 11", "Bread 4"], net: "−31" },
	{ d: "Fri 9 Oct", earned: "+230", bought: "−38", items: ["Coffee 12", "Smoke 20", "Bread 6"], net: "+192" },
	{ d: "Thu 8 Oct", earned: "+64", bought: "−130", items: ["Phone credit 100", "Smoke 20", "Bread 10"], net: "−66" },
];

// ---------- settings ----------

export const editFields = () =>
	fld("Name", "Sami", { f: true, name: "name", keep: "profile.name" }) +
	fld("Email", "sami@email.com", { t: "email", name: "email", keep: "profile.email" }) +
	fld("Phone", "+212 6 00 00 00 00", { t: "tel", name: "phone", keep: "profile.phone" }) +
	fld("Bio", "Saving for the laptop", { name: "bio", keep: "profile.bio" });

export const themeSwitch = () =>
	`<div class="sg"><button type="button" data-set-theme="dark">${ic("moon")}Dark</button><button type="button" data-set-theme="light">${ic("sun")}White</button></div>`;

export type Quick = { n: string; p: string; i: string };
export const QUICK_DEF: Quick[] = [
	{ n: "Smoke", p: "2", i: "Smoke" },
	{ n: "Coffee", p: "12", i: "Coffee" },
	{ n: "Bread", p: "4", i: "Bread" },
];
export const ICON_KEYS = ["Smoke", "Coffee", "Bread", "Food", "Bus", "Phone", "Gift", "Cart", "Tag"];

/** Quick buy editor. The rows are drawn by the page script from what is saved in the browser. */
export const quickEditor = () =>
	`<div class="lb" style="margin-bottom:6px">These are the buttons under Quick buy. Change a name, price or icon and it saves right away.</div><div data-qedit></div><div class="qadd" data-qadd><select class="in sel" data-ai aria-label="Icon">${ICON_KEYS.map((k) => `<option value="${k}">${k}</option>`).join("")}</select><input class="in" data-an placeholder="Name" autocomplete="off"><input class="in n3" data-ap placeholder="Price" inputmode="decimal" autocomplete="off"><button type="button" class="btn xs" data-qaddbtn>Add</button></div>`;

// ---------- auth form ----------

/** Sign in / sign up. Submitting just goes to the dashboard: no session, no cookie. */
export const auth = (up: boolean, wide: boolean) =>
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">${wide ? "" : '<div style="height:22px"></div>'}<h1 class="t" style="margin-bottom:20px">${
		up ? "Sign up" : "Sign in"
	}</h1><a class="gbtn" href="/home">${GOOGLE}${up ? "Sign up with Google" : "Continue with Google"}</a><div class="or">or</div>${
		up ? fld("Name", "", { name: "name", p: "Your name" }) : ""
	}${fld("Email", "", { t: "email", name: "email", p: "you@email.com" })}${fld("Password", "", {
		t: "password",
		name: "password",
		p: "••••••••",
	})}<button class="btn full">${up ? "Create account" : "Sign in"}</button><div style="display:flex;justify-content:space-between;margin-top:16px"><a class="lnk" href="${
		up ? "/login" : "/signup"
	}">${up ? "I have an account" : "Create account"}</a>${up ? "" : '<a class="lnk" href="/login">Forgot password?</a>'}</div></form>`;
MT_EOF
cat > "app/ui/primitives.tsx" <<'MT_EOF'
import { Icon } from "./icons.tsx"
type Kids = { children?: unknown }
export const Google = () => (
<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>
)
export const Goat = () => (
<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/></svg>
)
export const Logo = ({ href }: { href: string }) => (
<a class="logo" href={href}><Goat /><span>moneytracker</span></a>
)
export const ThemeIcons = () => (
<><Icon name="sun" class="ic t-sun" /><Icon name="moon" class="ic t-moon" /></>
)
export const Card = ({ title, children }: Kids & { title: unknown }) => (
<div class="cd"><div class="tg">{title}</div><div class="cb">{children}</div></div>
)
export const Section = ({ title, right = "", children }: Kids & { title: unknown; right?: unknown }) => (
<div class="sc"><div class="sh"><span>{title}</span><span class="lb">{right}</span></div>{children}</div>
)
export const Field = ({ label, value = "", name, type, placeholder, f, keep }: { label: string; value?: string; name?: string; type?: string; placeholder?: string; f?: boolean; keep?: string }) => (
<div class="fl"><label>{label}</label><input class={"in" + (f ? " f" : "")} name={name} data-keep={keep} type={type} value={value} placeholder={value ? undefined : (placeholder ?? "")} autocomplete="off" /></div>
)
export const Header = ({ title, right = "", back }: { title: string; right?: unknown; back?: string }) => (
<div class="hd">{back ? <a class="back" href={back}><Icon name="back" /><h1 class="t">{title}</h1></a> : <h1 class="t">{title}</h1>}<span class="lb">{right}</span></div>
)
export const ThemeSwitch = () => (
<div class="sg"><button type="button" data-set-theme="dark"><Icon name="moon" />Dark</button><button type="button" data-set-theme="light"><Icon name="sun" />White</button></div>
)
MT_EOF
cat > "app/ui/script.ts" <<'MT_EOF'
/**
 * Tiny inline script, plain JavaScript. All data now lives in the database and every change is a
 * normal form post. This script only handles what a form cannot: picking a quick buy, the
 * quantity stepper, open/close panels, selecting a note, choosing an income mode, and the theme.
 * The browser still remembers two small UI things: the theme and whether "I owe" is open.
 */
export const themeBoot = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;

export const script = String.raw`
(function(){
var d=document,r=d.documentElement;
function all(sel,root){return [].slice.call((root||d).querySelectorAll(sel))}
function money(n){return (Math.round(n*100)/100).toLocaleString('en-US')}

function setTheme(t){
  r.setAttribute('data-theme',t);
  try{localStorage.setItem('mtheme',t)}catch(e){}
  try{fetch('/settings/theme',{method:'POST',body:new URLSearchParams({theme:t}),credentials:'same-origin',redirect:'manual'})}catch(e){}
}

/* ---------- quick buy ---------- */
function calc(f){
  var q=parseFloat(f.querySelector('[data-qty]').value)||0,p=parseFloat(String(f.querySelector('[data-price]').value).replace(',','.'))||0;
  var t=Math.round(q*p*100)/100,o=f.querySelector('[data-tot]');
  o.textContent=(o.getAttribute('data-pre')||'')+(t?'−':'')+money(t);
}
function pick(q,keep){
  var w=q.closest('[data-qb]'),f=w.querySelector('[data-qp]'),n=q.getAttribute('data-q');
  all('[data-q]',w).forEach(function(b){b.classList.toggle('on',b===q)});
  f.hidden=false;
  f.querySelector('[data-cat]').value=n;
  var ti=f.querySelector('[data-qt]');if(ti)ti.textContent=n;
  var lw=f.querySelector('[data-labelwrap]');if(lw)lw.hidden=!q.hasAttribute('data-o');
  if(!keep)f.querySelector('[data-qty]').value=1;
  f.querySelector('[data-price]').value=q.getAttribute('data-p')||'';
  calc(f);
}
all('.qk4').forEach(function(g){var first=g.querySelector('[data-q]');if(first)pick(first,false)});

/* ---------- notes ---------- */
function endEdit(c){
  var id=c.querySelector('[data-eid]');if(id)id.value='';
  var eb=c.querySelector('.eb');if(eb)eb.hidden=true;
  c.querySelector('textarea').value='';
}
all('[data-list]').forEach(function(L){
  var last=L.lastElementChild;
  if(L.getAttribute('data-list')!=='dash'&&last&&last.scrollIntoView)last.scrollIntoView({block:'end'});
});

/* ---------- "I owe" open or closed, kept in the browser ---------- */
var open={};try{open=JSON.parse(localStorage.getItem('mt:open')||'{}')}catch(e){}
all('details[data-keep-open]').forEach(function(x){var k=x.getAttribute('data-keep-open');if(k in open)x.open=!!open[k]});
d.addEventListener('toggle',function(e){
  var x=e.target;
  if(x.matches&&x.matches('details[data-keep-open]')){
    open[x.getAttribute('data-keep-open')]=x.open;
    try{localStorage.setItem('mt:open',JSON.stringify(open))}catch(err){}
  }
  if(x.matches&&x.matches('.xd')&&!x.open){var xf=x.querySelector('[data-adp]'),xb=x.parentNode.querySelector('[data-xplus]');if(xf)xf.hidden=true;if(xb)xb.classList.remove('on')}
},true);

/* ---------- clicks ---------- */
d.addEventListener('click',function(e){
  var t=e.target,q;
  if(t.closest('[data-theme-toggle]')){setTheme(r.getAttribute('data-theme')==='dark'?'light':'dark');return}
  if((q=t.closest('[data-set-theme]'))){setTheme(q.getAttribute('data-set-theme'));return}
  if((q=t.closest('[data-eye]'))){
    var v=q.parentNode.firstChild,hide=q.getAttribute('data-s')!=='1';
    q.setAttribute('data-s',hide?'1':'0');
    v.innerHTML=hide?(v.getAttribute('data-bal')+' <small>'+v.getAttribute('data-cur')+'</small>'):'••••••';
    return
  }
  if((q=t.closest('[data-edit-bal]'))){var bf=q.closest('.cd,.sc').querySelector('[data-balf]');bf.hidden=!bf.hidden;q.textContent=bf.hidden?'Edit balance':'Cancel';if(!bf.hidden){var bi=bf.querySelector('input:not([type=hidden])');if(bi){bi.focus();bi.select()}}return}
  if((q=t.closest('[data-all]'))){
    var af=q.closest('.iw').querySelector('input');
    af.value=q.getAttribute('data-all');af.focus();
    return
  }
  if((q=t.closest('[data-tg],[data-pay]'))){
    var w=q.closest('.dbw'),which=q.hasAttribute('data-tg')?'[data-addp]':'[data-payp]',other=q.hasAttribute('data-tg')?'[data-payp]':'[data-addp]';
    var p=w.querySelector(which),o=w.querySelector(other);
    if(o)o.hidden=true;
    p.hidden=!p.hidden;
    if(!p.hidden){var i=p.querySelector('input[name=amount]');if(i)i.focus()}
    return
  }
  if((q=t.closest('[data-plus]'))){
    var pn=q.closest('.cd,.sc').querySelector('[data-pnl]');
    if(pn){
      pn.hidden=!pn.hidden;
      q.classList.toggle('on',!pn.hidden);
      if(!pn.hidden){var fi=pn.querySelector('input:not([type=hidden])');if(fi)fi.focus()}
    }
    return
  }
  if((q=t.closest('[data-xplus]'))){
    var xc=q.closest('.xc'),xd=xc.querySelector('details'),xm=xc.querySelector('[data-adp]');
    if(xm){
      if(!xd.open){xd.open=true;xm.hidden=false}else xm.hidden=!xm.hidden;
      q.classList.toggle('on',!xm.hidden);
      if(!xm.hidden){var xi=xm.querySelector('input:not([type=hidden])');if(xi)xi.focus()}
    }
    return
  }
  if((q=t.closest('[data-nm]'))){
    var nf=q.closest('form'),nin=nf.querySelector('[data-name]'),pin=nf.querySelector('[data-price]');
    nin.value=q.getAttribute('data-nm');
    if(pin)pin.focus();
    return
  }
  if((q=t.closest('[data-bigadd]'))){
    var tf=q.getAttribute('data-for'),ap=tf?d.getElementById(tf):q.closest('.bgc').querySelector('[data-adp]');
    ap.hidden=!ap.hidden;
    q.classList.toggle('on',!ap.hidden);
    if(!ap.hidden){var ai=ap.querySelector('input:not([type=hidden])');if(ai)ai.focus()}
    return
  }
  if((q=t.closest('[data-q]'))){pick(q,false);return}
  if((q=t.closest('[data-step]'))){
    var f2=q.closest('[data-qp]'),i2=f2.querySelector('[data-qty]');
    i2.value=Math.max(1,(parseFloat(i2.value)||0)+parseInt(q.getAttribute('data-step'),10));calc(f2);return
  }
  if((q=t.closest('[data-mode]'))){
    var form=q.closest('form');
    all('[data-mode]',form).forEach(function(c){c.classList.toggle('on',c===q)});
    form.querySelector('[data-mode-input]').value=q.getAttribute('data-mode');
    return
  }
  if((q=t.closest('.bub'))){
    q.classList.toggle('sel');var a=q.parentNode.querySelector('.acts');a.hidden=!a.hidden;return
  }
  if((q=t.closest('[data-act]'))){
    var m=q.closest('.msg'),act=q.getAttribute('data-act'),body=m.querySelector('.bub').textContent;
    if(act==='copy'){try{navigator.clipboard.writeText(body)}catch(x){}return}
    if(act==='edit'){
      var key=m.parentNode.getAttribute('data-list'),c=d.querySelector('[data-comp="'+key+'"]');
      c.querySelector('[data-eid]').value=m.getAttribute('data-id');
      c.querySelector('.eb').hidden=false;
      var ta=c.querySelector('textarea');ta.value=body;ta.focus();
    }
    return
  }
  if((q=t.closest('[data-cancel]'))){endEdit(q.closest('[data-comp]'));return}
});

d.addEventListener('input',function(e){
  var f=e.target.closest&&e.target.closest('[data-qp]');
  if(f)calc(f);
});

d.addEventListener('click',function(e){
  var b=e.target.closest&&e.target.closest('[data-confirm-btn]');
  if(b&&!confirm(b.getAttribute('data-confirm-btn')))e.preventDefault();
},true);

d.addEventListener('submit',function(e){
  var f=e.target,msg=f.getAttribute&&f.getAttribute('data-confirm');
  if(msg&&!confirm(msg)){e.preventDefault();return}
  setTimeout(function(){if(e.defaultPrevented)return;all('button',f).forEach(function(b){if(!b.disabled){b.disabled=true;b.setAttribute('data-busy','1')}})},0);
});
window.addEventListener('pageshow',function(e){if(e.persisted)all('button[data-busy]').forEach(function(b){b.disabled=false;b.removeAttribute('data-busy')})});

d.addEventListener('keydown',function(e){
  if(e.key!=='Enter'||e.shiftKey)return;
  var t=e.target;
  if(t.matches&&t.matches('[data-comp] textarea')){
    e.preventDefault();
    if(t.value.trim()){var f=t.closest('form');if(f.requestSubmit)f.requestSubmit();else f.submit()}
  }
});

/* ---------- live clock (Africa/Casablanca) ---------- */
function updateLiveClock(){
  var tEls = all('[data-clock-time]');
  var dEls = all('[data-clock-date]');
  var sEls = all('[data-clock-subdate]');
  if(!tEls.length) return;
  var now = new Date();
  try{
    var tf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', hour: '2-digit', minute: '2-digit', hour12: false });
    var df = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', weekday: 'long', day: 'numeric', month: 'long' });
    var nf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', day: '2-digit', month: '2-digit', year: 'numeric' });
    var af = new Intl.DateTimeFormat('ar-MA', { timeZone: 'Africa/Casablanca', weekday: 'long' });
    var tStr = tf.format(now);
    var dStr = df.format(now);
    var sStr = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + '</span>';
    tEls.forEach(function(el){ el.textContent = tStr; });
    dEls.forEach(function(el){ el.textContent = dStr; });
    sEls.forEach(function(el){ el.innerHTML = sStr; });
  }catch(err){}
}
setInterval(updateLiveClock, 1000);

/* ---------- background fallback ---------- */
var bgCustomEl = d.querySelector('[data-bg-custom]');
if(bgCustomEl){
  var bgUrl = bgCustomEl.getAttribute('data-bg-custom');
  if(bgUrl){
    var testImg = new Image();
    testImg.onerror = function(){
      bgCustomEl.classList.add('bg-fallback-auto');
    };
    testImg.src = bgUrl;
  }
}
})();
`;
MT_EOF
cat > "app/ui/shell.ts" <<'MT_EOF'
import { css } from "./css.ts";
import { clockWidget, ic, logo, themeIcons } from "./parts.ts";
import { script, themeBoot } from "./script.ts";
import { liveClockNow } from "../lib/time.ts";
import { SITE } from "../lib/assets.ts";
import { env } from "../env.ts";
export type MobileTab = "home" | "notes" | "goals" | "income" | "pad" | "history" | "profile" | "";
export type DesktopTab = "home" | "notes" | "plan" | "income" | "pad" | "history" | "settings" | "";
const splitCss = ".top-status-bar.tsplit{justify-content:space-between}.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}";
export type PageOptions = {
title: string;
user?: boolean;
mobile: string;
desktop: string;
mobileTab?: MobileTab;
desktopTab?: DesktopTab;
dock?: string;
full?: boolean;
theme?: string;
mobileBar?: boolean;
desc?: string;
path?: string;
};
const attr = (s: string) => s.replace(/[&<>"]/g, (c) => `&#${c.charCodeAt(0)};`);
const bottomBar = (a: MobileTab) =>
'<nav class="bt" aria-label="Main">' +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["income", "Income", "gear", "/income"],
["pad", "Pad", "pad", "/pad"],
["profile", "Profile", "user", "/profile"],
] as const
)
.map(([key, label, icon, href]) => `<a href="${href}" class="${a === key ? "on" : ""}" aria-label="${label}">${ic(icon)}</a>`)
.join("") +
"</nav>";
const sidebar = (a: DesktopTab) =>
`<aside class="sb d">${logo("/home")}` +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["plan", "Plan", "goal", "/plan"],
["income", "Income", "coin", "/income"],
["pad", "Pad", "pad", "/pad"],
["history", "History", "hist", "/history"],
["settings", "Settings", "gear", "/settings"],
] as const
)
.map(([key, label, icon, href]) => `<a class="sbl${a === key ? " on" : ""}" href="${href}">${ic(icon)}${label}</a>`)
.join("") +
`<div class="sp"></div><button type="button" class="sbl" data-theme-toggle>${themeIcons}<span>Theme</span></button>` +
`<form method="post" action="/logout"><button class="sbl">${ic("out")}<span class="neg">Log out</span></button></form></aside>`;
export function page(o: PageOptions): string {
const user = o.user !== false;
const desc = o.desc ?? SITE.desc;
const origin = env.APP_ORIGIN.replace(/\/$/, "");
const ld = JSON.stringify({ "@context": "https://schema.org", "@type": "WebApplication", name: SITE.name, url: origin, description: SITE.desc, applicationCategory: "FinanceApplication", operatingSystem: "Any" }).replace(/</g, "\\u003c");
const { timeStr, dateStr, subDateStr } = liveClockNow();
const clock = clockWidget(timeStr, dateStr, subDateStr);
const topBar = `<div class="top-status-bar">${clock}</div>`;
const mobileTop = `<div class="top-status-bar tsplit">${clock}<div class="clock-subdate" dir="ltr">${subDateStr}</div></div>`;
return (
`<!DOCTYPE html><html lang="en" data-theme="${o.theme === "light" ? "light" : "dark"}"><head><meta charset="utf-8">` +
`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` +
`<meta name="theme-color" content="${SITE.color}"><title>${attr(o.title)} · ${SITE.name}</title>` +
`<meta name="description" content="${attr(desc)}"><meta name="robots" content="${user ? "noindex,nofollow" : "index,follow"}">` +
`<meta name="application-name" content="${SITE.name}"><meta name="apple-mobile-web-app-title" content="${SITE.name}"><meta name="mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black"><meta name="format-detection" content="telephone=no">` +
`<link rel="manifest" href="/manifest.webmanifest"><link rel="icon" href="/favicon.svg" type="image/svg+xml"><link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png"><link rel="apple-touch-icon" href="/apple-touch-icon.png">` +
`<meta property="og:type" content="website"><meta property="og:site_name" content="${SITE.name}"><meta property="og:title" content="${attr(o.title)} · ${SITE.name}"><meta property="og:description" content="${attr(desc)}"><meta property="og:image" content="${origin}/icon-512.png"><meta name="twitter:card" content="summary"><meta name="twitter:title" content="${attr(o.title)} · ${SITE.name}"><meta name="twitter:description" content="${attr(desc)}">` +
(o.path && !user ? `<link rel="canonical" href="${origin}${o.path}"><meta property="og:url" content="${origin}${o.path}">` : "") +
(user ? "" : `<script type="application/ld+json">${ld}</script>`) +
`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap">` +
`<style>${css}${splitCss}</style><script>${o.theme ? "" : themeBoot}</script></head>` +
`<body>` +
`<div class="app">` +
(user
? sidebar(o.desktopTab ?? "")
: `<div class="tf-clock">${clock}<button type="button" class="ib" data-theme-toggle aria-label="Theme">${themeIcons}</button></div>`) +
(user
? `<main><div class="m">${mobileTop}</div><div class="m mm">${o.mobile}</div><div class="d">${topBar}</div><div class="d pg${o.full ? " full" : ""}">${o.desktop}</div></main>`
: `<main class="auth-viewport">${o.desktop}</main>`) +
(user ? `<div class="dock m">${o.dock ?? ""}${bottomBar(o.mobileTab ?? "")}</div>` : "") +
`</div><script>${script}</script><script>if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))</script></body></html>`
);
}
MT_EOF
cat > "app/utils/render.ts" <<'MT_EOF'
const enc = new TextEncoder()
const html = (body: BodyInit, init: ResponseInit) => {
const headers = new Headers(init.headers)
headers.set("Content-Type", "text/html; charset=utf-8")
return new Response(body, { ...init, headers })
}
export async function render(node: unknown, init: ResponseInit = {}) {
const m: any = await import("remix/component/server")
if (typeof m.renderToStream === "function") {
const reader = m.renderToStream(node).getReader()
const body = new ReadableStream<Uint8Array>({
async start(c) {
try {
c.enqueue(enc.encode("<!DOCTYPE html>"))
for (;;) {
const { done, value } = await reader.read()
if (done) break
c.enqueue(typeof value === "string" ? enc.encode(value) : value)
}
c.close()
} catch (e) {
c.error(e)
}
},
})
return html(body, init)
}
if (typeof m.renderToString === "function") return html("<!DOCTYPE html>" + (await m.renderToString(node)), init)
throw new Error("remix/component/server exports neither renderToStream nor renderToString")
}
MT_EOF
cat > "app/utils/request.ts" <<'MT_EOF'
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
MT_EOF
cat > "vite.config.ts" <<'MT_EOF'
import { cloudflare } from "@cloudflare/vite-plugin"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"
const ui = (file: string) => fileURLToPath(new URL(`./app/ui/${file}`, import.meta.url))
export default defineConfig({
server: { host: "0.0.0.0", port: 3000, allowedHosts: true },
resolve: {
tsconfigPaths: true,
alias: [
{ find: "~/app/ui/jsx-runtime", replacement: ui("jsx-runtime.ts") },
{ find: "~/app/ui/jsx-dev-runtime", replacement: ui("jsx-dev-runtime.ts") },
],
},
oxc: { jsx: { runtime: "automatic", importSource: "~/app/ui" } },
plugins: [cloudflare()],
})
MT_EOF
sed -i 's#"../ui/parts.ts"#"../ui/icons.tsx"#' app/lib/actions.ts
grep -q '../ui/icons.tsx' app/lib/actions.ts || { echo "could not patch app/lib/actions.ts"; exit 1; }
sed -i 's#"jsxImportSource": "remix/component"#"jsxImportSource": "~/app/ui"#' tsconfig.json
grep -q '"jsxImportSource": "~/app/ui"' tsconfig.json || { echo "could not patch tsconfig.json"; exit 1; }
echo "done. old files saved in $B"
echo "run: npm run dev"
