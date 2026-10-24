#!/usr/bin/env bash
set -e
cd "${1:-.}"
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder: bash file9.sh"; exit 1; fi
bk(){ for f in "$@"; do if [ -f "$f" ]; then mkdir -p ".mt_backup/file9/$(dirname "$f")"; [ -e ".mt_backup/file9/$f" ] || cp "$f" ".mt_backup/file9/$f"; fi; done; }
bk app/lib/trade-math.ts app/lib/trading.ts app/components/trading.tsx app/db/tables.ts app/commands.ts app/routes.ts app/client/app.css database/schema.sql scripts/migrate.ts
cat > app/lib/trade-math.ts << '__EOF_MT__'
export const DEPOSIT = 400;
export const BTC_STAKE = 100;
export const PRED_STAKE = 300;
export const BTC_ROUNDS = 4;
export const PRED_COUNT = 3;
export const PICKS: [string, number][] = [
	["BTC", 5],
	["BTC", 15],
	["ETH", 5],
	["ETH", 15],
];

export type Game = "btc" | "pred";
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number; state: "set" | "done"; asset: string; tf: number };
export type TradeSession = {
	id: string;
	day: string;
	deposit: number;
	rate: number;
	status: "open" | "settled";
	pnl: number;
	returnUsdt: number;
	returnMad: number;
	at: number;
	results: TradeResult[];
};

export const isDone = (x: TradeResult) => x.state === "done";
export const doneOf = (r: TradeResult[]) => r.filter(isDone);
export const btcOf = (r: TradeResult[]) => r.filter((x) => x.game === "btc").sort((a, b) => a.idx - b.idx);
export const predOf = (r: TradeResult[]) => r.filter((x) => x.game === "pred").sort((a, b) => a.idx - b.idx);
export const btcLost = (r: TradeResult[]) => btcOf(r).some((x) => isDone(x) && !x.won);
export const btcDone = (r: TradeResult[]) => btcLost(r) || doneOf(btcOf(r)).length >= BTC_ROUNDS;
export const predDone = (r: TradeResult[]) => doneOf(predOf(r)).length >= PRED_COUNT;
export const allDone = (r: TradeResult[]) => btcDone(r) && predDone(r);
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0);
export const missAmount = (game: Game, r: TradeResult[]) => (game === "btc" ? BTC_STAKE + doneOf(btcOf(r)).reduce((a, x) => a + x.pnl, 0) : PRED_STAKE / PRED_COUNT);
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl);
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100);
export const strip = (r: TradeResult[]) => doneOf(r).map((x) => (x.won ? "W" : "M")).join(" ");
__EOF_MT__
cat > app/lib/trading.ts << '__EOF_MT__'
import { sql } from "remix/data-table";
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts";
import { today } from "./time.ts";
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcOf,
	DEPOSIT,
	doneOf,
	isDone,
	missAmount,
	PICKS,
	PRED_COUNT,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "./trade-math.ts";
import type { User } from "./users.ts";

const id = () => crypto.randomUUID();
const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max);

const usdtMinor = (v: unknown) => {
	const raw = String(v ?? "").trim().replace(",", ".");
	if (!raw) return null;
	const n = Math.abs(Number(raw));
	return Number.isFinite(n) && n <= 100000 ? Math.round(n * 100) : null;
};

const toResult = (r: { id: string; game: string; idx: number; won: number; pnl_minor: number; state: string; asset: string; tf: number }): TradeResult => ({
	id: r.id,
	game: r.game === "pred" ? "pred" : "btc",
	idx: r.idx,
	won: r.won !== 0,
	pnl: r.pnl_minor,
	state: r.state === "set" ? "set" : "done",
	asset: r.asset || "",
	tf: r.tf || 0,
});

async function resultsOf(uid: string, sessionId: string): Promise<TradeResult[]> {
	const rows = await db.findMany(tradeResults, { where: { user_id: uid, session_id: sessionId }, orderBy: ["created_at", "asc"] });
	return rows.map(toResult);
}

export async function loadTrades(uid: string): Promise<TradeSession[]> {
	const rows = await db.findMany(tradeSessions, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 30 });
	if (!rows.length) return [];
	const res = await db.findMany(tradeResults, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 });
	const by = new Map<string, TradeResult[]>();
	for (const r of res) {
		const list = by.get(r.session_id) ?? [];
		list.push(toResult(r));
		by.set(r.session_id, list);
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
			results: (by.get(s.id) ?? []).sort((a, b) => (a.game === b.game ? a.idx - b.idx : a.game === "btc" ? -1 : 1)),
		}),
	);
}

export async function startTrade(user: User): Promise<string | void> {
	const uid = user.id;
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } });
	if (open) return "Finish your open trade first";
	const cost = toMad(DEPOSIT, user.usdt_rate);
	if (!cost) return "Set the USDT price in Settings first";
	const now = Date.now();
	const day = today();
	const sessionId = id();
	const purchaseId = id();
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
		});
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
		});
	});
}

async function settle(uid: string, s: { id: string; deposit_minor: number; rate_minor: number }, results: TradeResult[]) {
	const pnl = totalPnl(results);
	const back = backUsdt(s.deposit_minor, pnl);
	const mad = toMad(back, s.rate_minor);
	const now = Date.now();
	const incomeId = mad > 0 ? id() : "";
	await db.transaction(async (tx) => {
		if (mad > 0) {
			await tx.create(incomes, {
				id: incomeId,
				user_id: uid,
				amount_minor: mad,
				day: today(),
				created_at: now,
				meta: JSON.stringify({ trade: 1, name: "Trading", usdt_minor: back }),
				ext_key: `trade:${s.id}`,
			});
		}
		await tx.update(tradeSessions, s.id, {
			status: "settled",
			pnl_minor: pnl,
			return_usdt_minor: back,
			return_mad_minor: mad,
			income_id: incomeId,
			settled_at: now,
		});
	});
}

export async function setPredict(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const game: Game = f.get("game") === "pred" ? "pred" : "btc";
	const idx = Math.floor(Number(f.get("idx")));
	const max = game === "btc" ? BTC_ROUNDS : PRED_COUNT;
	if (!Number.isInteger(idx) || idx < 1 || idx > max) return "Unknown predict";
	let asset = "";
	let tf = 0;
	if (game === "btc") {
		const [a, t] = text(f.get("pick"), 8).split("-");
		const ok = PICKS.some(([pa, pt]) => pa === a && pt === Number(t));
		if (!ok) return "Pick BTC or ETH and 5 or 15 minutes";
		asset = a!;
		tf = Number(t);
	}
	const rows = await resultsOf(uid, s.id);
	if (rows.some((r) => r.game === game && r.idx === idx)) return "That predict is already set";
	if (game === "btc") {
		if (btcDone(rows)) return "The up or down predicts are finished";
		if (btcOf(rows).some((r) => !isDone(r))) return "Wait for the result of the last predict first";
		if (idx !== btcOf(rows).length + 1) return "Do the predicts in order";
	}
	await db.create(tradeResults, { id: id(), user_id: uid, session_id: s.id, game, idx, won: 0, pnl_minor: 0, state: "set", asset, tf, created_at: Date.now() });
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const game: Game = f.get("game") === "pred" ? "pred" : "btc";
	const idx = Math.floor(Number(f.get("idx")));
	const outcome = text(f.get("outcome"), 4);
	if (outcome !== "win" && outcome !== "miss") return "Pick Win or Miss";
	const rows = await resultsOf(uid, s.id);
	const cur = rows.find((r) => r.game === game && r.idx === idx);
	if (!cur || isDone(cur)) return "Set this predict first";
	const won = outcome === "win";
	let pnl = 0;
	if (won) {
		const amount = usdtMinor(f.get("pnl"));
		if (!amount) return "Enter the PnL in USDT";
		pnl = amount;
	} else {
		pnl = -missAmount(game, rows);
	}
	await db.update(tradeResults, cur.id, { state: "done", won: won ? 1 : 0, pnl_minor: pnl });
	const next = rows.map((r): TradeResult => (r.id === cur.id ? { ...r, state: "done", won, pnl } : r));
	if (allDone(next)) await settle(uid, s, next);
}

export async function undoResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const r = await db.findOne(tradeResults, { where: { id: text(f.get("result_id"), 36), session_id: s.id, user_id: uid } });
	if (!r) return;
	if (r.game === "btc") {
		const last = btcOf(await resultsOf(uid, s.id)).at(-1);
		if (last?.id !== r.id) return "Undo the latest predict first";
	}
	if (r.state === "set") await db.deleteMany(tradeResults, { where: { id: r.id, user_id: uid } });
	else await db.update(tradeResults, r.id, { state: "set", won: 0, pnl_minor: 0 });
}

export async function finishTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const rows = await resultsOf(uid, s.id);
	const done = doneOf(rows);
	if (!done.length) return "Add at least one result first";
	await db.deleteMany(tradeResults, { where: { session_id: s.id, user_id: uid, state: "set" } });
	await settle(uid, s, done);
}

export async function reopenTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s || s.status !== "settled") return;
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } });
	if (open) return "Finish your open trade first";
	const key = `trade:${s.id}`;
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key = ${key}`);
		await tx.exec(
			sql`update trade_sessions set status = 'open', income_id = '', settled_at = null, pnl_minor = 0, return_usdt_minor = 0, return_mad_minor = 0 where id = ${s.id} and user_id = ${uid}`,
		);
	});
}
__EOF_MT__
cat > app/components/trading.tsx << '__EOF_MT__'
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel } from "../lib/time.ts";
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcLost,
	btcOf,
	DEPOSIT,
	isDone,
	PICKS,
	PRED_COUNT,
	predOf,
	strip,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "../lib/trade-math.ts";
import { Icon } from "./Icon.tsx";
import { Back, Card } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`;
const tone = (minor: number) => (minor < 0 ? "neg" : "pos");

type RowState = "result" | "active" | "wait" | "skip";

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
));

const PredictRow = view<{ s: State; t: TradeSession; game: Game; idx: number; r: TradeResult | undefined; state: RowState; canUndo: boolean }>(
	({ s, t, game, idx, r, state, canUndo }) => {
		const meta = r && r.asset ? `${r.asset} ${r.tf}m` : "";
		if (r && isDone(r)) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						{meta ? <div class="lb">{meta}</div> : null}
					</div>
					<span class="rt">
						<span class={`tbs ${r.won ? "pos" : "mu"}`}>{r.won ? "Win" : "Missed"}</span>
						<b class={r.won ? tone(r.pnl) : "mu"}>{sg(r.pnl)}</b>
						{canUndo ? (
							<form method="post" action="/trading/undo" style={contents} data-confirm={`Move predict ${idx} back to waiting?`}>
								<SessionHid s={s} t={t} />
								<input type="hidden" name="result_id" value={r.id} />
								<button class="ub" aria-label={`Undo predict ${idx}`}>
									<Icon name="undo" />
								</button>
							</form>
						) : null}
					</span>
				</div>
			);
		}
		if (r) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						<div class="lb">{meta ? `${meta} · waiting` : "waiting"}</div>
					</div>
					<form method="post" action="/trading/result" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<input class="in" name="pnl" placeholder="PnL USDT" inputmode="decimal" autocomplete="off" />
						<button class="btn xs win" name="outcome" value="win">
							Win
						</button>
						<button class="btn xs miss" name="outcome" value="miss" formnovalidate>
							Miss
						</button>
					</form>
					{canUndo ? (
						<form method="post" action="/trading/undo" style={contents}>
							<SessionHid s={s} t={t} />
							<input type="hidden" name="result_id" value={r.id} />
							<button class="ub" aria-label={`Cancel predict ${idx}`}>
								<Icon name="undo" />
							</button>
						</form>
					) : null}
				</div>
			);
		}
		if (state === "active" && game === "btc") {
			return (
				<div class="tbr" style={{ flexDirection: "column", alignItems: "stretch" }}>
					<b>Predict {idx}</b>
					<form method="post" action="/trading/set" style={contents}>
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<div class="hxg">
							{PICKS.map(([a, m]) => (
								<button key={`${a}-${m}`} class="chip hc" name="pick" value={`${a}-${m}`}>
									<b>{a}</b>
									<small>{m}m</small>
								</button>
							))}
						</div>
					</form>
				</div>
			);
		}
		if (state === "active") {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
					</div>
					<form method="post" action="/trading/set" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<button class="btn xs o">Set</button>
					</form>
				</div>
			);
		}
		return (
			<div class="tbr lock">
				<div>
					<b>Predict {idx}</b>
				</div>
				<span class="lb">{state === "skip" ? "skipped" : "waiting"}</span>
			</div>
		);
	},
);

const BtcCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = btcOf(t.results);
	const done = btcDone(t.results);
	const lost = btcLost(t.results);
	return (
		<Card title="Crypto · up or down">
			<div class="lb tbn">1 USDT. Up to {BTC_ROUNDS} predicts. Pick BTC or ETH and 5 or 15 minutes, then wait for the result. Win goes to the next one. Miss ends it.</div>
			{Array.from({ length: BTC_ROUNDS }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx);
				const state: RowState = r ? "result" : done ? "skip" : idx === list.length + 1 && list.every(isDone) ? "active" : "wait";
				return <PredictRow key={idx} s={s} t={t} game="btc" idx={idx} r={r} state={state} canUndo={!!r && idx === list.length} />;
			})}
			{done ? <div class="lb tbn">{lost ? "Finished. This one missed." : `Finished. You won all ${BTC_ROUNDS}.`}</div> : null}
		</Card>
	);
});

const PredCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = predOf(t.results);
	return (
		<Card title="3 predicts · lol or sport">
			<div class="lb tbn">3 USDT. Each predict is on its own. Tap Set, then wait. Type the PnL and tap Win, or tap Miss.</div>
			{Array.from({ length: PRED_COUNT }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx);
				return <PredictRow key={idx} s={s} t={t} game="pred" idx={idx} r={r} state={r ? "result" : "active"} canUndo={!!r} />;
			})}
		</Card>
	);
});

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency;
	const pnl = totalPnl(t.results);
	const back = backUsdt(t.deposit, pnl);
	const net = toMad(pnl, t.rate);
	return (
		<Card title="Open trade">
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
			{t.results.some(isDone) && !allDone(t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the predicts that are left?">
					<SessionHid s={s} t={t} />
					<button class="btn o full">Finish now</button>
				</form>
			) : null}
			<div class="lb tbn">When every predict has a result, the money is added to your balance by itself.</div>
		</Card>
	);
});

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency;
	const rate = s.user.usdt_rate;
	const cost = toMad(DEPOSIT, rate);
	return (
		<Card title="Today's trade">
			<div class="ow" style={{ margin: "0 0 6px" }}>
				<b class="big2">
					{fmt(DEPOSIT)} <small>USDT</small>
				</b>
				<span class="lb">{`${fmt(cost)} ${cur}`}</span>
			</div>
			<div class="lb">{`1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
			<form method="post" action="/trading/deposit" data-confirm={`Deposit ${fmt(DEPOSIT)} USDT? It counts as a buy of ${fmt(cost)} ${cur}.`}>
				<Back s={s} />
				<button class="btn full">Deposit {fmt(DEPOSIT)} USDT</button>
			</form>
			<div class="lb tbn">Then you do 4 up or down predicts (1 USDT) and 3 more predicts (3 USDT).</div>
		</Card>
	);
});

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate);
	const btc = strip(btcOf(t.results));
	const pred = strip(predOf(t.results));
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{`${btc ? `BTC ${btc}` : ""}${btc && pred ? " · " : ""}${pred ? `P ${pred}` : ""}`}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this trade again? The money it added is taken back.">
						<SessionHid s={s} t={t} />
						<button class="ub" aria-label="Open this trade again">
							<Icon name="undo" />
						</button>
					</form>
				) : null}
			</span>
		</div>
	);
});

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null;
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0);
	return (
		<Card title={`Past trades · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	);
});

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open");
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10);
	return (
		<div class="trd">
			{open ? (
				<>
					<OpenSummary s={s} t={open} />
					<BtcCard s={s} t={open} />
					<PredCard s={s} t={open} />
				</>
			) : (
				<StartCard s={s} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	);
});
__EOF_MT__
cat > .mt_patch9.cjs << '__EOF_MT__'
const fs = require("fs");
let failed = 0;
function edit(file, fn) {
  const s = fs.readFileSync(file, "utf8");
  const r = fn(s);
  if (r === null) { console.error("patch problem in " + file); failed++; return; }
  if (r !== s) fs.writeFileSync(file, r);
}
function swap(s, old, add) {
  if (!s.includes(old)) return null;
  return s.replace(old, () => add);
}
edit("app/db/tables.ts", (s) => {
  if (s.includes("asset: c.varchar(8)")) return s;
  return swap(s, "idx: c.integer(),\nwon: c.integer(),", "idx: c.integer(),\nwon: c.integer(),\nstate: c.varchar(8),\nasset: c.varchar(8),\ntf: c.integer(),");
});
edit("app/commands.ts", (s) => {
  if (s.includes("tradeSet")) return s;
  return swap(s, "\ttradeResult:", '\ttradeSet: { run: (u, f) => trading.setPredict(u.id, f), to: "/trading" },\n\ttradeResult:');
});
edit("app/routes.ts", (s) => {
  if (s.includes("tradeSet")) return s;
  return swap(s, "\t\ttradeResult:", '\t\ttradeSet: post("/trading/set"),\n\t\ttradeResult:');
});
edit("database/schema.sql", (s) => {
  if (s.includes("asset         TEXT")) return s;
  return swap(s, "  created_at    INTEGER NOT NULL,\n  UNIQUE (session_id, game, idx)", "  state         TEXT NOT NULL DEFAULT 'done',\n  asset         TEXT NOT NULL DEFAULT '',\n  tf            INTEGER NOT NULL DEFAULT 0,\n  created_at    INTEGER NOT NULL,\n  UNIQUE (session_id, game, idx)");
});
edit("scripts/migrate.ts", (s) => {
  if (s.includes("trade_results ADD COLUMN")) return s;
  return swap(s, '"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",\n', '"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",\n"ALTER TABLE trade_results ADD COLUMN state TEXT NOT NULL DEFAULT \'done\'",\n"ALTER TABLE trade_results ADD COLUMN asset TEXT NOT NULL DEFAULT \'\'",\n"ALTER TABLE trade_results ADD COLUMN tf INTEGER NOT NULL DEFAULT 0",\n');
});
edit("app/client/app.css", (s) => {
  if (s.includes("/*file9*/")) return s;
  return s.replace(/\s*$/, "\n") + "/*file9*/.btn.miss{background:var(--s2);color:var(--mu);border-color:var(--ln)}\n";
});
if (failed) { console.error(`\n${failed} patch problem(s). Backups are in .mt_backup/file9`); process.exit(1); }
console.log("patches applied");
__EOF_MT__
node .mt_patch9.cjs
rm -f .mt_patch9.cjs
echo "file9 done. Backups: .mt_backup/file9"
if [ -f .dev.vars ] && command -v bun >/dev/null 2>&1; then npm run db:migrate || echo "Migration failed. Run: npm run db:migrate"; else echo "Now run: npm run db:migrate   (adds state, asset, tf to trade_results, needed before Trading works)"; fi
