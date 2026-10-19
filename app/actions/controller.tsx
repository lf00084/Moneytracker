import { createController } from "remix/router";

import {
	debtsPage,
	goalsPage,
	historyPage,
	homePage,
	incomePage,
	loginPage,
	notesPage,
	profileEditPage,
	profilePage,
	settingsPage,
	signupPage,
} from "../pages/screens.ts";
import { routes } from "../routes.ts";

const html = (body: string) => new Response(body, { headers: { "Content-Type": "text/html; charset=utf-8" } });

/** UI only: there is no session, no cookie and no database. Every form sends you to a page. */
const go = (href: string) => new Response(null, { status: 303, headers: { Location: href } });

export default createController(routes, {
	actions: {
		// Sign in and sign up. Anything you type works: you land on the dashboard.
		root() {
			return go("/login");
		},
		login() {
			return html(loginPage());
		},
		signIn() {
			return go("/home");
		},
		signup() {
			return html(signupPage());
		},
		signUp() {
			return go("/home");
		},
		logout() {
			return go("/login");
		},

		// Pages
		home() {
			return html(homePage());
		},
		debts() {
			return html(debtsPage());
		},
		notes() {
			return html(notesPage());
		},
		goals() {
			return html(goalsPage());
		},
		income() {
			return html(incomePage());
		},
		plan() {
			return html(goalsPage());
		},
		history() {
			return html(historyPage());
		},
		profile() {
			return html(profilePage());
		},
		profileEdit() {
			return html(profileEditPage());
		},
		settings() {
			return html(settingsPage());
		},

		// Forms. Empty on purpose: they send you back to the page that holds them.
		buy() {
			return go("/home");
		},
		addDebt() {
			return go("/debts");
		},
		addNote() {
			return go("/notes");
		},
		addWish() {
			return go("/goals");
		},
		addSource() {
			return go("/income");
		},
		addPlan() {
			return go("/plan");
		},
		saveProfile() {
			return go("/profile");
		},
		saveSettings() {
			return go("/settings");
		},
	},
});
