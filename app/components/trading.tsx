import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel } from "../lib/time.ts";
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcLost,
	btcOf,
	DEPOSIT,
	isDone,
	PICKS,
	PRED_COUNT,
	predOf,
	strip,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "../lib/trade-math.ts";
import { Icon } from "./Icon.tsx";
import { Back, Card } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`;
const tone = (minor: number) => (minor < 0 ? "neg" : "pos");

type RowState = "result" | "active" | "wait" | "skip";

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
));

const PredictRow = view<{ s: State; t: TradeSession; game: Game; idx: number; r: TradeResult | undefined; state: RowState; canUndo: boolean }>(
	({ s, t, game, idx, r, state, canUndo }) => {
		const meta = r && r.asset ? `${r.asset} ${r.tf}m` : "";
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
								<button class="ub" aria-label={`Undo predict ${idx}`}>
									<Icon name="undo" />
								</button>
							</form>
						) : null}
					</span>
				</div>
			);
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
						<button class="btn xs win" name="outcome" value="win">
							Win
						</button>
						<button class="btn xs miss" name="outcome" value="miss" formnovalidate>
							Miss
						</button>
					</form>
					{canUndo ? (
						<form method="post" action="/trading/undo" style={contents}>
							<SessionHid s={s} t={t} />
							<input type="hidden" name="result_id" value={r.id} />
							<button class="ub" aria-label={`Cancel predict ${idx}`}>
								<Icon name="undo" />
							</button>
						</form>
					) : null}
				</div>
			);
		}
		if (state === "active" && game === "btc") {
			return (
				<div class="tbr" style={{ flexDirection: "column", alignItems: "stretch" }}>
					<b>Predict {idx}</b>
					<form method="post" action="/trading/set" style={contents}>
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<div class="hxg">
							{PICKS.map(([a, m]) => (
								<button key={`${a}-${m}`} class="chip hc" name="pick" value={`${a}-${m}`}>
									<b>{a}</b>
									<small>{m}m</small>
								</button>
							))}
						</div>
					</form>
				</div>
			);
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
						<button class="btn xs o">Set</button>
					</form>
				</div>
			);
		}
		return (
			<div class="tbr lock">
				<div>
					<b>Predict {idx}</b>
				</div>
				<span class="lb">{state === "skip" ? "skipped" : "waiting"}</span>
			</div>
		);
	},
);

const BtcCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = btcOf(t.results);
	const done = btcDone(t.results);
	const lost = btcLost(t.results);
	return (
		<Card title="Crypto · up or down">
			<div class="lb tbn">1 USDT. Up to {BTC_ROUNDS} predicts. Pick BTC or ETH and 5 or 15 minutes, then wait for the result. Win goes to the next one. Miss ends it.</div>
			{Array.from({ length: BTC_ROUNDS }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx);
				const state: RowState = r ? "result" : done ? "skip" : idx === list.length + 1 && list.every(isDone) ? "active" : "wait";
				return <PredictRow key={idx} s={s} t={t} game="btc" idx={idx} r={r} state={state} canUndo={!!r && idx === list.length} />;
			})}
			{done ? <div class="lb tbn">{lost ? "Finished. This one missed." : `Finished. You won all ${BTC_ROUNDS}.`}</div> : null}
		</Card>
	);
});

const PredCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = predOf(t.results);
	return (
		<Card title="3 predicts · lol or sport">
			<div class="lb tbn">3 USDT. Each predict is on its own. Tap Set, then wait. Type the PnL and tap Win, or tap Miss.</div>
			{Array.from({ length: PRED_COUNT }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx);
				return <PredictRow key={idx} s={s} t={t} game="pred" idx={idx} r={r} state={r ? "result" : "active"} canUndo={!!r} />;
			})}
		</Card>
	);
});

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency;
	const pnl = totalPnl(t.results);
	const back = backUsdt(t.deposit, pnl);
	const net = toMad(pnl, t.rate);
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
					<button class="btn o full">Finish now</button>
				</form>
			) : null}
			<div class="lb tbn">When every predict has a result, the money is added to your balance by itself.</div>
		</Card>
	);
});

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency;
	const rate = s.user.usdt_rate;
	const cost = toMad(DEPOSIT, rate);
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
				<button class="btn full">Deposit {fmt(DEPOSIT)} USDT</button>
			</form>
			<div class="lb tbn">Then you do 4 up or down predicts (1 USDT) and 3 more predicts (3 USDT).</div>
		</Card>
	);
});

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate);
	const btc = strip(btcOf(t.results));
	const pred = strip(predOf(t.results));
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
						<button class="ub" aria-label="Open this trade again">
							<Icon name="undo" />
						</button>
					</form>
				) : null}
			</span>
		</div>
	);
});

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null;
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0);
	return (
		<Card title={`Past trades · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	);
});

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open");
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10);
	return (
		<div class="trd">
			{open ? (
				<>
					<OpenSummary s={s} t={open} />
					<BtcCard s={s} t={open} />
					<PredCard s={s} t={open} />
				</>
			) : (
				<StartCard s={s} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	);
});
