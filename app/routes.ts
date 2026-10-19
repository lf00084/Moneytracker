import { get, post, route } from "remix/routes";

export const routes = route({
	// Auth. UI only: signing in just redirects to the dashboard.
	root: get("/"),
	login: get("/login"),
	signIn: post("/login"),
	signup: get("/signup"),
	signUp: post("/signup"),
	logout: post("/logout"),

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

	// Forms. Each one is wired to an empty handler that redirects back to its page.
	buy: post("/buy"),
	addDebt: post("/debts"),
	addNote: post("/notes"),
	addWish: post("/goals"),
	addSource: post("/income"),
	addPlan: post("/plan"),
	saveProfile: post("/profile/edit"),
	saveSettings: post("/settings"),
});
