import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon, view } from "./ui.tsx"

export const BalanceCard = view<{ s: State }>(({ s }) => {
	const onHold = s.money?.pendingMad ?? 0
	const pe = s.snapshot?.priceEffectMad ?? 0
	const peSign = pe < 0 ? "−" : "+"
	const peFmt = `${peSign}${fmt(Math.abs(pe))}`

	return (
		<div class="hm-c hm-bal-card">
			<div class="hm-bal-top-row">
				<span class="hm-bal-label">Total balance</span>
				<button type="button" class="ib sm" data-eye aria-label="Show balance">
					<Icon name="eye" />
				</button>
			</div>
			<div class="hm-bal-val-row">
				<b
					class="hm-dots"
					data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`}
					data-cur={s.user.currency}
				>
					••••••
				</b>
			</div>
			<div class="hm-bal-sub-row">
				{onHold > 0 ? (
					<a href="/income" class="hm-onhold-badge">
						+{fmt(onHold)} {s.user.currency} on hold
					</a>
				) : (
					<span class="hm-bal-hint">All-time count</span>
				)}
				{s.snapshot ? (
					<span class="hm-pe-badge">
						pe {peFmt}
					</span>
				) : null}
			</div>
		</div>
	)
})
