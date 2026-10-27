import * as act from "./lib/actions.ts"
import * as inc from "./lib/income.ts"
import { toMinor } from "./lib/money.ts"
import * as pad from "./lib/pad.ts"
import * as trading from "./lib/trading.ts"
import { setTheme, updatePrefs, updateProfile, type User } from "./lib/users.ts"

export type Command = {
	run: (user: User, f: FormData) => Promise<unknown>
	to: string
	back?: boolean
	fail?: string
	empty?: boolean
}

const field = (f: FormData, key: string) => String(f.get(key) ?? "")

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
	addSource: { run: (u, f) => inc.addSource(u.id, f), to: "/income" },
	setHours: { run: (u, f) => inc.setHours(u.id, f), to: "/home" },
	addNamed: { run: (u, f) => inc.addNamed(u.id, f), to: "/home" },
	addIncome: { run: (u, f) => act.addIncome(u.id, f), to: "/income" },
	deleteIncome: { run: (u, f) => act.deleteIncome(u.id, f), to: "/income" },
	toggleSource: { run: (u, f) => act.toggleSource(u.id, f), to: "/income" },
	editSource: { run: (u, f) => inc.editSource(u.id, f), to: "/income" },
	deleteSource: { run: (u, f) => act.deleteSource(u.id, f), to: "/income" },
	tradeDeposit: { run: (u) => trading.startTrade(u), to: "/trading" },
	tradeSet: { run: (u, f) => trading.setPredict(u.id, f), to: "/trading" },
	tradeResult: { run: (u, f) => trading.saveResult(u.id, f), to: "/trading" },
	tradeGame: { run: (u, f) => trading.saveGame(u.id, f), to: "/trading" },
	tradeUndo: { run: (u, f) => trading.undoResult(u.id, f), to: "/trading" },
	tradeFinish: { run: (u, f) => trading.finishTrade(u.id, f), to: "/trading" },
	tradeReopen: { run: (u, f) => trading.reopenTrade(u.id, f), to: "/trading" },
	saveProfile: { run: (u, f) => updateProfile(u.id, { name: field(f, "name"), email: field(f, "email") }), to: "/profile", back: false, fail: "/profile/edit" },
	saveSettings: {
		run: quiet((u, f) => updatePrefs(u.id, { currency: field(f, "currency"), run_at: field(f, "run_at"), day_start: parseInt(field(f, "day_start"), 10), week_start: field(f, "week"), usdt_rate_minor: toMinor(f.get("usdt")), usd_rate_minor: toMinor(f.get("usd_rate")) })),
		to: "/settings",
	},
	setTheme: { run: quiet((u, f) => setTheme(u.id, field(f, "theme"))), to: "/settings", empty: true },
	padAddSpace: { run: (u, f) => pad.addSpace(u.id, f), to: "/pad", fail: "/pad/new" },
	padEditSpace: { run: (u, f) => pad.editSpace(u.id, f), to: "/pad", fail: "/pad" },
	padDelSpace: { run: quiet((u, f) => pad.deleteSpace(u.id, f)), to: "/pad" },
	padAdd: { run: (u, f) => pad.addEntry(u.id, f), to: "/pad" },
	padToggle: { run: quiet((u, f) => pad.toggleEntry(u.id, f)), to: "/pad" },
	padEdit: { run: (u, f) => pad.editEntry(u.id, f), to: "/pad" },
	padDel: { run: quiet((u, f) => pad.deleteEntry(u.id, f)), to: "/pad" },
} satisfies Record<string, Command>

export type CommandName = keyof typeof commands

export const errorOf = (r: unknown) => (typeof r === "string" && r ? r : "")
