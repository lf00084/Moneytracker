import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export const HomeBalance = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<button type="button" class="ib" data-eye aria-label="Show balance">
			<Icon name="eye" />
		</button>
		<div class="hm-m">Total balance</div>
	</div>
))

export const HomeToday = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hm-two">
			<div class="hm-c">
				<div class="hm-m">Earned today</div>
				<div class="hm-big">
					+{fmt(c.earned)} <small>{s.user.currency}</small>
				</div>
			</div>
			<div class="hm-c">
				<div class="hm-m">Bought today</div>
				<div class="hm-big">
					−{fmt(c.bought)} <small>{s.user.currency}</small>
				</div>
			</div>
		</div>
	)
})
