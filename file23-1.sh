#!/usr/bin/env bash
set -e
[ -f app/lib/trading.ts ] || { echo "Run this inside the Moneytracker folder"; exit 1; }
if grep -q "hm-pr" app/client/app.css; then echo "already applied"; exit 0; fi
RUN="$(command -v node || command -v bun || true)"
[ -n "$RUN" ] || { echo "node or bun is needed"; exit 1; }

cat > app/components/home.tsx <<'GOAT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export type PadLeft = { projects: number; home: number }

export const HomeBalance = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<div class="hm-ba">
			<button type="button" class="ib" data-eye aria-label="Show balance">
				<Icon name="eye" />
			</button>
		</div>
		<div class="hm-m">Total balance</div>
	</div>
))

const Stat = view<{ label: string; sign: string; value: number; cur: string }>(({ label, sign, value, cur }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots">{`${sign}${fmt(value)}`} <small>{cur}</small></b>
		<div class="hm-m">{label}</div>
	</div>
))

export const HomeToday = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hm-two">
			<Stat label="Earned today" sign="+" value={c.earned} cur={s.user.currency} />
			<Stat label="Bought today" sign="−" value={c.bought} cur={s.user.currency} />
		</div>
	)
})

export const HomePredict = view<{ s: State }>(({ s }) => {
	const open = s.trades.some((t) => t.status === "open")
	const done = s.trades.some((t) => t.day === today(s.user.day_start))
	const ok = open || !done
	return (
		<a class="hm-c hm-bal hm-pr" href="/trading">
			<b class={ok ? "hm-dots" : "hm-dots no"}>{ok ? "You can predict today" : "You can't predict today"}</b>
			<div class="hm-m">Predict</div>
		</a>
	)
})

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => (
	<div class="hm-c hm-tk">
		<a href="/pad">
			<span class="hm-m">Project tasks left</span>
			<b>{p.projects}</b>
		</a>
		<a href="/pad/home">
			<span class="hm-m">Home tasks left</span>
			<b>{p.home}</b>
		</a>
	</div>
))
GOAT_EOF

cat > app/controllers/pages.tsx <<'GOAT_EOF'
import { createController } from "remix/router"
import type { RemixNode } from "remix/component"
import * as act from "../lib/actions.ts"
import { loadState, type Part, type State } from "../lib/data.ts"
import { DebtsScreen, GoalsScreen, HistoryScreen, HomeScreen, IncomeScreen, NotesScreen, PadScreen, ProfileEditScreen, ProfileScreen, SettingsScreen, TradingScreen } from "../screens.tsx"
import { routes } from "../routes.ts"
import { go, takeError, userOf, type Ctx } from "../request.ts"
import { loadPad } from "../lib/pad.ts"
import type { PadData } from "../lib/padmeta.ts"
import { saveTab, type User } from "../lib/users.ts"
import type { PadTab } from "../components/pad.tsx"
import type { PadLeft } from "../components/home.tsx"

const KEEP = /^\/(home|trading|income|notes|profile|history|plan|settings|pad(\/(said|home))?)(\?p=[0-9a-f-]{36})?$/

const remember = async (user: User, path: string) => {
	if (user.last_tab === path || !KEEP.test(path)) return
	try {
		await saveTab(user.id, path)
	} catch {}
}

const padLeft = (d: PadData): PadLeft => ({
	projects: d.entries.filter((e) => e.kind === "task" && d.spaces.some((x) => x.id === e.space)).length,
	home: d.entries.filter((e) => e.kind === "task" && !e.space).length,
})

const page = (path: string, parts: Part[], render: (s: State) => RemixNode) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	await remember(user, path)
	return ctx.render(render(await loadState(user, parts, { back: path, error: takeError(ctx) })))
}

const padPage = (tab: PadTab) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	const url = new URL(ctx.request.url)
	const q = url.searchParams
	const p = q.get("p") ?? ""
	await remember(user, `${url.pathname}${p ? `?p=${p}` : ""}`)
	const d = await loadPad(user.id, p)
	return ctx.render(<PadScreen u={user} d={d} tab={tab} f={q.get("f") ?? ""} error={takeError(ctx)} />)
}

const homePage = async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	await remember(user, "/home")
	const [s, d] = await Promise.all([
		loadState(user, ["today", "sources", "names", "incnames", "debts", "goals", "notes", "balance", "trading"], { back: "/home", error: takeError(ctx) }),
		loadPad(user.id, ""),
	])
	return ctx.render(<HomeScreen s={s} p={padLeft(d)} />)
}

export default createController(routes.pages, {
	actions: {
		root: (ctx: Ctx) => {
			const user = userOf(ctx)
			if (!user) return go("/login")
			return go(KEEP.test(user.last_tab) ? user.last_tab : "/home")
		},
		home: homePage,
		debts: page("/debts", ["debts", "goals", "balance"], (s) => <DebtsScreen s={s} />),
		notes: page("/notes", ["notes"], (s) => <NotesScreen s={s} />),
		goals: page("/goals", ["goals", "debts", "balance"], (s) => <GoalsScreen s={s} />),
		plan: page("/plan", ["goals", "debts", "sources", "today", "balance"], (s) => <GoalsScreen s={s} />),
		income: page("/income", ["sources", "today", "invoice"], (s) => <IncomeScreen s={s} />),
		history: page("/history", ["history"], (s) => <HistoryScreen s={s} />),
		profile: page("/profile", ["avatar", "balance"], (s) => <ProfileScreen s={s} />),
		profileEdit: page("/profile/edit", ["avatar", "balance"], (s) => <ProfileEditScreen s={s} />),
		settings: page("/settings", ["balance"], (s) => <SettingsScreen s={s} />),
		pad: padPage("projects"),
		padSaid: padPage("said"),
		padHome: padPage("home"),
		padNew: padPage("new"),
		padProject: padPage("edit"),
		trading: page("/trading", ["trading"], (s) => <TradingScreen s={s} />),

		async exportCsv(ctx: Ctx) {
			const user = userOf(ctx)
			if (!user) return go("/login")
			return new Response(await act.exportCsv(user.id), {
				headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": 'attachment; filename="moneytracker.csv"' },
			})
		},
	},
})
GOAT_EOF

cat > /tmp/file23.cjs <<'GOAT_EOF'
const fs = require("fs")
const edits = [
	["app/components/layout.tsx", [
		['{ key: "trading", label: "Trading", icon: "trade", href: "/trading" }', '{ key: "trading", label: "Predict", icon: "trade", href: "/trading" }'],
		['{ key: "trading", label: "Trading", icon: "btrade", href: "/trading" }', '{ key: "trading", label: "Predict", icon: "btrade", href: "/trading" }'],
		["aria-label={t.label}>\n\t\t\t\t<Icon name={t.icon} />\n", "aria-label={t.label}>\n\t\t\t\t<Icon name={t.icon} />\n\t\t\t\t<span class=\"bl\">{t.label}</span>\n"],
	]],
	["app/components/ui.tsx", [
		[`trade: '<path d="M3 17l5-6 4 3 8-9"/><path d="M15 5h5v5"/>',`, `trade: '<circle cx="12" cy="10" r="7"/><path d="M7.5 21h9M8.8 16.6 7.5 21M15.2 16.6l1.3 4.4M8.6 8.2a4 4 0 0 1 2.8-2"/>',`],
		[`btrade: '<path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/>',`, `btrade: '<circle cx="12" cy="10" r="7"/><path d="M7.5 21h9M8.8 16.6 7.5 21M15.2 16.6l1.3 4.4M8.6 8.2a4 4 0 0 1 2.8-2"/>',`],
	]],
	["app/screens.tsx", [
		['import { HomeBalance, HomeToday } from "./components/home.tsx"', 'import { HomeBalance, HomePredict, HomeTasks, HomeToday, type PadLeft } from "./components/home.tsx"'],
		["export const HomeScreen = view<{ s: State }>(({ s }) => (", "export const HomeScreen = view<{ s: State; p: PadLeft }>(({ s, p }) => ("],
		["<HomeToday s={s} />\n\t\t\t\t<HomeIncome", "<HomeToday s={s} />\n\t\t\t\t<HomePredict s={s} />\n\t\t\t\t<HomeTasks p={p} />\n\t\t\t\t<HomeIncome"],
		['title="Trading"', 'title="Predict"'],
	]],
	["app/components/trading.tsx", [
		["Stop trading today", "Stop predicting today"],
		['title="Open trade"', 'title="Open predict"'],
		["title=\"Today's trade\"", "title=\"Today's predict\""],
		["One trade a day", "One predict a day"],
		['"You can trade"', '"You can predict"'],
		['"You cannot trade"', '"You cannot predict"'],
		["You can trade again at", "You can predict again at"],
		["to start today's trade.", "to start today's predict."],
		["Your trade is open.", "Your predict is open."],
		["Past trades · ", "Past predicts · "],
		["Open this trade again", "Open this predict again"],
	]],
	["app/lib/trading.ts", [
		["Finish your open trade first", "Finish your open predict first"],
		["One trade a day", "One predict a day"],
		["Trade not found", "Predict not found"],
		["This trade is already settled", "This predict is already settled"],
		['name: "Trading"', 'name: "Predict"'],
	]],
	["app/lib/actions.ts", [
		["Undo this from the Trading page", "Undo this from the Predict page"],
	]],
	["app/lib/users.ts", [
		["\tusdt_rate: number\n}", "\tusdt_rate: number\n\tlast_tab: string\n}"],
		["Number(r.usdt_rate_minor) : 1100,\n})", "Number(r.usdt_rate_minor) : 1100,\n\tlast_tab: r.last_tab || \"\",\n})"],
	]],
	["app/db/tables.ts", [
		["\t\tusdt_rate_minor: c.integer(),\n", "\t\tusdt_rate_minor: c.integer(),\n\t\tlast_tab: c.varchar(80),\n"],
	]],
	["database/schema.sql", [
		["  usdt_rate_minor INTEGER NOT NULL DEFAULT 1100,\n", "  usdt_rate_minor INTEGER NOT NULL DEFAULT 1100,\n  last_tab      TEXT NOT NULL DEFAULT '',\n"],
	]],
	["scripts/migrate.ts", [
		['\t"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",\n', '\t"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",\n\t"ALTER TABLE users ADD COLUMN last_tab TEXT NOT NULL DEFAULT \'\'",\n'],
		['await client.execute("UPDATE users SET day_start = 5 WHERE day_start = 17")\n', 'await client.execute("UPDATE users SET day_start = 5 WHERE day_start = 17")\nawait client.execute(`UPDATE incomes SET meta = replace(meta, \'"name":"Trading"\', \'"name":"Predict"\') WHERE ext_key LIKE \'trade:%\'`)\n'],
	]],
	["app/controllers/auth.tsx", [
		['go("/home")', 'go("/")'],
		['returnTo: "/home"', 'returnTo: "/"'],
		['returnTo ?? "/home"', 'returnTo ?? "/"'],
	]],
	["app/lib/assets.ts", [
		['start_url: "/home"', 'start_url: "/"'],
	]],
]
const out = []
for (const [file, pairs] of edits) {
	let s = fs.readFileSync(file, "utf8")
	for (const [a, b] of pairs) {
		if (!s.includes(a)) {
			console.error("not found in " + file + ": " + a.slice(0, 70))
			process.exit(1)
		}
		s = s.split(a).join(b)
	}
	out.push([file, s])
}
for (const [file, s] of out) fs.writeFileSync(file, s)
console.log("patched " + out.length + " files")
GOAT_EOF

"$RUN" /tmp/file23.cjs
rm -f /tmp/file23.cjs

cat >> app/client/app.css <<'GOAT_EOF'

.hm-two .hm-c.hm-bal{flex:1 1 0;min-width:0;min-height:48px;padding:8px 8px 8px 14px}
.hm-two .hm-dots{white-space:nowrap}
.hm-c.hm-pr{padding-right:14px;text-decoration:none;color:inherit}
.hm-pr .hm-dots{letter-spacing:0;font-size:16px}
.hm-pr .hm-dots.no{color:var(--h-mu)}
.hm-tk{display:flex;flex-direction:column;padding:4px 14px}
.hm-tk a{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:8px 0;color:inherit;text-decoration:none}
.hm-tk a+a{border-top:1px solid var(--h-ln)}
.hm-tk b{font-size:17px;font-weight:700;line-height:1.1}
.bt{height:74px}
.bt a,.bt button{flex:1 1 0;width:auto;min-width:0;max-width:66px;height:58px;flex-direction:column;gap:3px;border-radius:16px}
.bt a.on{width:auto}
.bt svg.ic,.bt .on svg.ic{width:23px;height:23px;stroke-width:2.1}
.bt .on svg.ic{stroke-width:2.4}
.bt .bl{position:relative;font-size:10px;line-height:1;font-weight:500;letter-spacing:.1px}
.bt .on .bl{font-weight:700}
GOAT_EOF

if [ -f .dev.vars ] && command -v bun >/dev/null 2>&1; then
  bun run db:migrate
else
  echo "Now run: bun run db:migrate  (before deploy, it adds the last_tab column)"
fi
echo "file23 done"
