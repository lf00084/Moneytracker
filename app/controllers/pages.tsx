import { createController } from "remix/router"
import type { RemixNode } from "remix/component"
import * as act from "../lib/actions.ts"
import { loadState, type Part, type State } from "../lib/data.ts"
import { DebtsScreen, GoalsScreen, HistoryScreen, HomeScreen, IncomeScreen, NotesScreen, PadScreen, ProfileEditScreen, ProfileScreen, SettingsScreen, TradingScreen } from "../screens.tsx"
import { routes } from "../routes.ts"
import { go, takeError, userOf, type Ctx } from "../request.ts"
import { loadPad } from "../lib/pad.ts"
import type { PadTab } from "../components/pad.tsx"

const page = (path: string, parts: Part[], render: (s: State) => RemixNode) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	return ctx.render(render(await loadState(user, parts, { back: path, error: takeError(ctx) })))
}

const padPage = (tab: PadTab) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	const q = new URL(ctx.request.url).searchParams
	const d = await loadPad(user.id, q.get("p") ?? "")
	return ctx.render(<PadScreen u={user} d={d} tab={tab} f={q.get("f") ?? ""} error={takeError(ctx)} />)
}

export default createController(routes.pages, {
	actions: {
		root: (ctx: Ctx) => go(userOf(ctx) ? "/home" : "/login"),
		home: page("/home", ["today", "sources", "names", "incnames", "debts", "goals", "notes", "balance"], (s) => <HomeScreen s={s} />),
		debts: page("/debts", ["debts", "goals", "balance"], (s) => <DebtsScreen s={s} />),
		notes: page("/notes", ["notes"], (s) => <NotesScreen s={s} />),
		goals: page("/goals", ["goals", "debts", "balance"], (s) => <GoalsScreen s={s} />),
		plan: page("/plan", ["goals", "debts", "sources", "today", "balance"], (s) => <GoalsScreen s={s} />),
		income: page("/income", ["sources", "today"], (s) => <IncomeScreen s={s} />),
		history: page("/history", ["history"], (s) => <HistoryScreen s={s} />),
		profile: page("/profile", ["avatar", "balance"], (s) => <ProfileScreen s={s} />),
		profileEdit: page("/profile/edit", ["avatar", "balance"], (s) => <ProfileEditScreen s={s} />),
		settings: page("/settings", ["balance"], (s) => <SettingsScreen s={s} />),
		pad: padPage("projects"),
		padSaid: padPage("said"),
		padHome: padPage("home"),
		padNew: padPage("new"),
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
