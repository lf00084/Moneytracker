/**
 * Server loaders. Every screen declares which slices of the user's data it needs and one loader
 * fetches exactly those, on the server, before the page is rendered. Controllers call
 * `loadScreen()`, screens receive the finished `State` as a prop, and the JSON API reuses the
 * same loaders so the HTML and the JSON can never drift apart.
 */
import { loadState, type Part, type State } from "../lib/data.ts";
import type { User } from "../lib/users.ts";

export type ScreenKey = "home" | "debts" | "notes" | "goals" | "plan" | "income" | "history" | "profile" | "profileEdit" | "settings" | "pad";

type ScreenDef = { path: string; parts: Part[]; first?: Part[] };

export const screenDefs: Record<ScreenKey, ScreenDef> = {
	home: { path: "/home", parts: ["today", "sources", "names", "debts", "goals", "notes", "balance"], first: ["today", "sources", "names", "debts", "goals", "balance"] },
	debts: { path: "/debts", parts: ["debts", "goals", "balance"] },
	notes: { path: "/notes", parts: ["notes"] },
	goals: { path: "/goals", parts: ["goals", "debts", "balance"] },
	plan: { path: "/plan", parts: ["goals", "debts", "sources", "today", "balance"] },
	income: { path: "/income", parts: ["sources", "today"] },
	history: { path: "/history", parts: ["history"] },
	profile: { path: "/profile", parts: ["avatar", "balance"] },
	profileEdit: { path: "/profile/edit", parts: ["avatar", "balance"] },
	settings: { path: "/settings", parts: ["balance"] },
	pad: { path: "/pad", parts: [] },
};

export const isScreen = (key: string): key is ScreenKey => Object.hasOwn(screenDefs, key);

export function loadScreen(user: User, key: ScreenKey, error = "", first = false): Promise<State> {
	const def = screenDefs[key];
	return loadState(user, first && def.first ? def.first : def.parts, { back: def.path, error });
}

export const loadFrame = (user: User, back: string, parts: Part[]): Promise<State> => loadState(user, parts, { back });
