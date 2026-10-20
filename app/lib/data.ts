import { sql } from "remix/data-table";

import { db, debtPayments, debts, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { fmt } from "./money.ts";
import { addDays, dayLabel, today } from "./time.ts";
import { getActiveAvatar, type User } from "./users.ts";

export type Quick = { id: string; name: string; icon: string; price: number };
export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number };
export type Income = { id: string; source: string; amount: number; day: string };
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number };
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number };
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean };
export type Note = { id: string; body: string; at: number; edited: boolean };
export type DayRow = { label: string; earned: number; bought: number; items: string[] };

export type Part = "quick" | "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar";

export type State = {
	user: User;
	back: string;
	error: string;
	avatar: string | null;
	quick: Quick[];
	buys: Buy[];
	incomesToday: Income[];
	sources: Source[];
	debts: DebtView[];
	goals: Goal[];
	notes: Note[];
	days: DayRow[];
	balance: number;
};

const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []));
const scalar = (r: unknown) => {
	const row = rowsOf(r)[0];
	return Number(row?.s ?? row?.[0] ?? 0) || 0;
};

/** Loads only the parts a page needs, in parallel. */
export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
	const need = new Set(parts);
	const uid = user.id;
	const t = today();
	const s: State = {
		user,
		back: extra.back,
		error: extra.error ?? "",
		avatar: null,
		quick: [],
		buys: [],
		incomesToday: [],
		sources: [],
		debts: [],
		goals: [],
		notes: [],
		days: [],
		balance: 0,
	};

	const jobs: Promise<void>[] = [];

	if (need.has("avatar")) jobs.push(getActiveAvatar(uid).then((a) => void (s.avatar = a)));

	if (need.has("quick"))
		jobs.push(
			db.findMany(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "asc"] }).then((rows) => {
				s.quick = rows.map((r) => ({ id: r.id, name: r.name, icon: r.icon, price: r.price_minor }));
			}),
		);

	const needSources = need.has("sources") || need.has("today") || need.has("history");
	let sourceRows: Source[] = [];
	if (needSources) {
		const rows = await db.findMany(incomeSources, { where: { user_id: uid }, orderBy: ["created_at", "asc"] });
		sourceRows = rows.map((r) => ({ id: r.id, name: r.name, mode: r.mode, every: r.every ?? "", amount: r.amount_minor, created: r.created_at }));
		s.sources = sourceRows;
		await accrue(uid, sourceRows);
	}

	if (need.has("today")) {
		const byId = new Map(sourceRows.map((x) => [x.id, x.name]));
		jobs.push(
			db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
				s.buys = rows.map(toBuy);
			}),
			db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {
				s.incomesToday = rows.map((r) => ({ id: r.id, source: byId.get(r.source_id ?? "") ?? "Other", amount: r.amount_minor, day: r.day }));
			}),
		);
	}

	if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));

	if (need.has("goals"))
		jobs.push(
			db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }).then((rows) => {
				s.goals = rows.map((g) => ({ id: g.id, title: g.title, target: g.target_minor, saved: g.saved_minor, done: !!g.done_at }));
			}),
		);

	if (need.has("notes"))
		jobs.push(
			db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
				s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }));
			}),
		);

	if (need.has("history")) {
		const from = addDays(t, -6);
		jobs.push(
			Promise.all([
				db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 400 }),
				db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 400 }),
			]).then(([bs, is]) => {
				s.days = Array.from({ length: 7 }, (_, i) => {
					const day = addDays(t, -i);
					const b = bs.filter((x) => x.day === day && day >= from);
					const inc = is.filter((x) => x.day === day);
					return {
						label: dayLabel(day),
						earned: inc.reduce((a, x) => a + x.amount_minor, 0),
						bought: b.reduce((a, x) => a + x.total_minor, 0),
						items: b.map((x) => `${x.name}${x.qty > 1 ? ` ×${x.qty}` : ""} ${fmt(x.total_minor)}`),
					};
				});
			}),
		);
	}

	if (need.has("balance"))
		jobs.push(
			Promise.all([
				db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
				db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
			]).then(([i, p]) => void (s.balance = scalar(i) - scalar(p))),
		);

	await Promise.all(jobs);
	return s;
}

const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number }): Buy => ({
	id: r.id,
	name: r.name,
	qty: r.qty,
	unit: r.unit_minor,
	total: r.total_minor,
	day: r.day,
	at: r.created_at,
});

async function loadDebts(uid: string): Promise<DebtView[]> {
	const [pe, de, pay] = await Promise.all([
		db.findMany(people, { where: { user_id: uid } }),
		db.findMany(debts, { where: { user_id: uid } }),
		db.findMany(debtPayments, { where: { user_id: uid } }),
	]);
	const names = new Map(pe.map((p) => [p.id, p.name]));
	const paid = new Map<string, number>();
	for (const p of pay) paid.set(p.debt_id, (paid.get(p.debt_id) ?? 0) + p.amount_minor);

	return de
		.map((d): DebtView => {
			const kind = d.kind === "item" ? "item" : "money";
			return {
				id: d.id,
				person: names.get(d.person_id) ?? "?",
				kind,
				item: d.item_name || "cig",
				owed: kind === "item" ? (d.item_qty ?? 0) : d.amount_minor,
				paid: paid.get(d.id) ?? 0,
			};
		})
		.filter((d) => d.owed > 0) // paid-off people stay in the database but leave the list
		.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1));
}

/** Auto sources add their own income rows. The row id is source + day, so a repeat can never double count. */
async function accrue(uid: string, list: Source[]) {
	const t = today();
	await Promise.all(
		list
			.filter((s) => s.mode === "auto" && s.amount > 0)
			.map(async (s) => {
				const last = await db.findOne(incomes, { where: { source_id: s.id }, orderBy: ["day", "desc"] });
				if (last?.day === t) return;
				const created = new Date(s.created).toISOString().slice(0, 10);
				const due: string[] = [];

				if (s.every === "month") {
					const dom = Number(created.slice(8, 10));
					let [y, m] = [Number(created.slice(0, 4)), Number(created.slice(5, 7))];
					const [ty, tm] = [Number(t.slice(0, 4)), Number(t.slice(5, 7))];
					while (y < ty || (y === ty && m <= tm)) {
						const dim = new Date(Date.UTC(y, m, 0)).getUTCDate();
						const day = `${y}-${String(m).padStart(2, "0")}-${String(Math.min(dom, dim)).padStart(2, "0")}`;
						if (day >= created && day <= t && (!last || day > last.day)) due.push(day);
						m++;
						if (m > 12) [y, m] = [y + 1, 1];
					}
				} else {
					let d = last ? addDays(last.day, 1) : created;
					const floor = addDays(t, -45);
					if (d < floor) d = floor;
					while (d <= t) {
						due.push(d);
						d = addDays(d, 1);
					}
				}
				if (!due.length) return;
				try {
					await db.createMany(
						incomes,
						due.map((day) => ({ id: `auto:${s.id}:${day}`, user_id: uid, source_id: s.id, amount_minor: s.amount, day, created_at: Date.now() })),
					);
				} catch {
					// Another request added the same days first. Nothing to do.
				}
			}),
	);
}
