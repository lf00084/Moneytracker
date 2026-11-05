import type { BankView, MoneyView, PendingView } from "../lib/banks.ts"
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm, timeAgo, today } from "../lib/time.ts"
import { DEPOSIT, flowOf, toMad, TRIES } from "../lib/trade-math.ts"
import { calc } from "../lib/view.ts"
import { BankIcon, Empty, ExpandCard, FlowBadge, Icon, Link, NameChips, Submit, view } from "./ui.tsx"
import { FromPicker } from "./buys.tsx"

export type PadProject = { id: string; title: string; color: string; left: number; total: number }
export type PadLeft = { projects: PadProject[]; home: { left: number; total: number } }

export const NeedsYouChip = view<{ s: State }>(({ s }) => {
	const m = s.money
	const w = s.wallet
	const items: { label: string; href: string }[] = []

	if (m && m.unmatchedCount > 0) {
		items.push({ label: `${m.unmatchedCount} unmatched order${m.unmatchedCount > 1 ? "s" : ""}`, href: "/trading#unmatched" })
	}
	if (m) {
		const late = m.pending.filter((p) => p.overdue > 0)
		if (late.length > 0) {
			items.push({ label: `${late.length} late payment${late.length > 1 ? "s" : ""}`, href: "/income" })
		}
	}

	if (!items.length) return null

	return (
		<div class="hm-needs-wrap">
			{items.map((it, idx) => (
				<Link key={idx} href={it.href} class="hm-needs-chip">
					<span class="hm-needs-dot"></span>
					<span>Needs you: {it.label}</span>
					<Icon name="chev" />
				</Link>
			))}
		</div>
	)
})

export const QuickButtons = view<{ s: State }>(({ s }) => (
	<div class="hm-quick-row">
		<button type="button" class="hm-qbtn" data-sheet-trigger="bought">
			<span class="hm-qbtn-icon sp">−</span>
			<span class="hm-qbtn-txt">Bought</span>
		</button>
		<button type="button" class="hm-qbtn" data-sheet-trigger="add-money">
			<span class="hm-qbtn-icon pos">+</span>
			<span class="hm-qbtn-txt">Add money</span>
		</button>
		<button type="button" class="hm-qbtn" data-sheet-trigger="paid">
			<span class="hm-qbtn-icon ea">✓</span>
			<span class="hm-qbtn-txt">Paid</span>
		</button>
		<button type="button" class="hm-qbtn" data-sheet-trigger="transfer">
			<span class="hm-qbtn-icon">⇄</span>
			<span class="hm-qbtn-txt">Move money</span>
		</button>
	</div>
))

export const MoneyTiles = view<{ s: State }>(({ s }) => {
	const m = s.money
	if (!m) return null
	const cur = s.user.currency

	return (
		<div class="hm-tiles-section">
			<div class="hm-tiles-row">
				{m.banks.map((b) => (
					<div key={b.id} class={b.isDefault ? "hm-tile on" : "hm-tile"}>
						<div class="hm-tile-top">
							<BankIcon name={b.name} url={b.iconUrl} size={26} />
							{b.isDefault ? <span class="hm-tile-tag">Def</span> : null}
						</div>
						<div class="hm-tile-name">{b.name}</div>
						<div class="hm-tile-bal">
							<b>{fmt(b.balance)}</b>
							<small>{cur}</small>
						</div>
					</div>
				))}

				{m.unmatchedCount > 0 ? (
					<Link href="/trading#unmatched" class="hm-tile unmatched">
						<div class="hm-tile-top">
							<span class="hm-tile-warn-icon">!</span>
							<span class="hm-tile-tag warn">{m.unmatchedCount}</span>
						</div>
						<div class="hm-tile-name">Pick bank</div>
						<div class="hm-tile-bal">
							<b>{fmt(m.unmatchedMad)}</b>
							<small>{cur}</small>
						</div>
					</Link>
				) : null}

				<button type="button" class="hm-tile add-tile" data-sheet-trigger="add-bank">
					<div class="hm-tile-top">
						<span class="hm-tile-plus">+</span>
					</div>
					<div class="hm-tile-name">Add bank</div>
					<div class="hm-tile-sub">New bank</div>
				</button>
			</div>
		</div>
	)
})

export const UsdtCard = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const cur = s.user.currency
	const totalUsdt = w?.usdt ?? 0
	const rate = w?.rate ?? s.user.usdt_rate
	const madVal = w?.valueMad ?? toMad(totalUsdt, rate)

	return (
		<div class="hm-wide">
			<span class="bk-ic usdt">₮</span>
			<span class="hm-wide-mid">
				<b>USDT</b>
				<small>
					Funding {fmt(w?.fundingUsdt ?? 0)} · Predict {fmt(w?.predictUsdt ?? 0)}
				</small>
			</span>
			<span class="hm-wide-end">
				<b>
					{fmt(totalUsdt)} <small>USDT</small>
				</b>
				<small>
					≈ {fmt(madVal)} {cur}
				</small>
			</span>
		</div>
	)
})

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`

export const HomePredict = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const w = s.wallet
	const open = s.trades.find((t) => t.status === "open")
	const played = s.trades.some((t) => t.day === day)
	const f = open ? flowOf(open.deposit, open.results) : null
	const bal = w?.predictUsdt ?? w?.usdt ?? 0
	const ready = !!w?.connected && bal >= DEPOSIT

	let title = "Predict ready"
	let sub = w?.connected ? `${fmt(bal)} USDT in Predict · ${sg(w.earnedToday)} today` : "Not connected"
	let action = "Start"
	let warn = false

	if (f) {
		title = f.over ? (f.won ? "Finish the games" : "Stop · finish the games") : `Try ${f.tryNo} of ${TRIES}`
		action = "Continue"
	} else if (played) {
		title = "Predict done"
		action = "Details"
	} else if (!ready) {
		title = "Add balance"
		sub = w?.connected ? `${fmt(bal)} of ${fmt(DEPOSIT)} USDT` : "Connect Binance"
		action = "Open"
		warn = true
	}

	const body = (
		<>
			<span class="bk-ic pr">
				<Icon name="trade" />
			</span>
			<span class="hm-wide-mid">
				<b>{title}</b>
				<small class={warn ? "neg" : undefined}>{sub}</small>
			</span>
			<span class="hm-pg">{action}</span>
		</>
	)

	if (!f && !played && ready) {
		return (
			<form method="post" action="/trading/deposit" style={{ margin: 0 }}>
				<input type="hidden" name="back" value="/trading" />
				<Submit class="hm-wide">{body}</Submit>
			</form>
		)
	}

	return (
		<Link href="/trading" class="hm-wide">
			{body}
		</Link>
	)
})

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

export const HomeTimeline = view<{ s: State }>(({ s }) => {
	const t = today(s.user.day_start)
	const cur = s.user.currency
	const bankMap = new Map((s.money?.banks ?? []).map((b) => [b.id, b.name]))
	const bankName = (id: string) => bankMap.get(id) || (id ? id : "Cash")

	const events: { at: number; label: string; amount: number; sign: string; from: string; to: string }[] = []

	for (const b of s.buys) {
		const from = b.bankId ? bankName(b.bankId) : "Cash"
		events.push({
			at: b.at,
			label: b.name,
			amount: b.total,
			sign: "−",
			from,
			to: "Outside",
		})
	}

	for (const i of s.incomesToday) {
		events.push({
			at: Date.now(),
			label: i.source,
			amount: i.amount,
			sign: "+",
			from: i.locked ? "On hold" : "Outside",
			to: "Cash",
		})
	}

	for (const m of s.money?.moves ?? []) {
		if (m.day === t) {
			if (m.kind === "transfer") {
				events.push({
					at: m.at,
					label: m.note,
					amount: Math.abs(m.amount),
					sign: m.amount < 0 ? "−" : "+",
					from: m.amount < 0 ? m.bank : "Another bank",
					to: m.amount < 0 ? "Another bank" : m.bank,
				})
			} else if (m.kind === "added") {
				events.push({
					at: m.at,
					label: m.note || "Money added",
					amount: m.amount,
					sign: "+",
					from: "Outside",
					to: m.bank,
				})
			}
		}
	}

	for (const p of s.wallet?.moves ?? []) {
		if (p.day === t) {
			if (p.kind === "buy") {
				events.push({
					at: p.at,
					label: `P2P Buy ${fmt(p.usdt)} USDT`,
					amount: p.mad,
					sign: "−",
					from: p.bankId ? bankName(p.bankId) : "Cash",
					to: "Funding",
				})
			} else if (p.kind === "sell") {
				events.push({
					at: p.at,
					label: `P2P Sell ${fmt(p.usdt)} USDT`,
					amount: p.mad,
					sign: "+",
					from: "Funding",
					to: p.bankId ? bankName(p.bankId) : "Cash",
				})
			} else if (p.kind === "to_predict") {
				events.push({
					at: p.at,
					label: `Moved ${fmt(p.usdt)} USDT to Predict`,
					amount: p.mad,
					sign: "",
					from: "Funding",
					to: "Predict",
				})
			} else if (p.kind === "to_funding") {
				events.push({
					at: p.at,
					label: `Moved ${fmt(p.usdt)} USDT to Funding`,
					amount: p.mad,
					sign: "",
					from: "Predict",
					to: "Funding",
				})
			}
		}
	}

	events.sort((a, b) => b.at - a.at)

	return (
		<ExpandCard
			storeKey="today-moves"
			open={false}
			title="Today's moves"
			label="Moves"
			class="card-grey xc-grey"
			head={<span class="lb">{events.length ? `${events.length} entries` : "No moves"}</span>}
		>
			{events.length ? (
				<div class="hm-timeline-list">
					{events.map((e, idx) => (
						<div key={idx} class="hm-timeline-row">
							<div>
								<div class="hm-timeline-name">{e.label}</div>
								<div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "2px" }}>
									{e.at ? <span class="time-tag">{hhmm(e.at)}</span> : null}
									<FlowBadge from={e.from} to={e.to} />
								</div>
							</div>
							<div class="hm-timeline-val">
								<b class={e.sign === "−" ? "sp" : e.sign === "+" ? "pos" : ""}>
									{e.sign}{fmt(e.amount)} <small>{cur}</small>
								</b>
							</div>
						</div>
					))}
				</div>
			) : (
				<Empty>No moves recorded today.</Empty>
			)}
		</ExpandCard>
	)
})

const TaskRow = view<{ href: string; title: string; color: string; left: number }>(({ href, title, color, left }) => (
	<Link class="hm-tr" href={href}>
		<i class="hm-td" style={{ background: color }}></i>
		<span class="hm-tn">{title}</span>
		<span class="hm-m">{left}</span>
	</Link>
))

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => {
	if (!p.projects.length && p.home.left < 1) return null
	return (
		<div class="hm-c hm-tl">
			{p.projects.map((x) => (
				<TaskRow key={x.id} href={`/pad?p=${x.id}`} title={x.title} color={x.color} left={x.left} />
			))}
			{p.home.left > 0 ? <TaskRow href="/pad/home" title="Home" color="#8b979e" left={p.home.left} /> : null}
		</div>
	)
})


export const HomeSheets = view<{ s: State }>(({ s }) => (
	<>
		<div class="app-sheet-ov" id="sheet-bought" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b>Bought</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<form method="post" action="/buy" class="sheet-form">
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
					<Submit class="full">Record spend</Submit>
				</form>
			</div>
		</div>

		<div class="app-sheet-ov" id="sheet-add-money" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b>Add money</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<form method="post" action="/banks/entry" class="sheet-form">
					<FromPicker s={s} name="bank_id" />
					<div class="ln">
						<input class="in pr" name="amount" data-live-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
						<input class="in" name="note" placeholder="Note (optional)" autocomplete="off" />
					</div>
					<div class="sheet-live-line" data-live-total="plus">
						Total: no change
					</div>
					<Submit class="full">Add money</Submit>
				</form>
			</div>
		</div>

		<div class="app-sheet-ov" id="sheet-transfer" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b>Move money</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<form method="post" action="/banks/transfer" class="sheet-form" id="sheet-transfer-form">
					<div class="ln">
						<div style={{ flex: 1 }}>
							<label class="lb">From</label>
							<select class="in sel" name="from" id="transfer-from" required style={{ width: "100%" }}>
								{s.money?.banks.map((b, idx) => (
									<option key={b.id} value={b.id} selected={idx === 0}>
										{b.name} ({fmt(b.balance)} {s.user.currency})
									</option>
								))}
							</select>
						</div>
						<div style={{ flex: 1 }}>
							<label class="lb">To</label>
							<select class="in sel" name="to" id="transfer-to" required style={{ width: "100%" }}>
								{s.money?.banks.map((b, idx) => (
									<option key={b.id} value={b.id} selected={idx === 1 || (idx === 0 && s.money?.banks.length === 1)}>
										{b.name} ({fmt(b.balance)} {s.user.currency})
									</option>
								))}
							</select>
						</div>
					</div>
					<div class="ln" style={{ marginTop: "10px" }}>
						<input class="in pr" name="amount" id="transfer-amount" data-live-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
						<input class="in" name="note" placeholder="Note (optional)" autocomplete="off" />
					</div>
					<div class="ferr" id="transfer-error" role="alert" style={{ display: "none", marginTop: "4px" }}></div>
					<div class="sheet-live-line" data-live-total="none">
						Total: no change (inside my world)
					</div>
					<Submit class="full" type="submit">Move money</Submit>
				</form>
			</div>
		</div>

		<div class="app-sheet-ov" id="sheet-paid" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b id="sheet-paid-title">Mark paid</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<form method="post" action="/pending/paid" class="sheet-form" id="sheet-paid-form">
					<div class="fld" style={{ marginBottom: "10px" }}>
						<label class="lb" for="sheet-paid-source-select" style={{ display: "block", marginBottom: "4px" }}>Source / Company</label>
						<select class="in" name="source_id" id="sheet-paid-source-select" required>
							<option value="">Select source / company...</option>
							{s.sources.map((src) => {
								const wait = s.money?.pending.find((p) => p.id === src.id)
								const amt = wait?.left ?? 0
								const isUsd = src.type === "exoclick" || wait?.usd
								const waitText = amt > 0 ? ` (${fmt(amt)} ${isUsd ? "USD" : s.user.currency} on hold)` : ""
								return (
									<option key={src.id} value={src.id} data-amt={amt} data-usd={isUsd ? "1" : "0"} data-name={src.name}>
										{src.name}{waitText}
									</option>
								)
							})}
						</select>
					</div>
					<div class="lb" id="sheet-paid-pending-text" style={{ marginBottom: "8px" }}>
						Leave empty to pay all pending
					</div>
					<div class="ln">
						<input class="in pr" name="amount" id="sheet-paid-amount" data-live-price placeholder="Amount (blank = all)" inputmode="decimal" autocomplete="off" />
					</div>
					<div style={{ marginTop: "10px" }}>
						<FromPicker s={s} name="to" label="Deposit to" />
					</div>
					<div class="sheet-live-line" data-live-total="plus">
						Total: no change
					</div>
					<Submit class="full" type="submit" id="sheet-paid-submit">Confirm paid</Submit>
				</form>
			</div>
		</div>

		<div class="app-sheet-ov" id="sheet-adjust" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b id="sheet-adjust-title">Adjust pending</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<form method="post" action="/pending/adjust" class="sheet-form" id="sheet-adjust-form">
					<input type="hidden" name="source_id" id="sheet-adjust-source-id" value="" />
					<div class="lb" id="sheet-adjust-current-text" style={{ marginBottom: "8px" }}>
						Current pending: 0.00
					</div>
					<div class="ln">
						<input class="in pr" name="amount" id="sheet-adjust-amount" placeholder="New pending amount" inputmode="decimal" autocomplete="off" required />
						<input class="in" name="note" placeholder="Reason / note" autocomplete="off" />
					</div>
					<div class="sheet-live-line" data-live-total="none">
						Total: no change (pending is on hold, not in total)
					</div>
					<Submit class="full">Save adjustment</Submit>
				</form>
			</div>
		</div>

		<div class="app-sheet-ov" id="sheet-bank-actions" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b id="sheet-bank-name">Bank</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<div id="sheet-bank-body" class="sheet-form">
					<div class="gl">
						<div>
							<div class="tg">Balance</div>
							<b class="big" id="sheet-bank-bal">
								0.00
							</b>
						</div>
					</div>

					<form method="post" action="/banks/icon" class="ln" id="sheet-bank-icon-form" style={{ marginTop: "10px" }}>
						<input type="hidden" name="id" id="sheet-bank-icon-id" />
						<input class="in" name="icon_url" id="sheet-bank-icon-input" placeholder="Icon URL (e.g. https://...)" />
						<Submit class="xs">Save icon</Submit>
					</form>
					<div id="sheet-bank-icon-preview" style={{ marginTop: "6px" }}></div>

					<form method="post" action="/banks/default" id="sheet-bank-default-form" style={{ marginTop: "12px" }}>
						<input type="hidden" name="id" id="sheet-bank-default-id" />
						<Submit class="full outline" id="sheet-bank-default-btn">
							Set as default bank
						</Submit>
					</form>

					<form
						method="post"
						action="/banks/delete"
						id="sheet-bank-delete-form"
						style={{ marginTop: "8px" }}
						data-confirm="Delete this bank? Its moves will be moved to Cash."
					>
						<input type="hidden" name="id" id="sheet-bank-delete-id" />
						<Submit class="full dng" id="sheet-bank-delete-btn">
							Delete bank
						</Submit>
					</form>
				</div>
			</div>
		</div>

		<div class="app-sheet-ov" id="sheet-add-bank" hidden>
			<div class="app-sheet">
				<div class="app-sheet-header">
					<b>Add new bank</b>
					<button type="button" class="ub" data-sheet-close aria-label="Close">
						<Icon name="plus" />
					</button>
				</div>
				<form method="post" action="/banks/add" class="sheet-form">
					<div class="ln">
						<input class="in" name="name" placeholder="Bank name (CIH, BMCE, Attijari...)" autocomplete="off" required />
					</div>
					<div class="ln" style={{ marginTop: "10px" }}>
						<input class="in" name="icon_url" placeholder="Icon URL (optional)" autocomplete="off" />
					</div>
					<Submit class="full">Create bank</Submit>
				</form>
			</div>
		</div>
	</>
))
