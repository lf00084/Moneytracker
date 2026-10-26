#!/bin/bash
set -e
cd "$(dirname "$0")"
cat > app/components/layout.tsx << 'EOF'
import type { RemixNode } from "remix/component"
import { env } from "../env.ts"
import { SITE } from "../lib/assets.ts"
import { liveClockNow } from "../lib/time.ts"
import { V } from "../lib/static.ts"
import { Icon, Logo, ThemeIcons, view } from "./ui.tsx"

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
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap"

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
			<button class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</button>
		</form>
	</aside>
))

export type MobileTab = "home" | "notes" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "income", label: "Income", icon: "gear", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "profile", label: "Profile", icon: "user", href: "/profile" },
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
				<div class="m mm">{mobile}</div>
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
EOF
cat > app/screens.tsx << 'EOF'
import { BuysDesktop, BuysExpand, Hero, TodayCards } from "./components/buys.tsx"
import { OweDesktop, OweMobile, RoadCard } from "./components/debts.tsx"
import { GoalsExpand } from "./components/goals.tsx"
import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"
import { HomeIncome, IncomeDesktop, IncomeExpand } from "./components/income.tsx"
import { AppLayout, AuthLayout } from "./components/layout.tsx"
import { ChatHead, Composer, NoteCard, NoteList } from "./components/notes.tsx"
import { BalanceCard, EditProfileMobile, ProfileMobile, SettingsDesktop, SettingsMobile } from "./components/profile.tsx"
import { TradingBody } from "./components/trading.tsx"
import { ErrorBanner, FloatField, GoogleMark, Logo, PageHeader, Section, view } from "./components/ui.tsx"
import type { State } from "./lib/data.ts"
import { fmt } from "./lib/money.ts"
import { calc } from "./lib/view.ts"

export const HomeScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Home"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="home"
		mobile={
			<>
				<ErrorBanner s={s} />
				<BalanceCard s={s} />
				<TodayCards s={s} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<Hero s={s} />
				<div class="g2">
					<div>
						<BuysDesktop s={s} />
					</div>
					<div>
						<OweDesktop s={s} open={false} storeKey="owe" />
						<IncomeDesktop s={s} bare />
						<NoteCard s={s} />
					</div>
				</div>
			</>
		}
	/>
))

export const DebtsScreen = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<AppLayout
			title="Debts"
			theme={s.user.theme}
			mobileTab="home"
			desktopTab="home"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={s.debts.map((d) => d.person).slice(0, 2).join(" + ")} />
					<RoadCard s={s} />
					<OweMobile s={s} open storeKey="owe-page" manage />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`} />
					<div class="g3">
						<div>
							<OweDesktop s={s} open storeKey="owe-page" manage />
						</div>
						<div>
							<Section title="How it works">
								<div class="rw">
									<span>+ left of a name</span>
									<span class="mu">adds to that person</span>
								</div>
								<div class="rw">
									<span>Pay</span>
									<span class="mu">counts as a buy today</span>
								</div>
								<div class="rw">
									<span>Paid to 0</span>
									<span class="mu">hidden, kept in history</span>
								</div>
								<div class="rw">
									<span>Type old name</span>
									<span class="mu">brings them back</span>
								</div>
							</Section>
						</div>
					</div>
				</>
			}
		/>
	)
})

export const GoalsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Goals"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="plan"
		mobile={
			<>
				<PageHeader title="Goals" right="add, edit, remove" />
				<ErrorBanner s={s} />
				<GoalsExpand s={s} open storeKey="goals-page" manage />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<PageHeader title="Plan" right="goals + income" />
				<div class="g3">
					<div>
						<GoalsExpand s={s} open storeKey="goals-d" manage />
					</div>
					<div>
						<IncomeDesktop s={s} />
					</div>
				</div>
			</>
		}
	/>
))

export const HistoryScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="History"
		theme={s.user.theme}
		mobileTab="history"
		desktopTab="history"
		mobile={
			<>
				<PageHeader title="History" right="last 30 days" />
				<HistoryMobile s={s} />
			</>
		}
		desktop={<HistoryDesktop s={s} />}
	/>
))

export const IncomeScreen = view<{ s: State }>(({ s }) => {
	const earned = calc(s).earned
	return (
		<AppLayout
			title="Income"
			theme={s.user.theme}
			mobileTab="income"
			desktopTab="income"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Income" right={earned ? `+${fmt(earned)} today` : ""} />
					<IncomeExpand s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<div class="hd">
						<h1 class="t">Income</h1>
						<span></span>
					</div>
					<IncomeExpand s={s} />
				</>
			}
		/>
	)
})

export const NotesScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Notes"
		theme={s.user.theme}
		mobileTab="notes"
		desktopTab="notes"
		mobile={
			<>
				<ChatHead />
				<NoteList s={s} listKey="m" />
			</>
		}
		dock={<Composer s={s} listKey="m" />}
		desktop={
			<div class="chat" data-x>
				<ChatHead />
				<NoteList s={s} listKey="d" />
				<div style={{ margin: "30px 0 0" }}>
					<Composer s={s} listKey="d" />
				</div>
			</div>
		}
	/>
))

export const PadScreen = view<{ s: State }>(({ s }) => <AppLayout title="Pad" theme={s.user.theme} mobileTab="pad" desktopTab="pad" mobile={null} desktop={null} />)

export const ProfileScreen = view<{ s: State }>(({ s }) => (
	<AppLayout title="Profile" theme={s.user.theme} mobileTab="profile" desktopTab="settings" mobile={<ProfileMobile s={s} />} desktop={<SettingsDesktop s={s} />} />
))

export const ProfileEditScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Edit profile"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="Edit profile" back="/profile" />
				<EditProfileMobile s={s} />
			</>
		}
		desktop={<SettingsDesktop s={s} />}
	/>
))

export const SettingsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Settings"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="Settings" back="/profile" />
				<SettingsMobile s={s} />
			</>
		}
		desktop={<SettingsDesktop s={s} />}
	/>
))

export const TradingScreen = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.user.usdt_rate)} ${s.user.currency}`
	return (
		<AppLayout
			title="Trading"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
		/>
	)
})

const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-center-wrap">
		<div class="auth-glass-box">
			<div class="auth-logo-center">
				<Logo href="/login" />
			</div>
			<h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1>
			<div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>
			<form class="au" method="post" action={up ? "/signup" : "/login"}>
				<a class="gbtn" href="/login/google">
					<GoogleMark />
					<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
				</a>
				<div class="or">or</div>
				{error ? (
					<div class="auth-err-banner" role="alert">
						{error}
					</div>
				) : null}
				{up ? <FloatField label="Name" name="name" auto="name" /> : null}
				<FloatField label="Email" type="email" name="email" auto="email" />
				<FloatField label="Password" type="password" name="password" auto={up ? "new-password" : "current-password"} />
				<button class="btn full">{up ? "Create account" : "Sign in"}</button>
				<div class="auth-switch-wrap">
					<a class="lnk-switch" href={up ? "/login" : "/signup"}>
						{up ? (
							<>
								Already have an account? <b>Sign in</b>
							</>
						) : (
							<>
								Don't have an account? <b>Create account</b>
							</>
						)}
					</a>
				</div>
			</form>
		</div>
	</div>
))

export const LoginScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker.">
		<AuthCard up={false} error={error} />
	</AuthLayout>
))

export const SignupScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals.">
		<AuthCard up error={error} />
	</AuthLayout>
))
EOF
cat > app/components/income.tsx << 'EOF'
import type { Income, Source, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { isFixed } from "../lib/util.ts"
import { calc, gotToday, srcAmount } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, view } from "./ui.tsx"

const contents = { display: "contents" }
const rateOf = (x: Source) => Number(x.config.rate_minor) || 0
const tagOf = (x: Source) => (!x.active ? "paused" : x.type === "exoclick" ? "exoclick" : isFixed(x.type) ? "fixed" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "daily") : "manual")
const usdTxt = (n: number) => `$${fmt(n)}`
const exoSub = (s: State, x: Source) => s.exo[x.id] || `${usdTxt(s.exoToday[x.id] ?? 0)} today`

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
))

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`incl. ${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">
				+{fmt(i.amount)} <small>{s.user.currency}</small>
			</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<button class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
))

const HoursPanel = view<{ s: State; x: Source; row: Income }>(({ s, x, row }) => {
	const rate = rateOf(x)
	const h = row.hours
	const cur = s.user.currency
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))} ${cur}` : `${fmt(rate)} ${cur} / hour`}</span>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hxb">
				<div class="hxg">
					{opts.map((n) => (
						<form key={n} method="post" action="/income/hours" style={contents}>
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input type="hidden" name="hours" value={String(n)} />
							<input type="hidden" name="toggle" value="1" />
							<button class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</button>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<button class="btn xs o">Set</button>
					<button type="button" class="btn xs o" data-close>
						Close
					</button>
				</form>
			</div>
		</details>
	)
})

const HomeAct = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const amt = (n: number) => (
		<b class="ea">
			+{fmt(n)} <small>{cur}</small>
		</b>
	)
	if (x.type === "exoclick") {
		return (
			<>
				{amt(sum)}
				<span></span>
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				{amt(x.amount)}
				<span></span>
			</>
		)
	}
	if (got.length) {
		return (
			<>
				{amt(sum)}
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</button>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan" data-tg>
			Add
		</button>
	)
})


const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
))

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const all = gotToday(s, x)
	const got = fixedSrc ? all[0] : undefined
	const cur = s.user.currency
	const exo = x.type === "exoclick"
	const sub = exo ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} ${cur} + ${fmt(rateOf(x))} / hour`) : ""
	const manual = !fixedSrc && !exo && x.mode !== "auto" && !all.length
	return (
		<div class="sw dbw" data-exo={exo ? "1" : undefined}>
			<div class="hr">
				<div class="hn">
					<div>{x.name}</div>
					{sub ? <div class={exo && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
					{exo && s.exo[x.id] ? (
						<a class="lnk" href="/income">
							Fix
						</a>
					) : null}
				</div>
				<HomeAct s={s} x={x} />
			</div>
			{manual ? (
				<form method="post" action="/income/add" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<div class="ln">
						<input class="in" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs">Add</button>
					</div>
				</form>
			) : null}
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	)
})

const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<button class="btn full">Add income</button>
	</>
))

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
	["exoclick", "ExoClick"],
]

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<input class="in" name="name" placeholder="Source name (e.g. Construction)" autocomplete="off" required />
		<input type="hidden" name="kind" value="fixed" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 8px" }}>
			{KINDS.map(([k, l]) => (
				<span key={k} class={k === "fixed" ? "chip on" : "chip"} data-mode={k} style={{ cursor: "pointer" }}>
					{l}
				</span>
			))}
		</div>
		<div class="kf kf-fixed">
			<div class="ln">
				<input class="in" name="fixed" placeholder="Per day" inputmode="decimal" autocomplete="off" />
				<input class="in" name="rate" placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
			</div>
			<div class="lb">Tap it once a day on Home, then pick the extra hours.</div>
		</div>
		<div class="kf kf-manual">
			<div class="lb">You type the amount yourself each day.</div>
		</div>
		<div class="kf kf-daily kf-monthly">
			<input class="in" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
			<div class="lb">Added for you automatically.</div>
		</div>
		<div class="kf kf-exoclick">
			<input class="in" name="api_key" type="password" placeholder="ExoClick API key" autocomplete="off" />
			<div class="lb">Saved encrypted. Counted in USD during the day, converted to {s.user.currency} when the day ends.</div>
		</div>
		<button class="btn full">Add source</button>
	</>
))

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-kind="fixed" data-adp hidden>
		<SourceFields s={s} />
	</form>
))

const TodayRows = view<{ s: State }>(({ s }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return sources.length || others.length ? (
		<>
			{sources.map((x) => (
				<HomeRow key={x.id} s={s} x={x} />
			))}
			{others.map((i) => (
				<IncomeRow key={i.id} s={s} i={i} />
			))}
		</>
	) : (
		<Empty>No sources yet. Add one on the Income page.</Empty>
	)
})

export const IncomeDesktop = view<{ s: State; title?: string; id?: string; bare?: boolean }>(({ s, title = "Income today", id = "f-inc-d", bare = false }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	if (bare) {
		return (
			<div class="sc incbare">
				<TodayRows s={s} />
			</div>
		)
	}
	return (
		<>
			<form method="post" action="/income/named" id={id} class="sc spf" data-adp hidden>
				<NamedFields s={s} />
			</form>
			<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add manual income">
				{sources.length || others.length ? (
					<>
						{sources.map((x) => (
							<HomeRow key={x.id} s={s} x={x} />
						))}
						{others.map((i) => (
							<IncomeRow key={i.id} s={s} i={i} />
						))}
					</>
				) : (
					<Empty>No sources yet. Add one on the Income page.</Empty>
				)}
			</ListCard>
		</>
	)
})

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : ""
	return (
		<div class="dbw" data-exo={x.type === "exoclick" ? "1" : undefined}>
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{tagOf(x)}</span>
					</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">{x.active ? "Pause" : "Resume"}</button>
					</form>
					<button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}>
						<Icon name="edit" />
					</button>
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			<form method="post" action="/income/edit" class="ad" data-addp hidden>
				<Hid s={s} id={x.id} />
				<label>Edit {x.name}</label>
				<input class="in f" name="name" value={x.name} autocomplete="off" required />
				{fixedSrc ? (
					<div class="ln" style={{ marginTop: "8px" }}>
						<input class="in" name="fixed" value={fixed ? plain(fixed) : ""} placeholder="Per day" inputmode="decimal" autocomplete="off" />
						<input class="in" name="rate" value={rateOf(x) ? plain(rateOf(x)) : ""} placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
					</div>
				) : null}
				{x.type === "exoclick" ? <input class="in" style={{ marginTop: "8px" }} name="api_key" type="password" placeholder="New API key (leave empty to keep)" autocomplete="off" /> : null}
				{!fixedSrc && x.type !== "exoclick" && x.mode === "auto" ? <input class="in" style={{ marginTop: "8px" }} name="amount" value={plain(x.amount)} placeholder="Amount" inputmode="decimal" autocomplete="off" /> : null}
				<button class="btn xs" style={{ marginTop: "10px" }}>
					Save
				</button>
			</form>
		</div>
	)
})

export const IncomeExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="income"
		open
		title="Income sources"
		label="Add source"
		head={
			<>
				<b class="big2">{s.sources.length}</b>
				<span class="lb">{`${s.sources.filter((x) => x.active).length} active`}</span>
			</>
		}
		form={<SourceForm s={s} />}
	>
		{s.sources.length ? <>{s.sources.map((x) => <ManageRow key={x.id} s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>}
	</ExpandCard>
))

export const HomeIncome = view<{ s: State }>(({ s }) => (
	<div class="xc xbare">
		<div class="xb">
			<TodayRows s={s} />
		</div>
	</div>
))
EOF
cat > app/client/app.css << 'EOF'
:root:root:root{--pico-font-family:var(--font-sys);--pico-font-size:100%;--pico-line-height:1.45;--pico-background-color:var(--bg);--pico-color:var(--ink);--pico-muted-color:var(--mu);--pico-muted-border-color:var(--ln);--pico-primary:var(--ac);--pico-primary-background:var(--ac);--pico-primary-border:var(--ac);--pico-primary-hover:var(--ac);--pico-primary-hover-background:var(--ac);--pico-primary-hover-border:var(--ac);--pico-primary-focus:var(--acs);--pico-primary-inverse:var(--on);--pico-border-radius:12px;--pico-border-width:1px;--pico-outline-width:3px;--pico-block-spacing-vertical:0px;--pico-block-spacing-horizontal:0px;--pico-form-element-background-color:var(--s1);--pico-form-element-border-color:var(--ln);--pico-form-element-color:var(--ink);--pico-form-element-placeholder-color:var(--mu);--pico-form-element-active-background-color:var(--s1);--pico-form-element-active-border-color:var(--ac);--pico-form-element-focus-color:var(--ac);--pico-form-element-disabled-background-color:var(--s2);--pico-form-element-spacing-vertical:.8rem;--pico-form-element-spacing-horizontal:1rem;--pico-form-element-invalid-border-color:var(--neg);--pico-form-element-invalid-active-border-color:var(--neg);--pico-form-element-invalid-focus-color:var(--neg)}
html input:not([type=checkbox]):not([type=radio]):not([type=hidden]),html select,html textarea,form,h1,h2,h3{margin:0}
button:not(:focus-visible):focus{box-shadow:none}
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}
.cd,.sc,.xc,.hero{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}
a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}
button{cursor:pointer}
.mu,.lb{color:var(--mu)}
.lb{font-size:11px;font-family:var(--mono)}
.pos{color:var(--pos)!important}
.neg{color:var(--neg)!important}
.ea{color:var(--earn)!important}
.sp{color:var(--spend)!important}
.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}
details{margin:0}
details>summary:not([role])::after,details>summary::after{content:none}
details>summary:not([role]){color:inherit}
details[open]>summary{margin-bottom:0}
summary::-webkit-details-marker{display:none}
button,input[type=button],input[type=submit],.btn,.sbl,.chip,.ib{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.chip:active,.ib:active{transform:scale(.97);opacity:.88}
.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
@media(min-width:900px){
	.m{display:none!important}
}
@media(max-width:899px){
	.d{display:none!important}
}
.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){
	.app{flex-direction:column}
}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}
.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib{flex:none;aspect-ratio:1}
.ib.sm{width:28px;height:28px;min-width:28px}
.ib svg.ic{width:16px;height:16px}
.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}
.bt .on svg.ic{stroke-width:2}
.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}
.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}
.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}
h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}
.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}
.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}
.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}
.cd{margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}
.two .cb{padding:3px 12px 10px}
.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}
.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.fl{margin-top:14px}
.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}
.ln{display:flex;gap:10px;align-items:center}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}
.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}
.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}
.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}
.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}
.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}
.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}
.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}
.cm .eb b{font-weight:600}
.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}
.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}
.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}
.li:hover{background:var(--s2)}
.li:last-child{border:0}
.li:first-child{padding-top:14px}
.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}
.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}
.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s ease}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}
.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:var(--bg);border:1px solid var(--ln);color:var(--ink)}
.sf .in{display:block;margin-bottom:10px}
.sf .btn.full{margin-top:0}
.chips.nm{flex-wrap:nowrap;overflow-x:auto;margin:0 0 10px;padding-bottom:2px;scrollbar-width:none}
.chips.nm::-webkit-scrollbar{display:none}
.chips.nm .chip{flex:none;white-space:nowrap}
.bgc{display:flex;overflow:hidden;padding:0}
.bgc>.ct{flex:1;min-width:0}
.sc.bgc>.ct{padding:18px 22px 20px}
.addb{flex:none;width:64px;border:0;border-right:1px solid var(--acl);border-radius:0;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0}
.addb svg.ic{width:30px;height:30px;stroke-width:2;transition:transform .18s ease}
.addb.on svg.ic{transform:rotate(45deg)}
.addb:active{transform:none;opacity:.8}
.bgc .adp{margin:6px 14px 14px}
.sc.bgc .adp{margin:14px 0 0}
.sc.bgc summary.sh{cursor:pointer}
.l1{gap:12px}
.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}
.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.ok{color:var(--earn)}
.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}
.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}
.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}
.spf .ln .in{flex:1 1 0}
.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
.rw>.rt{max-width:62%;justify-content:flex-end}
.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
.xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
.xh::-webkit-details-marker{display:none}
.xh>div{min-width:0}
.xc .chev{position:absolute;right:66px;top:50%;margin-top:-10px}
.xp{position:absolute;right:12px;top:18px;width:46px;height:44px;border-radius:13px;border:1px solid var(--acl);background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0;z-index:2}
.xp svg.ic{width:24px;height:24px;stroke-width:2;transition:transform .18s ease}
.xp.on svg.ic{transform:rotate(45deg)}
.xb{padding:4px 16px 8px;border-top:1px solid var(--ln)}
.xf{padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.xl{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:12px;color:var(--mu);font-family:var(--mono)}
.xl b{color:var(--ink);font-weight:600;white-space:nowrap}
.xf form{margin:12px 0 0}
.xfm .ln{gap:10px;margin:0}
.xfm .ln .in{flex:1 1 0;margin:0}
.xfm .ln .in.pr{flex:0 0 96px;width:96px}
.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}
.gw:last-child{border-bottom:0}
.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}
.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}
.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}
.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}
.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
.top-status-bar.tsplit{justify-content:space-between}
.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}
.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}
main{transition:opacity .2s ease}
html[data-nav=busy],html[data-nav=busy] a,html[data-nav=busy] button{cursor:progress}
html[data-nav=busy] main{opacity:.55}
button[data-busy]{cursor:progress}
.btn[data-busy]{opacity:.7}
.btn[data-busy]::after{content:"";display:inline-block;width:12px;height:12px;margin-left:8px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:spin .6s linear infinite;vertical-align:-2px}
@keyframes spin{to{transform:rotate(360deg)}}
@media(prefers-reduced-motion:reduce){
	main{transition:none}
	.btn[data-busy]::after{animation:none}
}
.trd{max-width:640px;margin:0 auto}
.tbn{margin:2px 0 6px;line-height:1.5}
.tbr{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px 0;border-bottom:1px solid var(--ln)}
.tbr:last-child{border-bottom:0;padding-bottom:0}
.tbr.lock{opacity:.45}
.tbf{display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0}
.tbf .in{width:96px;flex:0 1 96px;min-width:0;padding:8px 10px;font-size:14px;border-radius:12px}
.btn.win{background:rgba(76,195,138,.14);color:var(--pos);border-color:rgba(76,195,138,.45)}
.tbs{font-size:11px;font-weight:600;border:1px solid currentColor;border-radius:12px;padding:2px 9px;font-family:var(--mono)}
.sw{border-bottom:1px solid var(--ln)}
.sw:last-child{border:0}
.sw>.rw{border:0}
.hx{margin:0 0 12px;border:1px solid var(--ln);background:var(--bg);border-radius:14px;overflow:hidden}
.hx>summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 12px;list-style:none;cursor:pointer;font-size:12px;color:var(--mu);font-family:var(--mono)}
.hx>summary::-webkit-details-marker{display:none}
.hx>summary>span:nth-child(2){margin-left:auto;color:var(--earn)}
.hx>summary .chev{position:static;margin:0;right:auto;top:auto;flex:none}
.hx[open]>summary .chev{transform:rotate(180deg)}
.hxb{padding:2px 12px 12px}
.hxg{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}
.hc{display:flex;flex-direction:column;align-items:center;gap:2px;padding:9px 4px;border-radius:12px}
.hc b{font-size:14px;color:var(--ink)}
.hc small{font-size:11px;font-family:var(--mono)}
.hc.on b{color:var(--ac)}
.hxm{display:flex;gap:8px;align-items:center;margin-top:10px}
.hxm .in{padding:9px 12px;font-size:14px}
.hxm .btn{flex:none}
.kf{display:none;margin-top:2px}
form[data-kind=fixed] .kf-fixed,form[data-kind=manual] .kf-manual,form[data-kind=daily] .kf-daily,form[data-kind=monthly] .kf-monthly,form[data-kind=exoclick] .kf-exoclick{display:block}
.kf .in{margin-bottom:8px}
.kf .ln .in{margin-bottom:8px}
.kf .lb{margin-bottom:10px}
.ad>.in{display:block;width:100%}
.btn.miss{background:var(--s2);color:var(--mu);border-color:var(--ln)}

.btn{font-weight:600;font-size:15px;letter-spacing:.01em;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:999px;min-height:44px;padding:0 24px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center;box-shadow:0 1px 2px rgba(0,0,0,.28),0 1px 3px 1px rgba(0,0,0,.14);transition:box-shadow .2s,filter .2s,transform .12s}
.btn:hover{filter:brightness(1.07);box-shadow:0 1px 3px rgba(0,0,0,.28),0 4px 8px 3px rgba(0,0,0,.14)}
.btn.o{background:transparent;color:var(--ac);border:1px solid var(--acl);box-shadow:none}
.btn.o:hover{background:var(--acs);filter:none;box-shadow:none}
.btn.xs{min-height:32px;padding:0 14px;font-size:12px;box-shadow:none}
.btn.full{width:100%;min-height:52px;font-size:16px;font-weight:700;margin-top:20px}
.in{min-width:0;font-size:15px;font-family:inherit}
.of{position:relative;margin-top:14px}
.of input{height:56px;padding:22px 16px 6px;border-radius:12px;font-size:16px}
.of label{position:absolute;left:17px;top:19px;margin:0;color:var(--mu);font-size:16px;line-height:1;pointer-events:none;transition:top .15s,font-size .15s,color .15s}
.of input::placeholder{color:transparent}
.of input:focus+label,.of input:not(:placeholder-shown)+label,.of input:-webkit-autofill+label{top:9px;font-size:11px;font-weight:600;color:var(--ac)}

/* file15 */
.earn-top{display:flex;flex-direction:column;gap:3px;min-width:0}
.earn-top .lb{font-size:11px}
.earn-top b{font-size:20px;font-weight:700;letter-spacing:-.04em;line-height:1;white-space:nowrap}
.earn-top small,.rt b small{font-size:11px;color:var(--mu);font-weight:400;letter-spacing:0;margin-left:3px}
.xbare .xb{border-top:0;padding:8px 16px 6px}
.addrow{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:11px 14px;border:1px dashed var(--acl);border-radius:var(--rm);background:var(--acs);color:var(--ac);font-weight:600;font-size:13px}
.addrow svg.ic{width:18px;height:18px;stroke-width:2;transition:transform .18s ease}
.addrow.on svg.ic{transform:rotate(45deg)}
.incbare{padding:6px 22px 18px}
.incbare .addrow{margin-top:12px}
details[data-fixed]>.xh{cursor:default;padding-right:70px}
.dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}
.mm>.cd .big2{font-size:24px}
.mm .two .big2{font-size:20px}
.mm .xbare .xb{padding:2px 14px}
.hr{display:grid;grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;align-items:center;padding:9px 0}
.hn{min-width:0;font-size:15px}
.hr .ea{white-space:nowrap;text-align:right;font-size:15px}
.hr .ub{width:32px;height:32px;border-radius:12px;background:var(--s2)}
.hspan{grid-column:2/4;justify-self:end}
.sw .ad{margin:0 0 10px}
.hx{margin:0 0 8px;border:0;background:var(--s2);border-radius:14px}
.hx>summary{min-height:38px;padding:5px 6px 5px 12px;justify-content:flex-start;gap:10px}
.hx>summary>span:nth-child(2){margin-left:0;color:var(--mu)}
.hx>summary .chev{margin-left:auto;width:28px;height:28px;border-radius:50%;background:var(--s1);align-items:center;justify-content:center}
EOF
