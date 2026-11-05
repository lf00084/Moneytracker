import { Frame } from "remix/component"
import { routes } from "./routes.ts"
import { BuysExpand } from "./components/buys.tsx"
import { OweDesktop, OweMobile, RoadCard } from "./components/debts.tsx"
import { GoalsExpand } from "./components/goals.tsx"
import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"
import { HomePredict, HomeSheets, HomeTasks, HomeTimeline, HomeToday, MoneyTiles, NeedsYouChip, QuickButtons, UsdtCard, type PadLeft } from "./components/home.tsx"
import { IncomeDesktop, IncomeExpand, IncomeStripCard, InvoiceCard, OnHoldPendingList } from "./components/income.tsx"
import { ApiBody } from "./components/apis.tsx"
import { BalanceCard } from "./components/balancecard.tsx"
import { DateCard } from "./components/datecard.tsx"
import { AppLayout, AuthLayout } from "./components/layout.tsx"
import { PadBody, PadComposer, type PadTab } from "./components/pad.tsx"
import type { PadData } from "./lib/padmeta.ts"
import type { User } from "./lib/users.ts"
import { EditProfileMobile, ProfileMobile, SettingsDesktop, SettingsMobile } from "./components/profile.tsx"
import { TodayCard, TradingBody } from "./components/trading.tsx"
export { TodayCard }
import { ErrorBanner, GoogleMark, Link, Logo, PageHeader, Section, Submit, view } from "./components/ui.tsx"
import type { State } from "./lib/data.ts"
import { fmt } from "./lib/money.ts"
import { calc } from "./lib/view.ts"

export const HomeScreen = view<{ s: State; p: PadLeft }>(({ s, p }) => (
	<AppLayout
		title="Home"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="home"
		mobile={
			<div class="hm hm-f">
				<ErrorBanner s={s} />
				<div class="hm-top">
					<BalanceCard s={s} />
					<DateCard />
				</div>
				<HomeToday s={s} />
				<IncomeStripCard s={s} open={true} storeKey="income" />
				<div class="hm-bank-group">
					<NeedsYouChip s={s} />
					<QuickButtons s={s} />
					<MoneyTiles s={s} />
					<UsdtCard s={s} />
					<HomePredict s={s} />
				</div>
				<BuysExpand s={s} />
				<HomeTasks p={p} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
				<HomeTimeline s={s} />
				<HomeSheets s={s} />
			</div>
		}
		desktop={
			<div class="hm hm-d">
				<ErrorBanner s={s} />
				<div class="hm-top">
					<BalanceCard s={s} />
					<DateCard />
				</div>
				<HomeToday s={s} />
				<div class="grid">
					<div class="hm-col">
						<IncomeStripCard s={s} open={true} storeKey="income-d" />
						<div class="hm-bank-group">
							<NeedsYouChip s={s} />
							<QuickButtons s={s} />
							<MoneyTiles s={s} />
							<UsdtCard s={s} />
							<HomePredict s={s} />
						</div>
					</div>
					<div class="hm-col">
						<BuysExpand s={s} />
						<HomeTasks p={p} />
						<GoalsExpand s={s} open={false} storeKey="goals-d-home" manage={false} />
						<OweMobile s={s} open={false} storeKey="owe-d" />
						<HomeTimeline s={s} />
					</div>
				</div>
				<HomeSheets s={s} />
			</div>
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
					<PageHeader title="On hold & Income" right={earned ? `+${fmt(earned)} today` : ""} />
					<OnHoldPendingList s={s} />
					<InvoiceCard s={s} />
					<IncomeExpand s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<div class="hd">
						<h1 class="t">On hold & Income</h1>
						<span></span>
					</div>
					<OnHoldPendingList s={s} />
					<InvoiceCard s={s} />
					<IncomeExpand s={s} />
				</>
			}
		/>
	)
})

export const PadScreen = view<{ u: User; d: PadData; tab: PadTab; f: string; error: string }>(({ u, d, tab, f, error }) => (
	<AppLayout
		title="Pad"
		theme={u.theme}
		mobileTab="pad"
		desktopTab="pad"
		mobile={<PadBody d={d} tab={tab} f={f} error={error} />}
		dock={<PadComposer d={d} tab={tab} f={f} />}
		desktop={
			<div class="chat">
				<PadBody d={d} tab={tab} f={f} error={error} />
				<PadComposer d={d} tab={tab} f={f} />
			</div>
		}
	/>
))

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

const PanelLoading = view<{ label: string }>(({ label }) => (
	<article>
		<div class="cb">
			<div class="lb">{label}</div>
		</div>
	</article>
))

// The API page connects to Binance (network latency), so its body streams in
// through a Frame while the shell renders instantly.
export const ApiScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="API connections"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="API connections" back="/profile" />
				<Frame src={routes.pages.apiPanel.href()} fallback={<PanelLoading label="Loading connections…" />}>
				</Frame>
			</>
		}
		desktop={
			<>
				<PageHeader title="API connections" />
				<Frame src={routes.pages.apiPanel.href()} fallback={<PanelLoading label="Loading connections…" />}>
				</Frame>
			</>
		}
	/>
))

export const ApiPanel = view<{ s: State }>(({ s }) => <ApiBody s={s} />)

// The Predict page waits on Binance wallet sync, so its panel streams in
// through a Frame: the shell (nav, header, error banner) paints immediately.
export const TradingScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Predict"
		theme={s.user.theme}
		mobileTab="trading"
		desktopTab="trading"
		mobile={
			<>
				<ErrorBanner s={s} />
				<Frame
					src={routes.pages.tradingPanel.href()}
					fallback={
						<>
							<PageHeader title="Predict" />
							<PanelLoading label="Syncing Binance…" />
						</>
					}
				></Frame>
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<Frame
					src={routes.pages.tradingPanel.href()}
					fallback={
						<>
							<PageHeader title="Predict" />
							<PanelLoading label="Syncing Binance…" />
						</>
					}
				></Frame>
			</>
		}
	/>
))

export const TradingPanel = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.wallet?.rate ?? s.user.usdt_rate)} ${s.user.currency}`
	return (
		<>
			<PageHeader title="Predict" right={right} />
			<TradingBody s={s} />
		</>
	)
})

const AuthField = view<{ label: string; name: string; type?: string; auto?: string }>(({ label, name, type = "text", auto }) => (
	<div class="fld">
		<label for={`f-${name}`}>{label}</label>
		<input id={`f-${name}`} name={name} type={type as any} autocomplete={auto} />
	</div>
))

const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-wrap">
		<div class="auth-logo">
			<Logo href="/login" />
		</div>
		<h1>{up ? "Create account" : "Sign in"}</h1>
		<p class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</p>
		<a class="auth-google" role="button" href="/login/google">
			<GoogleMark />
			<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
		</a>
		<div class="auth-or">or</div>
		{error ? (
			<div class="auth-error" role="alert">
				{error}
			</div>
		) : null}
		<form method="post" action={up ? "/signup" : "/login"}>
			{up ? <AuthField label="Name" name="name" auto="name" /> : null}
			<AuthField label="Email" type="email" name="email" auto="email" />
			<AuthField label="Password" type="password" name="password" auto={up ? "new-password" : "current-password"} />
			<div class="submit-row">
				<Submit type="submit">{up ? "Create account" : "Sign in"}</Submit>
			</div>
		</form>
		<p class="auth-switch">
			{up ? (
				<>
					Already have an account? <Link href="/login">Sign in</Link>
				</>
			) : (
				<>
					Don't have an account? <Link href="/signup">Create account</Link>
				</>
			)}
		</p>
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
