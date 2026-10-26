import type { RemixNode } from "remix/component"
import { env } from "../env.ts"
import { SITE } from "../lib/assets.ts"
import { liveClockNow } from "../lib/time.ts"
import { V } from "../lib/static.ts"
import { Icon, Logo, Submit, ThemeIcons, view } from "./ui.tsx"

type DocumentProps = {
	title: string
	user?: boolean
	theme?: string
	desc?: string
	path?: string
	auth?: boolean
	children?: RemixNode
}

const THEME_BOOT = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`
const REGISTER_SW = `if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))`
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Noto+Sans+Arabic:wght@500;600&display=swap"

export const Document = view<DocumentProps>(({ title, user = true, theme, desc, path, auth, children }) => {
	const description = desc ?? SITE.desc
	const origin = env.APP_ORIGIN.replace(/\/$/, "")
	const fullTitle = `${title} · ${SITE.name}`
	const ld = JSON.stringify({
		"@context": "https://schema.org",
		"@type": "WebApplication",
		name: SITE.name,
		url: origin,
		description: SITE.desc,
		applicationCategory: "FinanceApplication",
		operatingSystem: "Any",
	}).replace(/</g, "\\u003c")

	return (
		<html lang="en" data-theme={theme === "light" ? "light" : "dark"}>
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="theme-color" content={SITE.color} />
				<title>{fullTitle}</title>
				<meta name="description" content={description} />
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
				<meta property="og:title" content={fullTitle} />
				<meta property="og:description" content={description} />
				<meta property="og:image" content={`${origin}/icon-512.png`} />
				<meta name="twitter:card" content="summary" />
				<meta name="twitter:title" content={fullTitle} />
				<meta name="twitter:description" content={description} />
				{path && !user ? <link rel="canonical" href={`${origin}${path}`} /> : null}
				{path && !user ? <meta property="og:url" content={`${origin}${path}`} /> : null}
				{user ? null : <script type="application/ld+json">{ld}</script>}
				<link rel="preconnect" href="https://fonts.googleapis.com" />
				<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
				<link rel="stylesheet" href={FONTS} />
				<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2.1.1/css/pico.min.css" />
				<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />
				{auth ? <link rel="stylesheet" href={`/assets/auth.css?v=${V.auth}`} /> : null}
				{theme ? null : <script>{THEME_BOOT}</script>}
			</head>
			<body>
				{children}
				<script src={`/assets/app.js?v=${V.js}`} defer></script>
				<script>{REGISTER_SW}</script>
			</body>
		</html>
	)
})

type Parts = { numDate: string; arabicDay: string }

const SubDate = view<Parts>(({ numDate, arabicDay }) => (
	<>
		<span class="clock-num">{numDate}</span> <span class="clock-dot">·</span> <span class="clock-ar">{arabicDay}</span>
	</>
))

export const ClockWidget = view(() => {
	const { timeStr, dateStr, numDate, arabicDay } = liveClockNow()
	return (
		<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time">
			<div class="clock-time" data-clock-time>
				{timeStr}
			</div>
			<div class="clock-date" data-clock-date>
				{dateStr}
			</div>
			<div class="clock-subdate" data-clock-subdate dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})

export const TopBar = view<{ split?: boolean; left?: RemixNode }>(({ split, left }) => {
	if (!split) {
		return (
			<div class="top-status-bar">
				<ClockWidget />
			</div>
		)
	}
	const { numDate, arabicDay } = liveClockNow()
	return (
		<div class="top-status-bar tsplit">
			{left}
			<ClockWidget />
			<div class="clock-subdate" dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})

export type DesktopTab = "home" | "notes" | "plan" | "income" | "trading" | "pad" | "history" | "settings" | ""

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "history", label: "History", icon: "hist", href: "/history" },
	{ key: "settings", label: "Settings", icon: "gear", href: "/settings" },
] as const

export const Sidebar = view<{ active: DesktopTab }>(({ active }) => (
	<aside class="sb d">
		<Logo href="/home" />
		{LINKS.map((l) => (
			<a key={l.key} class={active === l.key ? "sbl on" : "sbl"} href={l.href}>
				<Icon name={l.icon} />
				{l.label}
			</a>
		))}
		<div class="sp"></div>
		<button type="button" class="sbl" data-theme-toggle>
			<ThemeIcons />
			<span>Theme</span>
		</button>
		<form method="post" action="/logout">
			<Submit class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</Submit>
		</form>
	</aside>
))

export type MobileTab = "home" | "notes" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "bhome", href: "/home" },
	{ key: "trading", label: "Trading", icon: "btrade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "bdoc", href: "/pad" },
	{ key: "income", label: "Income", icon: "bsun", href: "/income" },
	{ key: "notes", label: "Notes", icon: "bchat", href: "/notes" },
	{ key: "profile", label: "Profile", icon: "buser", href: "/profile" },
] as const

export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label}>
				<Icon name={t.icon} />
			</a>
		))}
	</nav>
))

type AppLayoutProps = {
	title: string
	theme?: string
	mobile: RemixNode
	desktop: RemixNode
	mobileTab?: MobileTab
	desktopTab?: DesktopTab
	dock?: RemixNode
	full?: boolean
	topLeft?: RemixNode
}

export const AppLayout = view<AppLayoutProps>(({ title, theme, mobile, desktop, mobileTab = "", desktopTab = "", dock, full, topLeft }) => (
	<Document title={title} theme={theme}>
		<div class="app">
			<Sidebar active={desktopTab} />
			<main>
				<div class="m">
					<TopBar split left={topLeft} />
				</div>
				<div class="m mm hm">{mobile}</div>
				<div class="d">
					<TopBar />
				</div>
				<div class={full ? "d pg full" : "d pg"}>{desktop}</div>
			</main>
			<div class="dock m">
				{dock}
				<BottomBar active={mobileTab} />
			</div>
		</div>
	</Document>
))

type AuthLayoutProps = { title: string; path: string; desc: string; children?: RemixNode }

export const AuthLayout = view<AuthLayoutProps>(({ title, path, desc, children }) => (
	<Document title={title} path={path} desc={desc} user={false} auth>
		<div class="app">
			<main class="auth-main">{children}</main>
		</div>
	</Document>
))
