#!/usr/bin/env bash
set -e
[ -f app/lib/trading.ts ] || { echo "Run this inside the Moneytracker folder"; exit 1; }
if grep -q "pseg" app/client/app.css; then echo "already applied"; exit 0; fi
RUN="$(command -v node || command -v bun || true)"
[ -n "$RUN" ] || { echo "node or bun is needed"; exit 1; }

cat > app/lib/trade-math.ts <<'GOAT_EOF'
export const DEPOSIT = 1600
export const TRIES = 2
export const PARTS = 3

export type Game = "step" | "res"
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number; state: "set" | "done"; asset: string; tf: number }
export type TradeSession = {
	id: string
	day: string
	deposit: number
	rate: number
	status: "open" | "settled"
	pnl: number
	returnUsdt: number
	returnMad: number
	at: number
	results: TradeResult[]
}

export type Flow = {
	tryNo: number
	base: number
	left: number
	stakes: number[]
	steps: TradeResult[]
	staked: number
	won: boolean
	over: boolean
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const resOf = (r: TradeResult[]) => r.filter((x) => x.game === "res" && isDone(x)).sort((a, b) => a.idx - b.idx)
export const stepsOf = (r: TradeResult[], t: number) => r.filter((x) => x.game === "step" && Math.ceil(x.idx / PARTS) === t).sort((a, b) => a.idx - b.idx)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const strip = (r: TradeResult[]) => doneOf(r).map((x) => (x.won ? "W" : "M")).join(" ")

export const stakesFor = (base: number) => {
	const a = Math.round(base / 4)
	return [a, a, base - 2 * a]
}

export function flowOf(deposit: number, rows: TradeResult[]): Flow {
	const res = resOf(rows)
	const won = res.some((x) => x.won)
	const left = deposit + res.reduce((a, x) => a + x.pnl, 0)
	const over = won || res.length >= TRIES || (res.length > 0 && left <= 0)
	const tryNo = Math.min(res.length + 1, TRIES)
	const steps = stepsOf(rows, tryNo)
	return {
		tryNo,
		base: left,
		left,
		stakes: stakesFor(left),
		steps,
		staked: steps.reduce((a, x) => a + x.tf, 0),
		won,
		over,
	}
}
GOAT_EOF

cat > app/lib/trading.ts <<'GOAT_EOF'
import { sql } from "remix/data-table"
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts"
import { today } from "./time.ts"
import { todayFor } from "./users.ts"
import { backUsdt, DEPOSIT, doneOf, flowOf, PARTS, toMad, totalPnl, type TradeResult, type TradeSession } from "./trade-math.ts"
import type { User } from "./users.ts"
import { id, text } from "./util.ts"

const usdtMinor = (v: unknown) => {
	const raw = String(v ?? "").trim().replace(",", ".")
	if (!raw) return null
	const n = Math.abs(Number(raw))
	return Number.isFinite(n) && n <= 100000 ? Math.round(n * 100) : null
}

const toResult = (r: { id: string; game: string; idx: number; won: number; pnl_minor: number; state: string; asset: string; tf: number }): TradeResult => ({
	id: r.id,
	game: r.game === "step" ? "step" : "res",
	idx: r.idx,
	won: r.won !== 0,
	pnl: r.pnl_minor,
	state: r.state === "set" ? "set" : "done",
	asset: r.asset || "",
	tf: r.tf || 0,
})

async function resultsOf(uid: string, sessionId: string): Promise<TradeResult[]> {
	const rows = await db.findMany(tradeResults, { where: { user_id: uid, session_id: sessionId }, orderBy: ["created_at", "asc"] })
	return rows.map(toResult)
}

export async function loadTrades(uid: string): Promise<TradeSession[]> {
	const rows = await db.findMany(tradeSessions, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 30 })
	if (!rows.length) return []
	const res = await db.findMany(tradeResults, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 })
	const by = new Map<string, TradeResult[]>()
	for (const r of res) {
		const list = by.get(r.session_id) ?? []
		list.push(toResult(r))
		by.set(r.session_id, list)
	}
	return rows.map(
		(s): TradeSession => ({
			id: s.id,
			day: s.day,
			deposit: s.deposit_minor,
			rate: s.rate_minor,
			status: s.status === "settled" ? "settled" : "open",
			pnl: s.pnl_minor ?? 0,
			returnUsdt: s.return_usdt_minor ?? 0,
			returnMad: s.return_mad_minor ?? 0,
			at: s.created_at,
			results: (by.get(s.id) ?? []).sort((a, b) => (a.game === b.game ? a.idx - b.idx : a.game === "step" ? -1 : 1)),
		}),
	)
}

export async function startTrade(user: User): Promise<string | void> {
	const uid = user.id
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open predict first"
	const day = today(user.day_start)
	const already = await db.findOne(tradeSessions, { where: { user_id: uid, day } })
	if (already) return `One predict a day. The next one opens at ${String(user.day_start).padStart(2, "0")}:00`
	const cost = toMad(DEPOSIT, user.usdt_rate)
	if (!cost) return "Set the USDT price in Settings first"
	const now = Date.now()
	const sessionId = id()
	const purchaseId = id()
	await db.transaction(async (tx) => {
		await tx.create(purchases, {
			id: purchaseId,
			user_id: uid,
			name: `Deposit ${DEPOSIT / 100} USDT`,
			qty: 1,
			unit_minor: cost,
			total_minor: cost,
			day,
			created_at: now,
		})
		await tx.create(tradeSessions, {
			id: sessionId,
			user_id: uid,
			day,
			deposit_minor: DEPOSIT,
			rate_minor: user.usdt_rate,
			purchase_id: purchaseId,
			status: "open",
			pnl_minor: 0,
			return_usdt_minor: 0,
			return_mad_minor: 0,
			created_at: now,
		})
	})
}

async function settle(uid: string, s: { id: string; deposit_minor: number; rate_minor: number }, results: TradeResult[]) {
	const pnl = totalPnl(results)
	const back = backUsdt(s.deposit_minor, pnl)
	const mad = toMad(back, s.rate_minor)
	const now = Date.now()
	const t = await todayFor(uid)
	const incomeId = mad > 0 ? id() : ""
	await db.transaction(async (tx) => {
		if (mad > 0) {
			await tx.create(incomes, {
				id: incomeId,
				user_id: uid,
				amount_minor: mad,
				day: t,
				created_at: now,
				meta: JSON.stringify({ trade: 1, name: "Predict", usdt_minor: back }),
				ext_key: `trade:${s.id}`,
			})
		}
		await tx.update(tradeSessions, s.id, {
			status: "settled",
			pnl_minor: pnl,
			return_usdt_minor: back,
			return_mad_minor: mad,
			income_id: incomeId,
			settled_at: now,
		})
	})
}

const openOf = async (uid: string, f: FormData) => db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })

export async function setPredict(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const rows = await resultsOf(uid, s.id)
	const fl = flowOf(s.deposit_minor, rows)
	if (fl.over) return "This predict is finished"
	const n = fl.steps.length + 1
	if (n > PARTS) return "Enter the result first"
	const choice = text(f.get("choice"), 8)
	const first = fl.steps[0]?.asset === "down" ? "down" : "up"
	let side = "up"
	if (n === 1) {
		if (choice !== "up" && choice !== "down") return "Pick Up or Down"
		side = choice
	} else if (n === 2) {
		if (choice === "same") side = first
		else if (choice === "other") side = first === "up" ? "down" : "up"
		else return "Pick how the move went"
	} else {
		side = fl.steps[1]?.asset === "down" ? "down" : "up"
	}
	await db.create(tradeResults, {
		id: id(),
		user_id: uid,
		session_id: s.id,
		game: "step",
		idx: (fl.tryNo - 1) * PARTS + n,
		won: 0,
		pnl_minor: 0,
		state: "set",
		asset: side,
		tf: fl.stakes[n - 1]!,
		created_at: Date.now(),
	})
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const rows = await resultsOf(uid, s.id)
	const fl = flowOf(s.deposit_minor, rows)
	if (fl.over) return "This predict is finished"
	if (!fl.steps.length) return "Put in your first step first"
	const outcome = text(f.get("outcome"), 4)
	if (outcome !== "win" && outcome !== "lose") return "Pick I won or I lost"
	const won = outcome === "win"
	const amount = usdtMinor(f.get("pnl"))
	let pnl = 0
	if (won) {
		if (!amount) return "Enter the PnL in USDT"
		pnl = amount
	} else {
		pnl = 0 - Math.min(amount ?? fl.staked, fl.staked)
	}
	const row = { id: id(), user_id: uid, session_id: s.id, game: "res", idx: fl.tryNo, won: won ? 1 : 0, pnl_minor: pnl, state: "done", asset: "", tf: 0, created_at: Date.now() }
	await db.create(tradeResults, row)
	const next = [...rows, toResult(row)]
	if (flowOf(s.deposit_minor, next).over) await settle(uid, s, doneOf(next))
}

export async function undoResult(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const last = (await resultsOf(uid, s.id)).at(-1)
	if (!last) return
	await db.deleteMany(tradeResults, { where: { id: last.id, user_id: uid } })
}

export async function finishTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const done = doneOf(await resultsOf(uid, s.id))
	if (!done.length) return "Add at least one result first"
	await settle(uid, s, done)
}

export async function reopenTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s || s.status !== "settled") return
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open predict first"
	const key = `trade:${s.id}`
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key = ${key}`)
		await tx.exec(
			sql`update trade_sessions set status = 'open', income_id = '', settled_at = null, pnl_minor = 0, return_usdt_minor = 0, return_mad_minor = 0 where id = ${s.id} and user_id = ${uid}`,
		)
	})
}
GOAT_EOF

cat > app/components/trading.tsx <<'GOAT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import { backUsdt, DEPOSIT, flowOf, isDone, PARTS, resOf, stakesFor, strip, toMad, totalPnl, TRIES, type Flow, type TradeSession } from "../lib/trade-math.ts"
import { Back, Card, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")
const side = (x: string | undefined) => (x === "down" ? "Down" : "Up")

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const Bar = view<{ f: Flow }>(({ f }) => (
	<>
		<div class="pseg">
			{f.stakes.map((v, i) => (
				<b key={i} class={i < f.steps.length ? "on" : i === f.steps.length && !f.over ? "cur" : ""} style={{ flex: String(v) }}>
					{fmt(v)}
				</b>
			))}
		</div>
		<div class="psl">
			{f.stakes.map((v, i) => (
				<span key={i} style={{ flex: String(v) }}>{`step ${i + 1}`}</span>
			))}
		</div>
	</>
))

const Steps = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => {
	const n = f.steps.length
	const first = f.steps[0]?.asset
	const second = f.steps[1]?.asset
	const msg =
		n === 0
			? `Step 1 of ${PARTS}. Pick your side and put ${fmt(f.stakes[0]!)} USDT in.`
			: n === 1
				? `Step 2 of ${PARTS}. ${fmt(f.stakes[0]!)} USDT in on ${side(first)}. Watch the move, then tap how it went.`
				: n === 2
					? `Step 3 of ${PARTS}. Finish with ${fmt(f.stakes[2]!)} USDT on ${side(second)}.`
					: `All ${fmt(f.base)} USDT are in. Wait for the result, then tap I won or I lost.`
	return (
		<Card title={`Try ${f.tryNo} of ${TRIES} · ${fmt(f.base)} USDT`}>
			{f.tryNo > 1 && n === 0 ? <div class="lb tbn">{`You lost the first try. One more try with ${fmt(f.left)} USDT. This is the last try today.`}</div> : null}
			<Bar f={f} />
			<div class="lb tbn">{msg}</div>
			{n === 0 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<div class="pbt">
						<Submit class="btn" name="choice" value="up">
							<b>Up</b>
							<small>{`${fmt(f.stakes[0]!)} USDT`}</small>
						</Submit>
						<Submit class="btn o" name="choice" value="down">
							<b>Down</b>
							<small>{`${fmt(f.stakes[0]!)} USDT`}</small>
						</Submit>
					</div>
				</form>
			) : null}
			{n === 1 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<div class="pbt">
						<Submit class="btn o" name="choice" value="same">
							<b>Went my way</b>
							<small>{`+${fmt(f.stakes[1]!)} on ${side(first)}`}</small>
						</Submit>
						<Submit class="btn o" name="choice" value="other">
							<b>Went other way</b>
							<small>{`${fmt(f.stakes[1]!)} on ${first === "down" ? "Up" : "Down"}`}</small>
						</Submit>
					</div>
				</form>
			) : null}
			{n === 2 ? (
				<form method="post" action="/trading/set" style={contents}>
					<SessionHid s={s} t={t} />
					<Submit class="btn full" name="choice" value="go">
						{`Finish with ${fmt(f.stakes[2]!)} USDT · ${side(second)}`}
					</Submit>
				</form>
			) : null}
			{n > 0 ? (
				<form method="post" action="/trading/result" class="pres">
					<SessionHid s={s} t={t} />
					<input class="in" name="pnl" placeholder="Try PnL in USDT" inputmode="decimal" autocomplete="off" />
					<div class="lb tbn">{`Won: type what you made. Lost: leave it empty to count ${fmt(f.staked)} USDT, or type what you lost.`}</div>
					<div class="pbt">
						<Submit class="btn win" name="outcome" value="win">
							I won
						</Submit>
						<Submit class="btn miss" name="outcome" value="lose" formnovalidate>
							I lost
						</Submit>
					</div>
				</form>
			) : null}
			{t.results.length > 0 ? (
				<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last step?">
					<SessionHid s={s} t={t} />
					<Submit class="btn xs o">Undo last</Submit>
				</form>
			) : null}
		</Card>
	)
})

const OpenSummary = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => {
	const cur = s.user.currency
	const pnl = totalPnl(t.results)
	const back = backUsdt(t.deposit, pnl)
	const net = toMad(pnl, t.rate)
	return (
		<Card title="Open predict">
			<div class="ow" style={{ margin: "0 0 8px" }}>
				<b class={`big2 ${t.results.some(isDone) ? tone(pnl) : ""}`}>
					{t.results.some(isDone) ? sg(pnl) : "0"} <small>USDT PnL</small>
				</b>
				<span class="lb">{dayLabel(t.day)}</span>
			</div>
			<div class="rw">
				<span class="mu">Deposit</span>
				<span>{`${fmt(t.deposit)} USDT · ${fmt(toMad(t.deposit, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">You get back</span>
				<span>{`${fmt(back)} USDT · ${fmt(toMad(back, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">Net for your balance</span>
				<b class={tone(net)}>{`${sg(net)} ${cur}`}</b>
			</div>
			{t.results.some(isDone) && !f.over ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the try that is left?">
					<SessionHid s={s} t={t} />
					<Submit class="btn o full">Finish now</Submit>
				</form>
			) : null}
			<div class="lb tbn">When the predict ends, the money is added to your balance by itself.</div>
		</Card>
	)
})

const LockedCard = view<{ s: State }>(({ s }) => (
	<Card title="Today's predict">
		<div class="lb tbn">{`Done for today. One predict a day. The next one opens at ${String(s.user.day_start).padStart(2, "0")}:00.`}</div>
	</Card>
))

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency
	const rate = s.user.usdt_rate
	const cost = toMad(DEPOSIT, rate)
	const [a, b, c] = stakesFor(DEPOSIT)
	return (
		<Card title="Today's predict">
			<div class="ow" style={{ margin: "0 0 6px" }}>
				<b class="big2">
					{fmt(DEPOSIT)} <small>USDT</small>
				</b>
				<span class="lb">{`${fmt(cost)} ${cur}`}</span>
			</div>
			<div class="lb">{`1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
			<form method="post" action="/trading/deposit" data-confirm={`Deposit ${fmt(DEPOSIT)} USDT? It counts as a buy of ${fmt(cost)} ${cur}.`}>
				<Back s={s} />
				<Submit class="btn full">Deposit {fmt(DEPOSIT)} USDT</Submit>
			</form>
			<div class="lb tbn">{`Try 1 goes ${fmt(a!)} → ${fmt(b!)} → ${fmt(c!)} USDT. A win ends it. If you lose, one more try with what is left. One predict a day.`}</div>
		</Card>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const tries = strip(resOf(t.results))
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{tries ? `Tries ${tries}` : ""}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this predict again? The money it added is taken back.">
						<SessionHid s={s} t={t} />
						<Submit class="ub" aria-label="Open this predict again">
							<Icon name="undo" />
						</Submit>
					</form>
				) : null}
			</span>
		</div>
	)
})

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0)
	return (
		<Card title={`Past predicts · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

const Status = view<{ ok: boolean; title: string; sub: string }>(({ ok, title, sub }) => (
	<div class={ok ? "tst ok" : "tst no"} role="status">
		<span class="tsi">
			<Icon name={ok ? "check" : "plus"} />
		</span>
		<div>
			<b>{title}</b>
			<div class="lb">{sub}</div>
		</div>
	</div>
))

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	const day = today(s.user.day_start)
	const tradedToday = s.trades.some((t) => t.day === day)
	const at = `${String(s.user.day_start).padStart(2, "0")}:00`
	const ok = !!open || !tradedToday
	const f = open ? flowOf(open.deposit, open.results) : null
	const sub = open
		? `Try ${f!.tryNo} of ${TRIES}. Follow the steps below.`
		: tradedToday
			? `One predict a day. You can predict again at ${at}.`
			: `Deposit ${fmt(DEPOSIT)} USDT to start today's predict.`
	return (
		<div class="trd">
			<Status ok={ok} title={ok ? "You can predict" : "You cannot predict"} sub={sub} />
			{open && f ? (
				<>
					<OpenSummary s={s} t={open} f={f} />
					<Steps s={s} t={open} f={f} />
				</>
			) : tradedToday ? (
				<LockedCard s={s} />
			) : (
				<StartCard s={s} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	)
})
GOAT_EOF

cat > app/components/home.tsx <<'GOAT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { DEPOSIT, flowOf, resOf, TRIES } from "../lib/trade-math.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export type PadProject = { id: string; title: string; color: string; left: number; total: number }
export type PadLeft = { projects: PadProject[]; home: { left: number; total: number } }

export const HomeBalance = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<div class="hm-ba">
			<button type="button" class="ib" data-eye aria-label="Show balance">
				<Icon name="eye" />
			</button>
		</div>
		<div class="hm-m">Total balance</div>
	</div>
))

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

export const HomePredict = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const open = s.trades.find((t) => t.status === "open")
	const done = s.trades.find((t) => t.day === day && t.status === "settled")
	const f = open ? flowOf(open.deposit, open.results) : null
	const won = !!done && resOf(done.results).some((x) => x.won)
	const title = f
		? f.tryNo > 1 && f.steps.length === 0
			? `Lost · one more try, ${fmt(f.left)} USDT left`
			: `Predict is open · try ${f.tryNo} of ${TRIES}`
		: done
			? won
				? "Won today · predict ended"
				: "Done for today"
			: "You can predict today"
	const tag = f ? "running" : done ? "done" : "available"
	return (
		<div class="hm-c hm-gc hm-pc">
			<div class="hm-gr">
				<span class="hm-m">Predict</span>
				<span class={f || !done ? "hm-tag" : "hm-tag no"}>{tag}</span>
			</div>
			<div class="hm-gt2">{title}</div>
			{f ? (
				<a class="hm-go" href="/trading">
					Continue predict
				</a>
			) : !done ? (
				<a class="hm-go" href="/trading">{`Start predict · ${fmt(DEPOSIT)} USDT`}</a>
			) : null}
		</div>
	)
})

const Prog = view<{ href: string; title: string; color: string; left: number; total: number }>(({ href, title, color, left, total }) => (
	<a class="hm-c hm-gc" href={href}>
		<div class="hm-gr">
			<span class="hm-gt">
				<i style={{ background: color }}></i>
				{title}
			</span>
			<span class="hm-m">{`${left} left of ${total}`}</span>
		</div>
		<div class="hm-pb">
			<i style={{ width: `${total ? Math.round(((total - left) / total) * 100) : 0}%`, background: color }}></i>
		</div>
	</a>
))

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => (
	<>
		{p.projects.map((x) => (
			<Prog key={x.id} href={`/pad?p=${x.id}`} title={x.title} color={x.color} left={x.left} total={x.total} />
		))}
		{p.home.left > 0 ? <Prog href="/pad/home" title="Home" color="#8b979e" left={p.home.left} total={p.home.total} /> : null}
	</>
))
GOAT_EOF

cat > /tmp/file26.cjs <<'GOAT_EOF'
const fs = require("fs")
const f = "app/controllers/pages.tsx"
let s = fs.readFileSync(f, "utf8")
const a = s.indexOf("const padLeft")
const b = s.indexOf("\n})\n", a) + 4
if (a < 0 || b < 4) { console.error("padLeft not found"); process.exit(1) }
const n = "const padLeft = (d: PadData): PadLeft => ({\n\tprojects: d.spaces\n\t\t.map((x) => {\n\t\t\tconst es = d.entries.filter((e) => e.space === x.id && (e.kind === \"task\" || e.kind === \"done\"))\n\t\t\treturn { id: x.id, title: x.title, color: x.color, left: es.filter((e) => e.kind === \"task\").length, total: es.length }\n\t\t})\n\t\t.filter((x) => x.left > 0),\n\thome: (() => {\n\t\tconst es = d.entries.filter((e) => !e.space && (e.kind === \"task\" || e.kind === \"done\"))\n\t\treturn { left: es.filter((e) => e.kind === \"task\").length, total: es.length }\n\t})(),\n})\n"
fs.writeFileSync(f, s.slice(0, a) + n + s.slice(b))
GOAT_EOF
"$RUN" /tmp/file26.cjs
rm -f /tmp/file26.cjs

cat >> app/client/app.css <<'GOAT_EOF'

.pseg{display:flex;gap:4px;margin-top:6px}
.pseg b{height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:600;background:var(--s2);color:var(--mu);border:1px solid transparent;min-width:0}
.pseg b.on{background:var(--ac);color:var(--on)}
.pseg b.cur{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.psl{display:flex;gap:4px;margin:4px 0 6px}
.psl span{text-align:center;font:400 11px/1.2 var(--mono);color:var(--mu);min-width:0}
.pbt{display:flex;gap:6px;margin:6px 0}
.pbt .btn{flex:1 1 0;min-width:0;flex-direction:column;gap:2px;min-height:54px;padding:6px 10px;border-radius:16px;line-height:1.2}
.pbt .btn small{font:400 12px/1.2 var(--mono);opacity:.85}
.pres{display:flex;flex-direction:column;gap:4px;margin-top:8px}
.hm-gc{display:block;background:var(--h-chip);border-color:var(--h-ln2);padding:10px 14px;color:inherit;text-decoration:none}
.hm-gr{display:flex;align-items:center;justify-content:space-between;gap:10px}
.hm-gt{display:flex;align-items:center;gap:8px;min-width:0;font-size:15px;font-weight:500}
.hm-gt i{width:10px;height:10px;border-radius:50%;flex:none}
.hm-gt2{font-size:16px;font-weight:600;margin:3px 0 0}
.hm-pb{height:5px;border-radius:3px;background:var(--h-bg);margin-top:8px;overflow:hidden}
.hm-pb i{display:block;height:100%;border-radius:3px}
.hm-tag{font:400 12px/1.3 var(--h-mono);color:var(--h-ac)}
.hm-tag.no{color:var(--h-mu)}
.hm-go{display:flex;align-items:center;justify-content:center;margin-top:10px;height:42px;border-radius:14px;background:var(--h-fill);color:var(--h-on);font-size:15px;font-weight:600;text-decoration:none}
GOAT_EOF

echo "file26 done"
