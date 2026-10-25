#!/usr/bin/env bash
set -e
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder"; exit 1; fi
if ! command -v bun >/dev/null 2>&1; then echo "bun not found"; exit 1; fi
if [ ! -f app/client/auth.css ]; then echo "Run file14.sh first (auth.css is missing)"; exit 1; fi

B="../$(basename "$PWD")-backup-$(date +%Y%m%d-%H%M%S)"
if command -v zip >/dev/null 2>&1; then
  B="$B.zip"
  zip -qr "$B" . -x "node_modules/*" ".wrangler/*" ".git/*"
else
  B="$B.tar.gz"
  tar czf "$B" --exclude=node_modules --exclude=.wrangler --exclude=.git .
fi
echo "Backup: $B"

cat > "app/components/income.tsx" << 'MT_EOF_15'
import type { Income, Source, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { isFixed } from "../lib/util.ts"
import { calc, gotToday, srcAmount } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, view } from "./ui.tsx"

const contents = { display: "contents" }
const rateOf = (x: Source) => Number(x.config.rate_minor) || 0
const tagOf = (x: Source) => (!x.active ? "paused" : x.type === "exoclick" ? "exoclick" : isFixed(x.type) ? "fixed" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "daily") : "manual")
const usdTxt = (n: number) => `$${fmt(n)}`
const exoSub = (s: State, x: Source) => s.exo[x.id] || `${usdTxt(s.exoToday[x.id] ?? 0)} today`

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
))

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`incl. ${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">
				+{fmt(i.amount)} <small>{s.user.currency}</small>
			</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<button class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
))

const HoursPanel = view<{ s: State; x: Source; row: Income }>(({ s, x, row }) => {
	const rate = rateOf(x)
	const h = row.hours
	const cur = s.user.currency
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`} open={h ? undefined : true}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))} ${cur}` : `${fmt(rate)} ${cur} / hour`}</span>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hxb">
				<div class="hxg">
					{opts.map((n) => (
						<form key={n} method="post" action="/income/hours" style={contents}>
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input type="hidden" name="hours" value={String(n)} />
							<input type="hidden" name="toggle" value="1" />
							<button class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</button>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<button class="btn xs o">Set</button>
					<button type="button" class="btn xs o" data-close>
						Close
					</button>
				</form>
			</div>
		</details>
	)
})

const SourceMain = view<{ s: State; x: Source; toggle: boolean }>(({ s, x, toggle }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	if (toggle && !x.active) {
		return (
			<form method="post" action="/income/toggle" style={contents}>
				<Hid s={s} id={x.id} />
				<button class="btn xs o">Resume</button>
			</form>
		)
	}
	if (x.type === "exoclick") {
		return (
			<>
				<b class="ea">
					+{fmt(sum)} <small>{cur}</small>
				</b>
				{s.exo[x.id] ? (
					<a class="btn xs o" href="/income">
						Fix
					</a>
				) : null}
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				<b class="ea">
					+{fmt(x.amount)} <small>{cur}</small>
				</b>
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		)
	}
	if (got.length) {
		return (
			<>
				<b class="ea">
					+{fmt(sum)} <small>{cur}</small>
				</b>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o">
					Add {fmt(fixed)} {cur}
				</button>
			</form>
		)
	}
	return (
		<form method="post" action="/income/add" class="ln" style={{ gap: "6px" }}>
			<Back s={s} />
			<input type="hidden" name="source_id" value={x.id} />
			<input class="in pr2" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs o">Add</button>
		</form>
	)
})

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
))

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const got = fixedSrc ? gotToday(s, x)[0] : undefined
	const cur = s.user.currency
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} ${cur} + ${fmt(rateOf(x))} / hour`) : ""
	return (
		<div class="sw" data-exo={x.type === "exoclick" ? "1" : undefined}>
			<div class="rw">
				<div>
					<div>{x.name}</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle={false} />
				</span>
			</div>
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	)
})

const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<button class="btn full">Add income</button>
	</>
))

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
	["exoclick", "ExoClick"],
]

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<input class="in" name="name" placeholder="Source name (e.g. Construction)" autocomplete="off" required />
		<input type="hidden" name="kind" value="fixed" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 8px" }}>
			{KINDS.map(([k, l]) => (
				<span key={k} class={k === "fixed" ? "chip on" : "chip"} data-mode={k} style={{ cursor: "pointer" }}>
					{l}
				</span>
			))}
		</div>
		<div class="kf kf-fixed">
			<div class="ln">
				<input class="in" name="fixed" placeholder="Per day" inputmode="decimal" autocomplete="off" />
				<input class="in" name="rate" placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
			</div>
			<div class="lb">Tap it once a day on Home, then pick the extra hours.</div>
		</div>
		<div class="kf kf-manual">
			<div class="lb">You type the amount yourself each day.</div>
		</div>
		<div class="kf kf-daily kf-monthly">
			<input class="in" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
			<div class="lb">Added for you automatically.</div>
		</div>
		<div class="kf kf-exoclick">
			<input class="in" name="api_key" type="password" placeholder="ExoClick API key" autocomplete="off" />
			<div class="lb">Saved encrypted. Counted in USD during the day, converted to {s.user.currency} when the day ends.</div>
		</div>
		<button class="btn full">Add source</button>
	</>
))

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-kind="fixed" data-adp hidden>
		<SourceFields s={s} />
	</form>
))

const TodayRows = view<{ s: State }>(({ s }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return sources.length || others.length ? (
		<>
			{sources.map((x) => (
				<HomeRow key={x.id} s={s} x={x} />
			))}
			{others.map((i) => (
				<IncomeRow key={i.id} s={s} i={i} />
			))}
		</>
	) : (
		<Empty>No sources yet. Add one on the Income page.</Empty>
	)
})

export const IncomeDesktop = view<{ s: State; title?: string; id?: string; bare?: boolean }>(({ s, title = "Income today", id = "f-inc-d", bare = false }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	if (bare) {
		return (
			<>
				<form method="post" action="/income/named" id={id} class="sc spf" data-adp hidden>
					<NamedFields s={s} />
				</form>
				<div class="sc incbare">
					<TodayRows s={s} />
					<button type="button" class="addrow" data-bigadd data-for={id}>
						<Icon name="plus" />
						<span>Add manual income</span>
					</button>
				</div>
			</>
		)
	}
	return (
		<>
			<form method="post" action="/income/named" id={id} class="sc spf" data-adp hidden>
				<NamedFields s={s} />
			</form>
			<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add manual income">
				{sources.length || others.length ? (
					<>
						{sources.map((x) => (
							<HomeRow key={x.id} s={s} x={x} />
						))}
						{others.map((i) => (
							<IncomeRow key={i.id} s={s} i={i} />
						))}
					</>
				) : (
					<Empty>No sources yet. Add one on the Income page.</Empty>
				)}
			</ListCard>
		</>
	)
})

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : ""
	return (
		<div class="dbw" data-exo={x.type === "exoclick" ? "1" : undefined}>
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{tagOf(x)}</span>
					</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">{x.active ? "Pause" : "Resume"}</button>
					</form>
					<button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}>
						<Icon name="edit" />
					</button>
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			<form method="post" action="/income/edit" class="ad" data-addp hidden>
				<Hid s={s} id={x.id} />
				<label>Edit {x.name}</label>
				<input class="in f" name="name" value={x.name} autocomplete="off" required />
				{fixedSrc ? (
					<div class="ln" style={{ marginTop: "8px" }}>
						<input class="in" name="fixed" value={fixed ? plain(fixed) : ""} placeholder="Per day" inputmode="decimal" autocomplete="off" />
						<input class="in" name="rate" value={rateOf(x) ? plain(rateOf(x)) : ""} placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
					</div>
				) : null}
				{x.type === "exoclick" ? <input class="in" style={{ marginTop: "8px" }} name="api_key" type="password" placeholder="New API key (leave empty to keep)" autocomplete="off" /> : null}
				{!fixedSrc && x.type !== "exoclick" && x.mode === "auto" ? <input class="in" style={{ marginTop: "8px" }} name="amount" value={plain(x.amount)} placeholder="Amount" inputmode="decimal" autocomplete="off" /> : null}
				<button class="btn xs" style={{ marginTop: "10px" }}>
					Save
				</button>
			</form>
		</div>
	)
})

export const IncomeExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="income"
		open
		title="Income sources"
		label="Add source"
		head={
			<>
				<b class="big2">{s.sources.length}</b>
				<span class="lb">{`${s.sources.filter((x) => x.active).length} active`}</span>
			</>
		}
		form={<SourceForm s={s} />}
	>
		{s.sources.length ? <>{s.sources.map((x) => <ManageRow key={x.id} s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>}
	</ExpandCard>
))

export const HomeIncome = view<{ s: State }>(({ s }) => (
	<div class="xc xbare">
		<div class="xb">
			<TodayRows s={s} />
		</div>
		<div class="xf">
			<button type="button" class="addrow" data-xplus>
				<Icon name="plus" />
				<span>Add manual income</span>
			</button>
			<form method="post" action="/income/named" class="sf xfm" data-adp hidden>
				<NamedFields s={s} />
			</form>
		</div>
	</div>
))
MT_EOF_15
cat > "app/components/debts.tsx" << 'MT_EOF_15'
import type { DebtView, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { dayLabel, dayOf, hhmm } from "../lib/time.ts"
import { calc, debtPct, peopleCount, pctOf } from "../lib/view.ts"
import { Back, BigAdd, Empty, ExpandCard, Icon, NameChips, view } from "./ui.tsx"

type DebtProps = { s: State; d: DebtView; manage: boolean }

const lastLine = (s: State, d: DebtView) => {
	const when = `${dayLabel(dayOf(d.at))} · ${hhmm(d.at)}`
	if (!d.delta) return `Started ${when}`
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
MT_EOF_15
cat > "app/components/buys.tsx" << 'MT_EOF_15'
import type { Buy, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Back, Card, Empty, ExpandCard, Icon, ListCard, NameChips, view } from "./ui.tsx"

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
				<button class="ub" aria-label="Undo buy">
					<Icon name="undo" />
				</button>
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
		<button class="btn full">Add a spend</button>
	</>
))

export const BuysExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="buys"
		open
		fixed
		title="Today's buys"
		label="Add a spend"
		form={
			<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>
				<SpendFields s={s} />
			</form>
		}
	>
		<BuyRows s={s} />
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

export const TodayCards = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<Card title="Bought today">
			<div class="big2" style={{ whiteSpace: "nowrap" }}>
				−{fmt(c.bought)} <small>{s.user.currency}</small>
			</div>
		</Card>
	)
})

export const EarnedTop = view<{ s: State }>(({ s }) => (
	<div class="earn-top">
		<div class="lb">Earned today</div>
		<b class="ea">
			+{fmt(calc(s).earned)} <small>{s.user.currency}</small>
		</b>
	</div>
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
MT_EOF_15
cat > ".mt_patch15.mjs" << 'MT_EOF_15'
// file15: Home cleanup (income card, earned today, buys, I owe) and "last update" per debt. Run from the Moneytracker folder.
import { appendFileSync, readFileSync, writeFileSync } from "node:fs"

let failed = 0
const edit = (file, steps) => {
	let s = readFileSync(file, "utf8")
	for (const { done, find, replace, label } of steps) {
		if (s.includes(done)) {
			console.log(`  skip  ${file} (${label}) already applied`)
			continue
		}
		if (!s.includes(find)) {
			console.error(`  FAIL  ${file} (${label}) anchor not found`)
			failed++
			continue
		}
		s = s.replace(find, () => replace)
		console.log(`  ok    ${file} (${label})`)
	}
	writeFileSync(file, s)
}

// ---- Expand card: optional "fixed" (no collapse) ----
edit("app/components/ui.tsx", [
	{
		label: "fixed prop type",
		done: "fixed?: boolean",
		find: "\tjar?: number\n\tchildren?: RemixNode\n}",
		replace: "\tjar?: number\n\tfixed?: boolean\n\tchildren?: RemixNode\n}",
	},
	{
		label: "fixed prop arg",
		done: "jar = -1, fixed = false",
		find: 'label = "", jar = -1, children }) => (',
		replace: 'label = "", jar = -1, fixed = false, children }) => (',
	},
	{
		label: "details attrs",
		done: 'data-fixed={fixed ? "1" : undefined}',
		find: '<details class="xd" data-keep-open={storeKey} open={open ? true : undefined}>',
		replace: '<details class="xd" data-keep-open={fixed ? undefined : storeKey} data-fixed={fixed ? "1" : undefined} open={open || fixed ? true : undefined}>',
	},
	{
		label: "hide chevron when fixed",
		done: "{fixed ? null : (",
		find: '\t\t\t\t<span class="chev">\n\t\t\t\t\t<Icon name="chev" />\n\t\t\t\t</span>\n\t\t\t</summary>\n\t\t\t<div class="xb">',
		replace:
			'\t\t\t\t{fixed ? null : (\n\t\t\t\t\t<span class="chev">\n\t\t\t\t\t\t<Icon name="chev" />\n\t\t\t\t\t</span>\n\t\t\t\t)}\n\t\t\t</summary>\n\t\t\t<div class="xb">',
	},
])

// ---- Top bar: optional left slot (Earned today on Home) ----
edit("app/components/layout.tsx", [
	{
		label: "TopBar left prop",
		done: "split?: boolean; left?: RemixNode",
		find: "export const TopBar = view<{ split?: boolean }>(({ split }) => {",
		replace: "export const TopBar = view<{ split?: boolean; left?: RemixNode }>(({ split, left }) => {",
	},
	{
		label: "TopBar left slot",
		done: "{left}",
		find: '<div class="top-status-bar tsplit">\n\t\t\t<ClockWidget />',
		replace: '<div class="top-status-bar tsplit">\n\t\t\t{left}\n\t\t\t<ClockWidget />',
	},
	{
		label: "AppLayout prop type",
		done: "topLeft?: RemixNode",
		find: "\tdock?: RemixNode\n\tfull?: boolean\n}",
		replace: "\tdock?: RemixNode\n\tfull?: boolean\n\ttopLeft?: RemixNode\n}",
	},
	{
		label: "AppLayout arg",
		done: "dock, full, topLeft",
		find: 'desktopTab = "", dock, full }) => (',
		replace: 'desktopTab = "", dock, full, topLeft }) => (',
	},
	{
		label: "AppLayout top bar",
		done: "<TopBar split left={topLeft} />",
		find: "<TopBar split />",
		replace: "<TopBar split left={topLeft} />",
	},
])

// ---- Screens ----
edit("app/screens.tsx", [
	{
		label: "EarnedTop import",
		done: "EarnedTop, Hero",
		find: 'import { BuysDesktop, BuysExpand, Hero, TodayCards } from "./components/buys.tsx"',
		replace: 'import { BuysDesktop, BuysExpand, EarnedTop, Hero, TodayCards } from "./components/buys.tsx"',
	},
	{
		label: "Home earned top left",
		done: "topLeft={<EarnedTop",
		find: '\t\ttitle="Home"\n',
		replace: '\t\ttitle="Home"\n\t\ttopLeft={<EarnedTop s={s} />}\n',
	},
	{
		label: "Home desktop income card without header",
		done: "<IncomeDesktop s={s} bare />",
		find: '<IncomeDesktop s={s} title="Income today" />',
		replace: "<IncomeDesktop s={s} bare />",
	},
	{
		label: "Debts page mobile manage",
		done: 'storeKey="owe-page" manage />',
		find: '<OweMobile s={s} open storeKey="owe-page" />',
		replace: '<OweMobile s={s} open storeKey="owe-page" manage />',
	},
	{
		label: "Debts page desktop manage",
		done: '<OweDesktop s={s} open storeKey="owe-page" manage />',
		find: '<OweDesktop s={s} open storeKey="owe-page" />',
		replace: '<OweDesktop s={s} open storeKey="owe-page" manage />',
	},
])

// ---- Client JS ----
edit("app/client/app.js", [
	{
		label: "fixed cards do not collapse",
		done: "details[data-fixed] > summary",
		find: '\t\tvar t = e.target\n\t\tvar q = t.closest("button[name][value]")',
		replace: '\t\tvar t = e.target\n\t\tif (t.closest && t.closest("details[data-fixed] > summary")) {\n\t\t\te.preventDefault()\n\t\t\treturn\n\t\t}\n\t\tvar q = t.closest("button[name][value]")',
	},
	{
		label: "plus button without details",
		done: "if (xd && !xd.open) {",
		find: "\t\t\t\tif (!xd.open) {\n\t\t\t\t\txd.open = true",
		replace: "\t\t\t\tif (xd && !xd.open) {\n\t\t\t\t\txd.open = true",
	},
])

// ---- CSS ----
{
	const file = "app/client/app.css"
	const s = readFileSync(file, "utf8")
	if (s.includes("/* file15 */")) console.log(`  skip  ${file} (file15 css) already applied`)
	else {
		appendFileSync(
			file,
			`
/* file15 */
.earn-top{display:flex;flex-direction:column;gap:3px;min-width:0}
.earn-top .lb{font-size:11px}
.earn-top b{font-size:20px;font-weight:700;letter-spacing:-.04em;line-height:1;white-space:nowrap}
.earn-top small,.rt b small{font-size:11px;color:var(--mu);font-weight:400;letter-spacing:0;margin-left:3px}
.xbare .xb{border-top:0;padding:8px 16px 6px}
.addrow{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:11px 14px;border:1px dashed var(--acl);border-radius:var(--rm);background:var(--acs);color:var(--ac);font-weight:600;font-size:13px}
.addrow svg.ic{width:18px;height:18px;stroke-width:2;transition:transform .18s ease}
.addrow.on svg.ic{transform:rotate(45deg)}
.incbare{padding:6px 22px 18px}
.incbare .addrow{margin-top:12px}
details[data-fixed]>.xh{cursor:default;padding-right:70px}
.dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}
`,
		)
		console.log(`  ok    ${file} (file15 css)`)
	}
}

// ---- Database: when a debt was last added to / paid ----
edit("database/schema.sql", [
	{
		label: "debts columns",
		done: "last_delta    INTEGER",
		find: "  amount_minor  INTEGER NOT NULL DEFAULT 0,\n  created_at    INTEGER NOT NULL\n);\nCREATE INDEX IF NOT EXISTS debts_user_idx",
		replace: "  amount_minor  INTEGER NOT NULL DEFAULT 0,\n  updated_at    INTEGER NOT NULL DEFAULT 0,\n  last_delta    INTEGER NOT NULL DEFAULT 0,\n  created_at    INTEGER NOT NULL\n);\nCREATE INDEX IF NOT EXISTS debts_user_idx",
	},
])

edit("scripts/migrate.ts", [
	{
		label: "debts alter",
		done: "ALTER TABLE debts ADD COLUMN updated_at",
		find: '\t"ALTER TABLE trade_results ADD COLUMN tf INTEGER NOT NULL DEFAULT 0",\n]',
		replace: '\t"ALTER TABLE trade_results ADD COLUMN tf INTEGER NOT NULL DEFAULT 0",\n\t"ALTER TABLE debts ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",\n\t"ALTER TABLE debts ADD COLUMN last_delta INTEGER NOT NULL DEFAULT 0",\n]',
	},
])

edit("app/db/tables.ts", [
	{
		label: "debts table columns",
		done: "last_delta: c.integer()",
		find: "\t\titem_qty: c.integer(),\n\t\tamount_minor: c.integer(),\n\t\tcreated_at: c.integer(),",
		replace: "\t\titem_qty: c.integer(),\n\t\tamount_minor: c.integer(),\n\t\tupdated_at: c.integer(),\n\t\tlast_delta: c.integer(),\n\t\tcreated_at: c.integer(),",
	},
])

edit("app/lib/data.ts", [
	{
		label: "DebtView type",
		done: "paid: number; at: number",
		find: "owed: number; paid: number }",
		replace: "owed: number; paid: number; at: number; delta: number }",
	},
	{
		label: "loadDebts fields",
		done: "at: d.updated_at || d.created_at",
		find: "\t\t\t\tpaid: paid.get(d.id) ?? 0,\n",
		replace: "\t\t\t\tpaid: paid.get(d.id) ?? 0,\n\t\t\t\tat: d.updated_at || d.created_at,\n\t\t\t\tdelta: d.last_delta || 0,\n",
	},
])

edit("app/lib/actions.ts", [
	{
		label: "undo buy restores debt",
		done: "amount_minor: d.amount_minor + back, updated_at",
		find: "if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back })",
		replace: "if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back, updated_at: Date.now(), last_delta: back })",
	},
	{
		label: "add to item debt",
		done: "(d.item_qty ?? 0) + n, updated_at",
		find: "await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n })",
		replace: "await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n, updated_at: Date.now(), last_delta: n })",
	},
	{
		label: "add to money debt",
		done: "d.amount_minor + m, updated_at",
		find: "await db.update(debts, d.id, { amount_minor: d.amount_minor + m })",
		replace: "await db.update(debts, d.id, { amount_minor: d.amount_minor + m, updated_at: Date.now(), last_delta: m })",
	},
	{
		label: "person money update",
		done: "row.amount_minor + money, updated_at",
		find: "if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money })",
		replace: "if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money, updated_at: Date.now(), last_delta: money })",
	},
	{
		label: "person money create",
		done: "amount_minor: money, updated_at",
		find: 'kind: "money", amount_minor: money, created_at: Date.now() })',
		replace: 'kind: "money", amount_minor: money, updated_at: Date.now(), last_delta: money, created_at: Date.now() })',
	},
	{
		label: "person item update",
		done: "(row.item_qty ?? 0) + cig, updated_at",
		find: "if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig })",
		replace: "if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig, updated_at: Date.now(), last_delta: cig })",
	},
	{
		label: "person item create",
		done: "item_qty: cig, amount_minor: 0, updated_at",
		find: 'item_qty: cig, amount_minor: 0, created_at: Date.now() })',
		replace: 'item_qty: cig, amount_minor: 0, updated_at: Date.now(), last_delta: cig, created_at: Date.now() })',
	},
	{
		label: "clear debt",
		done: "last_delta: -(d.item_qty ?? 0)",
		find: 'if (d) await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 })',
		replace:
			'if (d) await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0, updated_at: Date.now(), last_delta: -(d.item_qty ?? 0) } : { amount_minor: 0, updated_at: Date.now(), last_delta: -d.amount_minor })',
	},
	{
		label: "pay item debt",
		done: "(d.item_qty ?? 0) - n, updated_at",
		find: "await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n })",
		replace: "await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n, updated_at: Date.now(), last_delta: -n })",
	},
	{
		label: "pay money debt",
		done: "d.amount_minor - pay, updated_at",
		find: "await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay })",
		replace: "await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay, updated_at: now, last_delta: -pay })",
	},
])

if (failed) {
	console.error(`\n${failed} patch step(s) failed. Your files differ from the version this script expects; nothing was reverted. Restore from the backup zip and send me the folder.`)
	process.exit(1)
}
MT_EOF_15
echo "Applying changes..."
if ! bun .mt_patch15.mjs; then rm -f .mt_patch15.mjs; exit 1; fi
rm -f .mt_patch15.mjs

if [ -f .dev.vars ]; then
  read -r -p "Run the database migration now (adds 2 columns to debts)? [Y/n] " A || A=n
  case "$A" in n|N) echo "Skipped. Run: bun run db:migrate" ;; *) bun run db:migrate ;; esac
else
  echo "Next: bun run db:migrate   (needs .dev.vars)"
fi
echo "Production database: run the same migration there before you deploy."

echo "Typecheck..."
bun run typecheck || echo "Typecheck printed issues above. Send them to me."
echo "Done. Start it with: bun run dev"
