#!/bin/bash
set -e
cat > app/lib/trade-math.ts <<'MT_EOF_1'
export const FIVE = 1600
export const GAME = 400
export const GAMES = 2
export const DEPOSIT = FIVE + GAME * GAMES
export const TRIES = 2
export const PARTS = 3

export type GameKey = "ga" | "gb"
export type Game = "step" | "res" | GameKey
export type Kind = "won" | "lost" | "miss" | "skip"
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
	won: boolean
	over: boolean
	stop: boolean
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const resOf = (r: TradeResult[]) => r.filter((x) => x.game === "res" && isDone(x)).sort((a, b) => a.idx - b.idx)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const kindOf = (x: TradeResult): Kind => (x.asset === "skip" ? "skip" : x.won ? "won" : x.tf <= 0 || 0 - x.pnl >= x.tf ? "miss" : "lost")
export const letter = (x: TradeResult) => ({ won: "W", lost: "L", miss: "M", skip: "S" })[kindOf(x)]
export const word = (x: TradeResult) => ({ won: "Won", lost: "Lost", miss: "Miss", skip: "Skipped" })[kindOf(x)]
export const strip = (r: TradeResult[]) => doneOf(r).map(letter).join(" ")
export const hasGames = (deposit: number) => deposit > FIVE
export const gameOf = (r: TradeResult[], g: GameKey) => r.find((x) => x.game === g && isDone(x))
export const gamesDone = (r: TradeResult[]) => !!gameOf(r, "ga") && !!gameOf(r, "gb")
export const gamesStrip = (r: TradeResult[]) => (["ga", "gb"] as const).map((g) => { const x = gameOf(r, g); return x ? letter(x) : "-" }).join(" ")

export const stakesFor = (base: number) => {
	const a = Math.round(base / 4)
	return [a, a, base - 2 * a]
}

export function flowOf(deposit: number, rows: TradeResult[]): Flow {
	const res = resOf(rows)
	const won = res.some((x) => x.won)
	const left = Math.min(deposit, FIVE) + res.reduce((a, x) => a + x.pnl, 0)
	const over = won || res.length >= TRIES || (res.length > 0 && left <= 0)
	const tryNo = Math.min(res.length + 1, TRIES)
	return {
		tryNo,
		base: left,
		left,
		stakes: stakesFor(left),
		won,
		over,
		stop: over && !won,
	}
}

export const allDone = (deposit: number, rows: TradeResult[]) => flowOf(deposit, rows).over && (!hasGames(deposit) || gamesDone(rows))
MT_EOF_1
cat > app/lib/trading.ts <<'MT_EOF_2'
import { sql } from "remix/data-table"
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts"
import { today } from "./time.ts"
import { todayFor } from "./users.ts"
import { allDone, backUsdt, DEPOSIT, doneOf, flowOf, GAME, gameOf, hasGames, toMad, totalPnl, type TradeResult, type TradeSession } from "./trade-math.ts"
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
	game: r.game === "step" || r.game === "ga" || r.game === "gb" ? r.game : "res",
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

const pnlFor = (outcome: string, amount: number | null, base: number, skip = false): { pnl: number } | { error: string } => {
	if (skip && outcome === "skip") return { pnl: 0 }
	if (outcome === "win") return amount ? { pnl: amount } : { error: "Enter how much you won in USDT" }
	if (outcome === "lose") return amount ? { pnl: 0 - Math.min(amount, base) } : { error: "Enter how much you lost in USDT" }
	if (outcome === "miss") return { pnl: 0 - base }
	return { error: "Pick Won, Lost or Miss" }
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	const rows = await resultsOf(uid, s.id)
	const fl = flowOf(s.deposit_minor, rows)
	if (fl.over) return "This predict is finished"
	if (fl.base <= 0) return "Nothing is left to predict with"
	const outcome = text(f.get("outcome"), 4)
	const r = pnlFor(outcome, usdtMinor(f.get("pnl")), fl.base)
	if ("error" in r) return r.error
	const coin = text(f.get("coin"), 3).toLowerCase()
	const row = { id: id(), user_id: uid, session_id: s.id, game: "res", idx: fl.tryNo, won: outcome === "win" ? 1 : 0, pnl_minor: r.pnl, state: "done", asset: coin === "btc" || coin === "eth" ? coin : "", tf: fl.base, created_at: Date.now() }
	await db.create(tradeResults, row)
	const next = [...rows, toResult(row)]
	if (allDone(s.deposit_minor, next)) await settle(uid, s, doneOf(next))
}

export async function saveGame(uid: string, f: FormData): Promise<string | void> {
	const s = await openOf(uid, f)
	if (!s) return "Predict not found"
	if (s.status !== "open") return "This predict is already settled"
	if (!hasGames(s.deposit_minor)) return "This predict has no games"
	const g = text(f.get("game"), 2)
	if (g !== "ga" && g !== "gb") return "Pick a game"
	const rows = await resultsOf(uid, s.id)
	if (gameOf(rows, g)) return "That game already has a result"
	const outcome = text(f.get("outcome"), 4)
	const r = pnlFor(outcome, usdtMinor(f.get("pnl")), GAME, true)
	if ("error" in r) return r.error
	const row = { id: id(), user_id: uid, session_id: s.id, game: g, idx: 1, won: outcome === "win" ? 1 : 0, pnl_minor: r.pnl, state: "done", asset: outcome === "skip" ? "skip" : "", tf: GAME, created_at: Date.now() }
	await db.create(tradeResults, row)
	const next = [...rows, toResult(row)]
	if (allDone(s.deposit_minor, next)) await settle(uid, s, doneOf(next))
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
MT_EOF_2
cat > app/components/trading.tsx <<'MT_EOF_3'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import { allDone, backUsdt, DEPOSIT, FIVE, flowOf, GAME, gameOf, gamesStrip, hasGames, isDone, letter, resOf, stakesFor, toMad, totalPnl, TRIES, word, type Flow, type GameKey, type TradeSession } from "../lib/trade-math.ts"
import { Back, Card, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const PnlField = view(() => (
	<div class="fld">
		<div class="ferr" role="alert" hidden></div>
		<input class="in" name="pnl" placeholder="PnL in USDT" inputmode="decimal" autocomplete="off" />
	</div>
))

const Outcomes = view(() => (
	<div class="pbt p3">
		<Submit class="btn win" name="outcome" value="win">
			Won
		</Submit>
		<Submit class="btn lost" name="outcome" value="lose">
			Lost
		</Submit>
		<Submit class="btn miss" name="outcome" value="miss" formnovalidate>
			Miss
		</Submit>
	</div>
))

const MethodRows = view<{ stakes: number[] }>(({ stakes }) => (
	<>
		<div class="rw">
			<span>1 · Follow the indicator. Pick Up or Down</span>
			<b>{`${fmt(stakes[0]!)} USDT`}</b>
		</div>
		<div class="rw">
			<span>2 · Instantly, same side</span>
			<b>{`${fmt(stakes[1]!)} USDT`}</b>
		</div>
		<div class="rw">
			<span>3 · Went your way: same side. If not: other side</span>
			<b>{`${fmt(stakes[2]!)} USDT`}</b>
		</div>
	</>
))

const Steps = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => (
	<Card title={`5 min predict · try ${f.tryNo} of ${TRIES} · ${fmt(f.base)} USDT`}>
		{f.tryNo > 1 ? <div class="lb tbn">{`First try lost. ${fmt(f.left)} USDT is left. Do a second 5 min predict with it. This is the last try today.`}</div> : null}
		<div class="lb tbn">Instructions</div>
		<div class="lb tbn">{`Open the 5 min BTC or ETH. Use only ${fmt(f.base)} USDT in total. Follow the method below, nothing else.`}</div>
		<div class="lb tbn">Method</div>
		<MethodRows stakes={f.stakes} />
		<form method="post" action="/trading/result" class="pres" data-pnl novalidate>
			<SessionHid s={s} t={t} />
			<PnlField />
			<div class="lb tbn">{`Won: type how much you won. Lost: type how much you lost, what is left stays for the next try. Miss: all ${fmt(f.base)} USDT is gone.`}</div>
			<Outcomes />
		</form>
		{t.results.length > 0 ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
				<SessionHid s={s} t={t} />
				<Submit class="btn xs o">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const StopCard = view<{ f: Flow; games: boolean }>(({ f, games }) => (
	<div class="tstop" role="alert">
		<b>Stop trading now</b>
		<span>
			{`Do not predict again. ${fmt(f.left)} USDT is left from the 5 min.`}
			{games ? " If you feel like trading more, just wait for the other 2 games and close." : ""}
			{" Wait for the next day and follow your method only."}
		</span>
	</div>
))

const GameRow = view<{ s: State; t: TradeSession; g: GameKey; n: number }>(({ s, t, g, n }) => {
	const x = gameOf(t.results, g)
	if (x) {
		return (
			<div class="rw gdn">
				<span>{`Game ${n}`}</span>
				{x.asset === "skip" ? <b class="mu">Skipped</b> : <b class={tone(x.pnl)}>{`${word(x)} ${sg(x.pnl)} USDT`}</b>}
			</div>
		)
	}
	return (
		<form method="post" action="/trading/game" class="gm" data-pnl novalidate>
			<SessionHid s={s} t={t} />
			<input type="hidden" name="game" value={g} />
			<div class="gmh">
				<span>{`Game ${n}`}</span>
				<b>{`${fmt(GAME)} USDT`}</b>
			</div>
			<div class="gq">Did you predict this game?</div>
			<div class="gseg">
				<label>
					<input type="radio" name="did" value="yes" />
					<span>Yes, I predicted</span>
				</label>
				<label>
					<input type="radio" name="did" value="no" />
					<span>No, I skipped</span>
				</label>
			</div>
			<div class="gyes">
				<PnlField />
				<Outcomes />
			</div>
			<div class="gno">
				<div class="lb tbn">{`No prediction, no loss. The ${fmt(GAME)} USDT stays with you.`}</div>
				<Submit class="btn o full gsk" name="outcome" value="skip" formnovalidate>
					Save as skipped
				</Submit>
			</div>
		</form>
	)
})

const GamesCard = view<{ s: State; t: TradeSession; undo: boolean }>(({ s, t, undo }) => (
	<Card title="Matches / vote predict · 2 games">
		<GameRow s={s} t={t} g="ga" n={1} />
		<GameRow s={s} t={t} g="gb" n={2} />
		{undo && t.results.length > 0 ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
				<SessionHid s={s} t={t} />
				<Submit class="btn xs o">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const Plan = view(() => {
	const st = stakesFor(FIVE)
	return (
		<Card title="The way">
			<div class="lb tbn">{`5 min predict · BTC or ETH · ${fmt(FIVE)} USDT`}</div>
			<MethodRows stakes={st} />
			<div class="lb tbn">When the 5 min ends, enter the PnL: Won, Lost or Miss. Lost with something left: one more 5 min try with what is left. Miss or a second loss: stop for the day.</div>
			<div class="lb tbn">{`Matches / vote predict · 2 games · ${fmt(GAME)} USDT each`}</div>
			<div class="lb tbn">For each game say if you predicted it, then enter the PnL: Won, Lost or Miss.</div>
		</Card>
	)
})

const Note = view(() => (
	<div class="tnote">
		<b>Note</b>
		<span>Only predict through this app. Don't predict random.</span>
	</div>
))

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
			{t.results.some(isDone) && !allDone(t.deposit, t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip what is left?">
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
	return (
		<>
			<Card title="Today's predict">
				<div class="ow" style={{ margin: "0 0 6px" }}>
					<b class="big2">
						{fmt(DEPOSIT)} <small>USDT</small>
					</b>
					<span class="lb">{`${fmt(cost)} ${cur}`}</span>
				</div>
				<div class="lb">{`${fmt(FIVE)} for the 5 min predict + ${fmt(GAME)} + ${fmt(GAME)} for two games. 1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
				<form method="post" action="/trading/deposit">
					<Back s={s} />
					<Submit class="btn full">Start predict</Submit>
				</form>
				<div class="lb tbn">{`Tapping start puts in the ${fmt(DEPOSIT)} USDT deposit by itself. It counts as a buy of ${fmt(cost)} ${cur}. One predict a day.`}</div>
			</Card>
			<Plan />
		</>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const five = resOf(t.results).map((x) => `${letter(x)}${x.asset ? ` ${x.asset.toUpperCase()}` : ""}`).join(" · ")
	const games = hasGames(t.deposit) ? gamesStrip(t.results) : ""
	const label = `${five ? `5 min ${five}` : ""}${five && games ? " · " : ""}${games ? `Games ${games}` : ""}`
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{label}</div>
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
	const f = open ? flowOf(open.deposit, open.results) : null
	const stop = !!f?.stop
	const ok = (!!open || !tradedToday) && !stop
	const sub = open
		? f!.over
			? f!.won
				? "5 min is done. Finish the games below."
				: "5 min is done. Do not predict again. Finish the games below."
			: `Try ${f!.tryNo} of ${TRIES}. Follow the method below.`
		: tradedToday
			? `One predict a day. You can predict again at ${at}.`
			: `Deposit ${fmt(DEPOSIT)} USDT to start today's predict.`
	return (
		<div class="trd">
			<Status ok={ok} title={stop ? "Stop trading now" : ok ? "You can predict" : "You cannot predict"} sub={sub} />
			<Note />
			{open && f ? (
				<>
					<OpenSummary s={s} t={open} f={f} />
					{f.stop ? <StopCard f={f} games={hasGames(open.deposit) && !allDone(open.deposit, open.results)} /> : null}
					{f.over ? null : <Steps s={s} t={open} f={f} />}
					{hasGames(open.deposit) ? <GamesCard s={s} t={open} undo={f.over} /> : null}
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
MT_EOF_3
cat > app/client/app.js <<'MT_EOF_4'
(function () {
	if (window.__mt) return
	window.__mt = 1
	var d = document
	var r = d.documentElement
	var all = function (sel, root) {
		return [].slice.call((root || d).querySelectorAll(sel))
	}
	var focusFirst = function (box) {
		var i = box.querySelector("input:not([type=hidden])")
		if (i) i.focus()
	}

	function setTheme(t) {
		r.setAttribute("data-theme", t)
		try {
			localStorage.setItem("mtheme", t)
		} catch (e) {}
		try {
			fetch("/settings/theme", { method: "POST", body: new URLSearchParams({ theme: t }), credentials: "same-origin", redirect: "manual" })
		} catch (e) {}
	}

	function endEdit(c) {
		var id = c.querySelector("[data-eid]")
		if (id) id.value = ""
		var eb = c.querySelector(".eb")
		if (eb) eb.hidden = true
		c.querySelector("textarea").value = ""
	}

	var open = {}
	try {
		open = JSON.parse(localStorage.getItem("mt:open") || "{}")
	} catch (e) {}

	d.addEventListener(
		"toggle",
		function (e) {
			var x = e.target
			if (x.matches && x.matches("details[data-keep-open]")) {
				open[x.getAttribute("data-keep-open")] = x.open
				try {
					localStorage.setItem("mt:open", JSON.stringify(open))
				} catch (err) {}
			}
			if (x.matches && x.matches(".xd") && !x.open) {
				var xf = x.querySelector("[data-adp]")
				var xb = x.parentNode.querySelector("[data-xplus]")
				if (xf) xf.hidden = true
				if (xb) xb.classList.remove("on")
			}
		},
		true,
	)

	d.addEventListener("click", function (e) {
		var t = e.target
		if (t.closest && !t.closest("[data-xplus]") && t.closest("details[data-fixed] > summary")) {
			e.preventDefault()
			return
		}
		var q = t.closest("button[name][value]")
		if (q && q.form) {
			var sh = q.form.querySelector('input[type=hidden][data-sub="' + q.name + '"]')
			if (!sh) {
				sh = d.createElement("input")
				sh.type = "hidden"
				sh.name = q.name
				sh.setAttribute("data-sub", q.name)
				q.form.appendChild(sh)
			}
			sh.value = q.value
		}
		if ((q = t.closest("[data-close]"))) {
			var cd = q.closest("details")
			if (cd) cd.open = false
			return
		}
		if (t.closest("[data-theme-toggle]")) return setTheme(r.getAttribute("data-theme") === "dark" ? "light" : "dark")
		if ((q = t.closest("[data-set-theme]"))) return setTheme(q.getAttribute("data-set-theme"))
		if ((q = t.closest("[data-pw]"))) {
			var pwi = q.parentNode.querySelector("input")
			if (pwi) {
				var pwShow = pwi.type === "password"
				pwi.type = pwShow ? "text" : "password"
				q.setAttribute("aria-pressed", pwShow ? "true" : "false")
				q.setAttribute("aria-label", pwShow ? "Hide password" : "Show password")
			}
			return
		}
		if ((q = t.closest("[data-eye]"))) {
			var v = q.closest(".hm-bal").querySelector(".hm-dots")
			var hide = q.getAttribute("data-s") !== "1"
			q.setAttribute("data-s", hide ? "1" : "0")
			v.innerHTML = hide ? v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>" : "••••••"
			return
		}
		if ((q = t.closest("[data-edit-bal]"))) {
			var bf = q.closest(".cd,.sc").querySelector("[data-balf]")
			bf.hidden = !bf.hidden
			q.setAttribute("aria-label", bf.hidden ? "Edit balance" : "Cancel")
			q.classList.toggle("hi", !bf.hidden)
			if (!bf.hidden) {
				var bi = bf.querySelector("input:not([type=hidden])")
				if (bi) {
					bi.focus()
					bi.select()
				}
			}
			return
		}
		if ((q = t.closest("[data-all]"))) {
			var af = q.closest(".iw").querySelector("input")
			af.value = q.getAttribute("data-all")
			af.focus()
			return
		}
		if ((q = t.closest("[data-tg],[data-pay]"))) {
			var add = q.hasAttribute("data-tg")
			var w = q.closest(".dbw")
			var p = w.querySelector(add ? "[data-addp]" : "[data-payp]")
			var o = w.querySelector(add ? "[data-payp]" : "[data-addp]")
			if (o) o.hidden = true
			p.hidden = !p.hidden
			if (!p.hidden) {
				var i = p.querySelector("input[name=amount]")
				if (i) i.focus()
			}
			return
		}
		if ((q = t.closest("[data-xplus]"))) {
			e.preventDefault()
			var xc = q.closest(".xc")
			var xd = xc.querySelector("details")
			var xm = xc.querySelector("[data-adp]")
			if (xm) {
				if (xd && !xd.open) {
					xd.open = true
					xm.hidden = false
				} else xm.hidden = !xm.hidden
				q.classList.toggle("on", !xm.hidden)
				if (!xm.hidden) focusFirst(xm)
			}
			return
		}
		if ((q = t.closest("[data-nm]"))) {
			var nf = q.closest("form")
			nf.querySelector("[data-name]").value = q.getAttribute("data-nm")
			var pin = nf.querySelector("[data-price]")
			if (pin) pin.focus()
			return
		}
		if ((q = t.closest("[data-bigadd]"))) {
			var tf = q.getAttribute("data-for")
			var ap = tf ? d.getElementById(tf) : q.closest(".bgc").querySelector("[data-adp]")
			ap.hidden = !ap.hidden
			q.classList.toggle("on", !ap.hidden)
			if (!ap.hidden) focusFirst(ap)
			return
		}
		if ((q = t.closest("[data-mode]"))) {
			var form = q.closest("form")
			var mode = q.getAttribute("data-mode")
			all("[data-mode]", form).forEach(function (c) {
				c.classList.toggle("on", c === q)
			})
			form.querySelector("[data-mode-input]").value = mode
			form.setAttribute("data-kind", mode)
			form.setAttribute("data-m", mode)
			return
		}
		if ((q = t.closest(".bub"))) {
			q.classList.toggle("sel")
			var a = q.parentNode.querySelector(".acts")
			a.hidden = !a.hidden
			return
		}
		if ((q = t.closest("[data-act]"))) {
			var m = q.closest(".msg")
			var act = q.getAttribute("data-act")
			var body = m.querySelector(".bub").textContent
			if (act === "copy") {
				try {
					navigator.clipboard.writeText(body)
				} catch (x) {}
			} else if (act === "edit") {
				var c = d.querySelector('[data-comp="' + m.parentNode.getAttribute("data-list") + '"]')
				c.querySelector("[data-eid]").value = m.getAttribute("data-id")
				c.querySelector(".eb").hidden = false
				var ta = c.querySelector("textarea")
				ta.value = body
				ta.focus()
			}
			return
		}
		if ((q = t.closest("[data-cancel]"))) endEdit(q.closest("[data-comp]"))
	})

	d.addEventListener(
		"click",
		function (e) {
			var b = e.target.closest && e.target.closest("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn"))) e.preventDefault()
		},
		true,
	)

	// Fallback spinner for any submit button that is not the shared Submit component.
	var SPIN = '<span class="sb-i" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg></span>'
	d.addEventListener("submit", function (e) {
		var f = e.target
		var msg = f.getAttribute && f.getAttribute("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		var sub = e.submitter
		setTimeout(function () {
			if (e.defaultPrevented) return
			all("button", f).forEach(function (b) {
				if (b.disabled) return
				b.disabled = true
				if (!sub || b === sub) {
					b.setAttribute("data-busy", "1")
					b.setAttribute("aria-busy", "true")
					if (!b.querySelector(".sb-i")) b.insertAdjacentHTML("beforeend", SPIN)
				} else b.setAttribute("data-lock", "1")
			})
		}, 0)
	})

	function unbusy() {
		all("button[data-busy],button[data-lock]").forEach(function (b) {
			b.disabled = false
			b.removeAttribute("data-busy")
			b.removeAttribute("data-lock")
			b.removeAttribute("aria-busy")
		})
	}
	window.addEventListener("pageshow", function (e) {
		if (e.persisted) unbusy()
	})

	d.addEventListener("keydown", function (e) {
		var t = e.target
		if (e.key !== "Enter" || e.shiftKey || !(t.matches && t.matches("[data-comp] textarea"))) return
		e.preventDefault()
		if (t.value.trim()) t.closest("form").requestSubmit()
	})

	var zone = "Africa/Casablanca"
	var fmt = function (loc, o) {
		o.timeZone = zone
		return new Intl.DateTimeFormat(loc, o)
	}
	var tf = fmt("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })
	var df = fmt("en-GB", { weekday: "long", day: "numeric", month: "long" })
	var nf = fmt("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })
	var af = fmt("ar-MA", { weekday: "long" })
	function tick() {
		var now = new Date()
		var sub = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + "</span>"
		all("[data-clock-time]").forEach(function (el) {
			el.textContent = tf.format(now)
		})
		all("[data-clock-date]").forEach(function (el) {
			el.textContent = df.format(now)
		})
		all("[data-clock-subdate]").forEach(function (el) {
			el.innerHTML = sub
		})
	}
	setInterval(tick, 1000)

	all("details[data-keep-open]").forEach(function (x) {
		var k = x.getAttribute("data-keep-open")
		if (k in open) x.open = !!open[k]
	})

	var rb = false
	try {
		rb = sessionStorage.getItem("mt:rb") === "1"
		sessionStorage.removeItem("mt:rb")
	} catch (e) {}
	if (rb) all("[data-eye]").forEach(function (q) {
		q.setAttribute("data-s", "1")
		var v = q.parentNode.firstChild
		v.innerHTML = v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>"
	})

	all("[data-list]").forEach(function (L) {
		var last = L.lastElementChild
		if (L.getAttribute("data-list") !== "dash" && last && last.scrollIntoView) last.scrollIntoView({ block: "end" })
	})

	var loaded = Date.now()
	setInterval(function () {
		if (!d.querySelector("[data-exo]") || d.hidden || Date.now() - loaded < 240000) return
		var a = d.activeElement
		if (a && a.matches && a.matches("input,textarea,select")) return
		if (d.querySelector("[data-adp]:not([hidden]),[data-addp]:not([hidden])")) return
		try {
			if (d.querySelector('[data-eye][data-s="1"]')) sessionStorage.setItem("mt:rb", "1")
		} catch (e) {}
		location.reload()
	}, 30000)
})()

;(function () {
	var d = document
	var K = "mt:pad:v1"
	var TABS = {
		projects: { space: "project", entry: "note", head: "Projects", add: "New project", ph: "Write a note", empty: "No projects yet. Add your first one above.", noun: "notes" },
		people: { space: "person", entry: "quote", head: "People", add: "Add a person", ph: "What did they say?", empty: "No one yet. Add a person, then what they said.", noun: "things said" },
		books: { space: "book", entry: "lesson", head: "Books", add: "Book name", sub: "Author (optional)", ref: "Chapter or page (optional)", ph: "What did you learn?", empty: "No books yet. Add a book, then what you learned from it.", noun: "lessons" },
		tips: { entry: "tip", flat: true, ph: "Something useful to remember", ref: "Where from (optional)", empty: "Nothing saved yet." },
	}
	var data = { spaces: [], entries: [] }
	var load = function () {
		try {
			var v = JSON.parse(localStorage.getItem(K) || "null")
			if (v && v.spaces && v.entries) data = v
		} catch (e) {}
	}
	var save = function () {
		try {
			localStorage.setItem(K, JSON.stringify(data))
		} catch (e) {}
	}
	var uid = function () {
		return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
	}
	var esc = function (s) {
		return String(s).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
		})
	}
	var when = function (t) {
		return new Date(t).toLocaleDateString("en-GB", { day: "numeric", month: "short" })
	}
	var spaceOf = function (id) {
		return data.spaces.filter(function (s) {
			return s.id === id
		})[0]
	}
	var entriesOf = function (fn) {
		return data.entries
			.filter(fn)
			.sort(function (a, b) {
				return b.at - a.at
			})
	}
	var entryHtml = function (e, label) {
		return (
			'<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + "</div>" +
			'<div class="pdm"><span class="lb">' + (label ? esc(label) + " · " : "") + (e.ref ? esc(e.ref) + " · " : "") + when(e.at) + "</span>" +
			'<span class="pda"><button type="button" class="chip' + (e.home ? " on" : "") + '" data-pd="home">Home</button>' +
			'<button type="button" class="chip" data-pd="edit">Edit</button>' +
			'<button type="button" class="chip" data-pd="del">Delete</button></span></div></div>'
		)
	}
	var composer = function (c, spaceId) {
		return (
			'<form class="pdf" data-pd="entry" data-space="' + (spaceId || "") + '">' +
			'<textarea class="pdi" name="body" rows="3" placeholder="' + esc(c.ph) + '" required></textarea>' +
			(c.ref ? '<input class="pdi" name="ref" placeholder="' + esc(c.ref) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>'
		)
	}
	var tabHtml = function (key) {
		var c = TABS[key]
		var id = decodeURIComponent(location.hash.slice(1))
		if (c.flat) return composer(c, "") + (entriesOf(function (e) { return e.kind === c.entry }).map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">' + c.empty + "</div>")
		var sp = id && spaceOf(id)
		if (sp && sp.kind === c.space) {
			var list = entriesOf(function (e) { return e.space === sp.id })
			return (
				'<div class="pdhd"><a class="chip" href="#" data-pd="back">‹ ' + c.head + "</a>" +
				'<button type="button" class="chip" data-pd="delspace" data-id="' + sp.id + '">Delete</button></div>' +
				'<h2 class="pdtt">' + esc(sp.title) + "</h2>" + (sp.sub ? '<div class="lb">' + esc(sp.sub) + "</div>" : "") +
				composer(c, sp.id) +
				(list.map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">Nothing here yet.</div>')
			)
		}
		var spaces = data.spaces
			.filter(function (s) { return s.kind === c.space })
			.sort(function (a, b) { return b.at - a.at })
		return (
			'<form class="pdf" data-pd="space"><input class="pdi" name="title" placeholder="' + esc(c.add) + '" autocomplete="off" required>' +
			(c.sub ? '<input class="pdi" name="sub" placeholder="' + esc(c.sub) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>' +
			(spaces.map(function (s) {
				var n = data.entries.filter(function (e) { return e.space === s.id }).length
				return '<a class="pdc" href="#' + encodeURIComponent(s.id) + '"><span><b>' + esc(s.title) + '</b><span class="lb">' + (s.sub ? esc(s.sub) + " · " : "") + n + " " + c.noun + '</span></span><span class="mu">›</span></a>'
			}).join("") || '<div class="lb pde">' + c.empty + "</div>")
		)
	}
	var homeHtml = function () {
		var list = entriesOf(function (e) { return e.home }).slice(0, 6)
		return (
			'<div class="sh"><span>Pinned notes</span><span class="lb">' + list.length + "</span></div>" +
			'<form class="pdf" data-pd="entry" data-space="" data-home="1"><input class="pdi" name="body" placeholder="Add a note to home" autocomplete="off" required><button class="btn xs">Add</button></form>' +
			(list.map(function (e) {
				var s = e.space && spaceOf(e.space)
				return '<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + '</div><div class="pdm"><span class="lb">' + (s ? esc(s.title) + " · " : "") + when(e.at) + '</span><span class="pda"><button type="button" class="chip" data-pd="home">Unpin</button></span></div></div>'
			}).join("") || '<div class="lb pde">Pin any note with the Home button.</div>')
		)
	}
	var paint = function () {
		[].slice.call(d.querySelectorAll("[data-pad]")).forEach(function (r) {
			var a = d.activeElement
			if (a && r.contains(a) && a.value) return
			r.innerHTML = tabHtml(r.getAttribute("data-pad"))
		})
		var h = d.activeElement
		;[].slice.call(d.querySelectorAll("[data-pad-home]")).forEach(function (r) {
			if (h && r.contains(h) && h.value) return
			r.innerHTML = homeHtml()
		})
	}
	var repaint = function () {
		save()
		;[].slice.call(d.querySelectorAll("[data-pad],[data-pad-home]")).forEach(function (r) {
			r.innerHTML = r.hasAttribute("data-pad") ? tabHtml(r.getAttribute("data-pad")) : homeHtml()
		})
	}
	d.addEventListener("submit", function (e) {
		var f = e.target
		var kind = f.getAttribute && f.getAttribute("data-pd")
		if (kind !== "space" && kind !== "entry") return
		e.preventDefault()
		var root = f.closest("[data-pad]")
		var tab = root && root.getAttribute("data-pad")
		var c = tab && TABS[tab]
		var v = function (n) {
			var i = f.elements[n]
			return i ? i.value.trim() : ""
		}
		var now = Date.now()
		if (kind === "space" && c) {
			if (!v("title")) return
			data.spaces.push({ id: uid(), kind: c.space, title: v("title").slice(0, 120), sub: v("sub").slice(0, 120), at: now })
		} else if (kind === "entry") {
			if (!v("body")) return
			var home = f.getAttribute("data-home") === "1"
			data.entries.push({ id: uid(), space: f.getAttribute("data-space") || null, kind: c ? c.entry : "note", body: v("body").slice(0, 4000), ref: v("ref").slice(0, 120), home: home, at: now })
		}
		repaint()
	})
	d.addEventListener("click", function (e) {
		var b = e.target.closest && e.target.closest("[data-pd]")
		if (!b || b.tagName === "FORM") return
		var act = b.getAttribute("data-pd")
		var row = b.closest("[data-id]")
		var id = row ? row.getAttribute("data-id") : b.getAttribute("data-id")
		var en = id && data.entries.filter(function (x) { return x.id === id })[0]
		if (act === "back") {
			e.preventDefault()
			history.pushState("", "", location.pathname)
			return repaint()
		}
		if (act === "home" && en) en.home = !en.home
		else if (act === "edit" && en) {
			var t = prompt("Edit", en.body)
			if (t === null || !t.trim()) return
			en.body = t.trim().slice(0, 4000)
		} else if (act === "del" && en) {
			if (!confirm("Delete this?")) return
			data.entries = data.entries.filter(function (x) { return x.id !== id })
		} else if (act === "delspace" && id) {
			if (!confirm("Delete this and everything inside it?")) return
			data.spaces = data.spaces.filter(function (x) { return x.id !== id })
			data.entries = data.entries.filter(function (x) { return x.space !== id })
			history.pushState("", "", location.pathname)
		} else return
		repaint()
	})
	addEventListener("hashchange", paint)
	addEventListener("storage", function (e) {
		if (e.key !== K) return
		load()
		paint()
	})
	load()
	paint()
})()

/* file20 */
;(function () {
	var d = document
	var hold = 0
	var fired = false
	var sx = 0
	var sy = 0
	var toast = function (t) {
		var x = d.createElement("div")
		x.className = "nt-toast"
		x.textContent = t
		d.body.appendChild(x)
		setTimeout(function () {
			x.remove()
		}, 1100)
	}
	var copy = function (t) {
		try {
			if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(t)
		} catch (e) {}
		var a = d.createElement("textarea")
		a.value = t
		a.style.cssText = "position:fixed;opacity:0"
		d.body.appendChild(a)
		a.select()
		try {
			d.execCommand("copy")
		} catch (e) {}
		a.remove()
		return Promise.resolve()
	}
	var edit = function (it) {
		var f = it && it.querySelector("[data-edit]")
		var b = it && it.querySelector("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		var mn = it.querySelector(".nt-mn")
		if (mn) mn.hidden = true
		var ta = f.querySelector("input[name=body],textarea")
		if (!ta.value) ta.value = ta.defaultValue || it.querySelector("[data-copy] p").textContent.trim()
		ta.focus()
		ta.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "center", behavior: "smooth" })
	}
	d.addEventListener("pointerdown", function (e) {
		var b = e.target.closest && e.target.closest("[data-copy]")
		if (!b) return
		fired = false
		sx = e.clientX
		sy = e.clientY
		clearTimeout(hold)
		hold = setTimeout(function () {
			fired = true
			if (navigator.vibrate) navigator.vibrate(15)
			edit(b.closest("[data-pad-item]"))
		}, 450)
	})
	d.addEventListener("pointermove", function (e) {
		if (hold && (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8)) clearTimeout(hold)
	})
	;["pointerup", "pointercancel", "pointerleave"].forEach(function (n) {
		d.addEventListener(n, function () {
			clearTimeout(hold)
		}, true)
	})
	d.addEventListener("contextmenu", function (e) {
		if (e.target.closest && e.target.closest("[data-copy]")) e.preventDefault()
	})
	var closeMenus = function () {
		[].slice.call(d.querySelectorAll(".nt-dd:not([hidden])")).forEach(function (m) {
			m.hidden = true
			var o = m.parentNode.querySelector("[data-menu]")
			if (o) o.setAttribute("aria-expanded", "false")
		})
	}
	d.addEventListener("keydown", function (e) {
		if (e.key === "Escape") closeMenus()
	})
	d.addEventListener("click", function (e) {
		var t = e.target
		var mb = t.closest && t.closest("[data-menu]")
		if (mb) {
			var dd = mb.parentNode.querySelector(".nt-dd")
			var was = !dd.hidden
			closeMenus()
			if (!was) {
				dd.classList.remove("up")
				dd.hidden = false
				mb.setAttribute("aria-expanded", "true")
				var box = mb.closest(".nt-scr")
				if (box) {
					var br = box.getBoundingClientRect()
					var dr = dd.getBoundingClientRect()
					if (dr.bottom > br.bottom) dd.classList.add("up")
				}
			}
			return
		}
		var me = t.closest && t.closest("[data-menu-edit]")
		if (me) {
			closeMenus()
			edit(me.closest("[data-pad-item]"))
			return
		}
		if (!(t.closest && t.closest(".nt-dd"))) closeMenus()
		var b = t.closest && t.closest("[data-copy]")
		if (b) {
			if (fired) {
				fired = false
				return
			}
			var p = b.querySelector("p")
			copy((p || b).textContent.trim()).then(function () {
				toast("Copied")
			})
			return
		}
		var x = t.closest && t.closest("[data-edit-x]")
		if (x) {
			var it = x.closest("[data-pad-item]")
			it.querySelector("[data-edit]").hidden = true
			it.querySelector("[data-copy]").hidden = false
			var mn2 = it.querySelector(".nt-mn")
			if (mn2) mn2.hidden = false
			return
		}
		var a = t.closest && t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")
		if (a) {
			setTimeout(function () {
				var box = a.closest(".xc,.dbw,.sc,.cd") || d
				var f = [].slice.call(box.querySelectorAll("[data-adp],[data-addp],[data-payp]")).filter(function (n) {
					return !n.hidden && n.offsetParent
				})[0]
				if (!f) return
				var i = f.querySelector("input:not([type=hidden]),textarea")
				if (i) i.focus({ preventScroll: true })
				f.scrollIntoView({ block: "center", behavior: "smooth" })
			}, 60)
		}
	})

	var dis = {}
	try {
		dis = JSON.parse(localStorage.getItem("mt:inv") || "{}")
	} catch (e) {}
	;[].slice.call(d.querySelectorAll("[data-inv]")).forEach(function (n) {
		if (dis[n.getAttribute("data-inv")]) n.hidden = true
	})
	d.addEventListener("click", function (e) {
		var x = e.target.closest && e.target.closest("[data-inv-x]")
		if (!x) return
		var n = x.closest("[data-inv]")
		dis[n.getAttribute("data-inv")] = 1
		try {
			localStorage.setItem("mt:inv", JSON.stringify(dis))
		} catch (err) {}
		n.hidden = true
	})
})()

// Notes list: scroll to the newest (bottom) on load.
;(function () {
	var run = function () {
		;[].slice.call(document.querySelectorAll("[data-bottom]")).forEach(function (l) {
			l.scrollTop = l.scrollHeight
		})
	}
	run()
	window.addEventListener("load", run)
	window.addEventListener("pageshow", run)
})()

;(function () {
	var MSG = { win: "Enter how much you won in USDT", lose: "Enter how much you lost in USDT" }
	var clear = function (f) {
		var i = f.querySelector("[name=pnl]")
		var e = f.querySelector(".ferr")
		if (i) i.classList.remove("bad")
		if (e) {
			e.hidden = true
			e.textContent = ""
		}
	}
	document.addEventListener(
		"submit",
		function (e) {
			var f = e.target
			if (!f.hasAttribute || !f.hasAttribute("data-pnl")) return
			var o = e.submitter && e.submitter.value
			if (o !== "win" && o !== "lose") return
			var i = f.querySelector("[name=pnl]")
			var n = parseFloat(String(i.value).replace(",", "."))
			if (isFinite(n) && n > 0) return
			e.preventDefault()
			e.stopImmediatePropagation()
			var er = f.querySelector(".ferr")
			i.classList.add("bad")
			er.textContent = MSG[o]
			er.hidden = false
			;(er.parentNode || i).scrollIntoView({ block: "center", behavior: "smooth" })
			i.focus({ preventScroll: true })
		},
		true,
	)
	document.addEventListener("input", function (e) {
		var f = e.target.closest && e.target.closest("[data-pnl]")
		if (f && e.target.name === "pnl") clear(f)
	})
})()
MT_EOF_4
cat > app/client/app.css <<'MT_EOF_5'
:root:root:root{--pico-font-family:var(--font-sys);--pico-font-size:100%;--pico-line-height:1.45;--pico-background-color:var(--bg);--pico-color:var(--ink);--pico-muted-color:var(--mu);--pico-muted-border-color:var(--ln);--pico-primary:var(--ac);--pico-primary-background:var(--ac);--pico-primary-border:var(--ac);--pico-primary-hover:var(--ac);--pico-primary-hover-background:var(--ac);--pico-primary-hover-border:var(--ac);--pico-primary-focus:var(--acs);--pico-primary-inverse:var(--on);--pico-border-radius:12px;--pico-border-width:1px;--pico-outline-width:3px;--pico-block-spacing-vertical:0px;--pico-block-spacing-horizontal:0px;--pico-form-element-background-color:var(--s1);--pico-form-element-border-color:var(--ln);--pico-form-element-color:var(--ink);--pico-form-element-placeholder-color:var(--mu);--pico-form-element-active-background-color:var(--s1);--pico-form-element-active-border-color:var(--ac);--pico-form-element-focus-color:var(--ac);--pico-form-element-disabled-background-color:var(--s2);--pico-form-element-spacing-vertical:.8rem;--pico-form-element-spacing-horizontal:1rem;--pico-form-element-invalid-border-color:var(--neg);--pico-form-element-invalid-active-border-color:var(--neg);--pico-form-element-invalid-focus-color:var(--neg)}
html input:not([type=checkbox]):not([type=radio]):not([type=hidden]),html select,html textarea,form,h1,h2,h3{margin:0}
button:not(:focus-visible):focus{box-shadow:none}
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}
.cd,.sc,.xc,.hero{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}
a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}
button{cursor:pointer}
.mu,.lb{color:var(--mu)}
.lb{font-size:11px;font-family:var(--mono)}
.pos{color:var(--pos)!important}
.neg{color:var(--neg)!important}
.ea{color:var(--earn)!important}
.sp{color:var(--spend)!important}
.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}
details{margin:0}
details>summary:not([role])::after,details>summary::after{content:none}
details>summary:not([role]){color:inherit}
details[open]>summary{margin-bottom:0}
summary::-webkit-details-marker{display:none}
button,input[type=button],input[type=submit],.btn,.sbl,.chip,.ib{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.chip:active,.ib:active{transform:scale(.97);opacity:.88}
.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
@media(min-width:900px){
	.m{display:none!important}
}
@media(max-width:899px){
	.d{display:none!important}
}
.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){
	.app{flex-direction:column}
}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}
.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib{flex:none;aspect-ratio:1}
.ib.sm{width:28px;height:28px;min-width:28px}
.ib svg.ic{width:16px;height:16px}
.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}
.bt .on svg.ic{stroke-width:2}
.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}
.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}
.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}
h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}
.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}
.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}
.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}
.cd{margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}
.two .cb{padding:3px 12px 10px}
.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}
.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.fl{margin-top:14px}
.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}
.ln{display:flex;gap:10px;align-items:center}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}
.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}
.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}
.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}
.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}
.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}
.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}
.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}
.cm .eb b{font-weight:600}
.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}
.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}
.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}
.li:hover{background:var(--s2)}
.li:last-child{border:0}
.li:first-child{padding-top:14px}
.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}
.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}
.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s ease}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}
.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:var(--bg);border:1px solid var(--ln);color:var(--ink)}
.sf .in{display:block;margin-bottom:10px}
.sf .btn.full{margin-top:0}
.chips.nm{flex-wrap:nowrap;overflow-x:auto;margin:0 0 10px;padding-bottom:2px;scrollbar-width:none}
.chips.nm::-webkit-scrollbar{display:none}
.chips.nm .chip{flex:none;white-space:nowrap}
.bgc{display:flex;overflow:hidden;padding:0}
.bgc>.ct{flex:1;min-width:0}
.sc.bgc>.ct{padding:18px 22px 20px}
.addb{flex:none;width:64px;border:0;border-right:1px solid var(--acl);border-radius:0;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0}
.addb svg.ic{width:30px;height:30px;stroke-width:2;transition:transform .18s ease}
.addb.on svg.ic{transform:rotate(45deg)}
.addb:active{transform:none;opacity:.8}
.bgc .adp{margin:6px 14px 14px}
.sc.bgc .adp{margin:14px 0 0}
.sc.bgc summary.sh{cursor:pointer}
.l1{gap:12px}
.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}
.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.ok{color:var(--earn)}
.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}
.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}
.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}
.spf .ln .in{flex:1 1 0}
.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
.rw>.rt{max-width:62%;justify-content:flex-end}
.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
.xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
.xh::-webkit-details-marker{display:none}
.xh>div{min-width:0}
.xc .chev{position:absolute;right:66px;top:50%;margin-top:-10px}
.xp{position:absolute;right:12px;top:18px;width:46px;height:44px;border-radius:13px;border:1px solid var(--acl);background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0;z-index:2}
.xp svg.ic{width:24px;height:24px;stroke-width:2;transition:transform .18s ease}
.xp.on svg.ic{transform:rotate(45deg)}
.xb{padding:4px 16px 8px;border-top:1px solid var(--ln)}
.xf{padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.xl{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:12px;color:var(--mu);font-family:var(--mono)}
.xl b{color:var(--ink);font-weight:600;white-space:nowrap}
.xf form{margin:12px 0 0}
.xfm .ln{gap:10px;margin:0}
.xfm .ln .in{flex:1 1 0;margin:0}
.xfm .ln .in.pr{flex:0 0 96px;width:96px}
.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}
.gw:last-child{border-bottom:0}
.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}
.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}
.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}
.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}
.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
.top-status-bar.tsplit{justify-content:space-between}
.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}
.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}
main{transition:opacity .2s ease}
html[data-nav=busy],html[data-nav=busy] a,html[data-nav=busy] button{cursor:progress}
html[data-nav=busy] main{opacity:.55}
button[data-busy]{cursor:progress}
.btn[data-busy]{opacity:.7}
.sb-l{display:contents}
.sb-i{position:absolute;inset:0;display:none;align-items:center;justify-content:center;pointer-events:none}
button[data-busy]{position:relative}
button[data-busy] .sb-l{visibility:hidden}
button[data-busy] .sb-i{display:flex}
button[data-busy] .sb-i svg.ic{width:18px;height:18px;transform:none;animation:spin .7s linear infinite}
button[data-lock]{opacity:.5}
@keyframes spin{to{transform:rotate(360deg)}}
@media(prefers-reduced-motion:reduce){
	main{transition:none}
	button[data-busy] .sb-i svg.ic{animation:none}
}
.trd{max-width:640px;margin:0 auto}
.tbn{margin:2px 0 6px;line-height:1.5}
.tbr{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px 0;border-bottom:1px solid var(--ln)}
.tbr:last-child{border-bottom:0;padding-bottom:0}
.tbr.lock{opacity:.45}
.tbf{display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0}
.tbf .in{width:96px;flex:0 1 96px;min-width:0;padding:8px 10px;font-size:14px;border-radius:12px}
.tbr:has(.tbp){flex-wrap:wrap}
.tbp{flex:1 1 100%;flex-wrap:wrap;justify-content:flex-start;margin-top:2px}
.tbp .in{flex:1 1 100%;width:100%;padding:10px 12px}
.tst{display:flex;align-items:center;gap:14px;padding:16px 18px;border-radius:22px;border:1px solid var(--ln);margin-bottom:12px}
.tst b{display:block;font-size:26px;font-weight:700;letter-spacing:-.03em;line-height:1.1}
.tst .lb{margin-top:4px}
.tsi{flex:none;width:48px;height:48px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:2px solid currentColor}
.tsi svg.ic{width:26px;height:26px;stroke-width:2.6}
.tst.ok{color:var(--pos);background:rgba(76,195,138,.1);border-color:rgba(76,195,138,.4)}
.tst.no{color:var(--neg);background:rgba(255,90,77,.1);border-color:rgba(255,90,77,.4)}
.tst.no .tsi svg.ic{transform:rotate(45deg)}
.tst .lb{color:var(--ink);opacity:.75}
.btn.win{background:rgba(76,195,138,.14);color:var(--pos);border-color:rgba(76,195,138,.45)}
.tbs{font-size:11px;font-weight:600;border:1px solid currentColor;border-radius:12px;padding:2px 9px;font-family:var(--mono)}
.sw{border-bottom:1px solid var(--ln)}
.sw:last-child{border:0}
.sw>.rw{border:0}
.hx{margin:0 0 12px;border:1px solid var(--ln);background:var(--bg);border-radius:14px;overflow:hidden}
.hx>summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 12px;list-style:none;cursor:pointer;font-size:12px;color:var(--mu);font-family:var(--mono)}
.hx>summary::-webkit-details-marker{display:none}
.hx>summary>span:nth-child(2){margin-left:auto;color:var(--earn)}
.hx>summary .chev{position:static;margin:0;right:auto;top:auto;flex:none}
.hx[open]>summary .chev{transform:rotate(180deg)}
.hxb{padding:2px 12px 12px}
.hxg{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}
.hc{display:flex;flex-direction:column;align-items:center;gap:2px;padding:9px 4px;border-radius:12px}
.hc b{font-size:14px;color:var(--ink)}
.hc small{font-size:11px;font-family:var(--mono)}
.hc.on b{color:var(--ac)}
.hxm{display:flex;gap:8px;align-items:center;margin-top:10px}
.hxm .in{padding:9px 12px;font-size:14px}
.hxm .btn{flex:none}
.kf{display:none;margin-top:2px}
form[data-kind=fixed] .kf-fixed,form[data-kind=manual] .kf-manual,form[data-kind=daily] .kf-daily,form[data-kind=monthly] .kf-monthly,form[data-kind=exoclick] .kf-exoclick{display:block}
.kf .in{margin-bottom:8px}
.kf .ln .in{margin-bottom:8px}
.kf .lb{margin-bottom:10px}
.ad>.in{display:block;width:100%}
.btn.miss{background:var(--s2);color:var(--mu);border-color:var(--ln)}

.btn{font-weight:600;font-size:15px;letter-spacing:.01em;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:999px;min-height:44px;padding:0 24px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center;box-shadow:0 1px 2px rgba(0,0,0,.28),0 1px 3px 1px rgba(0,0,0,.14);transition:box-shadow .2s,filter .2s,transform .12s}
.btn:hover{filter:brightness(1.07);box-shadow:0 1px 3px rgba(0,0,0,.28),0 4px 8px 3px rgba(0,0,0,.14)}
.btn.o{background:transparent;color:var(--ac);border:1px solid var(--acl);box-shadow:none}
.btn.o:hover{background:var(--acs);filter:none;box-shadow:none}
.btn.xs{min-height:32px;padding:0 14px;font-size:12px;box-shadow:none}
.btn.full{width:100%;min-height:52px;font-size:16px;font-weight:700;margin-top:20px}
.in{min-width:0;font-size:15px;font-family:inherit}
.of{position:relative;margin-top:14px}
.of input{height:56px;padding:22px 16px 6px;border-radius:12px;font-size:16px}
.of label{position:absolute;left:17px;top:19px;margin:0;color:var(--mu);font-size:16px;line-height:1;pointer-events:none;transition:top .15s,font-size .15s,color .15s}
.of input::placeholder{color:transparent}
.of input:focus+label,.of input:not(:placeholder-shown)+label,.of input:-webkit-autofill+label{top:9px;font-size:11px;font-weight:600;color:var(--ac)}

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
.mm>.cd .big2{font-size:24px}
.mm .two .big2{font-size:20px}
.mm .xbare .xb{padding:2px 14px}
.hr{display:grid;grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;align-items:center;padding:9px 0}
.hn{min-width:0;font-size:15px}
.hr .ea{white-space:nowrap;text-align:right;font-size:15px}
.hr .ub{width:32px;height:32px;border-radius:12px;background:var(--s2)}
.hr .btn.xs{min-height:34px;min-width:96px;font-size:14px;white-space:nowrap}
.hspan{grid-column:2/4;justify-self:end}
.sw .ad{margin:0 0 10px}
.hx{margin:0 0 8px;border:0;background:var(--s2);border-radius:14px}
.hx>summary{min-height:38px;padding:5px 6px 5px 12px;justify-content:flex-start;gap:10px}
.hx>summary>span:nth-child(2){margin-left:0;color:var(--mu)}
.hx>summary .chev{margin-left:auto;width:28px;height:28px;border-radius:50%;background:var(--s1);align-items:center;justify-content:center}

.pdtabs{margin:8px 0 4px;flex-wrap:nowrap;overflow-x:auto;scrollbar-width:none}
.pdtabs::-webkit-scrollbar{display:none}
.pdtabs .chip{flex:none;white-space:nowrap}
.pdx{margin-top:12px}
.pdf{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 14px}
.pdi{flex:1 1 140px;min-width:0;width:100%;font-size:15px;font-family:inherit;background:var(--s1);color:var(--ink);border:1px solid var(--ln);border-radius:14px;padding:10px 14px;margin:0;resize:none;outline:0}
.pdi:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
textarea.pdi{flex-basis:100%}
.pdf .btn.xs{margin-left:auto}
.pdc{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:14px 16px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdc>span:first-child{display:flex;flex-direction:column;gap:2px;min-width:0}
.pdc b{font-weight:600;letter-spacing:-.01em;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.pdn{padding:12px 14px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdt{white-space:pre-wrap;word-break:break-word}
.pdm{display:flex;justify-content:space-between;align-items:center;gap:8px;margin-top:8px;flex-wrap:wrap}
.pda{display:flex;gap:6px}
.pda .chip{padding:3px 10px;font-size:11px}
.pdhd{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}
.pdtt{font-size:20px;font-weight:700;letter-spacing:-.03em;margin:4px 0 2px}
.pde{padding:14px 2px}
.pdhome .pdf{margin:12px 0}
.pdhome .pdn{background:var(--s2);box-shadow:none}

.app:has(.nt-page) .tsplit .clock-time{display:none}
.nt-ttl{font-size:18px;font-weight:700;letter-spacing:-.02em}
.nt-page{display:flex;flex-direction:column;gap:10px;padding:2px 0 14px}
.nt-c{background:var(--s1);border:1px solid var(--ln);border-radius:22px}
.nt-m{font-family:var(--mono);font-size:12px;color:var(--mu)}
.nt-spread{display:flex;justify-content:space-between;align-items:baseline}
.nt-seg{display:flex;background:var(--s2);border-radius:14px;padding:3px;gap:2px}
.nt-seg a{flex:1;text-align:center;padding:7px 0;border-radius:11px;font-size:14px;font-weight:600;color:var(--mu)}
.nt-seg a.on{background:var(--s1);color:var(--ink);box-shadow:0 1px 2px rgba(0,0,0,.1)}
.nt-pj{display:flex;gap:8px;overflow:hidden}
.nt-pc{flex:none;padding:7px 12px;border-radius:18px;border:1px solid var(--ln);background:var(--s1);font-size:14px;font-weight:600;color:var(--ink);display:flex;gap:6px;align-items:center}
.nt-pc small{font:12px var(--mono);color:var(--mu)}
.nt-pc.on{background:var(--acs);border-color:var(--acl);color:var(--ac)}
.nt-ph{padding:12px 14px}
.nt-ph b{font-size:18px}
.nt-bar2{height:5px;background:var(--s2);border-radius:3px;margin-top:9px}
.nt-bar2 i{display:block;height:5px;width:67%;background:var(--ac);border-radius:3px}
.nt-fl{display:flex;gap:6px;padding:0 2px}
.nt-fl span{font:12px var(--mono);padding:5px 11px;border-radius:12px;background:var(--s2);color:var(--mu)}
.nt-fl .on{background:var(--ink);color:var(--bg)}
.nt-list{overflow:hidden}
.nt-it{display:flex;gap:10px;align-items:flex-start;padding:11px 14px;border-top:1px solid var(--ln)}
.nt-it:first-child{border-top:0}
.nt-ck{flex:none;width:22px;height:22px;border-radius:50%;border:2px solid var(--mu);margin-top:1px;display:flex;align-items:center;justify-content:center;color:var(--on)}
.nt-ck.d{background:var(--ac);border-color:var(--ac)}
.nt-ck svg.ic{width:16px;height:16px;stroke-width:2.4}
.nt-it p{margin:0;font-size:15px;line-height:1.35}
.nt-it.dn p{color:var(--mu);text-decoration:line-through}
.nt-it.nt{border-left:3px solid var(--ac);background:var(--acs)}
.nt-it.nt p{font-size:14px}
.nt-it .nt-m{margin-top:3px}
.nt-gl{font:12px var(--mono);color:var(--mu);padding:2px 4px 0}
.nt-q{padding:13px 14px;border-top:1px solid var(--ln)}
.nt-q:first-child{border-top:0}
.nt-q p{margin:0 0 10px;font-size:15px;line-height:1.4}
.nt-who{display:flex;align-items:center;gap:10px}
.nt-av{width:30px;height:30px;border-radius:50%;background:var(--acs);color:var(--ac);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center}
.nt-who b{font-size:14px;display:block}
.nt-who .nt-tag{margin-left:auto}
.nt-tag{font:11px var(--mono);padding:2px 8px;border-radius:8px;background:var(--s2);color:var(--mu)}
.nt-tag.t{background:var(--acs);color:var(--ac)}
.nt-cmp{flex:none;padding:8px 12px 10px;background:var(--bg)}
.nt-cin{display:flex;align-items:center;gap:8px;padding:6px 6px 6px 14px}
.nt-cin input{flex:1;border:0;background:none;font:inherit;font-size:15px;height:38px;min-width:0;color:var(--ink);outline:0;box-shadow:none;padding:0}
.nt-tg2{display:flex;background:var(--s2);border-radius:12px;padding:2px}
.nt-tg2 span{padding:5px 10px;border-radius:10px;font-size:12px;font-weight:600;color:var(--mu)}
.nt-tg2 .on{background:var(--s1);color:var(--ac)}
.nt-sd{width:38px;height:38px;border-radius:50%;background:var(--ac);color:var(--on);border:0;display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.nt-sd svg.ic{width:18px;height:18px;stroke-width:2}
.nt-ov{position:fixed;inset:0;background:rgba(17,24,39,.42);z-index:40}
.nt-sht{position:fixed;left:50%;transform:translateX(-50%);width:100%;max-width:560px;bottom:0;background:var(--s1);border-radius:26px 26px 0 0;padding:10px 16px calc(16px + env(safe-area-inset-bottom,0px));display:flex;flex-direction:column;gap:10px;box-shadow:0 -8px 24px rgba(0,0,0,.15);z-index:41}
.nt-gr{width:40px;height:4px;border-radius:2px;background:var(--ln);align-self:center}
.nt-shh{display:flex;justify-content:space-between;align-items:center}
.nt-shh b{font-size:18px}
.nt-fi{background:var(--bg);border-radius:14px;padding:8px 12px}
.nt-fi .nt-m{display:block;font-size:11px}
.nt-fi b{font-size:16px;font-weight:600}
.nt-cl{display:flex;gap:12px;align-items:center}
.nt-cl i{width:26px;height:26px;border-radius:50%}
.nt-cl i.on{outline:2px solid var(--ink);outline-offset:2px}
.nt-op{display:flex;gap:12px;align-items:center;padding:9px 12px;border:1px solid var(--ln);border-radius:16px}
.nt-op.on{border-color:var(--ac);background:var(--acs)}
.nt-op b{font-size:15px;display:block}
.nt-op span.d{font-size:12px;color:var(--mu)}
.nt-rd{width:20px;height:20px;border-radius:50%;border:2px solid var(--mu);margin-left:auto;flex:none}
.nt-op.on .nt-rd{border:6px solid var(--ac)}
.nt-pv{width:46px;height:36px;border-radius:10px;background:var(--s2);flex:none;display:flex;flex-direction:column;justify-content:center;gap:5px;padding:0 8px}
.nt-pr2{display:flex;align-items:center;gap:4px}
.nt-pr2 u{width:7px;height:7px;border-radius:50%;border:1.5px solid var(--mu);box-sizing:border-box;flex:none}
.nt-pr2 i{height:4px;flex:1;border-radius:2px;background:var(--mu)}
.nt-tr2{display:flex;justify-content:space-between;align-items:center;font-size:14px}
.nt-tgl{width:40px;height:24px;border-radius:12px;background:var(--ac);position:relative}
.nt-tgl::after{content:"";position:absolute;right:3px;top:3px;width:18px;height:18px;border-radius:50%;background:var(--on)}
.nt-go{height:48px;border-radius:24px;background:var(--ac);color:var(--on);font-weight:700;font-size:16px;display:flex;align-items:center;justify-content:center}

/* file18: home (mobile) + bottom bar restyle */
html{--h-ink:var(--ink);--h-ink2:var(--ink);--h-mu:var(--mu);--h-ln:var(--ln);--h-ln2:var(--ln);--h-card:var(--s1);--h-chip:var(--s2);--h-chip2:var(--s2);--h-bar:var(--s2);--h-sub:var(--s2);--h-bg:var(--bg);--h-earn:var(--earn);--h-ac:var(--ac);--h-acs:var(--acs);--h-acl:var(--acl);--h-pur:var(--spend);--h-solid:var(--ac);--h-fill:var(--ac);--h-on:var(--on);--h-btmu:var(--mu);--h-btln:var(--ln);--h-mono:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--h-sans:Inter,var(--font-sys)}
html[data-theme=light]{--h-ink:#1f2430;--h-ink2:#374151;--h-mu:#5f6672;--h-ln:#eceef1;--h-ln2:#e1e4e8;--h-card:#fff;--h-chip:#eceef1;--h-chip2:#f1f2f4;--h-bar:#e5e7eb;--h-sub:#f1f2f4;--h-bg:#f3f4f6;--h-earn:#8a5a00;--h-ac:#2f6f78;--h-acs:#d6f1f1;--h-acl:#a9dcdc;--h-pur:#6a4fd1;--h-solid:#3b727b;--h-fill:#2f6f78;--h-on:#fff;--h-btmu:#5f6672;--h-btln:#e5e7eb}

/* bottom bar (all pages) */
.bt{height:64px;padding:0 10px env(safe-area-inset-bottom,0px);justify-content:space-around;border-top:1px solid var(--h-btln);background:var(--s1);box-shadow:none}
.bt a,.bt button{flex:none;width:52px;height:42px;border-radius:14px;border:1px solid transparent;color:var(--h-btmu)}
.bt a.on{width:58px;background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.bt a.on::before{content:none}
.bt svg.ic,.bt .on svg.ic{width:20px;height:20px;stroke-width:1.8}

/* top row on home */
.app:has(.hm) .mm{padding-left:12px;padding-right:12px}
.app:has(.hm) .top-status-bar.tsplit{padding:14px 16px 0}
.app:has(.hm) .top-status-bar.tsplit .clock-time{font-family:var(--h-sans);font-size:18px;font-weight:700;letter-spacing:0;color:var(--h-ink)}
.app:has(.hm) .top-status-bar.tsplit .clock-subdate,.app:has(.hm) .top-status-bar.tsplit .clock-num,.app:has(.hm) .top-status-bar.tsplit .clock-dot{font-family:var(--h-mono);font-size:13px;font-weight:500;color:var(--h-mu);opacity:1}
.app:has(.hm) .top-status-bar.tsplit .clock-ar{font-size:13px;font-weight:500;color:var(--h-mu)}

/* home base */
.hm{display:flex;flex-direction:column;gap:6px;padding-top:8px;font-family:var(--h-sans);color:var(--h-ink)}
.hm-c,.hm .xc{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none;margin:0}
.hm-m,.hm .tg0{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .tg0{font-weight:400}

/* balance */
.hm-bal{display:grid;grid-template-columns:1fr auto;grid-template-areas:"l b" "v b";align-items:center;height:44px;padding:4px 6px 4px 14px;column-gap:10px}
.hm-bal .hm-m{grid-area:l;font-size:11px;line-height:1.1}
.hm-bal .hm-dots{grid-area:v}
.hm-bal .ib{grid-area:b;align-self:center;justify-self:end;width:32px;height:32px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);box-shadow:none}
.hm .ib svg.ic{width:20px;height:20px;stroke-width:1.8}
.hm-dots{display:block;font-size:17px;line-height:1;letter-spacing:3px;font-weight:700}
.hm-dots:has(small){letter-spacing:0;font-size:19px}
.hm-dots small{font-size:12px;font-weight:500;color:var(--h-mu);letter-spacing:0}

/* earned / bought */
.hm-two{display:flex;gap:6px}
.hm-two .hm-c{flex:1;min-width:0;padding:6px 12px}
.hm-big{font-size:20px;font-weight:700;line-height:1.2;margin-top:2px;white-space:nowrap}
.hm-big small{font-size:13px;font-weight:500;color:var(--h-mu)}

/* income card */
.hm .xbare .xb{padding:4px 14px;border:0}
.hm .sw{border-top:1px solid var(--h-ln);border-bottom:0}
.hm .sw:first-child,.hm .sw:has(.hx)+.sw{border-top:0}
.hm .sw:last-child{border:0}
.hm .sw+.sw:last-child{border-top:1px solid var(--h-ln)}
.hm .hr{grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;min-height:44px;padding:4px 0}
.hm .hn{font-size:15px;font-weight:500}
.hm .hn .lb,.hm .by .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hr .ea,.hm .by .ea{color:var(--h-earn)!important;font-weight:600;font-size:15px;white-space:nowrap;text-align:right}
.hm .hr .ea small,.hm .by .ea small{font-size:12px;font-weight:500;color:inherit;margin-left:3px}
.hm .ub{width:30px;height:30px;border-radius:50%;border:0;background:var(--h-chip2);color:var(--h-mu);box-shadow:none}
.hm .hr .ub{justify-self:end;align-self:center}
.hm .ub svg.ic{width:16px;height:16px;stroke-width:1.6}
.hm .by{border-bottom:0;border-top:1px solid var(--h-ln);min-height:44px;padding:4px 0}
.hm .by:first-child{border-top:0}
.hm .btn.xs{height:36px;min-height:36px;padding:0 18px;border-radius:18px;font:600 15px/1 var(--h-sans);letter-spacing:0;box-shadow:none}
.hm .btn.xs.o{border:1px solid var(--h-acl);background:var(--h-card);color:var(--h-ac)}
.hm .btn.xs.o:hover{background:var(--h-acs);filter:none}
.hm .btn.xs:not(.o){background:var(--h-fill);border:1px solid var(--h-fill);color:var(--h-on)}
.hm .hr .btn.xs,.hm .btn.xs.hadd{height:34px;min-height:34px;min-width:96px;padding:0 14px;border-radius:17px;font:600 14px/1 var(--h-sans);align-self:center;justify-self:end;white-space:nowrap}
.hm .btn.xs.off,.hm .btn.xs:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu);opacity:.8}
.hm .sw .ad{background:var(--h-bg);border:1px solid var(--h-ln2);border-radius:14px;padding:8px;margin:0 0 8px}
.hm .ad .ln{gap:8px;margin:0}
.hm .ad .in{height:36px;padding:0 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font-size:14px;margin:0}
.hm .ad .iw{height:36px;padding:0 12px;border-radius:14px;border-color:var(--h-ln2);background:var(--h-card)}
.hm .ad .iw .in{height:34px;padding:0;border:0;background:transparent}
.hm .ad label{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .in::placeholder{color:var(--h-mu);opacity:.85}

/* extra hours */
.hm .hx{background:var(--h-chip);border:0;border-radius:16px;margin:0 0 4px;overflow:hidden}
.hm .hx>summary{min-height:38px;padding:0 5px 0 12px;gap:8px;font:400 13px/1 var(--h-mono);color:var(--h-ink2)}
.hm .hx>summary>span:nth-child(2){color:var(--h-mu)}
.hm .hx>summary .chev{background:var(--h-card);color:var(--h-mu);width:28px;height:28px}
.hm .hxb{padding:0}
.hm .hxg{gap:8px;padding:2px 10px 0}
.hm .hc{background:var(--h-card);border:0;border-radius:12px;padding:7px 4px;gap:0;color:var(--h-ink);box-shadow:none}
.hm .hc b{font-size:14px;font-weight:600;color:var(--h-ink)}
.hm .hc small{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hc.on{background:var(--h-acs);box-shadow:inset 0 0 0 1px var(--h-acl)}
.hm .hc.on b{color:var(--h-ac)}
.hm .hxm{margin:0;padding:10px;gap:8px}
.hm .hxm .in{height:36px;padding:0 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font-size:14px;flex:1;margin:0}

/* expandable cards: buys, goals, owe */
.hm .xh{min-height:0;padding:9px 112px 9px 16px}
.hm .xn .xh{padding-right:52px}
.hm details[data-fixed]>.xh{padding:9px 70px 0 16px}
.hm .osum .ow{margin:0;gap:0;flex-wrap:nowrap;align-items:baseline}
.hm .ow .big2{font-size:26px;font-weight:700;letter-spacing:0;line-height:1.15}
.hm .ow .big2.sp{color:var(--h-pur)!important}
.hm .ow .big2 small{font:500 13px/1 var(--h-mono);color:var(--h-mu);margin-left:6px;letter-spacing:0}
.hm .ow .big2.sp small{color:var(--h-mu);margin-left:0}
.hm .ow>.lb,.hm .ow>.sm{font:500 13px/1 var(--h-mono);color:var(--h-mu)!important;margin-left:6px}
.hm .xc .chev{top:22px;margin-top:0;color:var(--h-ink);right:75px}
.hm .xn .chev{right:16px}
.hm .xc .chev svg.ic{width:22px;height:22px;stroke-width:1.8}
.hm .xp{width:46px;height:38px;border-radius:14px;top:13px;right:14px;border:1px solid var(--h-acl);background:var(--h-acs);color:var(--h-ac)}
.hm .xc:has(details[data-fixed]) .xp{top:10px}
.hm .xp svg.ic{width:20px;height:20px;stroke-width:1.8}
.hm .xj{opacity:.2}
.hm .xb{padding:0;border-top:0}
.hm .xbare .xb{padding:4px 14px}
.hm details[data-fixed] .xb{padding:2px 16px 9px}
.hm .xb .lb[style]{font:400 14px/1.4 var(--h-sans);color:var(--h-mu);padding:0!important}
.hm .xf{padding:9px 16px;background:var(--h-sub);border-top:1px solid var(--h-ln)}
.hm .xl{font:400 14px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .xl b{color:var(--h-ink)}
.hm .lnk{color:var(--h-ac);font:600 15px/1.3 var(--h-sans);text-decoration:underline;text-underline-offset:3px}
.hm details[data-keep-open=owe] .xf{padding:0;border:0;background:none}
.hm details[data-keep-open=owe] .xf .xl{display:none}
.hm details[data-keep-open=owe] .xf form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--h-ln);background:var(--h-sub)}
.hm details[data-fixed] .xf{padding:0;border:0;background:none}
.hm details[data-fixed] .xf form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--h-ln);background:var(--h-sub)}
.hm .xf .in,.hm .xf .iw{border-color:var(--h-ln2);background:var(--h-card);color:var(--h-ink)}
.hm .xf .btn.full{border-radius:24px;min-height:48px;font-size:16px;background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none}
.hm .xf .chip{background:var(--h-card);border-color:var(--h-ln2);color:var(--h-mu)}

/* goals open */
.hm .gw{padding:10px 16px 4px;border-top:1px solid var(--h-ln);border-bottom:0}
.hm .gw .db{padding:0;border:0;gap:0}
.hm .gw .l1{margin-bottom:0;align-items:baseline}
.hm .gw .l1 b{font-size:17px;font-weight:700;white-space:normal;overflow:visible}
.hm .gw .l1 .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .gw .mt{height:4px;margin:8px 0;background:var(--h-bar);border-radius:2px}
.hm .gw .mt i{background:var(--h-mu);border-radius:2px}
.hm .gw .mt.full i{background:var(--h-ac)}
.hm .gi{height:48px;margin-left:6px;padding:0 0 0 22px;gap:10px;border-left:2px solid var(--h-ln2)}
.hm .gn{font-size:16px}
.hm .gi .lb{font:400 13px/1 var(--h-mono);color:var(--h-mu);margin-right:4px}
.hm .gi .btn.xs{height:34px;min-height:34px;padding:0 18px;border-radius:20px;background:var(--h-solid);border-color:var(--h-solid)}
.hm .gi .btn.xs.off{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}

/* owe open */
.hm .xc .db{padding:9px 14px;gap:12px;border-top:1px solid var(--h-ln);border-bottom:0;align-items:center}
.hm .gw .db{padding:0;border:0;gap:0}
.hm .db .ib.sm{width:40px;height:40px;min-width:40px;background:var(--h-acs);border:1px solid var(--h-acl);color:var(--h-ac);box-shadow:none}
.hm .db .l1 b{font-size:17px;font-weight:600}
.hm .db .l1>span{font-size:16px;color:var(--h-ink2)}
.hm .dn .dl{margin:2px 0 6px;font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .db .mt.s{height:4px;background:var(--h-bar);border-radius:2px}
.hm .db .mt.s i{border-radius:2px}
.hm .db .btn.xs{height:34px;min-height:34px;border-radius:20px}
.hm .db .l1>b{white-space:normal;overflow:visible}

/* file19: pad + other pages */
.hm{display:block;gap:0;padding-top:0}
.hm-f{display:flex;flex-direction:column;gap:6px;padding-top:8px}
.mm.hm{padding-top:8px}
.hm .cd,.hm .sc,.hm .hero{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none}
.hm .cd{margin-top:8px}
.hm .tg{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .lb,.hm .mu.sm{font-family:var(--h-mono)}
.hm .rw,.hm .by,.hm .db{border-color:var(--h-ln)}
.hm .big{font-size:34px;font-weight:700;letter-spacing:0}
.hm .big2{font-weight:700;letter-spacing:0}
.hm .hd{margin:10px 4px 2px}
.hm .hd h1.t{font-size:18px;font-weight:700;letter-spacing:0}
.hm .btn{background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none;font-family:var(--h-sans)}
.hm .btn.o{background:var(--h-card);border-color:var(--h-acl);color:var(--h-ac)}
.hm .btn.full{border-radius:24px;min-height:48px;font-size:16px}
.hm .btn.off,.hm .btn:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .in,.hm .of input{background:var(--h-card);border:1px solid var(--h-ln2);border-radius:14px;color:var(--h-ink)}
.hm .chip{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .chip.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .av{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .sg{background:var(--h-chip);border-color:var(--h-ln)}
.hm .li:hover{background:var(--h-chip)}
.hm .mt{background:var(--h-bar)}
.hm .mt i{background:var(--h-mu)}
.hm .mt.n i{background:var(--h-pur)}
.hm .pos{color:var(--pos)!important}
.hm .nt-page{padding-top:0}

/* pad */
.nt-c{background:var(--h-card);border-color:var(--h-ln)}
.nt-m{font-family:var(--h-mono);color:var(--h-mu)}
.nt-f{display:contents}
.nt-b{flex:1;min-width:0}
.nt-it{align-items:flex-start}
button.nt-ck{background:none;padding:0;cursor:pointer;color:var(--h-on);flex:none}
button.nt-ck.d{background:var(--h-ac);border-color:var(--h-ac)}
.nt-x{flex:none;width:26px;height:26px;border-radius:50%;border:0;background:none;color:var(--h-mu);padding:0;display:flex;align-items:center;justify-content:center;opacity:.75}
.nt-x svg.ic{width:16px;height:16px;transform:rotate(45deg)}
.nt-em{padding:16px 14px}
.nt-pj{overflow-x:auto;scrollbar-width:none}
.nt-pj::-webkit-scrollbar{display:none}
.nt-pc{text-decoration:none;white-space:nowrap}
.nt-dot{width:8px;height:8px;border-radius:50%;flex:none}
.nt-pc.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.nt-fl a{font:12px var(--h-mono);padding:5px 11px;border-radius:12px;background:var(--h-chip);color:var(--h-mu)}
.nt-fl a.on{background:var(--h-ink);color:var(--h-card)}
.nt-bar2{background:var(--h-bar)}
.nt-bar2 i{background:var(--h-ac)}
.nt-del{text-align:center;margin:2px 0 6px}
.nt-del button{background:none;border:0;padding:6px;color:var(--h-mu);font-size:12px;text-decoration:underline;width:auto}
.nt-who .nt-tag{margin-left:auto}
.nt-cin .nt-who-i{flex:0 0 76px;width:76px;border-right:1px solid var(--h-ln);padding-right:8px;border-radius:0}
.nt-cin input{background:none;border:0;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-tg2{position:relative;background:var(--h-chip)}
.nt-tg2 label{display:flex;margin:0}
.nt-tg2 input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-tg2 input:checked+span{background:var(--h-card);color:var(--h-ac)}
.nt-tg2 span{cursor:pointer}
.nt-sd{background:var(--h-fill);color:var(--h-on)}
.nt-sel{width:100%;margin:6px 0 0;padding:6px 12px;height:34px;border-radius:14px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);font-size:13px}
.nt-cmp{background:var(--bg)}
.nt-sht{max-height:92dvh;overflow:auto;background:var(--h-card)}
.nt-fi{display:block;background:var(--h-bg);margin:0}
.nt-fi input{display:block;width:100%;height:auto;border:0;background:none;padding:0;margin:0;font-size:16px;font-weight:600;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-cl label{position:relative;display:block;margin:0;cursor:pointer}
.nt-cl input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-cl input:checked+i{outline:2px solid var(--h-ink);outline-offset:2px}
.nt-op{position:relative;cursor:pointer;margin:0}
.nt-op input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-op:has(input:checked){border-color:var(--h-ac);background:var(--h-acs)}
.nt-op:has(input:checked) .nt-rd{border:6px solid var(--h-ac)}
.nt-tr2{margin:0;cursor:pointer}
input.nt-tgl[type=checkbox],input.nt-tgl[type=checkbox]:checked{-webkit-appearance:none;appearance:none;background-image:none;width:40px;height:24px;border-radius:12px;border:0;padding:0;margin:0;position:relative;background-color:var(--h-chip);flex:none}
input.nt-tgl[type=checkbox]:checked{background-color:var(--h-ac)}
input.nt-tgl[type=checkbox]::after{content:"";position:absolute;left:3px;right:auto;top:3px;width:18px;height:18px;border-radius:50%;background:var(--h-card);transition:left .15s}
input.nt-tgl[type=checkbox]:checked::after{left:19px}
.nt-go{border:0;width:100%;background:var(--h-fill);color:var(--h-on);text-decoration:none}

/* balance reveal + goals manage row */
.hm-bal{height:auto;min-height:48px;padding:8px 8px 8px 14px}
.hm-dots:has(small){font-size:18px;line-height:1.15;letter-spacing:0}
.hm-two .hm-c{flex:1 1 0}
.hm .gw .db{gap:10px}

/* file20: spacing, shadow, centered icons, invoice, pad edit */
.hm-f{gap:12px}
.hm-two{gap:10px}
.hm .cd{margin-top:12px}
.nt-page{gap:12px}
.hm-c,.hm .xc,.hm .cd,.hm .sc,.hm .hero,.nt-c{box-shadow:var(--sh1)}
.bt{box-shadow:var(--sh1)}

/* header icons centered inside the summary */
.hm .xp{top:50%;margin-top:-19px;right:14px}
.hm .xc:has(details[data-fixed]) .xp{top:50%}
.hm .xc .chev{top:50%;margin-top:-11px}
.hm .xc:has(.xp.on) .chev{display:none}
.hm details[data-fixed]>.xh{padding:9px 70px 9px 16px}
.hm .xb:empty{display:none}
.hm .osum .ow .em{font:400 14px/1.4 var(--h-sans);color:var(--h-mu)}

/* balance card (home + profile) */
.hm-bal .hm-ba{display:flex;align-items:center;justify-content:flex-end;gap:8px}
.hm-bal .hm-ba .ib{grid-area:auto;align-self:center}
.hm-balc{padding:0;overflow:hidden}
.hm-bedit{padding:0 14px 14px}

/* exoclick invoice */
.inv{display:flex;align-items:center;gap:10px;padding:8px 8px 8px 14px;margin-bottom:12px}
.inv>div:first-child{flex:1;min-width:0}
.inv-a{font-size:20px;font-weight:700;line-height:1.2}
.inv-st{font:600 12px/1 var(--h-mono);padding:5px 10px;border-radius:12px;background:var(--h-chip);color:var(--h-mu);flex:none}
.inv-st.pending{background:rgba(166,106,0,.14);color:var(--h-earn)}
.inv-st.processing{background:rgba(109,79,214,.14);color:var(--h-pur)}
.inv-st.paid{background:rgba(18,161,80,.14);color:var(--pos)}
.inv .ub svg.ic{transform:rotate(45deg)}

/* pad: tap copies, long press edits */
.nt-b{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;cursor:pointer}
.nt-it,.nt-q{flex-wrap:wrap}
.nt-q .nt-b p{margin:0 0 10px}
.nt-edit{flex:1 1 0;min-width:0;display:flex;flex-direction:column;gap:8px;margin:0}
.nt-edit textarea{width:100%;margin:0;padding:8px 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font:15px/1.35 var(--h-sans);resize:none}
.nt-eb{display:flex;gap:8px;justify-content:flex-end}
.nt-edit .nt-cin{padding:4px 6px 4px 14px}
.nt-xc{flex:none;width:30px;height:30px;border:0;background:none;color:var(--mu);padding:0;display:flex;align-items:center;justify-content:center;border-radius:50%}
.nt-xc svg.ic{width:18px;height:18px;transform:rotate(45deg)}
.nt-mn{position:relative;flex:none;align-self:flex-start}
.nt-mn[hidden],.nt-dd[hidden]{display:none!important}
.nt-mn .nt-x svg.ic{transform:none}
.nt-dd{position:absolute;right:0;top:calc(100% + 4px);z-index:40;min-width:150px;padding:4px;background:var(--s1);border:1px solid var(--ln);border-radius:14px;box-shadow:0 10px 28px rgba(0,0,0,.28)}
.nt-dd form{display:block;margin:0}
.nt-dd button{position:relative;display:flex;align-items:center;gap:10px;width:100%;padding:10px 12px;border:0;border-radius:10px;background:none;color:var(--ink);font:inherit;font-size:14px;text-align:left;cursor:pointer}
.nt-dd button:hover{background:var(--s2)}
.nt-dd button.dg{color:var(--neg)}
.nt-dd svg.ic{width:16px;height:16px;flex:none}
.nt-list:not(.nt-scr):has(.nt-dd:not([hidden])),.nt-q:has(.nt-dd:not([hidden])){overflow:visible}
.nt-dd.up{top:auto;bottom:calc(100% + 4px)}
.nt-toast{position:fixed;left:50%;bottom:96px;transform:translateX(-50%);background:var(--h-ink);color:var(--h-card);padding:8px 16px;border-radius:18px;font-size:13px;z-index:60}

/* balance icons: centered on the whole card (middle, right), not just the first row */
.hm-balc,.hm-c.hm-bal{position:relative}
.hm-bal{grid-template-columns:minmax(0,1fr);grid-template-areas:"l" "v";padding-right:58px}
.hm-balc .hm-bal{padding-right:104px}
.hm-bal .hm-ba{position:absolute;right:8px;top:50%;transform:translateY(-50%);z-index:2}
.hm-balc:has(.hm-bedit:not([hidden])) .hm-bedit{padding-right:104px}

/* pad: low project card with background progress, tighter spacing, scrolling notes */
.nt-page,.hm .nt-page{gap:6px;padding-bottom:8px}
.nt-ph.nt-pg{position:relative;overflow:hidden;display:flex;align-items:center;gap:10px;padding:0 6px 0 14px;min-height:42px}
.nt-pg>b{position:relative;z-index:1;font-size:16px;flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.nt-pg>.nt-m{position:relative;z-index:1;flex:none;white-space:nowrap}
.nt-pgf{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.nt-pgf.full{background:var(--ac);opacity:.32}
.nt-gs{position:relative;z-index:1;flex:none;width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:var(--mu);text-decoration:none}
.nt-gs svg.ic{width:18px;height:18px}
.nt-list.nt-scr{overflow-y:auto;max-height:calc(100dvh - 300px);min-height:150px;overscroll-behavior:contain;scrollbar-width:thin}
.nt-go.dg{background:rgba(255,90,77,.12);color:var(--neg);border:1px solid rgba(255,90,77,.35)}


.hm-two .hm-c.hm-bal{flex:1 1 0;min-width:0;min-height:48px;padding:8px 8px 8px 14px}
.hm-two .hm-dots{white-space:nowrap}
.hm-c.hm-pr{padding-right:14px;text-decoration:none;color:inherit}
.hm-pr .hm-dots{letter-spacing:0;font-size:16px}
.hm-pr .hm-dots.no{color:var(--h-mu)}
.hm-tk{display:flex;flex-direction:column;padding:4px 14px}
.hm-tk a{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:8px 0;color:inherit;text-decoration:none}
.hm-tk a+a{border-top:1px solid var(--h-ln)}
.hm-tk b{font-size:17px;font-weight:700;line-height:1.1}
.bt{height:74px}
.bt a,.bt button{flex:1 1 0;width:auto;min-width:0;max-width:66px;height:58px;flex-direction:column;gap:3px;border-radius:16px}
.bt a.on{width:auto}
.bt svg.ic,.bt .on svg.ic{width:23px;height:23px;stroke-width:2.1}
.bt .on svg.ic{stroke-width:2.4}
.bt .bl{position:relative;font-size:10px;line-height:1;font-weight:500;letter-spacing:.1px}
.bt .on .bl{font-weight:700}

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
.sg{padding:3px;gap:3px}
.sg button{padding:5px 12px;line-height:1.2}
.sg svg.ic{width:16px;height:16px}
.hm-bal:has(.hm-ba){display:grid;grid-template-columns:minmax(0,1fr) auto;grid-template-areas:"l b" "v b";align-items:center;column-gap:10px;min-height:48px;padding:8px 8px 8px 14px}
.hm-balc .hm-bal:has(.hm-ba){padding-right:8px}
.hm-bal .hm-ba{position:static;transform:none;grid-area:b;align-self:center;justify-self:end;display:flex;align-items:center;gap:8px}
.hm-bal:has(.hm-ba) .hm-m{grid-area:l}
.hm-bal:has(.hm-ba) .hm-dots{grid-area:v}
.hm-balc:has(.hm-bedit:not([hidden])) .hm-bedit{padding-right:14px}
.tnote{display:flex;gap:10px;align-items:baseline;padding:12px 14px;margin-bottom:12px;border-radius:16px;border:1px solid var(--ln);background:var(--s2);font-size:13px;line-height:1.4;color:var(--ink)}
.tnote b{font:600 12px/1.4 var(--mono);color:var(--mu);text-transform:uppercase;letter-spacing:.04em}

/* file21: icon buttons without browser margins, centered balance icons, compact theme switch */
button.ib{margin:0}
.hm-bal:has(.hm-ba){grid-template-rows:auto auto;align-content:center}
.hm-bal:has(.hm-ba) .hm-ba{grid-column:2;grid-row:1 / span 2;align-self:center;justify-self:end;margin:0;height:32px}
.hm-bal:has(.hm-ba) .hm-m{grid-column:1;grid-row:1}
.hm-bal:has(.hm-ba) .hm-dots{grid-column:1;grid-row:2}
.hm-bal .ib,.hm-bal .hm-ba .ib{margin:0;align-self:center}
.sg{align-items:stretch;margin:0}
.sg button{margin:0;min-height:0;height:34px;padding:0 12px;line-height:1;box-sizing:border-box}
.hm .cd .cb .sg{margin:0}

/* trading: three result buttons, game rows, stop notice */
.pbt.p3 .btn{flex-direction:row;min-height:46px;padding:0 8px;border-radius:14px;font-size:14px}
.btn.lost{background:rgba(255,170,60,.14);color:var(--earn);border-color:rgba(255,170,60,.45)}
.gm{margin:0;padding:10px 0;border-bottom:1px solid var(--ln)}
.gm:last-of-type{border-bottom:0}
.gmh{display:flex;justify-content:space-between;align-items:baseline;gap:10px;margin-bottom:2px}
.gmh span{font-size:14px;font-weight:600}
.gmh b{font:600 14px/1.2 var(--mono);color:var(--ink);white-space:nowrap}
.tstop{display:flex;flex-direction:column;gap:6px;padding:14px 16px;margin-bottom:12px;border-radius:18px;border:1px solid rgba(255,90,77,.4);background:rgba(255,90,77,.1);font-size:14px;line-height:1.45;color:var(--ink)}
.tstop b{font-size:18px;font-weight:700;color:var(--neg);letter-spacing:-.02em}
button.hm-go{width:100%;border:0;margin-bottom:0;cursor:pointer;font-family:inherit}

/* pad: chat-style lists, newest at the bottom */
.nt-wrap{display:flex;flex-direction:column;gap:6px}
.nt-wrap.nt-scr{overflow-y:auto;max-height:calc(100dvh - 300px);min-height:150px;overscroll-behavior:contain;scrollbar-width:thin}
.nt-scr{scroll-behavior:auto}
.nt-it,.nt-q{transition:background .15s ease}
.nt-it:hover,.nt-q:hover{background:var(--h-chip)}
.nt-it.nt:hover{background:var(--h-acs)}
.nt-cmp .nt-c{border-radius:26px;box-shadow:var(--sh1)}
.nt-cmp{padding-top:10px}
.nt-list.nt-scr>:last-child{padding-bottom:14px}

/* file22: field errors, game picker, trading page polish */
.fld{display:flex;flex-direction:column;gap:6px}
.ferr{font-size:13px;font-weight:600;color:var(--neg);line-height:1.3}
.in.bad,.hm .in.bad{border-color:var(--neg)!important;box-shadow:0 0 0 3px rgba(255,90,77,.18)}
.gm{display:flex;flex-direction:column;gap:10px;margin:10px 0 0;padding:14px;border:1px solid var(--ln);border-radius:18px;background:var(--s2)}
.gm:first-of-type{margin-top:0}
.gmh{margin:0}
.gmh span{font-size:15px}
.gq{font-size:13px;color:var(--mu)}
.gseg{display:grid;grid-template-columns:1fr 1fr;gap:6px;padding:3px;border-radius:14px;background:var(--bg);border:1px solid var(--ln)}
.gseg label{position:relative;display:block;margin:0;cursor:pointer}
.gseg input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.gseg span{display:flex;align-items:center;justify-content:center;min-height:40px;padding:0 8px;border-radius:11px;font-size:14px;font-weight:600;color:var(--mu);text-align:center}
.gseg input:checked+span{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}
.gyes,.gno{display:none}
.gm:has(input[value=yes]:checked) .gyes{display:flex;flex-direction:column;gap:8px}
.gm:has(input[value=no]:checked) .gno{display:block}
.gm .pbt{margin:0}
.gm .btn.full.gsk{margin-top:0;min-height:46px;font-size:15px}
.rw.gdn{padding:12px 14px;margin-bottom:8px;border:1px solid var(--ln);border-radius:14px;background:var(--s2)}
.rw.gdn:last-of-type{margin-bottom:0}
.trd{display:flex;flex-direction:column;gap:0}
.trd .cd{margin-top:0;margin-bottom:12px}
.trd .cd .tg{font-weight:600;letter-spacing:.01em;margin-bottom:6px}
.trd .cb>.rw{padding:10px 0}
.trd .cb>.rw:first-of-type{padding-top:2px}
.trd .pres .in{min-height:48px;font-size:16px}
MT_EOF_5
echo "file22 done"
