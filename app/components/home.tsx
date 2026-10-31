import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { DEPOSIT, flowOf, TRIES } from "../lib/trade-math.ts"
import { calc } from "../lib/view.ts"
import { Submit, view } from "./ui.tsx"

export type PadProject = { id: string; title: string; color: string; left: number; total: number }
export type PadLeft = { projects: PadProject[]; home: { left: number; total: number } }

const Stat = view<{ label: string; sign: string; value: number; cur: string }>(({ label, sign, value, cur }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots">{`${sign}${fmt(value)}`} <small>{cur}</small></b>
		<div class="hm-m">{label}</div>
	</div>
))

export const HomeToday = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hm-two">
			<Stat label="Earned today" sign="+" value={c.earned} cur={s.user.currency} />
			<Stat label="Bought today" sign="−" value={c.bought} cur={s.user.currency} />
		</div>
	)
})

const PredictLine = view<{ title: string; sub: string; action?: string; warn?: boolean }>(({ title, sub, action, warn }) => (
	<>
		<span class="hm-pl">
			<b>{title}</b>
			<span class={warn ? "hm-m hm-w" : "hm-m"}>{sub}</span>
		</span>
		{action ? <span class="hm-pg">{action}</span> : null}
	</>
))

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`

/** One minimal predict card: state on the left, one action on the right. */
export const HomePredict = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const w = s.wallet
	const open = s.trades.find((t) => t.status === "open")
	const done = s.trades.find((t) => t.day === day && t.status === "settled")
	const f = open ? flowOf(open.deposit, open.results) : null
	const ready = !!w?.connected && w.usdt >= DEPOSIT
	const bal = w?.connected ? `${fmt(w.usdt)} USDT · ${sg(w.today)} today` : "Not connected"
	if (f) {
		const title = f.over ? (f.won ? "Finish the games" : "Stop · finish the games") : `Try ${f.tryNo} of ${TRIES}`
		return (
			<a class="hm-c hm-pd" href="/trading">
				<PredictLine title={title} sub={bal} action="Continue" />
			</a>
		)
	}
	if (done || s.trades.some((t) => t.day === day))
		return (
			<a class="hm-c hm-pd" href="/wallet">
				<PredictLine title="Predict done" sub={bal} action="Wallet" />
			</a>
		)
	if (!ready)
		return (
			<a class="hm-c hm-pd" href="/wallet">
				<PredictLine title="Add balance" sub={w?.connected ? `${fmt(w.usdt)} of ${fmt(DEPOSIT)} USDT` : "Connect Binance"} action="Open" warn />
			</a>
		)
	return (
		<form method="post" action="/trading/deposit" style={{ margin: 0 }}>
			<input type="hidden" name="back" value="/trading" />
			<Submit class="hm-c hm-pd">
				<PredictLine title="Predict ready" sub={bal} action="Start" />
			</Submit>
		</form>
	)
})

const TaskRow = view<{ href: string; title: string; color: string; left: number }>(({ href, title, color, left }) => (
	<a class="hm-tr" href={href}>
		<i class="hm-td" style={{ background: color }}></i>
		<span class="hm-tn">{title}</span>
		<span class="hm-m">{left}</span>
	</a>
))

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => {
	if (!p.projects.length && p.home.left < 1) return null
	return (
		<div class="hm-c hm-tl">
			{p.projects.map((x) => (
				<TaskRow key={x.id} href={`/pad?p=${x.id}`} title={x.title} color={x.color} left={x.left} />
			))}
			{p.home.left > 0 ? <TaskRow href="/pad/home" title="Home" color="#8b979e" left={p.home.left} /> : null}
		</div>
	)
})
