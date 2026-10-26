import { BuysDesktop, BuysExpand, Hero, TodayCards } from "./components/buys.tsx"
import { OweDesktop, OweMobile, RoadCard } from "./components/debts.tsx"
import { GoalsExpand } from "./components/goals.tsx"
import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"
import { HomeBalance, HomePredict, HomeTasks, HomeToday, type PadLeft } from "./components/home.tsx"
import { HomeIncome, IncomeDesktop, IncomeExpand, InvoiceCard } from "./components/income.tsx"
import { AppLayout, AuthLayout } from "./components/layout.tsx"
import { ChatHead, Composer, NoteCard, NoteList } from "./components/notes.tsx"
import { PadBody, PadComposer, type PadTab } from "./components/pad.tsx"
import type { PadData } from "./lib/padmeta.ts"
import type { User } from "./lib/users.ts"
import { BalanceCard, EditProfileMobile, ProfileMobile, SettingsDesktop, SettingsMobile } from "./components/profile.tsx"
import { TradingBody } from "./components/trading.tsx"
import { ErrorBanner, FloatField, GoogleMark, Logo, PageHeader, Section, Submit, view } from "./components/ui.tsx"
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
				<HomeBalance s={s} />
				<HomeToday s={s} />
				<HomePredict s={s} />
				<HomeTasks p={p} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</div>
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
					<InvoiceCard s={s} />
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
					<InvoiceCard s={s} />
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

export const TradingScreen = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.user.usdt_rate)} ${s.user.currency}`
	return (
		<AppLayout
			title="Predict"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Predict" right={right} />
					<TradingBody s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Predict" right={right} />
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
				<Submit class="btn full">{up ? "Create account" : "Sign in"}</Submit>
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
