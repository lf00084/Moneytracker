import { SITE } from "../lib/assets.ts"
import { env } from "../env.ts"
import { ClockWidget, SubDate } from "./clock.tsx"
import { Icon } from "./icons.tsx"
import { Logo, ThemeIcons } from "./primitives.tsx"
type Kids = { children?: unknown }
export type MobileTab = "home" | "notes" | "goals" | "income" | "pad" | "history" | "profile" | ""
export type DesktopTab = "home" | "notes" | "plan" | "income" | "pad" | "history" | "settings" | ""
export type PageSpec = { title: string; mobileTab?: MobileTab; desktopTab?: DesktopTab; mobile: unknown; desktop: unknown; dock?: unknown; full?: boolean }
const origin = () => env.APP_ORIGIN.replace(/\/$/, "")
const ld = () => JSON.stringify({ "@context": "https://schema.org", "@type": "WebApplication", name: SITE.name, url: origin(), description: SITE.desc, applicationCategory: "FinanceApplication", operatingSystem: "Any" })
export function Document({ title, desc = SITE.desc, path, user, theme, children }: Kids & { title: string; desc?: string; path?: string; user: boolean; theme?: string }) {
const full = `${title} · ${SITE.name}`
return (
<html lang="en" data-theme={theme === "light" ? "light" : "dark"}>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<meta name="theme-color" content={SITE.color} />
<title>{full}</title>
<meta name="description" content={desc} />
<meta name="robots" content={user ? "noindex,nofollow" : "index,follow"} />
<meta name="application-name" content={SITE.name} />
<meta name="apple-mobile-web-app-title" content={SITE.name} />
<meta name="mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black" />
<meta name="format-detection" content="telephone=no" />
<link rel="manifest" href="/manifest.webmanifest" />
<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
<link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png" />
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
<meta property="og:type" content="website" />
<meta property="og:site_name" content={SITE.name} />
<meta property="og:title" content={full} />
<meta property="og:description" content={desc} />
<meta property="og:image" content={`${origin()}/icon-512.png`} />
<meta name="twitter:card" content="summary" />
<meta name="twitter:title" content={full} />
<meta name="twitter:description" content={desc} />
{path && !user ? <link rel="canonical" href={`${origin()}${path}`} /> : null}
{path && !user ? <meta property="og:url" content={`${origin()}${path}`} /> : null}
{user ? null : <script type="application/ld+json">{ld()}</script>}
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap" />
<link rel="stylesheet" href="/assets/app.css" />
{theme ? null : <script src="/assets/theme.js"></script>}
{import.meta.env.DEV ? <script type="module" src="/@vite/client"></script> : null}
</head>
<body>
<div class="app">{children}</div>
<script src="/assets/app.js" defer></script>
</body>
</html>
)
}
const mobileTabs = [["home", "Home", "home", "/home"], ["notes", "Notes", "notes", "/notes"], ["income", "Income", "gear", "/income"], ["pad", "Pad", "pad", "/pad"], ["profile", "Profile", "user", "/profile"]] as const
const desktopTabs = [["home", "Home", "home", "/home"], ["notes", "Notes", "notes", "/notes"], ["plan", "Plan", "goal", "/plan"], ["income", "Income", "coin", "/income"], ["pad", "Pad", "pad", "/pad"], ["history", "History", "hist", "/history"], ["settings", "Settings", "gear", "/settings"]] as const
const BottomBar = ({ active }: { active: MobileTab }) => (
<nav class="bt" aria-label="Main">{mobileTabs.map(([key, label, icon, href]) => <a href={href} class={active === key ? "on" : ""} aria-label={label}><Icon name={icon} /></a>)}</nav>
)
const Sidebar = ({ active }: { active: DesktopTab }) => (
<aside class="sb d"><Logo href="/home" />{desktopTabs.map(([key, label, icon, href]) => <a class={`sbl${active === key ? " on" : ""}`} href={href}><Icon name={icon} />{label}</a>)}<div class="sp"></div><button type="button" class="sbl" data-theme-toggle><ThemeIcons /><span>Theme</span></button><form method="post" action="/logout"><button class="sbl"><Icon name="out" /><span class="neg">Log out</span></button></form></aside>
)
export const AppPage = ({ title, theme, mobileTab = "", desktopTab = "", mobile, desktop, dock, full }: PageSpec & { theme?: string }) => (
<Document title={title} user={true} theme={theme}>
<Sidebar active={desktopTab} />
<main>
<div class="m"><div class="top-status-bar tsplit"><ClockWidget /><div class="clock-subdate" dir="ltr"><SubDate /></div></div></div>
<div class="m mm">{mobile}</div>
<div class="d"><div class="top-status-bar"><ClockWidget /></div></div>
<div class={`d pg${full ? " full" : ""}`}>{desktop}</div>
</main>
<div class="dock m">{dock}<BottomBar active={mobileTab} /></div>
</Document>
)
export const AuthPage = ({ title, desc, path, children }: Kids & { title: string; desc: string; path: string }) => (
<Document title={title} desc={desc} path={path} user={false}>
<div class="tf-clock"><ClockWidget /><button type="button" class="ib" data-theme-toggle aria-label="Theme"><ThemeIcons /></button></div>
<main class="auth-viewport">{children}</main>
</Document>
)
