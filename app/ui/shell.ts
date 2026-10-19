import { css } from "./css.ts";
import { ic, logo, themeBtn } from "./parts.ts";
import { script, themeBoot } from "./script.ts";

export type MobileTab = "home" | "notes" | "goals" | "history" | "";
export type DesktopTab = "home" | "notes" | "plan" | "history" | "";

export type PageOptions = {
	title: string;
	/** Signed-in chrome (nav, account button, tab bar). The login pages turn it off. */
	user?: boolean;
	mobile: string;
	desktop: string;
	mobileTab?: MobileTab;
	desktopTab?: DesktopTab;
	/** Mobile only: pinned above the tab bar (the notes composer). */
	dock?: string;
	/** Desktop only: let the content run edge to edge (the sign in split). */
	full?: boolean;
};

const tabs = (a: MobileTab) =>
	'<nav class="tb" aria-label="Main">' +
	(
		[
			["home", "Home", "home", "/home"],
			["notes", "Notes", "notes", "/notes"],
			["goals", "Goals", "goal", "/goals"],
			["history", "History", "hist", "/history"],
		] as const
	)
		.map(([key, label, icon, href]) => `<a href="${href}" class="${a === key ? "on" : ""}">${ic(icon)}${label}</a>`)
		.join("") +
	"</nav>";

const topNav = (a: DesktopTab) =>
	'<nav class="nl d" aria-label="Main">' +
	(
		[
			["home", "Home", "/home"],
			["notes", "Notes", "/notes"],
			["plan", "Plan", "/plan"],
			["history", "History", "/history"],
		] as const
	)
		.map(([key, label, href]) => `<a href="${href}" class="${a === key ? "on" : ""}">${label}</a>`)
		.join("") +
	"</nav>";

const accountMenu =
	`<details class="mw d"><summary class="ib" aria-label="Account">${ic("user")}</summary>` +
	`<div class="mn"><a class="mi" href="/settings">${ic("user")}Profile</a><a class="mi" href="/settings">${ic("gear")}Settings</a>` +
	`<form method="post" action="/logout"><button class="mi">${ic("out")}<span class="neg">Log out</span></button></form></div></details>`;

export function page(o: PageOptions): string {
	let user = o.user !== false;
	return (
		`<!DOCTYPE html><html lang="en" data-theme="dark"><head><meta charset="utf-8">` +
		`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` +
		`<meta name="theme-color" content="#121212"><title>${o.title} · moneytracker</title>` +
		`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap">` +
		`<style>${css}</style><script>${themeBoot}</script></head><body><div class="app">` +
		`<header class="bar"><div class="in">${logo(user ? "/home" : "/login")}${user ? topNav(o.desktopTab ?? "") : ""}` +
		`<div class="rt">${themeBtn}${user ? `<a class="ib m" href="/profile" aria-label="Account">${ic("user")}</a>${accountMenu}` : ""}</div></div></header>` +
		`<main><div class="m mm">${o.mobile}</div><div class="d pg${o.full ? " full" : ""}">${o.desktop}</div></main>` +
		(user ? `<div class="dock m">${o.dock ?? ""}${tabs(o.mobileTab ?? "")}</div>` : "") +
		`</div><script>${script}</script></body></html>`
	);
}
