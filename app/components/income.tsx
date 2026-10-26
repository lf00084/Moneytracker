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
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`}>
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

const HomeAct = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const amt = (n: number) => (
		<b class="ea">
			+{fmt(n)} <small>{cur}</small>
		</b>
	)
	if (x.type === "exoclick") {
		return (
			<>
				<span></span>
				{amt(sum)}
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				<span></span>
				{amt(x.amount)}
			</>
		)
	}
	if (got.length) {
		return (
			<>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="revert" />
					</button>
				</form>
				{amt(sum)}
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</button>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan" data-tg>
			Add
		</button>
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
	const all = gotToday(s, x)
	const got = fixedSrc ? all[0] : undefined
	const cur = s.user.currency
	const exo = x.type === "exoclick"
	const sub = exo ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} ${cur} + ${fmt(rateOf(x))} / hour`) : ""
	const manual = !fixedSrc && !exo && x.mode !== "auto" && !all.length
	return (
		<div class="sw dbw" data-exo={exo ? "1" : undefined}>
			<div class="hr">
				<div class="hn">
					<div>{x.name}</div>
					{sub ? <div class={exo && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
					{exo && s.exo[x.id] ? (
						<a class="lnk" href="/income">
							Fix
						</a>
					) : null}
				</div>
				<HomeAct s={s} x={x} />
			</div>
			{manual ? (
				<form method="post" action="/income/add" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<div class="ln">
						<input class="in" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs">Add</button>
					</div>
				</form>
			) : null}
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
			<div class="sc incbare">
				<TodayRows s={s} />
			</div>
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
	</div>
))
