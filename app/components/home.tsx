import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { DEPOSIT, flowOf, resOf, TRIES } from "../lib/trade-math.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export type PadProject = { id: string; title: string; color: string; left: number; total: number }
export type PadLeft = { projects: PadProject[]; home: { left: number; total: number } }

export const HomeBalance = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<div class="hm-ba">
			<button type="button" class="ib" data-eye aria-label="Show balance">
				<Icon name="eye" />
			</button>
		</div>
		<div class="hm-m">Total balance</div>
	</div>
))

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

export const HomePredict = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const open = s.trades.find((t) => t.status === "open")
	const done = s.trades.find((t) => t.day === day && t.status === "settled")
	const f = open ? flowOf(open.deposit, open.results) : null
	const won = !!done && resOf(done.results).some((x) => x.won)
	const title = f
		? f.tryNo > 1 && f.steps.length === 0
			? `Lost · one more try, ${fmt(f.left)} USDT left`
			: `Predict is open · try ${f.tryNo} of ${TRIES}`
		: done
			? won
				? "Won today · predict ended"
				: "Done for today"
			: "You can predict today"
	const tag = f ? "running" : done ? "done" : "available"
	return (
		<div class="hm-c hm-gc hm-pc">
			<div class="hm-gr">
				<span class="hm-m">Predict</span>
				<span class={f || !done ? "hm-tag" : "hm-tag no"}>{tag}</span>
			</div>
			<div class="hm-gt2">{title}</div>
			{f ? (
				<a class="hm-go" href="/trading">
					Continue predict
				</a>
			) : !done ? (
				<a class="hm-go" href="/trading">{`Start predict · ${fmt(DEPOSIT)} USDT`}</a>
			) : null}
		</div>
	)
})

const Prog = view<{ href: string; title: string; color: string; left: number; total: number }>(({ href, title, color, left, total }) => (
	<a class="hm-c hm-gc" href={href}>
		<div class="hm-gr">
			<span class="hm-gt">
				<i style={{ background: color }}></i>
				{title}
			</span>
			<span class="hm-m">{`${left} left of ${total}`}</span>
		</div>
		<div class="hm-pb">
			<i style={{ width: `${total ? Math.round(((total - left) / total) * 100) : 0}%`, background: color }}></i>
		</div>
	</a>
))

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => (
	<>
		{p.projects.map((x) => (
			<Prog key={x.id} href={`/pad?p=${x.id}`} title={x.title} color={x.color} left={x.left} total={x.total} />
		))}
		{p.home.left > 0 ? <Prog href="/pad/home" title="Home" color="#8b979e" left={p.home.left} total={p.home.total} /> : null}
	</>
))
