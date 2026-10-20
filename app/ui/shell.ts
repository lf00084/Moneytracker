import { css } from "./css.ts";
import { clockWidget, ic, logo, themeIcons } from "./parts.ts";
import { script, themeBoot } from "./script.ts";
import { liveClockNow } from "../lib/time.ts";

export type MobileTab = "home" | "notes" | "goals" | "history" | "profile" | "";
export type DesktopTab = "home" | "notes" | "plan" | "history" | "settings" | "";

const splitCss = ".top-status-bar.tsplit{justify-content:space-between}.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}";

export type PageOptions = {
title: string;
user?: boolean;
mobile: string;
desktop: string;
mobileTab?: MobileTab;
desktopTab?: DesktopTab;
dock?: string;
full?: boolean;
theme?: string;
mobileBar?: boolean;
};

const bottomBar = (a: MobileTab) =>
'<nav class="bt" aria-label="Main">' +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["profile", "Profile", "user", "/profile"],
] as const
)
.map(([key, label, icon, href]) => `<a href="${href}" class="${a === key ? "on" : ""}" aria-label="${label}">${ic(icon)}</a>`)
.join("") +
"</nav>";

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
const user = o.user !== false;
const { timeStr, dateStr, subDateStr } = liveClockNow();
const clock = clockWidget(timeStr, dateStr, subDateStr);
const topBar = `<div class="top-status-bar">${clock}</div>`;
const mobileTop = `<div class="top-status-bar tsplit">${clock}<div class="clock-subdate" dir="ltr">${subDateStr}</div></div>`;

return (
`<!DOCTYPE html><html lang="en" data-theme="${o.theme === "light" ? "light" : "dark"}"><head><meta charset="utf-8">` +
`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` +
`<meta name="theme-color" content="#121212"><title>${o.title} · moneytracker</title>` +
`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap">` +
`<style>${css}${splitCss}</style><script>${o.theme ? "" : themeBoot}</script></head>` +
`<body>` +
`<div class="app">` +
(user
? sidebar(o.desktopTab ?? "")
: `<div class="tf-clock">${clock}<button type="button" class="ib" data-theme-toggle aria-label="Theme">${themeIcons}</button></div>`) +
(user
? `<main><div class="m">${mobileTop}</div><div class="m mm">${o.mobile}</div><div class="d">${topBar}</div><div class="d pg${o.full ? " full" : ""}">${o.desktop}</div></main>`
: `<main class="auth-viewport">${o.desktop}</main>`) +
(user ? `<div class="dock m">${o.dock ?? ""}${bottomBar(o.mobileTab ?? "")}</div>` : "") +
`</div><script>${script}</script></body></html>`
);
}
