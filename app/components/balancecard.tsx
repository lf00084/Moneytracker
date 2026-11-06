import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { showMad, showUsdt } from "../lib/usdt.ts"
import { Icon, Link, view } from "./ui.tsx"

export const BalanceCard = view<{ s: State }>(({ s }) => {
	const onHold = s.money?.pendingMad ?? 0
	const pe = s.snapshot?.priceEffectMad ?? 0
	const peSign = pe < 0 ? "−" : "+"
	const peFmt = `${peSign}${fmt(Math.abs(pe))}`
	const cur = s.user.currency
	const w = s.wallet
	const usdt = w?.connected ? w : null
	const bal = showMad(s.balanceText)

	return (
		<article class="hm-bal-card">
			<div class="hm-bal-top-row">
				<span class="hm-bal-label">Total balance</span>
				<button type="button" class="ib sm" data-eye aria-label="Show balance">
					<Icon name="eye" />
				</button>
			</div>
			<div class="hm-bal-val-row">
				<b class="hm-dots" data-bal={bal} data-cur={cur}>
					•••••••••
				</b>
			</div>
			<div class="hm-bal-sub-row">
				{onHold > 0 ? (
					<Link href="/income" class="hm-onhold-badge">
						+{fmt(onHold)} {cur} on hold
					</Link>
				) : (
					<span class="hm-bal-hint">All-time count</span>
				)}
				{pe ? (
					<span class="hm-pe-badge">
						pe {peFmt}
					</span>
				) : null}
			</div>
			{usdt ? (
				<Link href="/trading" class="hm-bal-usdt">
					<span>
						USDT {showUsdt(usdt.totalText)} ≈ <b>{showMad(usdt.valueMadText)}</b> {cur}
					</span>
					<span class="mu">{`@ ${fmt(usdt.rate)}`}</span>
				</Link>
			) : null}
		</article>
	)
})
