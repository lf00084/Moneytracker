import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import { allDone, backUsdt, DEPOSIT, FIVE, flowOf, GAME, gameOf, gamesStrip, hasGames, isDone, PARTS, resOf, stakesFor, toMad, totalPnl, TRIES, type Flow, type GameKey, type TradeSession } from "../lib/trade-math.ts"
import { Back, Card, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")
const side = (x: string | undefined) => (x === "down" ? "Down" : "Up")

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const Bar = view<{ f: Flow }>(({ f }) => (
	<>
		<div class="pseg">
			{f.stakes.map((v, i) => (
				<b key={i} class={i < f.steps.length ? "on" : i === f.steps.length && !f.over ? "cur" : ""} style={{ flex: String(v) }}>
					{fmt(v)}
				</b>
			))}
		</div>
		<div class="psl">
			{f.stakes.map((v, i) => (
				<span key={i} style={{ flex: String(v) }}>{`step ${i + 1}`}</span>
			))}
		</div>
	</>
))

const Steps = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => {
	const n = f.steps.length
	const first = f.steps[0]?.asset
	const other = first === "down" ? "Up" : "Down"
	const msg =
		n === 0
			? `Step 1 of ${PARTS}. Follow the indicator. Pick Up or Down and put ${fmt(f.stakes[0]!)} USDT in.`
			: n === 1
				? `Step 2 of ${PARTS}. Instantly put another ${fmt(f.stakes[1]!)} USDT on ${side(first)}.`
				: n === 2
					? `Step 3 of ${PARTS}. Did it go your way? If yes add ${fmt(f.stakes[2]!)} USDT on ${side(first)}. If not, put it on ${other}.`
					: `All ${fmt(f.base)} USDT are in. Wait for the 5 min result, then enter the PnL or tap Miss.`
	return (
		<Card title={`5 min predict · try ${f.tryNo} of ${TRIES} · ${fmt(f.base)} USDT`}>
			{f.tryNo > 1 && n === 0 ? <div class="lb tbn">{`You missed the first try. One more try with ${fmt(f.left)} USDT. This is the last try today.`}</div> : null}
			<Bar f={f} />
			<div class="lb tbn">{msg}</div>
			{n === 0 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<div class="pbt">
						<Submit class="btn" name="choice" value="up">
							<b>Up</b>
							<small>{`${fmt(f.stakes[0]!)} USDT`}</small>
						</Submit>
						<Submit class="btn o" name="choice" value="down">
							<b>Down</b>
							<small>{`${fmt(f.stakes[0]!)} USDT`}</small>
						</Submit>
					</div>
				</form>
			) : null}
			{n === 1 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<Submit class="btn full" name="choice" value="go">
						{`Put ${fmt(f.stakes[1]!)} USDT · ${side(first)}`}
					</Submit>
				</form>
			) : null}
			{n === 2 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<div class="pbt">
						<Submit class="btn o" name="choice" value="same">
							<b>Went my way</b>
							<small>{`${fmt(f.stakes[2]!)} on ${side(first)}`}</small>
						</Submit>
						<Submit class="btn o" name="choice" value="other">
							<b>Went other way</b>
							<small>{`${fmt(f.stakes[2]!)} on ${other}`}</small>
						</Submit>
					</div>
				</form>
			) : null}
			{n > 0 ? (
				<form method="post" action="/trading/result" class="pres">
					<SessionHid s={s} t={t} />
					<select class="in" name="coin" style={{ width: "100%" }}>
						<option value="">Which 5 min? BTC or ETH</option>
						<option value="btc">5 min BTC</option>
						<option value="eth">5 min ETH</option>
					</select>
					<input class="in" name="pnl" placeholder="PnL in USDT" inputmode="decimal" autocomplete="off" />
					<div class="lb tbn">{`Won: type what you made. Miss: leave it empty to count ${fmt(f.staked)} USDT, or type what you lost.`}</div>
					<div class="pbt">
						<Submit class="btn win" name="outcome" value="win">
							Won
						</Submit>
						<Submit class="btn miss" name="outcome" value="lose" formnovalidate>
							Miss
						</Submit>
					</div>
				</form>
			) : null}
			{t.results.length > 0 ? (
				<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
					<SessionHid s={s} t={t} />
					<Submit class="btn xs o">Undo last</Submit>
				</form>
			) : null}
		</Card>
	)
})

const GameRow = view<{ s: State; t: TradeSession; g: GameKey; n: number }>(({ s, t, g, n }) => {
	const x = gameOf(t.results, g)
	if (x) {
		return (
			<div class="rw">
				<span>{`Game ${n} · ${fmt(GAME)} USDT`}</span>
				<b class={tone(x.pnl)}>{`${x.won ? "Won" : "Miss"} ${sg(x.pnl)}`}</b>
			</div>
		)
	}
	return (
		<form method="post" action="/trading/game" class="pres">
			<SessionHid s={s} t={t} />
			<input type="hidden" name="game" value={g} />
			<div class="lb">{`Game ${n} · ${fmt(GAME)} USDT`}</div>
			<input class="in" name="pnl" placeholder="PnL in USDT" inputmode="decimal" autocomplete="off" />
			<div class="pbt">
				<Submit class="btn win" name="outcome" value="win">
					Won
				</Submit>
				<Submit class="btn miss" name="outcome" value="lose" formnovalidate>
					Miss
				</Submit>
			</div>
		</form>
	)
})

const GamesCard = view<{ s: State; t: TradeSession; undo: boolean }>(({ s, t, undo }) => (
	<Card title={`Matches / vote predict · ${fmt(GAME)} + ${fmt(GAME)} USDT`}>
		<GameRow s={s} t={t} g="ga" n={1} />
		<GameRow s={s} t={t} g="gb" n={2} />
		<div class="lb tbn">{`Won: type what you made. Miss: leave it empty to count ${fmt(GAME)} USDT.`}</div>
		{undo && t.results.length > 0 ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
				<SessionHid s={s} t={t} />
				<Submit class="btn xs o">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const Plan = view(() => {
	const [a, b, c] = stakesFor(FIVE)
	return (
		<Card title="The way">
			<div class="lb tbn">{`5 min predict · BTC or ETH · ${fmt(FIVE)} USDT`}</div>
			<div class="rw">
				<span>1 · Follow the indicator. Pick Up or Down</span>
				<b>{fmt(a!)}</b>
			</div>
			<div class="rw">
				<span>2 · Instantly, same side</span>
				<b>{fmt(b!)}</b>
			</div>
			<div class="rw">
				<span>3 · Went your way: same side. If not: other side</span>
				<b>{fmt(c!)}</b>
			</div>
			<div class="lb tbn">Then enter the PnL, or Miss. A win ends the 5 min for today. A miss: one more try with what is left.</div>
			<div class="lb tbn">{`Matches / vote predict · 2 games · ${fmt(GAME)} + ${fmt(GAME)} USDT`}</div>
			<div class="lb tbn">Enter the PnL for each, or Miss.</div>
		</Card>
	)
})

const Note = view(() => (
	<div class="tnote">
		<b>Note</b>
		<span>Only predict through this app. Don't predict random.</span>
	</div>
))

const OpenSummary = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => {
	const cur = s.user.currency
	const pnl = totalPnl(t.results)
	const back = backUsdt(t.deposit, pnl)
	const net = toMad(pnl, t.rate)
	return (
		<Card title="Open predict">
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
			{t.results.some(isDone) && !allDone(t.deposit, t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip what is left?">
					<SessionHid s={s} t={t} />
					<Submit class="btn o full">Finish now</Submit>
				</form>
			) : null}
			<div class="lb tbn">When the predict ends, the money is added to your balance by itself.</div>
		</Card>
	)
})

const LockedCard = view<{ s: State }>(({ s }) => (
	<Card title="Today's predict">
		<div class="lb tbn">{`Done for today. One predict a day. The next one opens at ${String(s.user.day_start).padStart(2, "0")}:00.`}</div>
	</Card>
))

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency
	const rate = s.user.usdt_rate
	const cost = toMad(DEPOSIT, rate)
	return (
		<>
			<Card title="Today's predict">
				<div class="ow" style={{ margin: "0 0 6px" }}>
					<b class="big2">
						{fmt(DEPOSIT)} <small>USDT</small>
					</b>
					<span class="lb">{`${fmt(cost)} ${cur}`}</span>
				</div>
				<div class="lb">{`${fmt(FIVE)} for the 5 min predict + ${fmt(GAME)} + ${fmt(GAME)} for two games. 1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
				<form method="post" action="/trading/deposit" data-confirm={`Deposit ${fmt(DEPOSIT)} USDT? It counts as a buy of ${fmt(cost)} ${cur}.`}>
					<Back s={s} />
					<Submit class="btn full">Deposit {fmt(DEPOSIT)} USDT</Submit>
				</form>
				<div class="lb tbn">One predict a day.</div>
			</Card>
			<Plan />
		</>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const five = resOf(t.results).map((x) => `${x.won ? "W" : "M"}${x.asset ? ` ${x.asset.toUpperCase()}` : ""}`).join(" · ")
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
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this predict again? The money it added is taken back.">
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
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0)
	return (
		<Card title={`Past predicts · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

const Status = view<{ ok: boolean; title: string; sub: string }>(({ ok, title, sub }) => (
	<div class={ok ? "tst ok" : "tst no"} role="status">
		<span class="tsi">
			<Icon name={ok ? "check" : "plus"} />
		</span>
		<div>
			<b>{title}</b>
			<div class="lb">{sub}</div>
		</div>
	</div>
))

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	const day = today(s.user.day_start)
	const tradedToday = s.trades.some((t) => t.day === day)
	const at = `${String(s.user.day_start).padStart(2, "0")}:00`
	const ok = !!open || !tradedToday
	const f = open ? flowOf(open.deposit, open.results) : null
	const sub = open
		? f!.over
			? "5 min is done. Finish the games below."
			: `Try ${f!.tryNo} of ${TRIES}. Follow the steps below.`
		: tradedToday
			? `One predict a day. You can predict again at ${at}.`
			: `Deposit ${fmt(DEPOSIT)} USDT to start today's predict.`
	return (
		<div class="trd">
			<Status ok={ok} title={ok ? "You can predict" : "You cannot predict"} sub={sub} />
			<Note />
			{open && f ? (
				<>
					<OpenSummary s={s} t={open} f={f} />
					{f.over ? null : <Steps s={s} t={open} f={f} />}
					{hasGames(open.deposit) ? <GamesCard s={s} t={open} undo={f.over} /> : null}
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
