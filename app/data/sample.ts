/**
 * Sample data for every page. There is no database: the app pretends you are signed in and
 * everything below is fixed. "Today" is pinned so the sample numbers always line up.
 */

export const TODAY = "2026-10-12";
export const CURRENCY = "MAD";

export const user = { name: "You", email: "you@example.com" };

export const balance = 12480;

// ---------------------------------------------------------------------------------------------
// Types

export type Category = "Smoke" | "Coffee" | "Bread" | "Other";
export const categories: Category[] = ["Smoke", "Coffee", "Bread", "Other"];

export type Entry = { id: string; date: string; time: string; amount: number; hours?: number };
export type Source = {
	id: string;
	name: string;
	note: string;
	/** MAD per hour. Sources without a rate take a plain amount. */
	rate?: number;
	entries: Entry[];
};
export type Wish = { id: string; name: string; price: number; boughtOn?: string };
export type Debt = { id: string; name: string; total: number; paid: number; due: string };
export type Purchase = {
	id: string;
	date: string;
	time: string;
	label: string;
	amount: number;
	kind: "quick" | "wish" | "debt";
};

// ---------------------------------------------------------------------------------------------
// Income sources

function entry(id: string, date: string, time: string, amount: number, hours?: number): Entry {
	return hours === undefined ? { id, date, time, amount } : { id, date, time, amount, hours };
}

export const sources: Source[] = [
	{
		id: "company",
		name: "Company",
		note: "Hourly job",
		rate: 45,
		entries: [
			entry("c1", "2026-10-12", "18:00", 360, 8),
			entry("c2", "2026-10-10", "17:30", 270, 6),
			entry("c3", "2026-10-09", "18:00", 360, 8),
			entry("c4", "2026-10-08", "18:00", 360, 8),
			entry("c5", "2026-10-07", "18:00", 360, 8),
			entry("c6", "2026-10-06", "18:00", 360, 8),
		],
	},
	{
		id: "exoclick",
		name: "ExoClick",
		note: "Ads · manual",
		entries: [
			entry("x1", "2026-10-12", "06:00", 64),
			entry("x2", "2026-10-11", "06:00", 58),
			entry("x3", "2026-10-10", "06:00", 71),
			entry("x4", "2026-10-09", "06:00", 49),
			entry("x5", "2026-10-08", "06:00", 66),
			entry("x6", "2026-10-07", "06:00", 52),
			entry("x7", "2026-10-06", "06:00", 61),
		],
	},
	{
		id: "binance",
		name: "Binance P2P",
		note: "Trades · manual",
		entries: [
			entry("b1", "2026-10-11", "21:40", 120),
			entry("b2", "2026-10-09", "20:10", 85),
			entry("b3", "2026-10-07", "19:30", 140),
			entry("b4", "2026-10-06", "20:00", 60),
		],
	},
];

// ---------------------------------------------------------------------------------------------
// Wish list and debts

export const wishes: Wish[] = [
	{ id: "laptop", name: "Laptop", price: 3600 },
	{ id: "headphones", name: "Headphones", price: 450, boughtOn: "2026-10-03" },
];

export const debts: Debt[] = [
	{ id: "youssef", name: "Youssef", total: 1000, paid: 200, due: "2026-11-20" },
	{ id: "phone-store", name: "Phone store", total: 1500, paid: 1000, due: "2026-12-05" },
];

// ---------------------------------------------------------------------------------------------
// Purchases and monthly totals

export const purchases: Purchase[] = [
	{ id: "p1", date: "2026-10-12", time: "08:40", label: "Coffee", amount: 12, kind: "quick" },
	{ id: "p2", date: "2026-10-12", time: "07:55", label: "Bread", amount: 4, kind: "quick" },
	{ id: "p3", date: "2026-10-11", time: "21:10", label: "Smoke", amount: 35, kind: "quick" },
	{ id: "p4", date: "2026-10-11", time: "13:05", label: "Phone charger", amount: 60, kind: "quick" },
	{ id: "p5", date: "2026-10-10", time: "09:30", label: "Coffee", amount: 12, kind: "quick" },
	{ id: "p6", date: "2026-10-10", time: "09:00", label: "Bread", amount: 4, kind: "quick" },
	{ id: "p7", date: "2026-10-09", time: "22:15", label: "Smoke", amount: 35, kind: "quick" },
	{ id: "p8", date: "2026-10-08", time: "10:00", label: "Youssef", amount: 200, kind: "debt" },
	{ id: "p9", date: "2026-10-03", time: "16:20", label: "Headphones", amount: 450, kind: "wish" },
];

export const month = {
	label: "October",
	income: 8420,
	spent: 3250,
	incomeBySource: [
		{ name: "Company", amount: 6480 },
		{ name: "ExoClick", amount: 1540 },
		{ name: "Binance P2P", amount: 400 },
	],
	spentByCategory: [
		{ name: "Other", amount: 650 },
		{ name: "Smoke", amount: 620 },
		{ name: "Wish list", amount: 450 },
		{ name: "Coffee", amount: 340 },
		{ name: "Bread", amount: 190 },
		{ name: "Debt payments", amount: 1000 },
	],
};

// ---------------------------------------------------------------------------------------------
// Display helpers

const DAY = 86_400_000;
const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

const toDate = (iso: string) => new Date(`${iso}T00:00:00Z`);

export function fmt(n: number): string {
	return (Math.round(n * 100) / 100).toLocaleString("en-US", { maximumFractionDigits: 2 });
}

export function addDays(iso: string, n: number): string {
	return new Date(toDate(iso).getTime() + n * DAY).toISOString().slice(0, 10);
}

export function daysBetween(from: string, to: string): number {
	return Math.round((toDate(to).getTime() - toDate(from).getTime()) / DAY);
}

export function dayLabel(iso: string): string {
	if (iso === TODAY) return "Today";
	if (iso === addDays(TODAY, -1)) return "Yesterday";
	let d = toDate(iso);
	return `${WEEKDAYS[d.getUTCDay()]} ${d.getUTCDate()}`;
}

export function shortWeekday(iso: string): string {
	return WEEKDAYS[toDate(iso).getUTCDay()] ?? "";
}

export function shortDate(iso: string): string {
	let d = toDate(iso);
	return `${MONTHS[d.getUTCMonth()]} ${d.getUTCDate()}`;
}

export function todayLong(): string {
	let d = toDate(TODAY);
	return `${WEEKDAYS[d.getUTCDay()]} ${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]}`;
}

export function dueText(due: string): { text: string; tone: "normal" | "warn" | "late" } {
	let n = daysBetween(TODAY, due);
	let date = shortDate(due);
	if (n < 0) return { text: `Due ${date} · ${-n} days late`, tone: "late" };
	if (n === 0) return { text: "Due today", tone: "warn" };
	return { text: `Due ${date} · in ${n} day${n === 1 ? "" : "s"}`, tone: n <= 7 ? "warn" : "normal" };
}

// ---------------------------------------------------------------------------------------------
// Totals

const sum = <T>(list: T[], pick: (item: T) => number) => list.reduce((s, x) => s + pick(x), 0);

export const earnedOn = (source: Source, date: string) =>
	sum(
		source.entries.filter((e) => e.date === date),
		(e) => e.amount,
	);

export const hoursOn = (source: Source, date: string) =>
	sum(
		source.entries.filter((e) => e.date === date),
		(e) => e.hours ?? 0,
	);

/** The last seven days, oldest first, ending today. */
export const lastSevenDays = Array.from({ length: 7 }, (_, i) => addDays(TODAY, i - 6));

export const debtLeft = (debt: Debt) => Math.max(0, debt.total - debt.paid);

/**
 * One goal bar: wishes not bought yet plus the debts you still owe. A bought wish drops out of
 * the goal. Paid-off debt counts as progress.
 */
export function goal() {
	let wishLeft = sum(
		wishes.filter((w) => !w.boughtOn),
		(w) => w.price,
	);
	let debtOwed = sum(debts, debtLeft);
	let debtPaid = sum(debts, (d) => d.paid);
	let total = wishLeft + sum(debts, (d) => d.total);
	return {
		wishLeft,
		debtOwed,
		debtPaid,
		left: wishLeft + debtOwed,
		percent: total > 0 ? Math.round((debtPaid / total) * 100) : 0,
	};
}
