import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, timeAgo, today } from "../lib/time.ts"
import { AppLayout } from "./layout.tsx"
import { Back, ErrorBanner, Icon, PageHeader, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

const KeysForm = view<{ s: State; open: boolean }>(({ s, open }) => (
	<details class="wk" open={open ? true : undefined}>
		<summary>
			<span>{open ? "Connect Binance API" : "API keys"}</span>
			<Icon name="chev" />
		</summary>
		<form method="post" action="/wallet/keys" class="wkf" novalidate>
			<Back s={s} />
			<input class="in" name="api_key" placeholder="API key" autocomplete="off" />
			<input class="in" name="api_secret" type="password" placeholder="API secret" autocomplete="off" />
			<div class="wkn">Turn on the prediction permission. Keep withdrawals off.</div>
			<div class="wkb">
				<Submit class="btn">{open ? "Connect" : "Save keys"}</Submit>
				{open ? null : (
					<Submit class="btn o" formaction="/wallet/forget" formnovalidate data-confirm-btn="Remove the Binance keys?">
						Remove
					</Submit>
				)}
			</div>
		</form>
	</details>
))

const Hero = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.connected) return null
	return (
		<div class="wh">
			<div class="whm">
				<div class="whb">
					<b>{fmt(w.usdt)}</b>
					<small>USDT</small>
				</div>
				<span class="lb">{`≈ ${fmt(w.valueMad)} ${s.user.currency}`}</span>
			</div>
			<form method="post" action="/wallet/sync" style={contents}>
				<Back s={s} />
				<Submit class="ib whr" aria-label="Refresh now">
					<Icon name="revert" />
				</Submit>
			</form>
			<div class="whs">
				<div>
					<span>Today</span>
					<b class={tone(w.today)}>{sg(w.today)}</b>
				</div>
				<div>
					<span>Total</span>
					<b class={tone(w.total)}>{sg(w.total)}</b>
				</div>
				<div>
					<span>Rate</span>
					<b>{fmt(w.rate)}</b>
				</div>
			</div>
			<div class="wsy">{w.syncedAt ? `Synced ${timeAgo(w.syncedAt)}` : "Not synced yet"}</div>
		</div>
	)
})

/** One compact form. Two buttons: Add USDT or Sell USDT. */
const MoveForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/wallet/buy" class="wm" novalidate>
		<Back s={s} />
		<div class="wmi">
			<input class="in" name="usdt" placeholder="USDT" inputmode="decimal" autocomplete="off" />
			<input class="in" name="mad" placeholder={s.user.currency} inputmode="decimal" autocomplete="off" />
		</div>
		<div class="wmb">
			<Submit class="btn">Add USDT</Submit>
			<Submit class="btn o" formaction="/wallet/sell">
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
	return (
		<details class="wl" open>
			<summary>
				<span>Moves</span>
				<span class="lb">{`+${fmt(w.boughtUsdt)} · −${fmt(w.soldUsdt)} USDT`}</span>
			</summary>
			{w.moves.map((m) => (
				<div key={m.id} class="wr">
					<div>
						<b>{`${m.kind === "buy" ? "Added" : "Sold"} ${fmt(m.usdt)} USDT`}</b>
						<span class="lb">{dayLabel(m.day, t)}</span>
					</div>
					<span class="lb">{`${m.kind === "buy" ? "−" : "+"}${fmt(m.mad)} ${cur}`}</span>
					<form method="post" action="/wallet/delete" style={contents} data-confirm="Delete this entry?">
						<Back s={s} />
						<input type="hidden" name="id" value={m.id} />
						<Submit class="ib" aria-label="Delete">
							<Icon name="trash" />
						</Submit>
					</form>
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
			<Hero s={s} />
			<KeysForm s={s} open={!on} />
			<MoveForm s={s} />
			<Moves s={s} />
			<Progress s={s} />
		</div>
	)
})

export const WalletScreen = view<{ s: State }>(({ s }) => {
	const right = s.wallet?.connected ? `${fmt(s.wallet.usdt)} USDT` : ""
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
