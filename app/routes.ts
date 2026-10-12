import { get, post, route } from "remix/routes";

export const routes = route({
	// Pages
	home: get("/"),
	stats: get("/stats"),
	purchases: get("/purchases"),
	add: get("/add"),
	goals: get("/goals"),
	wishes: get("/wishes"),
	debts: get("/debts"),
	sources: get("/sources"),
	source: get("/sources/:id"),
	settings: get("/settings"),

	// Forms. Each one is wired to an empty handler that redirects back to its page.
	saveBalance: post("/balance"),
	createPurchase: post("/purchases"),
	createEntry: post("/sources/:id/entries"),
	deleteEntry: post("/sources/:id/entries/:entryId/delete"),
	saveRate: post("/sources/:id/rate"),
	createSource: post("/sources"),
	createWish: post("/wishes"),
	buyWish: post("/wishes/:id/bought"),
	createDebt: post("/debts"),
	payDebt: post("/debts/:id/pay"),
	saveSettings: post("/settings"),
	signOut: post("/sign-out"),
});
