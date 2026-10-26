import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	BTC_STAKE,
	btcOf,
	btcWon,
	DEPOSIT,
	isDone,
	PICKS,
	PRED_COUNT,
	PRED_STAKE,
	predOf,
	strip,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "../lib/trade-math.ts"
import { Back, Card, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

type RowState = "result" | "active" | "wait" | "skip"

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const PredictRow = view<{ s: State; t: TradeSession; game: Game; idx: number; r: TradeResult | undefined; state: RowState; canUndo: boolean }>(
	({ s, t, game, idx, r, state, canUndo }) => {
		const meta = r && r.asset ? `${r.asset} ${r.tf}m` : ""
		if (r && isDone(r)) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						{meta ? <div class="lb">{meta}</div> : null}
					</div>
					<span class="rt">
						<span class={`tbs ${r.won ? "pos" : "mu"}`}>{r.won ? "Win" : "Missed"}</span>
						<b class={r.won ? tone(r.pnl) : "mu"}>{sg(r.pnl)}</b>
						{canUndo ? (
							<form method="post" action="/trading/undo" style={contents} data-confirm={`Move predict ${idx} back to waiting?`}>
								<SessionHid s={s} t={t} />
								<input type="hidden" name="result_id" value={r.id} />
								<Submit class="ub" aria-label={`Undo predict ${idx}`}>
									<Icon name="undo" />
								</Submit>
							</form>
						) : null}
					</span>
				</div>
			)
		}
		if (r) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						<div class="lb">{meta ? `${meta} · waiting` : "waiting"}</div>
					</div>
					<form method="post" action="/trading/result" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<input class="in" name="pnl" placeholder="PnL USDT" inputmode="decimal" autocomplete="off" />
						<Submit class="btn xs win" name="outcome" value="win">
							Win
						</Submit>
						<Submit class="btn xs miss" name="outcome" value="miss" formnovalidate>
							Miss
						</Submit>
					</form>
					{canUndo ? (
						<form method="post" action="/trading/undo" style={contents}>
							<SessionHid s={s} t={t} />
							<input type="hidden" name="result_id" value={r.id} />
							<Submit class="ub" aria-label={`Cancel predict ${idx}`}>
								<Icon name="undo" />
							</Submit>
						</form>
					) : null}
				</div>
			)
		}
		if (state === "active" && game === "btc") {
			return (
				<div class="tbr" style={{ flexDirection: "column", alignItems: "stretch" }}>
					<b>Predict {idx}</b>
					<form method="post" action="/trading/set" style={contents}>
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<div class="hxg" style={{ gridTemplateColumns: "repeat(2,1fr)" }}>
							{PICKS.map(([a, m]) => (
								<Submit key={`${a}-${m}`} class="chip hc" name="pick" value={`${a}-${m}`}>
									<b>{a}</b>
									<small>{m}m</small>
								</Submit>
							))}
						</div>
					</form>
				</div>
			)
		}
		if (state === "active") {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
					</div>
					<form method="post" action="/trading/set" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<Submit class="btn xs o">Set</Submit>
					</form>
				</div>
			)
		}
		return (
			<div class="tbr lock">
				<div>
					<b>Predict {idx}</b>
				</div>
				<span class="lb">{state === "skip" ? "skipped" : "waiting"}</span>
			</div>
		)
	},
)

const BtcCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = btcOf(t.results)
	const done = btcDone(t.results)
	const won = btcWon(t.results)
	const stake = fmt(BTC_STAKE)
	const left = fmt(BTC_STAKE * (BTC_ROUNDS - list.length))
	return (
		<Card title="Crypto · 5 min up or down">
			<div class="lb tbn">
				{`${stake} USDT each. Pick BTC or ETH (5 min) and wait for the result. Win on the first = stop here. Miss = one more try with the ${stake} USDT left.`}
			</div>
			{!done && list.length > 0 && list.every(isDone) ? <div class="lb tbn">{`Last try. ${left} USDT left from ${fmt(BTC_STAKE * BTC_ROUNDS)}.`}</div> : null}
			{Array.from({ length: BTC_ROUNDS }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx)
				const state: RowState = r ? "result" : done ? "skip" : idx === list.length + 1 && list.every(isDone) ? "active" : "wait"
				return <PredictRow key={idx} s={s} t={t} game="btc" idx={idx} r={r} state={state} canUndo={!!r && idx === list.length} />
			})}
			{done ? <div class="lb tbn">{won ? `Won on try ${list.findIndex((x) => x.won) + 1}. Stop trading today. Do your ${PRED_COUNT} predicts below.` : "Both tries missed. Done with crypto today."}</div> : null}
		</Card>
	)
})

const PredCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = predOf(t.results)
	return (
		<Card title={`${PRED_COUNT} match predicts · lol or sport`}>
			<div class="lb tbn">{`${fmt(PRED_STAKE)} USDT each. Play both whatever the crypto result was. Tap Set, then wait. Type the PnL and tap Win, or tap Miss.`}</div>
			{Array.from({ length: PRED_COUNT }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx)
				return <PredictRow key={idx} s={s} t={t} game="pred" idx={idx} r={r} state={r ? "result" : "active"} canUndo={!!r} />
			})}
		</Card>
	)
})

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency
	const pnl = totalPnl(t.results)
	const back = backUsdt(t.deposit, pnl)
	const net = toMad(pnl, t.rate)
	return (
		<Card title="Open trade">
			<div class="ow" style={{ margin: "0 0 8px" }}>
				<b class={`big2 ${t.results.some(isDone) ? tone(pnl) : ""}`}>
					{t.results.some(isDone) ? sg(pnl) : "0"} <small>USDT PnL</small>
				</b>
				<span class="lb">{dayLabel(t.day)}</span>
			</div>
			<div class="rw">
				<span class="mu">Deposit</span>
				<span>{`${fmt(t.deposit)} USDT · ${fmt(toMad(t.deposit, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">You get back</span>
				<span>{`${fmt(back)} USDT · ${fmt(toMad(back, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">Net for your balance</span>
				<b class={tone(net)}>{`${sg(net)} ${cur}`}</b>
			</div>
			{t.results.some(isDone) && !allDone(t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the predicts that are left?">
					<SessionHid s={s} t={t} />
					<Submit class="btn o full">Finish now</Submit>
				</form>
			) : null}
			<div class="lb tbn">When every predict has a result, the money is added to your balance by itself.</div>
		</Card>
	)
})

const LockedCard = view<{ s: State }>(({ s }) => (
	<Card title="Today's trade">
		<div class="lb tbn">{`Done for today. One trade a day. The next one opens at ${String(s.user.day_start).padStart(2, "0")}:00.`}</div>
	</Card>
))

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency
	const rate = s.user.usdt_rate
	const cost = toMad(DEPOSIT, rate)
	return (
		<Card title="Today's trade">
			<div class="ow" style={{ margin: "0 0 6px" }}>
				<b class="big2">
					{fmt(DEPOSIT)} <small>USDT</small>
				</b>
				<span class="lb">{`${fmt(cost)} ${cur}`}</span>
			</div>
			<div class="lb">{`1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
			<form method="post" action="/trading/deposit" data-confirm={`Deposit ${fmt(DEPOSIT)} USDT? It counts as a buy of ${fmt(cost)} ${cur}.`}>
				<Back s={s} />
				<Submit class="btn full">Deposit {fmt(DEPOSIT)} USDT</Submit>
			</form>
			<div class="lb tbn">{`Then 1 crypto predict of ${fmt(BTC_STAKE)} USDT (a second try only if the first misses) and ${PRED_COUNT} match predicts of ${fmt(PRED_STAKE)} USDT. One trade a day.`}</div>
		</Card>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const btc = strip(btcOf(t.results))
	const pred = strip(predOf(t.results))
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{`${btc ? `BTC ${btc}` : ""}${btc && pred ? " · " : ""}${pred ? `P ${pred}` : ""}`}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this trade again? The money it added is taken back.">
						<SessionHid s={s} t={t} />
						<Submit class="ub" aria-label="Open this trade again">
							<Icon name="undo" />
						</Submit>
					</form>
				) : null}
			</span>
		</div>
	)
})

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0)
	return (
		<Card title={`Past trades · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	const day = today(s.user.day_start)
	const tradedToday = s.trades.some((t) => t.day === day)
	return (
		<div class="trd">
			{open ? (
				<>
					<OpenSummary s={s} t={open} />
					<BtcCard s={s} t={open} />
					<PredCard s={s} t={open} />
				</>
			) : tradedToday ? (
				<LockedCard s={s} />
			) : (
				<StartCard s={s} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	)
})
