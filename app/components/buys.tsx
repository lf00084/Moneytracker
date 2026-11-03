import type { Buy, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Back, BankIcon, Empty, ExpandCard, FlowBadge, Icon, ListCard, NameChips, Submit, view } from "./ui.tsx"

export const buyName = (b: Buy) => (b.qty > 1 ? `${b.name} ×${b.qty}` : b.name)

export const SpendRow = view<{ s: State; id: string; name: string; sub: string; amount: string; bankName?: string; at?: number }>(
	({ s, id, name, sub, amount, bankName = "", at }) => (
		<div class="by">
			<div>
				<div>{name}</div>
				<div class="lb">
					{at ? <span class="time-tag">{hhmm(at)} · </span> : null}
					{sub ? `${sub} · ` : ""}<FlowBadge from={bankName || "Cash"} to="Outside" />
				</div>
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
	),
)

export const FromPicker = view<{ s: State; name?: string; label?: string }>(({ s, name = "from", label }) => {
	const banks = s.money?.banks ?? []
	const defId = s.money?.banks.find((b) => b.isDefault)?.id ?? banks[0]?.id ?? ""

	return (
		<div class="from-picker-wrap">
			<label class="from-picker-label">{label ?? (name === "to" ? "To" : "From")}</label>
			<div class="from-picker-scroll">
				{banks.map((b) => (
					<label key={b.id} class="from-picker-item">
						<input
							type="radio"
							name={name}
							value={b.id}
							checked={b.id === defId ? true : undefined}
							data-from-radio
						/>
						<span class="from-picker-btn">
							<BankIcon name={b.name} url={b.iconUrl} size={18} />
							<span>{b.name}</span>
						</span>
					</label>
				))}
			</div>
		</div>
	)
})

const BuyRows = view<{ s: State }>(({ s }) => {
	const bankMap = new Map((s.money?.banks ?? []).map((b) => [b.id, b.name]))
	return (
		<div>
			{s.buys.length ? (
				s.buys.map((b) => (
					<SpendRow
						key={b.id}
						s={s}
						id={b.id}
						name={buyName(b)}
						bankName={bankMap.get(b.bankId) ?? "Cash"}
						sub={`${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`}
						amount={`−${fmt(b.total)}`}
					/>
				))
			) : (
				<Empty>Nothing bought today.</Empty>
			)}
		</div>
	)
})

export const SpendFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<div class="spend-chips-row">
			<NameChips names={s.names} />
			<button type="button" class="chip fee-chip" data-set-fee>
				Bank fee
			</button>
		</div>
		<FromPicker s={s} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Item" autocomplete="off" required />
			<input class="in pr" name="price" data-price data-live-price placeholder="Price" inputmode="decimal" autocomplete="off" required />
		</div>
		<div class="sheet-live-line" data-live-total="minus">
			Total: no change
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
				<div class="lb">{s.user.currency} {c.oweExtra}</div>
			</div>
		</div>
	)
})
