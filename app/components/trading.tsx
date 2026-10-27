import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import { backUsdt, DEPOSIT, flowOf, isDone, PARTS, resOf, stakesFor, strip, toMad, totalPnl, TRIES, type Flow, type TradeSession } from "../lib/trade-math.ts"
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
	const second = f.steps[1]?.asset
	const msg =
		n === 0
			? `Step 1 of ${PARTS}. Pick your side and put ${fmt(f.stakes[0]!)} USDT in.`
			: n === 1
				? `Step 2 of ${PARTS}. ${fmt(f.stakes[0]!)} USDT in on ${side(first)}. Watch the move, then tap how it went.`
				: n === 2
					? `Step 3 of ${PARTS}. Finish with ${fmt(f.stakes[2]!)} USDT on ${side(second)}.`
					: `All ${fmt(f.base)} USDT are in. Wait for the result, then tap I won or I lost.`
	return (
		<Card title={`Try ${f.tryNo} of ${TRIES} · ${fmt(f.base)} USDT`}>
			{f.tryNo > 1 && n === 0 ? <div class="lb tbn">{`You lost the first try. One more try with ${fmt(f.left)} USDT. This is the last try today.`}</div> : null}
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
					<div class="pbt">
						<Submit class="btn o" name="choice" value="same">
							<b>Went my way</b>
							<small>{`+${fmt(f.stakes[1]!)} on ${side(first)}`}</small>
						</Submit>
						<Submit class="btn o" name="choice" value="other">
							<b>Went other way</b>
							<small>{`${fmt(f.stakes[1]!)} on ${first === "down" ? "Up" : "Down"}`}</small>
						</Submit>
					</div>
				</form>
			) : null}
			{n === 2 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<Submit class="btn full" name="choice" value="go">
						{`Finish with ${fmt(f.stakes[2]!)} USDT · ${side(second)}`}
					</Submit>
				</form>
			) : null}
			{n > 0 ? (
				<form method="post" action="/trading/result" class="pres">
					<SessionHid s={s} t={t} />
					<input class="in" name="pnl" placeholder="Try PnL in USDT" inputmode="decimal" autocomplete="off" />
					<div class="lb tbn">{`Won: type what you made. Lost: leave it empty to count ${fmt(f.staked)} USDT, or type what you lost.`}</div>
					<div class="pbt">
						<Submit class="btn win" name="outcome" value="win">
							I won
						</Submit>
						<Submit class="btn miss" name="outcome" value="lose" formnovalidate>
							I lost
						</Submit>
					</div>
				</form>
			) : null}
			{t.results.length > 0 ? (
				<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last step?">
					<SessionHid s={s} t={t} />
					<Submit class="btn xs o">Undo last</Submit>
				</form>
			) : null}
		</Card>
	)
})

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
			{t.results.some(isDone) && !f.over ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the try that is left?">
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
	const [a, b, c] = stakesFor(DEPOSIT)
	return (
		<Card title="Today's predict">
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
			<div class="lb tbn">{`Try 1 goes ${fmt(a!)} → ${fmt(b!)} → ${fmt(c!)} USDT. A win ends it. If you lose, one more try with what is left. One predict a day.`}</div>
		</Card>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const tries = strip(resOf(t.results))
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{tries ? `Tries ${tries}` : ""}</div>
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
		? `Try ${f!.tryNo} of ${TRIES}. Follow the steps below.`
		: tradedToday
			? `One predict a day. You can predict again at ${at}.`
			: `Deposit ${fmt(DEPOSIT)} USDT to start today's predict.`
	return (
		<div class="trd">
			<Status ok={ok} title={ok ? "You can predict" : "You cannot predict"} sub={sub} />
			{open && f ? (
				<>
					<OpenSummary s={s} t={open} f={f} />
					<Steps s={s} t={open} f={f} />
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
