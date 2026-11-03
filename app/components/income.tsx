import type { Income, Source, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { isFixed } from "../lib/util.ts"
import { calc, gotToday, srcAmount } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, Submit, view } from "./ui.tsx"

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
			<div class="lb">
				{i.at ? <span class="time-tag">{hhmm(i.at)}</span> : null}
				{i.hours ? <span>{i.at ? " · " : ""}incl. {i.hours}h extra</span> : null}
			</div>
		</div>
		<span class="rt">
			<b class="ea">
				+{fmt(i.amount)} <small>{s.user.currency}</small>
			</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<Submit class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</Submit>
			</form>
		</span>
	</div>
))

const HoursPanel = view<{ s: State; x: Source; row: Income; compact?: boolean }>(({ s, x, row, compact = false }) => {
	const rate = rateOf(x)
	const h = row.hours
	const cur = s.user.currency
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`}>
			<summary class={compact ? (h ? "hxc on" : "hxc") : undefined} aria-label="Extra hours">
				{compact ? (
					<Icon name="clock" />
				) : (
					<>
						<span>Extra hours</span>
						<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))} ${cur}` : `${fmt(rate)} ${cur} / hour`}</span>
						<span class="chev">
							<Icon name="chev" />
						</span>
					</>
				)}
			</summary>
			<div class="hxb">
				<div class="hxg">
					{opts.map((n) => (
						<form key={n} method="post" action="/income/hours" style={contents}>
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input type="hidden" name="hours" value={String(n)} />
							<input type="hidden" name="toggle" value="1" />
							<Submit class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</Submit>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<Submit class="btn xs o">Set</Submit>
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
				{amt(sum)}
				<span></span>
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				{amt(x.amount)}
				<span></span>
			</>
		)
	}
	if (got.length) {
		return (
			<>
				<span class="hm-added-tag" title="Recorded today">
					{amt(sum)}
				</span>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<Submit class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="revert" />
					</Submit>
				</form>
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<Submit class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</Submit>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan hadd" data-tg>
			Add
		</button>
	)
})

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<Submit class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</Submit>
	</form>
))

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const all = gotToday(s, x)
	const got = all[0]
	const cur = s.user.currency
	const exo = x.type === "exoclick"
	const rate = rateOf(x)
	const sub = exo
		? exoSub(s, x)
		: fixedSrc
		? (got
			? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` · +${got.hours}h extra (${fmt(Math.round(got.hours * rate))} ${cur})` : ""}`
			: `${fmt(srcAmount(x))} ${cur}${rate ? ` + ${fmt(rate)} / h` : ""}`)
		: rate
		? (got
			? `${got.hours ? `+${got.hours}h extra (${fmt(Math.round(got.hours * rate))} ${cur})` : `${fmt(rate)} ${cur} / h`}`
			: `${fmt(rate)} ${cur} / hour`)
		: ""
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
						<Submit class="btn xs">Add</Submit>
					</div>
				</form>
			) : null}
			{got && rate > 0 ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	)
})

export const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<Submit class="btn full">Add income</Submit>
	</>
))

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
]

export const PayFields = view<{ s: State; initialPay?: string; initialTo?: string }>(({ s, initialPay = "pending", initialTo = "" }) => {
	const m = s.money
	const banks = m?.banks ?? []
	const def = initialTo || (banks.find((b) => b.isDefault)?.id ?? banks[0]?.id ?? "")

	return (
		<div style={{ marginTop: "8px" }}>
			<div class="ln">
				<select class="in" name="pay" data-pay-select>
					<option value="pending" selected={initialPay === "pending" ? true : undefined}>Pending until paid</option>
					<option value="instant" selected={initialPay === "instant" ? true : undefined}>Instant</option>
				</select>
				<select class="in" name="to" data-pay-to>
					{banks.map((b) => (
						<option key={b.id} value={b.id} selected={b.id === def ? true : undefined}>
							{b.name}
						</option>
					))}
				</select>
			</div>
			<div class="lb">Pending waits until marked Paid. Instant immediately credits the selected bank.</div>
		</div>
	)
})

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
		<PayFields s={s} />
		<input class="in" name="pay_days" placeholder="Pays after how many days? (optional, e.g. 15)" inputmode="numeric" autocomplete="off" style={{ marginTop: "8px" }} />
		<Submit class="btn full">Add source</Submit>
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
		<Empty>No sources yet. Add one on the On hold page.</Empty>
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
					<Empty>No sources yet. Add one on the On hold page.</Empty>
				)}
			</ListCard>
		</>
	)
})

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const base = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : ""
	const wait = s.money?.pending.find((p) => p.id === x.id)
	const days = Number(x.config.pay_days) || 0
	const inst = Number(x.config.instant) === 1
	const toName = inst ? (s.money?.banks.find((b) => b.id === String(x.config.to))?.name ?? s.money?.banks.find((b) => b.isDefault)?.name ?? "") : ""
	const sub = [base, inst ? `instant${toName ? ` to ${toName}` : ""}` : days ? `pays after ${days}d` : "", wait ? `pending ${fmt(wait.left)} ${wait.usd ? "USD" : cur}` : ""].filter(Boolean).join(" · ")

	const all = gotToday(s, x)
	const got = fixedSrc ? all[0] : undefined

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
					{x.active ? <HomeAct s={s} x={x} /> : null}
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<Submit class="btn xs o">{x.active ? "Pause" : "Resume"}</Submit>
					</form>
					<button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}>
						<Icon name="edit" />
					</button>
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
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
				{!fixedSrc && x.type !== "exoclick" && x.mode === "auto" ? <input class="in" style={{ marginTop: "8px" }} name="amount" value={plain(x.amount)} placeholder="Amount" inputmode="decimal" autocomplete="off" /> : null}
				{x.type !== "exoclick" ? (
					<PayFields s={s} initialPay={inst ? "instant" : "pending"} initialTo={String(x.config.to ?? "")} />
				) : null}
				{x.type !== "exoclick" ? (
					<input class="in" style={{ marginTop: "8px" }} name="pay_days" value={days ? String(days) : ""} placeholder="Pays after how many days (optional)" inputmode="numeric" autocomplete="off" />
				) : null}
				<div class="wkb" style={{ marginTop: "10px" }}>
					<Submit class="btn xs">Save</Submit>
					<button
						type="button"
						class="btn xs o"
						data-sheet-trigger="adjust-pending"
						data-source-id={x.id}
						data-source-name={x.name}
						data-source-amt={wait?.left ?? 0}
						data-source-usd={x.type === "exoclick" ? "1" : "0"}
					>
						Edit pending
					</button>
				</div>
			</form>
		</div>
	)
})

export const OnHoldPendingList = view<{ s: State }>(({ s }) => {
	const m = s.money
	const pending = m?.pending ?? []
	const cur = s.user.currency

	return (
		<div class="cd">
			<div class="cb">
				<div class="gl">
					<div>
						<div class="tg">Pending to receive</div>
						<b class="big">{fmt(m?.pendingMad ?? 0)} <small>{cur}</small></b>
					</div>
					<span class="lb">{pending.length} sources on hold</span>
				</div>
				{pending.length ? (
					<div class="hm-onhold-list">
						{pending.map((p) => (
							<div key={p.id} class="hm-onhold-row">
								<div class="hm-onhold-info">
									<b>{p.name}</b>
									<span class={p.overdue > 0 ? "hm-onhold-due late" : "hm-onhold-due"}>
										{p.overdue > 0 ? "Overdue" : p.due ? `Due ${p.due}` : "No set date"}
									</span>
								</div>
								<div class="hm-onhold-actions">
									<button
										type="button"
										class="hm-onhold-amt"
										data-sheet-trigger="adjust-pending"
										data-source-id={p.id}
										data-source-name={p.name}
										data-source-amt={p.left}
										data-source-usd={p.usd ? "1" : "0"}
										aria-label={`Edit pending ${p.name}`}
									>
										{fmt(p.left)} {p.usd ? "USD" : cur}
									</button>
									<button
										type="button"
										class="btn xs pos"
										data-sheet-trigger="paid"
										data-source-id={p.id}
										data-source-name={p.name}
										data-source-amt={p.left}
										data-source-usd={p.usd ? "1" : "0"}
									>
										Paid
									</button>
								</div>
							</div>
						))}
					</div>
				) : (
					<Empty>No pending money on hold. All clear.</Empty>
				)}
			</div>
		</div>
	)
})

export const InvoiceCard = view<{ s: State }>(({ s }) => {
	const v = s.invoice
	if (!v) return null
	const label = v.status === "paid" ? "Paid" : v.status === "processing" ? "Processing" : "Pending"
	const sub = v.status === "paid" ? (v.paid ? `paid ${v.paid}` : "paid") : v.due ? `due ${v.due}` : v.date ? `issued ${v.date}` : ""
	return (
		<div class="hm-c inv" data-inv={`${v.id}:${v.status}`}>
			<div>
				<div class="hm-m">{`ExoClick invoice${v.period ? ` · ${v.period}` : ""}`}</div>
				<div class="inv-a">{`$${v.usd.toFixed(2)}`}</div>
				{sub ? <div class="hm-m">{sub}</div> : null}
			</div>
			<span class={`inv-st ${v.status}`}>{label}</span>
			<button type="button" class="ub" data-inv-x aria-label="Close">
				<Icon name="plus" />
			</button>
		</div>
	)
})

export const IncomeExpand = view<{ s: State; open?: boolean; storeKey?: string }>(({ s, open = true, storeKey = "income" }) => (
	<ExpandCard
		storeKey={storeKey}
		open={open}
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

const SrcTile = view<{ s: State; x: Source }>(({ s, x }) => {
	const cur = s.user.currency
	const all = gotToday(s, x)
	const got = all[0]
	const sum = all.reduce((a, i) => a + i.amount, 0)
	const exo = x.type === "exoclick"
	const auto = !exo && x.mode === "auto"
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const rate = rateOf(x)
	const shown = auto ? x.amount : sum
	const filled = exo || auto || all.length > 0
	const bad = exo && !!s.exo[x.id]
	const sub = exo
		? exoSub(s, x)
		: fixedSrc
		? got?.hours
			? `+${got.hours}h extra`
			: `${fmt(fixed)} ${cur}${rate ? ` + ${fmt(rate)}/h` : ""}`
		: auto
		? x.every === "month"
			? "monthly"
			: "daily"
		: rate
		? `${fmt(rate)} ${cur} / h`
		: "manual"
	const manual = !fixedSrc && !exo && !auto && !all.length
	return (
		<div class="hm-src dbw" data-exo={exo ? "1" : undefined}>
			<div class="hm-src-top">
				<b>{x.name}</b>
				{got && !auto && !exo ? (
					<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
						<Hid s={s} id={got.id} />
						<Submit class="hm-src-x" aria-label={`Undo ${x.name}`}>
							<Icon name="revert" />
						</Submit>
					</form>
				) : null}
			</div>
			<div class={filled ? "hm-src-amt" : "hm-src-amt none"}>
				{filled ? `+${fmt(shown)}` : "—"}
				<small>{cur}</small>
			</div>
			<div class={bad ? "hm-src-sub neg" : "hm-src-sub"}>{sub}</div>
			{bad ? (
				<a class="hm-src-btn" href="/income">
					Fix
				</a>
			) : null}
			{fixedSrc && !got ? (
				<form method="post" action="/income/add" style={contents}>
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<Submit class="hm-src-btn">Add {fmt(fixed)}</Submit>
				</form>
			) : null}
			{manual ? (
				<>
					<button type="button" class="hm-src-btn" data-tg>
						Add
					</button>
					<form method="post" action="/income/add" class="ad" data-addp hidden>
						<Back s={s} />
						<input type="hidden" name="source_id" value={x.id} />
						<div class="ln">
							<input class="in" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
							<Submit class="hm-src-btn">Save</Submit>
						</div>
					</form>
				</>
			) : null}
			{got && rate > 0 ? <HoursPanel s={s} x={x} row={got} compact /> : null}
		</div>
	)
})

const OtherTile = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="hm-src dbw">
		<div class="hm-src-top">
			<b>{i.source}</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
				<Hid s={s} id={i.id} />
				<Submit class="hm-src-x" aria-label="Undo income">
					<Icon name="revert" />
				</Submit>
			</form>
		</div>
		<div class="hm-src-amt">
			+{fmt(i.amount)}
			<small>{s.user.currency}</small>
		</div>
		<div class="hm-src-sub">{i.at ? hhmm(i.at) : "today"}</div>
	</div>
))

export const IncomeStripCard = view<{ s: State; open?: boolean; storeKey?: string }>(({ s, open = true, storeKey = "income" }) => {
	const list = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="Income sources"
			label="Add source"
			head={
				<>
					<b class="big2">{s.sources.length}</b>
					<span class="lb">{`${list.length} active`}</span>
				</>
			}
			form={<SourceForm s={s} />}
		>
			{list.length || others.length ? (
				<div class="hm-src-row">
					{list.map((x) => (
						<SrcTile key={x.id} s={s} x={x} />
					))}
					{others.map((i) => (
						<OtherTile key={i.id} s={s} i={i} />
					))}
				</div>
			) : (
				<Empty>No sources yet. Tap + to add one.</Empty>
			)}
		</ExpandCard>
	)
})
