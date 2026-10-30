import type { State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { LANG } from "../lib/view.ts"
import { Avatar, Back, Card, ErrorBanner, Field, Icon, PageHeader, Section, Submit, ThemeSwitch, view } from "./ui.tsx"

const BalanceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/profile/balance">
		<Back s={s} />
		<div class="fl">
			<label>Balance ({s.user.currency})</label>
			<input class="in f" name="balance" inputmode="decimal" value={plain(s.balance)} autocomplete="off" required />
		</div>
		<Submit class="btn full" style={{ marginTop: "14px" }}>
			Update balance
		</Submit>
	</form>
))

export const BalanceEditCard = view<{ s: State; edit?: boolean }>(({ s, edit = false }) => (
	<div class="cd hm-balc">
		<div class="hm-bal">
			<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
				••••••
			</b>
			<div class="hm-ba">
				<button type="button" class="ib" data-eye aria-label="Show balance">
					<Icon name="eye" />
				</button>
				{edit ? (
					<button type="button" class="ib" data-edit-bal aria-label="Edit balance">
						<Icon name="edit" />
					</button>
				) : null}
			</div>
			<div class="hm-m">Total balance</div>
		</div>
		{edit ? (
			<div class="hm-bedit" data-balf hidden>
				<BalanceForm s={s} />
			</div>
		) : null}
	</div>
))

const ProfileForm = view<{ s: State; cancel: string; showError?: boolean }>(({ s, cancel, showError = false }) => (
	<form method="post" action="/profile/edit">
		{showError ? <ErrorBanner s={s} /> : null}
		<Field label="Name" value={s.user.name} name="name" first />
		<Field label="Email" value={s.user.email} type="email" name="email" />
		<div style={{ display: "flex", gap: "10px", marginTop: "18px" }}>
			<Submit class="btn" style={{ flex: "1" }}>
				Save
			</Submit>
			<a class="btn o" style={{ flex: "1" }} href={cancel}>
				Cancel
			</a>
		</div>
	</form>
))

const PrefsForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/settings">
		<Field label="Currency" value={s.user.currency} name="currency" />
		<Field label={`1 USDT costs (${s.user.currency})`} value={plain(s.user.usdt_rate)} name="usdt" />
		<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />
		<div class="fl">
			<label>Day resets at</label>
			<select class="in" name="day_start" style={{ width: "100%" }}>
				{Array.from({ length: 24 }, (_, h) => (
					<option key={h} value={String(h)} selected={h === s.user.day_start ? true : undefined}>
						{String(h).padStart(2, "0")}:00
					</option>
				))}
			</select>
		</div>
		<Field label="1 USD in MAD (ExoClick)" value={plain(s.user.usd_rate_minor)} name="usd_rate" />
		<Field label="Week starts" value={s.user.week_start} name="week" />
		<Submit class="btn" style={{ marginTop: "14px" }}>
			Save
		</Submit>
	</form>
))

const DataButtons = view(() => (
	<div style={{ display: "flex", gap: "10px", marginTop: "6px" }}>
		<a class="btn o" style={{ flex: "1" }} href="/export.csv">
			Export CSV
		</a>
		<form method="post" action="/account/delete" style={{ flex: "1", display: "flex" }} data-confirm="Delete your account and all your data? This cannot be undone.">
			<Submit class="btn dng" style={{ flex: "1" }}>
				Delete account
			</Submit>
		</form>
	</div>
))

const LinkRow = view<{ href: string; label: string }>(({ href, label }) => (
	<a class="li" href={href}>
		<span>{label}</span>
		<span class="mu">›</span>
	</a>
))

export const ProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "10px", margin: "20px 0 6px" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
			<div style={{ textAlign: "center" }}>
				<div style={{ fontSize: "22px", fontWeight: "700", letterSpacing: "-.04em" }}>{s.user.name}</div>
				<div class="lb">{s.user.email}</div>
				<div class="chips" style={{ justifyContent: "center", marginTop: "10px" }}>
					<span class="chip" style={{ cursor: "default" }}>
						{s.user.currency}
					</span>
					<span class="chip" style={{ cursor: "default" }}>
						{LANG}
					</span>
				</div>
			</div>
		</div>
		<BalanceEditCard s={s} edit />
		<Card title="Appearance">
			<ThemeSwitch />
		</Card>
		<Card title="Account">
			<LinkRow href="/profile/edit" label="Edit profile" />
			<LinkRow href="/settings" label="Settings" />
			<LinkRow href="/history" label="History" />
			<form method="post" action="/logout">
				<Submit class="li">
					<span class="neg">Log out</span>
					<span class="mu">›</span>
				</Submit>
			</form>
		</Card>
	</>
))

export const EditProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<div style={{ display: "flex", justifyContent: "center", margin: "14px 0 0" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
		</div>
		<Card title="Profile">
			<ProfileForm s={s} cancel="/profile" showError />
		</Card>
	</>
))

export const SettingsMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<Card title="Money & income">
			<PrefsForm s={s} />
		</Card>
		<Card title="Data">
			<DataButtons />
		</Card>
		<div class="lb" style={{ textAlign: "center", margin: "18px 0" }}>
			Moneytracker v1.0 · stable
		</div>
	</>
))

export const SettingsDesktop = view<{ s: State }>(({ s }) => (
	<>
		<PageHeader title="Settings" right={`${s.user.currency} · ${LANG}`} />
		<ErrorBanner s={s} />
		<div class="g3">
			<div>
				<BalanceEditCard s={s} edit />
				<Section title="Profile">
					<ProfileForm s={s} cancel="/home" />
				</Section>
				<Section title="Account">
					<form method="post" action="/logout">
						<Submit class="btn o">Log out</Submit>
					</form>
				</Section>
			</div>
			<div>
				<Section title="Appearance">
					<ThemeSwitch />
				</Section>
				<Section title="Money & income">
					<PrefsForm s={s} />
				</Section>
				<Section title="Data">
					<DataButtons />
				</Section>
			</div>
		</div>
	</>
))
