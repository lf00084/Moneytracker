/**
 * Every URL the app answers, grouped by what it is for. Each group is handled by exactly one
 * controller in `controllers/`:
 *
 *   pages     server-rendered screens (GET)            -> controllers/pages.tsx
 *   auth      login, signup, logout, Google, delete    -> controllers/auth.tsx
 *   commands  form posts that change data              -> controllers/commands.ts
 *   api       the same data as JSON                    -> controllers/api.ts
 *   assets    manifest, icons, service worker, css, js -> controllers/assets.ts
 */
import { get, post, route } from "remix/routes";

export const routes = route({
	pages: {
		root: get("/"),
		home: get("/home"),
		debts: get("/debts"),
		notes: get("/notes"),
		goals: get("/goals"),
		pad: get("/pad"),
		trading: get("/trading"),
		income: get("/income"),
		plan: get("/plan"),
		history: get("/history"),
		profile: get("/profile"),
		profileEdit: get("/profile/edit"),
		settings: get("/settings"),
		exportCsv: get("/export.csv"),
		frameNotes: get("/frames/notes"),
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
		setHours: post("/income/hours"),
		addNamed: post("/income/named"),
		deleteIncome: post("/income/delete"),
		toggleSource: post("/income/toggle"),
		editSource: post("/income/edit"),
		deleteSource: post("/income/source/delete"),
		tradeDeposit: post("/trading/deposit"),
		tradeSet: post("/trading/set"),
		tradeResult: post("/trading/result"),
		tradeUndo: post("/trading/undo"),
		tradeFinish: post("/trading/finish"),
		tradeReopen: post("/trading/reopen"),
		addPlan: post("/plan"),
		saveProfile: post("/profile/edit"),
		saveSettings: post("/settings"),
		quickBuy: post("/settings/quick"),
		setTheme: post("/settings/theme"),
		setBackground: post("/settings/background"),
		resetBackground: post("/settings/background/reset"),
	},

	api: route("/api", {
		me: get("/me"),
		screen: get("/screens/:screen"),
		command: post("/commands/:name"),
	}),

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
		entry: get("/assets/entry.js"),
	},
});
