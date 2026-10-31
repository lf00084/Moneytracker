import { createController } from "remix/router"
import type { RemixNode } from "remix/component"
import * as act from "../lib/actions.ts"
import { loadState, type Part, type State } from "../lib/data.ts"
import { WalletScreen } from "../components/wallet.tsx"
import { DebtsScreen, GoalsScreen, HistoryScreen, HomeScreen, IncomeScreen, PadScreen, ProfileEditScreen, ProfileScreen, SettingsScreen, TradingScreen } from "../screens.tsx"
import { routes } from "../routes.ts"
import { go, takeError, userOf, type Ctx } from "../request.ts"
import { loadPad } from "../lib/pad.ts"
import type { PadData } from "../lib/padmeta.ts"
import { saveTab, type User } from "../lib/users.ts"
import type { PadTab } from "../components/pad.tsx"
import type { PadLeft } from "../components/home.tsx"

const KEEP = /^\/(home|trading|wallet|income|profile|history|plan|settings|pad(\/(said|home))?)(\?p=[0-9a-f-]{36})?$/

const remember = async (user: User, path: string) => {
	if (user.last_tab === path || !KEEP.test(path)) return
	try {
		await saveTab(user.id, path)
	} catch {}
}

const padLeft = (d: PadData): PadLeft => ({
	projects: d.spaces
		.map((x) => {
			const es = d.entries.filter((e) => e.space === x.id && (e.kind === "task" || e.kind === "done"))
			return { id: x.id, title: x.title, color: x.color, left: es.filter((e) => e.kind === "task").length, total: es.length }
		})
		.filter((x) => x.left > 0),
	home: (() => {
		const es = d.entries.filter((e) => !e.space && (e.kind === "task" || e.kind === "done"))
		return { left: es.filter((e) => e.kind === "task").length, total: es.length }
	})(),
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
	const d = await loadPad(user.id, p, q.get("d") === "1")
	return ctx.render(<PadScreen u={user} d={d} tab={tab} f={q.get("f") ?? ""} error={takeError(ctx)} />)
}

const homePage = async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	await remember(user, "/home")
	const [s, d] = await Promise.all([
		loadState(user, ["today", "sources", "names", "incnames", "debts", "goals", "balance", "trading", "wallet"], { back: "/home", error: takeError(ctx) }),
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
		wallet: page("/wallet", ["wallet"], (s) => <WalletScreen s={s} />),

		async exportCsv(ctx: Ctx) {
			const user = userOf(ctx)
			if (!user) return go("/login")
			return new Response(await act.exportCsv(user.id), {
				headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": 'attachment; filename="moneytracker.csv"' },
			})
		},
	},
})
