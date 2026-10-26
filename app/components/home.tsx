import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export type PadLeft = { projects: number; home: number }

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
	const open = s.trades.some((t) => t.status === "open")
	const done = s.trades.some((t) => t.day === today(s.user.day_start))
	const ok = open || !done
	return (
		<a class="hm-c hm-bal hm-pr" href="/trading">
			<b class={ok ? "hm-dots" : "hm-dots no"}>{ok ? "You can predict today" : "You can't predict today"}</b>
			<div class="hm-m">Predict</div>
		</a>
	)
})

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => (
	<div class="hm-c hm-tk">
		<a href="/pad">
			<span class="hm-m">Project tasks left</span>
			<b>{p.projects}</b>
		</a>
		<a href="/pad/home">
			<span class="hm-m">Home tasks left</span>
			<b>{p.home}</b>
		</a>
	</div>
))
