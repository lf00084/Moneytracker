import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { flowOf, resOf, TRIES } from "../lib/trade-math.ts"
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

const PredictRow = view<{ title: string; action?: string }>(({ title, action }) => (
	<>
		<span class="hm-pt">{title}</span>
		{action ? <span class="hm-pg">{action}</span> : null}
	</>
))

const HomePredictCard = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const open = s.trades.find((t) => t.status === "open")
	const done = s.trades.find((t) => t.day === day && t.status === "settled")
	const f = open ? flowOf(open.deposit, open.results) : null
	const won = !!done && resOf(done.results).some((x) => x.won)
	const title = f
		? f.over
			? f.won
				? "5 min done · finish the games"
				: "Stop trading · finish the games"
			: f.tryNo > 1
				? `Second try · ${fmt(f.left)} USDT left`
				: `Predict is open · try ${f.tryNo} of ${TRIES}`
		: done
			? won
				? "Won today · predict ended"
				: "Done for today"
			: "You can predict today"
	if (f)
		return (
			<a class="hm-c hm-pd" href="/trading">
				<PredictRow title={title} action="Continue" />
			</a>
		)
	if (done)
		return (
			<div class="hm-c hm-pd">
				<PredictRow title={title} />
			</div>
		)
	return (
		<form method="post" action="/trading/deposit" style={{ margin: 0 }}>
			<input type="hidden" name="back" value="/trading" />
			<Submit class="hm-c hm-pd">
				<PredictRow title={title} action="Start" />
			</Submit>
		</form>
	)
})

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`

const HomeWallet = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w || !w.connected)
		return (
			<a class="hm-c hm-pd" href="/wallet">
				<PredictRow title="Predict wallet" action="Connect" />
			</a>
		)
	return (
		<a class="hm-c hm-pd" href="/wallet">
			<PredictRow title={`Predict wallet · ${fmt(w.usdt)} USDT`} action={`${sg(w.today)} today`} />
		</a>
	)
})

export const HomePredict = view<{ s: State }>(({ s }) => (
	<>
		<HomePredictCard s={s} />
		<HomeWallet s={s} />
	</>
))

const TaskRow = view<{ href: string; title: string; color: string; left: number; total: number }>(({ href, title, color, left, total }) => (
	<a class="hm-tr" href={href}>
		<i class="hm-td" style={{ background: color }}></i>
		<span class="hm-tn">{title}</span>
		<span class="hm-m">{`${left} left`}</span>
		<span class="hm-tb">
			<i style={{ width: `${total ? Math.round(((total - left) / total) * 100) : 0}%`, background: color }}></i>
		</span>
	</a>
))

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => {
	if (!p.projects.length && p.home.left < 1) return null
	return (
		<div class="hm-c hm-tl">
			{p.projects.map((x) => (
				<TaskRow key={x.id} href={`/pad?p=${x.id}`} title={x.title} color={x.color} left={x.left} total={x.total} />
			))}
			{p.home.left > 0 ? <TaskRow href="/pad/home" title="Home" color="#8b979e" left={p.home.left} total={p.home.total} /> : null}
		</div>
	)
})
