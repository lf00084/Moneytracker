import type { DebtView, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { dayLabel, dayOf, hhmm, timeAgo } from "../lib/time.ts"
import { calc, debtPct, peopleCount, pctOf } from "../lib/view.ts"
import { Back, BigAdd, Empty, ExpandCard, Icon, NameChips, view } from "./ui.tsx"

type DebtProps = { s: State; d: DebtView; manage: boolean }

const lastLine = (s: State, d: DebtView) => {
	const when = `${dayLabel(dayOf(d.at))} · ${hhmm(d.at)}`
	if (!d.delta) return `Started ${timeAgo(d.at)}`
	const unit = d.kind === "money" ? s.user.currency : d.item
	const n = d.kind === "money" ? fmt(Math.abs(d.delta)) : String(Math.abs(d.delta))
	return `${d.delta > 0 ? "Added" : "Paid"} ${n} ${unit} · ${when}`
}

const DebtPanel = view<DebtProps & { kind: "add" | "pay" }>(({ s, d, kind, manage }) => {
	const pay = kind === "pay"
	const unit = d.kind === "money" ? s.user.currency : d.item
	const all = d.kind === "money" ? plain(d.owed) : String(d.owed)
	return (
		<form method="post" action={pay ? "/debts/pay" : "/debts"} class="ad" data-addp={pay ? undefined : true} data-payp={pay ? true : undefined} hidden>
			<input type="hidden" name="debt_id" value={d.id} />
			<Back s={s} />
			<label>
				{pay ? "Pay" : "Add to"} {d.person}
			</label>
			<div class="ln">
				<div class="iw">
					<input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off" />
					{pay ? (
						<button type="button" class="all" data-all={all} aria-label="Fill the full amount">
							All
						</button>
					) : null}
					<span class="mu">{unit}</span>
				</div>
				<button class="btn xs">{pay ? "Pay" : "Add"}</button>
				{manage ? (
					<button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn={`Remove ${d.person} from the list without marking it paid?`} aria-label="Remove without paying" title="Remove without paying">
						<Icon name="trash" />
					</button>
				) : null}
			</div>
		</form>
	)
})

const DebtRow = view<DebtProps>(({ s, d, manage }) => {
	const label = d.kind === "money" ? `${fmt(d.owed)} ${s.user.currency}` : `${d.owed} ${d.item}`
	return (
		<div class="dbw">
			<div class="db">
				<button type="button" class="ib sm hi" data-tg aria-label={`Add debt to ${d.person}`}>
					<Icon name="plus" />
				</button>
				<div class="dn">
					<div class="l1">
						<b>{d.person}</b>
						<span>{label}</span>
					</div>
					<div class="lb dl">{lastLine(s, d)}</div>
					<div class="mt s n">
						<i style={{ width: `${debtPct(d)}%` }}></i>
					</div>
				</div>
				<button type="button" class="btn xs o" data-pay>
					Pay
				</button>
			</div>
			<DebtPanel s={s} d={d} manage={manage} kind="add" />
			<DebtPanel s={s} d={d} manage={manage} kind="pay" />
		</div>
	)
})

const DebtList = view<{ s: State; manage: boolean }>(({ s, manage }) => (s.debts.length ? <>{s.debts.map((d) => <DebtRow key={d.id} s={s} d={d} manage={manage} />)}</> : <Empty>Nobody to pay. All clear.</Empty>))

const AddDebtPanel = view<{ s: State }>(({ s }) => (
	<form method="post" action="/debts" class="sf adp" data-adp hidden>
		<Back s={s} />
		<NameChips names={[...new Set(s.debts.map((d) => d.person))]} />
		<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required />
		<div class="iw">
			<input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required />
			<span class="mu">{s.user.currency}</span>
		</div>
		<button class="btn full">Add</button>
	</form>
))

type OweProps = { s: State; open: boolean; storeKey: string; manage?: boolean }

export const OweMobile = view<OweProps>(({ s, open, storeKey, manage = false }) => {
	const c = calc(s)
	const n = peopleCount(s)
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="I owe"
			label="Add debt"
			head={
				<>
					<b class="big2 sp">
						{fmt(c.oweMoney)} <small>{s.user.currency}</small>
					</b>
					<span class="sp sm">{c.oweExtra}</span>
				</>
			}
			foot={
				<div class="xl">
					<span>{n === 1 ? "1 person" : `${n} people`}</span>
				</div>
			}
			form={<AddDebtPanel s={s} />}
		>
			<DebtList s={s} manage={manage} />
		</ExpandCard>
	)
})

export const OweDesktop = view<OweProps>(({ s, open, storeKey, manage = false }) => {
	const c = calc(s)
	return (
		<div class="sc bgc">
			<BigAdd label="Add debt" />
			<div class="ct">
				<details data-keep-open={storeKey} open={open ? true : undefined}>
					<summary class="sh">
						<span>I owe</span>
						<span class="rr">
							<span class="lb">{`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`}</span>
							<span class="chev">
								<Icon name="chev" />
							</span>
						</span>
					</summary>
					<DebtList s={s} manage={manage} />
				</details>
				<AddDebtPanel s={s} />
			</div>
		</div>
	)
})

export const RoadCard = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	const chips = [
		...s.goals.map((g) => ({ key: `g${g.id}`, text: `${g.title} ${pctOf(s, g)}%` })),
		...s.debts.filter((d) => d.kind === "money").map((d) => ({ key: `d${d.id}`, text: `${d.person} ${debtPct(d)}%` })),
	]
	return (
		<div class="cd jarc">
			<i class="jar" style={{ width: `${c.pct}%` }}></i>
			<div class="jin">
				<div class="tg">Road to goals</div>
				<div class="cb">
					<div class="gl">
						<span class="big">
							{c.pct}
							<small>%</small>
						</span>
						<span class="lb">{`${fmt(c.toGo)} ${s.user.currency} to go`}</span>
					</div>
					{chips.length ? (
						<div class="chips">
							{chips.map((x) => (
								<span key={x.key} class="chip">
									{x.text}
								</span>
							))}
						</div>
					) : null}
				</div>
			</div>
		</div>
	)
})
