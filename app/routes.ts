import { get, post, route } from "remix/routes";

export const routes = route({
	// Auth
	root: get("/"),
	login: get("/login"),
	signIn: post("/login"),
	signup: get("/signup"),
	signUp: post("/signup"),
	logout: post("/logout"),
	googleLogin: get("/login/google"),
	googleCallback: get("/auth/google/callback"),

	// Pages
	home: get("/home"),
	debts: get("/debts"),
	notes: get("/notes"),
	goals: get("/goals"),
	income: get("/income"),
	plan: get("/plan"),
	history: get("/history"),
	profile: get("/profile"),
	profileEdit: get("/profile/edit"),
	settings: get("/settings"),

	// Forms
	buy: post("/buy"),
	deleteBuy: post("/buy/delete"),
	addDebt: post("/debts"),
	payDebt: post("/debts/pay"),
	addNote: post("/notes"),
	deleteNote: post("/notes/delete"),
	addWish: post("/goals"),
	buyWish: post("/goals/buy"),
	deleteWish: post("/goals/delete"),
	addSource: post("/income"),
	addIncome: post("/income/add"),
	deleteIncome: post("/income/delete"),
	addPlan: post("/plan"),
	saveProfile: post("/profile/edit"),
	saveSettings: post("/settings"),
	quickBuy: post("/settings/quick"),
	setTheme: post("/settings/theme"),
	setBackground: post("/settings/background"),
	resetBackground: post("/settings/background/reset"),

	// Account
	exportCsv: get("/export.csv"),
	deleteAccount: post("/account/delete"),
});
