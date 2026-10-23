/** Pure view helpers: numbers and labels derived from `State`. No markup in here. */
import type { DebtView, Goal, GoalItem, Source, State } from "./data.ts";
import { fmt } from "./money.ts";

export const LANG = "English";

/** 1250 (minor units) -> "12.5", for filling an input. */
export const plain = (n: number) => (n / 100).toFixed(2).replace(/\.00$/, "");

export function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);
	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${n} ${fmt(a)}`).join(" · ");
	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";
	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = Math.min(Math.max(0, s.balance), wishTarget);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;
	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}

// ---------- goals ----------

export const covered = (s: State, g: Goal) => Math.min(Math.max(0, s.balance), g.target);
export const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round((covered(s, g) / g.target) * 100)) : 0);
export const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target;

export const goalLeft = (s: State, g: Goal) =>
	g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${s.user.currency} · ready` : `${fmt(g.target - covered(s, g))} to go`;

export function goalStat(s: State) {
	const target = s.goals.reduce((a, g) => a + g.target, 0);
	const saved = Math.min(Math.max(0, s.balance), target);
	const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0;
	return { target, pct, toGo: Math.max(0, target - saved) };
}

export const canAfford = (s: State, it: GoalItem) => s.balance >= it.price;

// ---------- debts ----------

export const debtPct = (d: DebtView) => (d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0);

export const peopleCount = (s: State) => new Set(s.debts.map((d) => d.person)).size;

// ---------- income ----------

export const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);
export const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id);
export const sourceTag = (x: Source) => (!x.active ? "paused" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto") : "manual");

// ---------- history ----------

export const dayNet = (earned: number, bought: number) => `${earned - bought < 0 ? "−" : "+"}${fmt(Math.abs(earned - bought))}`;
