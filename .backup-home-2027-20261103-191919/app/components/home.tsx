import type { BankView, MoneyView, PendingView } from "../lib/banks.ts"
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm, timeAgo, today } from "../lib/time.ts"
import { DEPOSIT, flowOf, toMad, TRIES } from "../lib/trade-math.ts"
import { calc, gotToday } from "../lib/view.ts"
import type { RemixNode } from "remix/component"
import { BankIcon, Empty, ExpandCard, FlowBadge, Icon, NameChips, Submit, view } from "./ui.tsx"
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
	if (w && w.openHints && w.openHints.length > 0) {
		items.push({ label: `${w.openHints.length} move hint${w.openHints.length > 1 ? "s" : ""}`, href: "/trading#hints" })
	}

	if (!items.length) return null

	return (
		<div class="hm-needs-wrap">
			{items.map((it, idx) => (
				<a key={idx} href={it.href} class="hm-needs-chip">
					<span class="hm-needs-dot"></span>
					<span>Needs you: {it.label}</span>
					<Icon name="chev" />
				</a>
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
					<button
						key={b.id}
						type="button"
						class={b.isDefault ? "hm-tile on" : "hm-tile"}
						data-bank-tile={b.id}
						data-bank-name={b.name}
						data-bank-bal={b.balance}
						data-bank-cash={b.cash ? "1" : "0"}
						data-bank-default={b.isDefault ? "1" : "0"}
						data-bank-icon={b.iconUrl}
					>
						<div class="hm-tile-top">
							<BankIcon name={b.name} url={b.iconUrl} size={26} />
							{b.isDefault ? <span class="hm-tile-tag">Def</span> : null}
						</div>
						<div class="hm-tile-name">{b.name}</div>
						<div class="hm-tile-bal">
							<b>{fmt(b.balance)}</b>
							<small>{cur}</small>
						</div>
					</button>
				))}

				{m.unmatchedCount > 0 ? (
					<a href="/trading#unmatched" class="hm-tile unmatched">
						<div class="hm-tile-top">
							<span class="hm-tile-warn-icon">!</span>
							<span class="hm-tile-tag warn">{m.unmatchedCount}</span>
						</div>
						<div class="hm-tile-name">Pick bank</div>
						<div class="hm-tile-bal">
							<b>{fmt(m.unmatchedMad)}</b>
							<small>{cur}</small>
						</div>
					</a>
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
	const fundingUsdt = w?.fundingUsdt ?? 0
	const predictUsdt = w?.predictUsdt ?? 0
	const rate = w?.rate ?? s.user.usdt_rate
	const madVal = w?.valueMad ?? toMad(totalUsdt, rate)

	return (
		<a href="/trading" class="hm-tile hm-usdt-tile-full compact" style={{ textDecoration: "none" }}>
			<div class="hm-tile-top">
				<span class="bk-ic usdt">₮</span>
			</div>
			<div class="hm-tile-name">USDT</div>
			<div class="hm-tile-bal">
				<b>{fmt(totalUsdt)}</b>
				<small>USDT</small>
				<span class="hm-usdt-mad-val">≈ {fmt(madVal)} {cur}</span>
			</div>
			<div class="hm-usdt-subbals">
				<span class="hm-usdt-sub">Funding: <b>{fmt(fundingUsdt)}</b></span>
				<span class="hm-usdt-dot">·</span>
				<span class="hm-usdt-sub">Predict: <b>{fmt(predictUsdt)}</b></span>
			</div>
		</a>
	)
})

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`

export const HomePredict = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const w = s.wallet
	const open = s.trades.find((t) => t.status === "open")
	const done = s.trades.find((t) => t.day === day && t.status === "settled")
	const f = open ? flowOf(open.deposit, open.results) : null
	const ready = !!w?.connected && (w.predictUsdt ?? w.usdt) >= DEPOSIT
	const bal = w?.connected ? `${fmt(w.predictUsdt ?? w.usdt)} USDT in Predict · ${sg(w.earnedToday)} today` : "Not connected"

	let title = "Predict"
	let sub = bal
	let action = "Open"
	let statusTag = "Ready"
	let warn = false

	if (f) {
		title = f.over ? (f.won ? "Finish the games" : "Stop · finish the games") : `Try ${f.tryNo} of ${TRIES}`
		action = "Continue"
		statusTag = "Active"
	} else if (done || s.trades.some((t) => t.day === day)) {
		title = "Predict done"
		action = "Details"
		statusTag = "Done"
	} else if (!ready) {
		title = "Add balance"
		sub = w?.connected ? `${fmt(w.predictUsdt ?? w.usdt)} of ${fmt(DEPOSIT)} USDT` : "Connect Binance"
		action = "Open"
		statusTag = "Setup"
		warn = true
	} else {
		title = "Predict ready"
		action = "Start"
		statusTag = "Ready"
	}

	const body = (
		<div class="hm-tile hm-predict-tile-full compact">
			<div class="hm-tile-top">
				<div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
					<span class="bk-ic" style={{ width: "24px", height: "24px", background: "var(--acs)", color: "var(--ac)", display: "inline-flex", alignItems: "center", justifyContent: "center", borderRadius: "50%" }}>
						<Icon name="trade" />
					</span>
					<span class="hm-tile-name" style={{ fontSize: "13px", fontWeight: 600 }}>Prediction</span>
				</div>
				<span class={warn ? "hm-tile-tag warn" : "hm-tile-tag"}>{statusTag}</span>
			</div>

			<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "4px" }}>
				<div>
					<b style={{ fontSize: "14px", display: "block" }}>{title}</b>
					{sub ? <span class={warn ? "hm-m hm-w" : "hm-m"}>{sub}</span> : null}
				</div>
				<span class="hm-pg">{action}</span>
			</div>
		</div>
	)

	if (!f && !done && !s.trades.some((t) => t.day === day) && ready) {
		return (
			<form method="post" action="/trading/deposit" style={{ margin: 0, textDecoration: "none" }}>
				<input type="hidden" name="back" value="/trading" />
				<Submit class="hm-predict-submit-btn" style={{ padding: 0, border: 0, background: "none", width: "100%", textAlign: "left" }}>
					{body}
				</Submit>
			</form>
		)
	}

	return (
		<a href="/trading" style={{ textDecoration: "none", display: "block" }}>
			{body}
		</a>
	)
})

export const OnHoldCard = view<{ s: State }>(({ s }) => {
	const m = s.money
	if (!m || !m.pending.length) return null
	const cur = s.user.currency

	return (
		<ExpandCard
			storeKey="onhold"
			open={true}
			title="On hold"
			head={<b>{fmt(m.pendingMad)} <small>{cur}</small></b>}
		>
			<div class="hm-onhold-list">
				{m.pending.map((p) => (
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
		</ExpandCard>
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
	<a class="hm-tr" href={href}>
		<i class="hm-td" style={{ background: color }}></i>
		<span class="hm-tn">{title}</span>
		<span class="hm-m">{left}</span>
	</a>
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


/* ───────── 2027 home: Pico <article> cards with a top-left category tag ───────── */

export const Cat = view<{ title: string; right?: RemixNode; tone?: string; children?: RemixNode }>(({ title, right, tone = "", children }) => (
	<article class={tone ? `h27c ${tone}` : "h27c"}>
		<span class="h27t">{title}</span>
		{right ? <span class="h27r">{right}</span> : null}
		{children}
	</article>
))

const Row = view<{ label: RemixNode; value: RemixNode; tone?: string; sub?: RemixNode }>(({ label, value, tone = "", sub }) => (
	<div class="h27row">
		<span class="h27l">
			<small>{label}</small>
			{sub ? <em>{sub}</em> : null}
		</span>
		<b class={tone}>{value}</b>
	</div>
))

const Sub = view<{ children?: RemixNode }>(({ children }) => <div class="h27sub">{children}</div>)

type Ev = { at: number; label: string; amount: number; sign: string; from: string; to: string }

const moveEvents = (s: State): Ev[] => {
	const t = today(s.user.day_start)
	const bankMap = new Map((s.money?.banks ?? []).map((b) => [b.id, b.name]))
	const bankName = (id: string) => bankMap.get(id) || (id ? id : "Cash")
	const ev: Ev[] = []
	for (const m of s.money?.moves ?? []) {
		if (m.day !== t) continue
		if (m.kind === "transfer") {
			ev.push({ at: m.at, label: m.note || "Transfer", amount: Math.abs(m.amount), sign: m.amount < 0 ? "−" : "+", from: m.amount < 0 ? m.bank : "Another bank", to: m.amount < 0 ? "Another bank" : m.bank })
		} else if (m.kind === "added") {
			ev.push({ at: m.at, label: m.note || "Money added", amount: m.amount, sign: "+", from: "Outside", to: m.bank })
		}
	}
	for (const p of s.wallet?.moves ?? []) {
		if (p.day !== t) continue
		const bank = p.bankId ? bankName(p.bankId) : "Cash"
		if (p.kind === "buy") ev.push({ at: p.at, label: `P2P buy ${fmt(p.usdt)} USDT`, amount: p.mad, sign: "−", from: bank, to: "Funding" })
		else if (p.kind === "sell") ev.push({ at: p.at, label: `P2P sell ${fmt(p.usdt)} USDT`, amount: p.mad, sign: "+", from: "Funding", to: bank })
		else if (p.kind === "to_predict") ev.push({ at: p.at, label: `${fmt(p.usdt)} USDT → Predict`, amount: p.mad, sign: "", from: "Funding", to: "Predict" })
		else if (p.kind === "to_funding") ev.push({ at: p.at, label: `${fmt(p.usdt)} USDT → Funding`, amount: p.mad, sign: "", from: "Predict", to: "Funding" })
	}
	return ev.sort((a, b) => b.at - a.at)
}

/** One card: earned / bought / income sources / buys / moves. No add buttons, no collapse, no totals header. */
export const TodayActivity = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	const cur = s.user.currency
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	const moves = moveEvents(s)
	const bankMap = new Map((s.money?.banks ?? []).map((b) => [b.id, b.name]))

	return (
		<Cat title="Today activity">
			<Row label="Earned today" value={`+${fmt(c.earned)} ${cur}`} tone="ea" />
			<Row label="Bought today" value={`−${fmt(c.bought)} ${cur}`} tone="sp" />

			{sources.length || others.length ? (
				<>
					<Sub>Income</Sub>
					{sources.map((x) => {
						const sum = gotToday(s, x).reduce((a, i) => a + i.amount, 0)
						const val = x.mode === "auto" && x.type !== "exoclick" ? x.amount : sum
						return <Row key={x.id} label={x.name} value={val > 0 ? `+${fmt(val)}` : "—"} tone={val > 0 ? "ea" : "mu"} />
					})}
					{others.map((i) => (
						<Row key={i.id} label={i.source} sub={i.at ? hhmm(i.at) : undefined} value={`+${fmt(i.amount)}`} tone="ea" />
					))}
				</>
			) : null}

			{s.buys.length ? (
				<>
					<Sub>Bought</Sub>
					{s.buys.map((b) => (
						<div class="h27row" key={b.id}>
							<span class="h27l">
								<small>{b.qty > 1 ? `${b.name} ×${b.qty}` : b.name}</small>
								<em>
									{hhmm(b.at)} · {bankMap.get(b.bankId) ?? "Cash"}
								</em>
							</span>
							<span class="h27end">
								<b class="sp">−{fmt(b.total)}</b>
								<form method="post" action="/buy/delete" data-confirm="Undo this buy? The money comes back.">
									<input type="hidden" name="back" value={s.back} />
									<input type="hidden" name="id" value={b.id} />
									<Submit class="h27x" aria-label="Undo buy">
										<Icon name="undo" />
									</Submit>
								</form>
							</span>
						</div>
					))}
				</>
			) : null}

			{moves.length ? (
				<>
					<Sub>Moves</Sub>
					{moves.map((e, i) => (
						<div class="h27row" key={i}>
							<span class="h27l">
								<small>{e.label}</small>
								<em>
									{e.at ? `${hhmm(e.at)} · ` : ""}
									{e.from} → {e.to}
								</em>
							</span>
							<b class={e.sign === "−" ? "sp" : e.sign === "+" ? "pos" : "mu"}>
								{e.sign}
								{fmt(e.amount)}
							</b>
						</div>
					))}
				</>
			) : null}
		</Cat>
	)
})

/** Cash & banks: gap-free rows, USDT sits right under them in the same card. */
export const MoneyCard = view<{ s: State }>(({ s }) => {
	const m = s.money
	const w = s.wallet
	const cur = s.user.currency
	const rate = w?.rate ?? s.user.usdt_rate
	const usdt = w?.usdt ?? 0
	const madVal = w?.valueMad ?? toMad(usdt, rate)
	return (
		<Cat title="Cash & banks">
			<div class="h27list">
				{(m?.banks ?? []).map((b) => (
					<button
						key={b.id}
						type="button"
						class="h27bank"
						data-bank-tile={b.id}
						data-bank-name={b.name}
						data-bank-bal={b.balance}
						data-bank-cash={b.cash ? "1" : "0"}
						data-bank-default={b.isDefault ? "1" : "0"}
						data-bank-icon={b.iconUrl}
					>
						<span class="h27l">
							<BankIcon name={b.name} url={b.iconUrl} size={22} />
							<small>{b.name}</small>
							{b.isDefault ? <i class="h27pill">default</i> : null}
						</span>
						<b>
							{fmt(b.balance)} <small>{cur}</small>
						</b>
					</button>
				))}
				{m && m.unmatchedCount > 0 ? (
					<a href="/trading#unmatched" class="h27bank warn">
						<span class="h27l">
							<span class="h27bang">!</span>
							<small>Pick bank · {m.unmatchedCount}</small>
						</span>
						<b>
							{fmt(m.unmatchedMad)} <small>{cur}</small>
						</b>
					</a>
				) : null}
				<a href="/trading" class="h27bank usdt">
					<span class="h27l">
						<span class="bk-ic usdt">₮</span>
						<small>USDT</small>
						<i class="h27pill">
							F {fmt(w?.fundingUsdt ?? 0)} · P {fmt(w?.predictUsdt ?? 0)}
						</i>
					</span>
					<b>
						{fmt(usdt)} <small>≈ {fmt(madVal)} {cur}</small>
					</b>
				</a>
				<button type="button" class="h27bank add" data-sheet-trigger="add-bank">
					<span class="h27l">
						<span class="h27plus">+</span>
						<small>Add bank</small>
					</span>
				</button>
			</div>
		</Cat>
	)
})

/** P2P: what I bought / sold today, plus profit in the card header. */
export const P2pCard = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const cur = s.user.currency
	const t = today(s.user.day_start)
	const list = (w?.moves ?? []).filter((x) => x.day === t && (x.kind === "buy" || x.kind === "sell"))
	const sum = (k: "buy" | "sell") => list.filter((x) => x.kind === k).reduce((a, x) => ({ usdt: a.usdt + x.usdt, mad: a.mad + x.mad }), { usdt: 0, mad: 0 })
	const b = sum("buy")
	const so = sum("sell")
	const pt = w?.p2pToday ?? 0
	return (
		<a href="/trading" class="h27a">
			<Cat title="P2P" right={<b class={pt < 0 ? "neg" : "pos"}>{sg(pt)} {cur}</b>}>
				<Row label="Bought" sub={`${fmt(b.usdt)} USDT`} value={`−${fmt(b.mad)} ${cur}`} tone="sp" />
				<Row label="Sold" sub={`${fmt(so.usdt)} USDT`} value={`+${fmt(so.mad)} ${cur}`} tone="pos" />
				<Row label="Profit today" value={`${sg(pt)} ${cur}`} tone={pt < 0 ? "neg" : "pos"} />
				<Row label="Profit total" value={`${sg(w?.p2pTotal ?? 0)} ${cur}`} tone={(w?.p2pTotal ?? 0) < 0 ? "neg" : ""} />
				{list.slice(0, 4).map((x) => (
					<div class="h27row mini" key={x.id}>
						<span class="h27l">
							<small>
								{x.kind === "buy" ? "Buy" : "Sell"} {fmt(x.usdt)} USDT
							</small>
							<em>{hhmm(x.at)}</em>
						</span>
						<b class={x.kind === "buy" ? "sp" : "pos"}>
							{x.kind === "buy" ? "−" : "+"}
							{fmt(x.mad)}
						</b>
					</div>
				))}
			</Cat>
		</a>
	)
})

/** Prediction: status + how much I won today. */
export const PredictCard = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const w = s.wallet
	const cur = s.user.currency
	const open = s.trades.find((t) => t.status === "open")
	const played = s.trades.some((t) => t.day === day)
	const f = open ? flowOf(open.deposit, open.results) : null
	const bal = w?.predictUsdt ?? w?.usdt ?? 0
	const ready = !!w?.connected && bal >= DEPOSIT
	const won = w?.today ?? 0
	const wonMad = toMad(won, w?.rate ?? s.user.usdt_rate)

	let status = "Ready"
	let line = "Start today's predict"
	let action = "Start"
	if (!w?.connected) { status = "Setup"; line = "Connect Binance"; action = "Open" }
	else if (f) { status = "Active"; line = f.over ? (f.won ? "Finish the games" : "Stop · finish the games") : `Try ${f.tryNo} of ${TRIES}`; action = "Continue" }
	else if (played) { status = "Done"; line = "Predict done"; action = "Details" }
	else if (!ready) { status = "Setup"; line = `Add balance · ${fmt(bal)} / ${fmt(DEPOSIT)} USDT`; action = "Open" }

	const start = !f && !played && ready
	return (
		<Cat title="Prediction" right={<span class={status === "Setup" ? "neg" : ""}>{status}</span>}>
			<div class="h27row">
				<span class="h27l">
					<small>{line}</small>
				</span>
				{start ? (
					<form method="post" action="/trading/deposit">
						<input type="hidden" name="back" value="/trading" />
						<Submit class="h27go">{action}</Submit>
					</form>
				) : (
					<a class="h27go" href="/trading">
						{action}
					</a>
				)}
			</div>
			<Row label="Won today" sub={played || won ? `≈ ${sg(wonMad)} ${cur}` : "no predict yet"} value={played || won ? `${sg(won)} USDT` : "—"} tone={won < 0 ? "neg" : won > 0 ? "pos" : "mu"} />
			<Row label="In Predict" value={`${fmt(bal)} USDT`} />
		</Cat>
	)
})

/** Tasks, renamed Doings. */
export const DoingsCard = view<{ p: PadLeft }>(({ p }) => {
	if (!p.projects.length && p.home.left < 1) return null
	const rows = [...p.projects.map((x) => ({ id: x.id, href: `/pad?p=${x.id}`, title: x.title, color: x.color, left: x.left })), ...(p.home.left > 0 ? [{ id: "home", href: "/pad/home", title: "Home", color: "#8b979e", left: p.home.left }] : [])]
	return (
		<Cat title="Doings" right={`${rows.reduce((a, r) => a + r.left, 0)} left`}>
			{rows.map((r) => (
				<a class="h27row" href={r.href} key={r.id}>
					<span class="h27l">
						<i class="h27dot" style={{ background: r.color }}></i>
						<small>{r.title}</small>
					</span>
					<b>{r.left}</b>
				</a>
			))}
		</Cat>
	)
})

export const OnHoldCat = view<{ s: State }>(({ s }) => {
	const m = s.money
	if (!m || !m.pending.length) return null
	const cur = s.user.currency
	return (
		<Cat title="On hold" right={<b>{fmt(m.pendingMad)} {cur}</b>}>
			{m.pending.map((p) => (
				<div key={p.id} class="h27row">
					<span class="h27l">
						<small>{p.name}</small>
						<em class={p.overdue > 0 ? "neg" : ""}>{p.overdue > 0 ? "Overdue" : p.due ? `Due ${p.due}` : "No set date"}</em>
					</span>
					<span class="h27end">
						<button type="button" class="h27amt" data-sheet-trigger="adjust-pending" data-source-id={p.id} data-source-name={p.name} data-source-amt={p.left} data-source-usd={p.usd ? "1" : "0"} aria-label={`Edit pending ${p.name}`}>
							{fmt(p.left)} {p.usd ? "USD" : cur}
						</button>
						<button type="button" class="h27go" data-sheet-trigger="paid" data-source-id={p.id} data-source-name={p.name} data-source-amt={p.left} data-source-usd={p.usd ? "1" : "0"}>
							Paid
						</button>
					</span>
				</div>
			))}
		</Cat>
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
					<Submit class="btn full">Record spend</Submit>
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
					<Submit class="btn full">Add money</Submit>
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
					<Submit class="btn full" type="submit">Move money</Submit>
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
					<Submit class="btn full" type="submit" id="sheet-paid-submit">Confirm paid</Submit>
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
					<Submit class="btn full">Save adjustment</Submit>
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
						<Submit class="btn xs">Save icon</Submit>
					</form>
					<div id="sheet-bank-icon-preview" style={{ marginTop: "6px" }}></div>

					<form method="post" action="/banks/default" id="sheet-bank-default-form" style={{ marginTop: "12px" }}>
						<input type="hidden" name="id" id="sheet-bank-default-id" />
						<Submit class="btn full o" id="sheet-bank-default-btn">
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
						<Submit class="btn full dng" id="sheet-bank-delete-btn">
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
					<Submit class="btn full">Create bank</Submit>
				</form>
			</div>
		</div>
	</>
))
