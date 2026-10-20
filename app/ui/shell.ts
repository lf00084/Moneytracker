import { css } from "./css.ts";
import { ic, logo, themeIcons } from "./parts.ts";
import { script, themeBoot } from "./script.ts";

export type MobileTab = "home" | "notes" | "goals" | "history" | "profile" | "";
export type DesktopTab = "home" | "notes" | "plan" | "history" | "settings" | "";

export type PageOptions = {
	title: string;
	/** Signed-in chrome (bottom bar, sidebar). The login pages turn it off. */
	user?: boolean;
	mobile: string;
	desktop: string;
	mobileTab?: MobileTab;
	desktopTab?: DesktopTab;
	/** Mobile only: pinned above the bottom bar (the notes composer). */
	dock?: string;
	/** Desktop only: let the content run edge to edge (the sign in split). */
	full?: boolean;
	/** The signed-in user's saved theme. When set it wins over the browser's copy. */
	theme?: string;
};

/** Phone: icon-only bottom bar, like X. Home, Notes, Goals, History, Profile. */
const bottomBar = (a: MobileTab) =>
	'<nav class="bt" aria-label="Main">' +
	(
		[
			["home", "Home", "home", "/home"],
			["notes", "Notes", "notes", "/notes"],
			["goals", "Goals", "goal", "/goals"],
			["history", "History", "hist", "/history"],
			["profile", "Profile", "user", "/profile"],
		] as const
	)
		.map(([key, label, icon, href]) => `<a href="${href}" class="${a === key ? "on" : ""}" aria-label="${label}">${ic(icon)}</a>`)
		.join("") +
	"</nav>";

/** Desktop: left sidebar, like X. */
const sidebar = (a: DesktopTab) =>
	`<aside class="sb d">${logo("/home")}` +
	(
		[
			["home", "Home", "home", "/home"],
			["notes", "Notes", "notes", "/notes"],
			["plan", "Plan", "goal", "/plan"],
			["history", "History", "hist", "/history"],
			["settings", "Settings", "gear", "/settings"],
		] as const
	)
		.map(([key, label, icon, href]) => `<a class="sbl${a === key ? " on" : ""}" href="${href}">${ic(icon)}${label}</a>`)
		.join("") +
	`<div class="sp"></div><button type="button" class="sbl" data-theme-toggle>${themeIcons}<span>Theme</span></button>` +
	`<form method="post" action="/logout"><button class="sbl">${ic("out")}<span class="neg">Log out</span></button></form></aside>`;

export function page(o: PageOptions): string {
	let user = o.user !== false;
	return (
		`<!DOCTYPE html><html lang="en" data-theme="${o.theme === "light" ? "light" : "dark"}"><head><meta charset="utf-8">` +
		`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` +
		`<meta name="theme-color" content="#121212"><title>${o.title} · moneytracker</title>` +
		`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap">` +
		`<style>${css}</style><script>${o.theme ? "" : themeBoot}</script></head><body><div class="app">` +
		(user ? sidebar(o.desktopTab ?? "") : `<button type="button" class="ib tf" data-theme-toggle aria-label="Theme">${themeIcons}</button>`) +
		`<main><div class="m mm">${o.mobile}</div><div class="d pg${o.full ? " full" : ""}">${o.desktop}</div></main>` +
		(user ? `<div class="dock m">${o.dock ?? ""}${bottomBar(o.mobileTab ?? "")}</div>` : "") +
		`</div><script>${script}</script></body></html>`
	);
}
