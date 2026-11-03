import type { State } from "../lib/data.ts"
import { timeAgo } from "../lib/time.ts"
import { Back, Card, ErrorBanner, Field, Icon, Submit, view } from "./ui.tsx"

const col = { display: "flex", flexDirection: "column", gap: "8px" } as const

const BinanceKeys = view<{ s: State; first: boolean }>(({ s, first }) => (
	<form method="post" action="/wallet/keys" style={col} novalidate>
		<Back s={s} />
		<input class="in" name="api_key" placeholder="API key" autocomplete="off" />
		<input class="in" name="api_secret" type="password" placeholder="API secret" autocomplete="off" />
		<input class="in" name="fee" inputmode="decimal" placeholder="P2P fee % (default 0.2)" autocomplete="off" />
		<input class="in" name="days" inputmode="numeric" placeholder="Import P2P orders from the last N days (0 = new only)" autocomplete="off" />
		<div class="wkn">Read-only with the prediction permission. Keep trading and withdrawals off.</div>
		<Submit class="btn">{first ? "Connect" : "Save keys"}</Submit>
	</form>
))

const Binance = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.connected)
		return (
			<Card title="Binance">
				{w?.error ? (
					<div class="wer" role="alert">
						{w.error}
					</div>
				) : null}
				<BinanceKeys s={s} first />
			</Card>
		)
	return (
		<Card title="Binance">
			<div style={col}>
				<div class="lb">{w.syncedAt ? `Connected · synced ${timeAgo(w.syncedAt)}` : "Connected · not synced yet"}</div>
				{w.error ? (
					<div class="wer" role="alert">
						{w.error}
					</div>
				) : null}
				{w.p2pError ? (
					<div class="wer" role="alert">
						{`P2P orders: ${w.p2pError}`}
					</div>
				) : null}
				<form method="post" action="/wallet/fee" style={col}>
					<Back s={s} />
					<Field label="P2P fee (%)" value={String(w.feePct)} name="fee" />
					<Submit class="btn o">Save fee</Submit>
				</form>
				<form method="post" action="/wallet/sync" style={col}>
					<Back s={s} />
					<div class="wkb">
						<Submit class="btn">Sync now</Submit>
						<Submit class="btn o" formaction="/wallet/forget" formnovalidate data-confirm-btn="Remove the Binance keys?">
							Remove
						</Submit>
					</div>
				</form>
				<details class="wk">
					<summary>
						<span>Change keys</span>
						<Icon name="chev" />
					</summary>
					<div class="wkf">
						<BinanceKeys s={s} first={false} />
					</div>
				</details>
			</div>
		</Card>
	)
})

const ExoClick = view<{ s: State }>(({ s }) => {
	const list = s.sources.filter((x) => x.type === "exoclick")
	return (
		<Card title="ExoClick">
			<div style={col}>
				{list.map((x) => (
					<form key={x.id} method="post" action="/income/edit" style={col}>
						<Back s={s} />
						<input type="hidden" name="id" value={x.id} />
						<input type="hidden" name="name" value={x.name} />
						<b>{x.name}</b>
						<div class={s.exo[x.id] ? "lb neg" : "lb"}>{s.exo[x.id] || "Connected"}</div>
						<input class="in" name="api_key" type="password" placeholder="New API key" autocomplete="off" />
						<Submit class="btn o">Save key</Submit>
					</form>
				))}
				<details class="wk" open={list.length ? undefined : true}>
					<summary>
						<span>Add ExoClick</span>
						<Icon name="chev" />
					</summary>
					<form method="post" action="/income" class="wkf">
						<Back s={s} />
						<input type="hidden" name="kind" value="exoclick" />
						<input class="in" name="name" value="ExoClick" autocomplete="off" required />
						<input class="in" name="api_key" type="password" placeholder="ExoClick API key" autocomplete="off" />
						<div class="wkn">Saved encrypted. Counted in USD during the day, converted to {s.user.currency} when the day ends.</div>
						<Submit class="btn">Add source</Submit>
					</form>
				</details>
			</div>
		</Card>
	)
})

export const ApiBody = view<{ s: State }>(({ s }) => (
	<div class="wal">
		<ErrorBanner s={s} />
		<Binance s={s} />
		<ExoClick s={s} />
	</div>
))
