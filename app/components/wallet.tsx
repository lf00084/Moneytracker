import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { showUsdt } from "../lib/usdt.ts"
import { dayLabel, timeAgo, today } from "../lib/time.ts"
import { AppLayout } from "./layout.tsx"
import { Back, ErrorBanner, Icon, Link, PageHeader, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

const ConnectLink = view(() => (
	<Link class="outline" href="/profile/api">
		Connect Binance in API connections
	</Link>
))

const Hero = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.connected) return null
	return (
		<div class="wh">
			<div class="whm">
				<div class="whb">
					<b>{showUsdt(w.totalText)}</b>
					<small>USDT</small>
				</div>
				<span class="lb">{`≈ ${fmt(w.valueMad)} ${s.user.currency} · all wallets`}</span>
			</div>
			<form method="post" action="/wallet/sync" style={contents}>
				<Back s={s} />
				<Submit class="ib whr" aria-label="Refresh now">
					<Icon name="revert" />
				</Submit>
			</form>
			<div class="whs two">
				<div>
					<span>Funding</span>
					<b>{`${showUsdt(w.fundingText)} USDT`}</b>
					<span class="lb">{`≈ ${fmt(w.fundingMad)} ${s.user.currency}`}</span>
				</div>
				<div>
					<span>Predictions</span>
					<b>{`${showUsdt(w.predictText)} USDT`}</b>
					<span class="lb">{`≈ ${fmt(w.predictMad)} ${s.user.currency}`}</span>
				</div>
			</div>
			<div class="whs">
				<div>
					<span>Earned today</span>
					<b class={tone(w.earnedToday)}>{sg(w.earnedToday)}</b>
				</div>
				<div>
					<span>All-time</span>
					<b class={tone(w.earnedTotal)}>{sg(w.earnedTotal)}</b>
				</div>
				<div>
					<span>{w.live ? "P2P rate" : "Rate"}</span>
					<b>{fmt(w.rate)}</b>
				</div>
			</div>
			<div class="wsy">{w.syncedAt ? `Synced ${timeAgo(w.syncedAt)} · earnings in ${s.user.currency}` : "Not synced yet"}</div>
		</div>
	)
})

const MoveForm = view<{ s: State }>(({ s }) => (

	<form method="post" action="/wallet/buy" class="wm" novalidate>
		<Back s={s} />
		<div class="wmi">
			<input class="in" name="usdt" placeholder="USDT" inputmode="decimal" autocomplete="off" />
			<input class="in" name="mad" placeholder={s.user.currency} inputmode="decimal" autocomplete="off" />
		</div>
		{s.money ? (
			<select class="in" name="bank">
				{s.money.banks.map((b) => (
					<option key={b.id} value={b.id} selected={b.isDefault ? true : undefined}>
						{b.name}
					</option>
				))}
			</select>
		) : null}
		<div class="wmb">
			<Submit >Add USDT</Submit>
			<Submit class="outline" formaction="/wallet/sell">
				Sell USDT
			</Submit>
		</div>
	</form>
))

const Moves = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.moves.length) return null
	const t = today(s.user.day_start)
	const cur = s.user.currency
	const bankName = (id: string) => s.money?.banks.find((b) => b.id === id)?.name ?? ""
	return (
		<details class="wl" open>
			<summary>
				<span>Moves</span>
				<span class="lb">{`+${fmt(w.boughtUsdt)} · −${fmt(w.soldUsdt)} USDT`}</span>
			</summary>
			{w.moves.map((m) => (
				<div key={m.id} class="wr">
					<div>
						<b>{m.kind === "in" ? `ExoClick paid ${fmt(m.usdt)} USDT` : `${m.kind === "buy" ? "Added" : "Sold"} ${fmt(m.usdt)} USDT`}</b>
						<span class="lb">{[dayLabel(m.day, t), m.fee ? `fee ${fmt(m.fee)}` : "", bankName(m.bankId) || (m.kind === "in" ? "" : m.pay)].filter(Boolean).join(" · ")}</span>
					</div>
					<span class="lb">{m.kind === "in" ? "not earnings" : `${m.kind === "buy" ? "−" : "+"}${fmt(m.mad)} ${cur}`}</span>
					{m.kind === "in" ? null : (
						<form method="post" action="/wallet/delete" style={contents} data-confirm="Delete this entry?">
							<Back s={s} />
							<input type="hidden" name="id" value={m.id} />
							<Submit class="ib" aria-label="Delete">
								<Icon name="trash" />
							</Submit>
						</form>
					)}
				</div>
			))}
		</details>
	)
})

const Progress = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.days.length) return null
	const t = today(s.user.day_start)
	return (
		<details class="wl">
			<summary>
				<span>Daily</span>
				<span class="lb">{`${w.days.length} days`}</span>
			</summary>
			{w.days.map((d) => (
				<div key={d.day} class="wr">
					<div>
						<b>{dayLabel(d.day, t)}</b>
					</div>
					<span class="lb">{`${fmt(d.balance)} USDT`}</span>
					<b class={tone(d.profit)}>{sg(d.profit)}</b>
				</div>
			))}
		</details>
	)
})

export const WalletBody = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const on = !!w?.connected
	return (
		<div class="wal">
			<ErrorBanner s={s} />
			{w?.error ? (
				<div class="wer" role="alert">
					{w.error}
				</div>
			) : null}
			{w?.p2pError ? (
				<div class="wer" role="alert">
					{`P2P orders: ${w.p2pError}`}
				</div>
			) : null}
			<Hero s={s} />
			{on ? null : <ConnectLink />}
			<MoveForm s={s} />
			<Moves s={s} />
			<Progress s={s} />
		</div>
	)
})

export const WalletScreen = view<{ s: State }>(({ s }) => {
	const right = s.wallet?.connected ? `${showUsdt(s.wallet.totalText)} USDT` : ""
	return (
		<AppLayout
			title="Predict wallet"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<PageHeader title="Predict wallet" right={right} />
					<WalletBody s={s} />
				</>
			}
			desktop={
				<>
					<PageHeader title="Predict wallet" right={right} />
					<WalletBody s={s} />
				</>
			}
		/>
	)
})
