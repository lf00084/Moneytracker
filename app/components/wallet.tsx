import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, timeAgo, today } from "../lib/time.ts"
import { AppLayout } from "./layout.tsx"
import { Back, Card, ErrorBanner, Icon, PageHeader, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

const KeysForm = view<{ s: State; open: boolean }>(({ s, open }) => (
	<details open={open ? true : undefined}>
		<summary class="lb">{open ? "Connect Binance" : "Change API keys"}</summary>
		<form method="post" action="/wallet/keys" class="sf" novalidate>
			<Back s={s} />
			<input class="in" name="api_key" placeholder="Binance API key" autocomplete="off" />
			<input class="in" name="api_secret" type="password" placeholder="Binance API secret" autocomplete="off" />
			<div class="lb tbn">Turn on the prediction permission. Keep withdrawals off.</div>
			<Submit class="btn full">Save keys</Submit>
		</form>
	</details>
))

const Summary = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w) return null
	return (
		<Card title="Predict wallet">
			<div class="rw">
				<span>Balance</span>
				<b>{`${fmt(w.usdt)} USDT`}</b>
			</div>
			<div class="rw">
				<span>Worth</span>
				<b>{`${fmt(w.valueMad)} ${s.user.currency}`}</b>
			</div>
			<div class="rw">
				<span>Earned today</span>
				<b class={tone(w.today)}>{`${sg(w.today)} USDT`}</b>
			</div>
			<div class="rw">
				<span>Earned in total</span>
				<b class={tone(w.total)}>{`${sg(w.total)} USDT`}</b>
			</div>
			<div class="lb tbn">{`1 USDT = ${fmt(w.rate)} ${s.user.currency}. ${w.syncedAt ? `Synced ${timeAgo(w.syncedAt)}` : "Not synced yet"}`}</div>
			{w.error ? (
				<div class="neg" role="alert" style={{ fontSize: "13px" }}>
					{w.error}
				</div>
			) : null}
			{w.connected ? (
				<form method="post" action="/wallet/sync" style={contents}>
					<Back s={s} />
					<Submit class="btn xs o">Refresh now</Submit>
				</form>
			) : null}
		</Card>
	)
})

const MoveForm = view<{ s: State; kind: "buy" | "sell" }>(({ s, kind }) => (
	<form method="post" action={kind === "buy" ? "/wallet/buy" : "/wallet/sell"} class="sf" novalidate>
		<Back s={s} />
		<input class="in" name="usdt" placeholder={kind === "buy" ? "USDT you got" : "USDT you sold"} inputmode="decimal" autocomplete="off" />
		<input class="in" name="mad" placeholder={kind === "buy" ? `${s.user.currency} you paid` : `${s.user.currency} you got`} inputmode="decimal" autocomplete="off" />
		<Submit class="btn full">{kind === "buy" ? "Add buy" : "Add sell"}</Submit>
	</form>
))

const Moves = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w) return null
	const t = today(s.user.day_start)
	return (
		<Card title="Buys and sells">
			<div class="rw">
				<span>Bought</span>
				<b>{`${fmt(w.boughtUsdt)} USDT · ${fmt(w.madSpent)} ${s.user.currency}`}</b>
			</div>
			<div class="rw">
				<span>Sold</span>
				<b>{`${fmt(w.soldUsdt)} USDT · ${fmt(w.madGot)} ${s.user.currency}`}</b>
			</div>
			{w.moves.map((m) => (
				<div key={m.id} class="rw">
					<span>{`${m.kind === "buy" ? "Bought" : "Sold"} ${fmt(m.usdt)} USDT · ${dayLabel(m.day, t)}`}</span>
					<span class="lb">{`${m.kind === "buy" ? "−" : "+"}${fmt(m.mad)} ${s.user.currency}`}</span>
					<form method="post" action="/wallet/delete" style={contents} data-confirm="Delete this entry?">
						<Back s={s} />
						<input type="hidden" name="id" value={m.id} />
						<Submit class="ib" aria-label="Delete">
							<Icon name="trash" />
						</Submit>
					</form>
				</div>
			))}
		</Card>
	)
})

const Progress = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.days.length) return null
	const t = today(s.user.day_start)
	return (
		<Card title="Daily progress">
			{w.days.map((d) => (
				<div key={d.day} class="rw">
					<span>{dayLabel(d.day, t)}</span>
					<span class="lb">{`${fmt(d.balance)} USDT`}</span>
					<b class={tone(d.profit)}>{`${sg(d.profit)} USDT`}</b>
				</div>
			))}
		</Card>
	)
})

export const WalletBody = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		{s.wallet?.connected ? <Summary s={s} /> : null}
		<Card title="Binance">
			<KeysForm s={s} open={!s.wallet?.connected} />
			{s.wallet?.connected ? (
				<form method="post" action="/wallet/forget" style={contents} data-confirm="Remove the Binance keys?">
					<Back s={s} />
					<Submit class="btn xs o">Remove keys</Submit>
				</form>
			) : null}
		</Card>
		<Card title="Bought USDT">
			<div class="lb tbn">Type the USDT you got and the MAD you paid.</div>
			<MoveForm s={s} kind="buy" />
		</Card>
		<Card title="Sold USDT">
			<div class="lb tbn">Type the USDT you sold and the MAD you got.</div>
			<MoveForm s={s} kind="sell" />
		</Card>
		<Moves s={s} />
		<Progress s={s} />
	</>
))

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
