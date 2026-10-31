import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import { allDone, backUsdt, DEPOSIT, FIVE, flowOf, GAME, gameOf, gamesStrip, hasGames, isDone, letter, resOf, stakesFor, toMad, totalPnl, TRIES, word, type Flow, type GameKey, type TradeSession } from "../lib/trade-math.ts"
import { Back, Card, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const PnlField = view(() => (
	<div class="fld">
		<div class="ferr" role="alert" hidden></div>
		<input class="in" name="pnl" placeholder="PnL in USDT" inputmode="decimal" autocomplete="off" />
	</div>
))

const Outcomes = view(() => (
	<div class="pbt p3">
		<Submit class="btn win" name="outcome" value="win">
			Won
		</Submit>
		<Submit class="btn lost" name="outcome" value="lose">
			Lost
		</Submit>
		<Submit class="btn miss" name="outcome" value="miss" formnovalidate>
			Miss
		</Submit>
	</div>
))

/** The strategy, always in a box so it is easy to see. */
const Strategy = view<{ base: number; note?: string }>(({ base, note }) => {
	const st = stakesFor(base)
	return (
		<div class="stb">
			<div class="stt">
				<b>Strategy</b>
				<span>{`5 min · BTC or ETH · ${fmt(base)} USDT`}</span>
			</div>
			<ol class="stl">
				<li>
					<i>1</i>
					<span>Follow the indicator. Pick Up or Down</span>
					<b>{fmt(st[0]!)}</b>
				</li>
				<li>
					<i>2</i>
					<span>Instantly, same side</span>
					<b>{fmt(st[1]!)}</b>
				</li>
				<li>
					<i>3</i>
					<span>Won: same side. Lost: other side</span>
					<b>{fmt(st[2]!)}</b>
				</li>
			</ol>
			<div class="stn">{note ?? "Lost with some left: one more try with the rest. Miss or a second loss: stop for the day."}</div>
		</div>
	)
})

const Steps = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => (
	<Card title={`5 min · try ${f.tryNo} of ${TRIES}`}>
		<Strategy base={f.base} note={f.tryNo > 1 ? `First try lost. ${fmt(f.left)} USDT is left. This is the last try today.` : undefined} />
		<form method="post" action="/trading/result" class="pres" data-pnl novalidate>
			<SessionHid s={s} t={t} />
			<PnlField />
			<Outcomes />
		</form>
		{t.results.length > 0 ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
				<SessionHid s={s} t={t} />
				<Submit class="btn xs o">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const StopCard = view<{ f: Flow; games: boolean }>(({ f, games }) => (
	<div class="tstop" role="alert">
		<b>Stop trading now</b>
		<span>{`${fmt(f.left)} USDT is left from the 5 min. Do not predict again today.${games ? " Finish the 2 games and close." : ""}`}</span>
	</div>
))

const GameRow = view<{ s: State; t: TradeSession; g: GameKey; n: number }>(({ s, t, g, n }) => {
	const x = gameOf(t.results, g)
	if (x) {
		return (
			<div class="rw gdn">
				<span>{`Game ${n}`}</span>
				{x.asset === "skip" ? <b class="mu">Skipped</b> : <b class={tone(x.pnl)}>{`${word(x)} ${sg(x.pnl)} USDT`}</b>}
			</div>
		)
	}
	return (
		<form method="post" action="/trading/game" class="gm" data-pnl novalidate>
			<SessionHid s={s} t={t} />
			<input type="hidden" name="game" value={g} />
			<div class="gmh">
				<span>{`Game ${n}`}</span>
				<b>{`${fmt(GAME)} USDT`}</b>
			</div>
			<PnlField />
			<Outcomes />
		</form>
	)
})

const GamesCard = view<{ s: State; t: TradeSession; undo: boolean }>(({ s, t, undo }) => (
	<Card title="Games · matches / vote">
		<GameRow s={s} t={t} g="ga" n={1} />
		<GameRow s={s} t={t} g="gb" n={2} />
		{undo && t.results.length > 0 ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
				<SessionHid s={s} t={t} />
				<Submit class="btn xs o">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency
	const pnl = totalPnl(t.results)
	const back = backUsdt(t.deposit, pnl)
	const net = toMad(pnl, t.rate)
	const any = t.results.some(isDone)
	return (
		<div class="pds">
			<div class="pdb">
				<b class={any ? tone(pnl) : ""}>{any ? sg(pnl) : "0.00"}</b>
				<small>USDT PnL</small>
			</div>
			<div class="pdm">
				<span>{`${dayLabel(t.day)} · back ${fmt(back)} USDT`}</span>
				<span class={any ? tone(net) : ""}>{`${sg(net)} ${cur}`}</span>
			</div>
			{any && !allDone(t.deposit, t.results) ? (
				<form method="post" action="/trading/finish" style={contents} data-confirm="Finish now and skip what is left?">
					<SessionHid s={s} t={t} />
					<Submit class="btn xs o">Finish now</Submit>
				</form>
			) : null}
		</div>
	)
})

const LockedCard = view<{ s: State }>(({ s }) => (
	<div class="pdn">{`Done for today. The next predict opens at ${String(s.user.day_start).padStart(2, "0")}:00.`}</div>
))

const Balance = view<{ s: State; ready: boolean }>(({ s, ready }) => {
	const w = s.wallet
	const have = w?.connected ? w.usdt : 0
	return (
		<div class={ready ? "pbal ok" : "pbal no"}>
			<div class="pbn">
				<span>Predict balance</span>
				<b>{`${fmt(have)} USDT`}</b>
			</div>
			<div class="pbn r">
				<span>Needed</span>
				<b>{`${fmt(DEPOSIT)} USDT`}</b>
			</div>
			{ready ? (
				<span class="pbi">
					<Icon name="check" />
				</span>
			) : (
				<a class="pba" href="/wallet">
					{w?.connected ? "Add balance" : "Connect"}
				</a>
			)}
		</div>
	)
})

const StartCard = view<{ s: State; ready: boolean }>(({ s, ready }) => {
	const w = s.wallet
	const miss = w?.connected ? `You need ${fmt(Math.max(0, DEPOSIT - w.usdt))} USDT more in your predict balance. Add it in Predict wallet.` : "Connect Binance in Predict wallet and add USDT first."
	return (
		<>
			<Balance s={s} ready={ready} />
			{ready ? (
				<form method="post" action="/trading/deposit" style={contents}>
					<Back s={s} />
					<Submit class="btn full pgo">Start predict</Submit>
				</form>
			) : (
				<div class="pdn">{miss}</div>
			)}
			<div class="pdn">{`Uses ${fmt(FIVE)} for the 5 min and ${fmt(GAME)} + ${fmt(GAME)} for the 2 games. Your balance is checked, nothing is bought.`}</div>
			<Strategy base={FIVE} />
		</>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = toMad(t.pnl, t.rate)
	const five = resOf(t.results).map((x) => `${letter(x)}${x.asset ? ` ${x.asset.toUpperCase()}` : ""}`).join(" · ")
	const games = hasGames(t.deposit) ? gamesStrip(t.results) : ""
	const label = `${five ? `5 min ${five}` : ""}${five && games ? " · " : ""}${games ? `Games ${games}` : ""}`
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{label}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this predict again?">
						<SessionHid s={s} t={t} />
						<Submit class="ub" aria-label="Open this predict again">
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
	const total = list.reduce((a, t) => a + toMad(t.pnl, t.rate), 0)
	return (
		<Card title={`Past · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

const Status = view<{ ok: boolean; title: string; sub: string }>(({ ok, title, sub }) => (
	<div class={ok ? "tsl ok" : "tsl no"} role="status">
		<i></i>
		<b>{title}</b>
		<span>{sub}</span>
	</div>
))

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	const day = today(s.user.day_start)
	const tradedToday = s.trades.some((t) => t.day === day)
	const at = `${String(s.user.day_start).padStart(2, "0")}:00`
	const f = open ? flowOf(open.deposit, open.results) : null
	const stop = !!f?.stop
	const ready = !!s.wallet?.connected && s.wallet.usdt >= DEPOSIT
	const ok = !stop && (!!open || (!tradedToday && ready))
	const title = stop ? "Stop trading now" : open ? "Predict open" : tradedToday ? "Done for today" : ready ? "You can predict" : "Add balance first"
	const sub = open
		? f!.over
			? "Finish the games"
			: `Try ${f!.tryNo} of ${TRIES}`
		: tradedToday
			? `Again at ${at}`
			: ready
				? "Balance is in predict"
				: "Not enough in predict"
	return (
		<div class="trd">
			<Status ok={ok} title={title} sub={sub} />
			{open && f ? (
				<>
					<OpenSummary s={s} t={open} />
					{f.stop ? <StopCard f={f} games={hasGames(open.deposit) && !allDone(open.deposit, open.results)} /> : null}
					{f.over ? null : <Steps s={s} t={open} f={f} />}
					{hasGames(open.deposit) ? <GamesCard s={s} t={open} undo={f.over} /> : null}
				</>
			) : tradedToday ? (
				<LockedCard s={s} />
			) : (
				<StartCard s={s} ready={ready} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	)
})
