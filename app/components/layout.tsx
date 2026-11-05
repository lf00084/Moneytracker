import type { RemixNode } from "remix/component"
import { clientEntry, type Handle } from "remix/component"
import { entryId, ENTRY_HREF } from "../client/entry-url.ts"
import { env } from "../env.ts"
import { SITE } from "../lib/assets.ts"
import { V } from "../lib/static.ts"
import { BottomBar, type MobileTab } from "./bottombar.tsx"
import { ClockWidget } from "./clock.tsx"
import { Icon, Link, Logo, Submit, ThemeIcons, view } from "./ui.tsx"

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
// Dev loads the source entry through Vite. The script URL must match the one
// loadModule imports (Vite rewrites dynamic imports to `?import`) or the
// module executes twice. Production serves the prebuilt bundle at the plain
// URL (the assets route answers with ETag/no-cache when no ?v is pinned).
const ENTRY_SRC = import.meta.env.DEV ? `${ENTRY_HREF}?import` : ENTRY_HREF

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
				<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />
				{theme ? null : <script>{THEME_BOOT}</script>}
			</head>
			<body>
				{children}
				<script type="module" src={ENTRY_SRC}></script>
				<script>{REGISTER_SW}</script>
			</body>
		</html>
	)
})

export const TopBar = view(() => (
	<div class="top-status-bar">
		<ClockWidget />
	</div>
))

export type DesktopTab = "home" | "income" | "trading" | "pad" | "profile" | "plan" | "history" | "settings" | ""

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "income", label: "On hold", icon: "coin", href: "/income" },
	{ key: "trading", label: "P2P & Predict", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "profile", label: "Profile", icon: "gear", href: "/profile" },
] as const

export const Sidebar = view<{ active: DesktopTab }>(({ active }) => (
	<aside class="sb d">
		<Logo href="/home" />
		<nav class="sb-nav">
			{LINKS.map((l) => (
				<Link key={l.key} class={active === l.key ? "sbl on" : "sbl"} href={l.href} aria-current={active === l.key ? "page" : undefined}>
					<Icon name={l.icon} />
					{l.label}
				</Link>
			))}
		</nav>
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

type AppLayoutProps = {
	title: string
	theme?: string
	mobile: RemixNode
	desktop: RemixNode
	mobileTab?: MobileTab
	desktopTab?: DesktopTab
	dock?: RemixNode
	full?: boolean
}

export const AppLayout = view<AppLayoutProps>(({ title, theme, mobile, desktop, mobileTab = "", desktopTab = "", dock, full }) => (
	<Document title={title} theme={theme}>
		<div class="app">
			<Sidebar active={desktopTab} />
			<main>
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
		<div class="app auth">
			<main class="auth-main">{children}</main>
		</div>
	</Document>
))
