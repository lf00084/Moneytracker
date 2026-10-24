import { createController } from "remix/router";
import type { RemixNode } from "remix/component";
import * as act from "../lib/actions.ts";
import type { State } from "../lib/data.ts";
import { loadFrame, loadScreen, type ScreenKey } from "../loaders/index.ts";
import { NoteCard } from "../components/notes.tsx";
import {
	DebtsScreen,
	GoalsScreen,
	HistoryScreen,
	HomeScreen,
	IncomeScreen,
	NotesScreen,
	PadScreen,
	ProfileEditScreen,
	ProfileScreen,
	SettingsScreen,
	TradingScreen,
} from "../screens/index.ts";
import { routes } from "../routes.ts";
import { go, takeError, userOf, type Ctx } from "../utils/request.ts";

/**
 * The server-loader pattern: check who is asking, run the screen's loader on the server, then
 * render the screen component with the loaded state. No data fetching happens in the browser.
 */
const screen = (key: ScreenKey, render: (s: State) => RemixNode) => async (ctx: Ctx) => {
	const user = userOf(ctx);
	if (!user) return go("/login");
	const state = await loadScreen(user, key, takeError(ctx), true);
	return ctx.render(render(state));
};

export default createController(routes.pages, {
	actions: {
		root: (ctx: Ctx) => go(userOf(ctx) ? "/home" : "/login"),
		home: screen("home", (s) => <HomeScreen s={s} />),
		debts: screen("debts", (s) => <DebtsScreen s={s} />),
		notes: screen("notes", (s) => <NotesScreen s={s} />),
		goals: screen("goals", (s) => <GoalsScreen s={s} />),
		plan: screen("plan", (s) => <GoalsScreen s={s} />),
		income: screen("income", (s) => <IncomeScreen s={s} />),
		history: screen("history", (s) => <HistoryScreen s={s} />),
		profile: screen("profile", (s) => <ProfileScreen s={s} />),
		profileEdit: screen("profileEdit", (s) => <ProfileEditScreen s={s} />),
		settings: screen("settings", (s) => <SettingsScreen s={s} />),
		pad: screen("pad", (s) => <PadScreen s={s} />),
		trading: screen("trading", (s) => <TradingScreen s={s} />),

		async frameNotes(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return new Response(null, { status: 401 });
			return ctx.render(<NoteCard s={await loadFrame(user, "/home", ["notes"])} />);
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
	},
});
