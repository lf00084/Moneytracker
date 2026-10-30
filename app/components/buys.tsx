import type { Buy, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, Submit, view } from "./ui.tsx"

export const buyName = (b: Buy) => (b.qty > 1 ? `${b.name} ×${b.qty}` : b.name)

export const SpendRow = view<{ s: State; id: string; name: string; sub: string; amount: string }>(({ s, id, name, sub, amount }) => (
	<div class="by">
		<div>
			<div>{name}</div>
			<div class="lb">{sub}</div>
		</div>
		<span class="rt">
			<b class="sp">{amount}</b>
			<form method="post" action="/buy/delete" style={{ display: "contents" }} data-confirm="Undo this buy? The money comes back.">
				<Back s={s} />
				<input type="hidden" name="id" value={id} />
				<Submit class="ub" aria-label="Undo buy">
					<Icon name="undo" />
				</Submit>
			</form>
		</span>
	</div>
))

const BuyRows = view<{ s: State }>(({ s }) => (
	<div>
		{s.buys.length ? (
			s.buys.map((b) => <SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={`${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`} amount={`−${fmt(b.total)}`} />)
		) : (
			<Empty>Nothing bought today.</Empty>
		)}
	</div>
))

const SpendFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.names} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Item" autocomplete="off" required />
			<input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required />
		</div>
		<Submit class="btn full">Add a spend</Submit>
	</>
))

export const BuysExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="buys"
		open
		fixed
		title="Today's buys"
		label="Add a spend"
		head={s.buys.length ? undefined : <span class="em">Nothing bought today.</span>}
		form={
			<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>
				<SpendFields s={s} />
			</form>
		}
	>
		{s.buys.length ? <BuyRows s={s} /> : null}
	</ExpandCard>
))

export const BuysDesktop = view<{ s: State }>(({ s }) => (
	<>
		<form method="post" action="/buy" id="f-buy-d" class="sc spf" data-sp data-adp hidden>
			<SpendFields s={s} />
		</form>
		<ListCard title="Today's buys" right={`${s.buys.length}`} target="f-buy-d" label="Add a spend">
			<BuyRows s={s} />
		</ListCard>
	</>
))

export const Hero = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hero">
			<div>
				<div class="lb">Earned today</div>
				<div class="v">+{fmt(c.earned)}</div>
				{c.earnedLine ? <div class="lb">{c.earnedLine}</div> : null}
			</div>
			<div>
				<div class="lb">Bought today</div>
				<div class="v">−{fmt(c.bought)}</div>
				<div class="lb">{s.buys.length} buys</div>
			</div>
			<div>
				<div class="lb">Road to goals</div>
				<div class="v">{c.pct}%</div>
				<div class="mt">
					<i style={{ width: `${c.pct}%` }}></i>
				</div>
			</div>
			<div>
				<div class="lb">I owe</div>
				<div class="v sp">{fmt(c.oweMoney)}</div>
				<div class="lb">
					{s.user.currency} {c.oweExtra}
				</div>
			</div>
		</div>
	)
})
