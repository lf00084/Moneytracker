import { esc } from "../lib/html.ts";
import type { DayRow, DebtView, Goal, GoalItem, Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { fld, hd, ic, sec, tg, themeSwitch } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";
function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);
	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${esc(n)} ${fmt(a)}`).join(" · ") || "";
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
const cur = (s: State) => esc(s.user.currency);
const back = (s: State) => `<input type="hidden" name="back" value="${esc(s.back)}">`;
const err = (s: State) => (s.error ? `<div class="neg" role="alert" style="margin:10px 0;font-size:13px">${esc(s.error)}</div>` : "");
const covered = (s: State) => new Map(s.goals.map((g) => [g.id, Math.min(Math.max(0, s.balance), g.target)] as const));
const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round(((covered(s).get(g.id) ?? 0) / g.target) * 100)) : 0);
const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target;
const avatar = (s: State) => {
	const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : "";
	return `<div class="av"${url ? ` style="background:url('${esc(url)}') center/cover"` : ""}>${url ? "" : esc((s.user.name.trim()[0] ?? "?").toUpperCase())}</div>`;
};
const debtRow = (s: State, d: DebtView) => {
	const unit = d.kind === "money" ? cur(s) : esc(d.item);
	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
	const all = d.kind === "money" ? plain(d.owed) : String(d.owed);
	const panel = (flag: string, action: string, title: string, btn: string) =>
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off">${flag === "data-payp" ? `<button type="button" class="all" data-all="${all}" aria-label="Fill the full amount">All</button>` : ""}<span class="mu">${unit}</span></div><button class="btn xs">${btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove ${esc(d.person)} from the list without marking it paid?" aria-label="Remove without paying">${ic("trash")}</button></div></form>`;
	return (
		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="sp">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
		panel("data-addp", "/debts", "Add to", "Add") +
		panel("data-payp", "/debts/pay", "Pay", "Pay") +
		`</div>`
	);
};
const debtList = (s: State) => s.debts.map((d) => debtRow(s, d)).join("") || '<div class="lb" style="padding:8px 0">Nobody to pay. All clear.</div>';
const nameChips = (names: string[]) =>
	names.length ? `<div class="chips nm">${names.map((n) => `<span class="chip" data-nm="${esc(n)}">${esc(n)}</span>`).join("")}</div>` : "";
const bigAdd = (label: string, target = "", right = false) =>
	`<button type="button" class="addb${right ? " r" : ""}" data-bigadd${target ? ` data-for="${target}"` : ""} aria-label="${label}">${ic("plus")}</button>`;
const listCard = (wide: boolean, title: string, right: string, body: string, target: string, label: string) =>
	wide
		? `<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>${title}</span><span class="lb">${right}</span></div>${body}</div>${bigAdd(label, target, true)}</div>`
		: `<div class="cd bgc rgt"><div class="ct"><div class="tg">${title}</div><div class="cb">${body}</div></div>${bigAdd(label, target, true)}</div>`;
const addDebtPanel = (s: State) =>
	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><div class="iw"><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><span class="mu">${cur(s)}</span></div><button class="btn full">Add</button></form>`;
const owePair = (s: State) => {
	const c = calc(s);
	return `<div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>`;
};
const chev = `<span class="chev">${ic("chev")}</span>`;
const tgp = (t: string, key: string, b: string) =>
	`<div class="cd"><div class="tg th2"><span>${t}</span><button type="button" class="pl" data-plus="${key}" aria-label="Add">${ic("plus")}</button></div><div class="cb">${b}</div></div>`;
const spendRow = (s: State, id: string, n: string, sub: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${sub}</div></div><span class="rt"><b class="sp">${a}</b><form method="post" action="/buy/delete" style="display:contents" data-confirm="Undo this buy? The money comes back.">${back(s)}<input type="hidden" name="id" value="${id}"><button class="ub" aria-label="Undo buy">${ic("undo")}</button></form></span></div>`;
const oweM = (s: State, open: boolean, key: string) => {
const c = calc(s);
return xcard(key, open, "I owe", `<b class="big2 sp">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span>`, debtList(s), `<div class="xl"><span>${new Set(s.debts.map((d) => d.person)).size === 1 ? "1 person" : `${new Set(s.debts.map((d) => d.person)).size} people`}</span></div>`, addDebtPanel(s), "Add debt");
};
const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="sc bgc">${bigAdd("Add debt")}<div class="ct"><details data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>${addDebtPanel(s)}</div></div>`;
};
const roadChips = (s: State) =>
	[
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = roadChips(s);
	return `<div class="cd jarc"><i class="jar" style="width:${c.pct}%"></i><div class="jin"><div class="tg">Road to goals</div><div class="cb"><div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}</div></div></div>`;
};
const xcard = (key: string, open: boolean, title: string, head: string, body: string, foot: string, form: string, label: string, jar = -1) =>
`<div class="xc${label ? "" : " xn"}"><details class="xd" data-keep-open="${key}"${open ? " open" : ""}><summary class="xh osum">${jar >= 0 ? `<i class="xj${jar >= 100 ? " full" : ""}" style="width:${jar}%"></i>` : ""}<div><div class="tg0">${title}</div>${head ? `<div class="ow">${head}</div>` : ""}</div><span class="chev">${ic("chev")}</span></summary><div class="xb">${body}</div><div class="xf${foot ? "" : " xo"}">${foot}${form}</div></details>${label ? `<button type="button" class="xp" data-xplus aria-label="${label}">${ic("plus")}</button>` : ""}</div>`;
const goalLeft = (s: State, g: Goal) => (g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`);
const itemRow = (s: State, it: GoalItem, manage: boolean) => {
const ok = s.balance >= it.price;
const hid = `${back(s)}<input type="hidden" name="id" value="${it.id}">`;
const cls = `gi${it.done ? " gdone" : ""}`;
const name = `<span class="gn">${esc(it.name)}</span><span class="lb">${fmt(it.price)}</span>`;
if (!manage) return `<div class="${cls}">${name}<span class="wb">${it.done ? "" : `<form method="post" action="/goals/buy" style="display:contents" data-confirm="Mark ${esc(it.name)} as bought? It will be added as a spend.">${hid}<button class="btn xs${ok ? "" : " off"}"${ok ? "" : " disabled"}>Bought</button></form>`}</span></div>`;
const del = `<form method="post" action="/goals/item/delete" style="display:contents" data-confirm="Remove ${esc(it.name)} from this goal?">${hid}<button class="ub" aria-label="Remove ${esc(it.name)}">${ic("trash")}</button></form>`;
const edit = it.done ? "" : `<button type="button" class="ub" data-pay aria-label="Edit ${esc(it.name)}">${ic("edit")}</button>`;
const panel = it.done ? "" : `<form method="post" action="/goals/item/edit" class="ad" data-payp hidden>${hid}<label>Edit ${esc(it.name)}</label><div class="ln"><input class="in f" name="name" value="${esc(it.name)}" autocomplete="off" required><input class="in pr2" name="price" value="${plain(it.price)}" placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn xs">Save</button></div></form>`;
return `<div class="dbw"><div class="${cls}">${name}<span class="wb">${edit}${del}</span></div>${panel}</div>`;
};
const goalRow = (s: State, g: Goal, manage: boolean) => {
const pct = pctOf(s, g);
const info = `<div class="dn"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt s${pct >= 100 ? " full" : ""}"><i style="width:${pct}%"></i></div></div>`;
const items = g.items.map((it) => itemRow(s, it, manage)).join("");
if (!manage) return `<div class="gw"><div class="db">${info}</div>${items}</div>`;
const del = `<form method="post" action="/goals/delete" style="display:contents" data-confirm="Delete ${esc(g.title)} and all its items?">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="ub" aria-label="Delete ${esc(g.title)}">${ic("trash")}</button></form>`;
const add = `<form method="post" action="/goals/item" class="ad" data-addp hidden>${back(s)}<input type="hidden" name="goal_id" value="${g.id}"><label>Add item to ${esc(g.title)}</label><div class="ln"><input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required><input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn xs">Add</button></div></form>`;
const ren = `<form method="post" action="/goals/edit" class="ad" data-payp hidden>${back(s)}<input type="hidden" name="id" value="${g.id}"><label>Rename goal</label><div class="ln"><input class="in f" name="name" value="${esc(g.title)}" autocomplete="off" required><button class="btn xs">Save</button></div></form>`;
return `<div class="gw"><div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add item to ${esc(g.title)}">${ic("plus")}</button>${info}<span class="wb"><button type="button" class="ub" data-pay aria-label="Rename ${esc(g.title)}">${ic("edit")}</button>${del}</span></div>${add}${ren}</div>${items}</div>`;
};
const goalList = (s: State, manage: boolean) => s.goals.map((g) => goalRow(s, g, manage)).join("") || `<div class="lb" style="padding:8px 0">${manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</div>`;
const goalForm = (s: State) => `<form method="post" action="/goals" class="sf xfm" data-adp hidden>${back(s)}<input class="in" name="name" placeholder="Goal name" autocomplete="off" required><button class="btn full">Add goal</button></form>`;
const goalStat = (s: State) => {
const target = s.goals.reduce((a, g) => a + g.target, 0);
const saved = Math.min(Math.max(0, s.balance), target);
const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0;
return { target, pct, toGo: Math.max(0, target - saved) };
};
const goalsX = (s: State, open: boolean, key: string, manage: boolean) => {
const g = goalStat(s);
const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${cur(s)} to go`;
const head = `<b class="big2">${g.pct}<small>%</small></b><span class="lb">${sub}</span>`;
if (manage) return xcard(key, open, "Goals", head, goalList(s, true), '<div class="xl"><span>Pencil edits, bin removes</span></div>', goalForm(s), "Add goal", g.pct);
return xcard(key, open, "Goals", head, goalList(s, false), `<div class="xl"><span>Left to buy ${fmt(g.target)} ${cur(s)}</span><a class="lnk" href="/goals">Manage</a></div>`, "", "", g.pct);
};
const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);
const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id);
const srcRows = (s: State) =>
	s.sources
		.map((x) => {
			const got = gotToday(s, x);
			const sum = got.reduce((a, i) => a + i.amount, 0);
			const auto = x.mode === "auto";
			const tag = !x.active ? "paused" : auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
			const fixed = srcAmount(x);
			const hid = (v: string) => `${back(s)}<input type="hidden" name="id" value="${v}">`;
			const del = `<form method="post" action="/income/source/delete" style="display:contents" data-confirm="Delete ${esc(x.name)}? What it already paid stays in your balance.">${hid(x.id)}<button class="ub" aria-label="Delete ${esc(x.name)}">${ic("trash")}</button></form>`;
			let main: string;
			if (!x.active) main = `<form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Resume</button></form>`;
			else if (auto)
				main = `<b class="ea">+${fmt(x.amount)}</b><form method="post" action="/income/toggle" style="display:contents">${hid(x.id)}<button class="btn xs o">Pause</button></form>`;
			else if (got.length)
				main = `<button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${hid(got[0]!.id)}<button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form>`;
			else if (fixed)
				main = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(fixed)}</button></form>`;
			else
				main = `<form method="post" action="/income/add" class="ln" style="gap:6px">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required><button class="btn xs o">Add</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div></div><span class="rt">${main}${del}</span></div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';
const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips" style="margin:10px 0 4px"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div><div class="lb" style="margin-bottom:2px">Manual: you tap it, once a day. Auto: added for you.</div>`;
const addSourceForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/income" id="${id}" class="${wide ? "sc" : "cd"} spf" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off"></div>${modeChips}<button class="btn full">Add source</button></form>`;
const srcForm = (s: State) => `<form method="post" action="/income" class="sf xfm" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off"></div>${modeChips}<button class="btn full">Add source</button></form>`;
const plain = (n: number) => (n / 100).toFixed(2).replace(/\.00$/, "");
const manageRow = (s: State, x: Source) => {
const auto = x.mode === "auto";
const tag = !x.active ? "paused" : auto ? (x.every === "month" ? "monthly" : "auto") : "manual";
const fixed = srcAmount(x);
const hid = `${back(s)}<input type="hidden" name="id" value="${x.id}">`;
const toggle = `<form method="post" action="/income/toggle" style="display:contents">${hid}<button class="btn xs o">${x.active ? "Pause" : "Resume"}</button></form>`;
const del = `<form method="post" action="/income/source/delete" style="display:contents" data-confirm="Delete ${esc(x.name)}? What it already paid stays in your balance.">${hid}<button class="ub" aria-label="Delete ${esc(x.name)}">${ic("trash")}</button></form>`;
const panel = `<form method="post" action="/income/edit" class="ad" data-addp hidden>${hid}<label>Edit ${esc(x.name)}</label><div class="ln"><input class="in f" name="name" value="${esc(x.name)}" autocomplete="off" required><input class="in pr2" name="amount" value="${fixed ? plain(fixed) : ""}" placeholder="Amount" inputmode="decimal" autocomplete="off"><button class="btn xs">Save</button></div></form>`;
return `<div class="dbw"><div class="rw"><div><div>${esc(x.name)}<span class="tag">${tag}</span></div>${fixed ? `<div class="lb">${fmt(fixed)} ${cur(s)}</div>` : ""}</div><span class="rt">${toggle}<button type="button" class="ub" data-tg aria-label="Edit ${esc(x.name)}">${ic("edit")}</button>${del}</span></div>${panel}</div>`;
};
const incomeX = (s: State) =>
xcard("income", true, "Income sources", `<b class="big2">${s.sources.length}</b><span class="lb">${s.sources.filter((x) => x.active).length} active</span>`, s.sources.map((x) => manageRow(s, x)).join("") || '<div class="lb" style="padding:8px 0">No sources yet. Tap + to add one.</div>', "", srcForm(s), "Add source");
const homeRow = (s: State, x: Source) => {
const got = gotToday(s, x);
const sum = got.reduce((a, i) => a + i.amount, 0);
const fixed = srcAmount(x);
const hid = (v: string) => `${back(s)}<input type="hidden" name="id" value="${v}">`;
let main: string;
if (x.mode === "auto") main = `<b class="ea">+${fmt(x.amount)}</b>`;
else if (got.length) main = `<button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(sum)} from ${esc(x.name)}?">${hid(got[0]!.id)}<button class="ub" aria-label="Undo ${esc(x.name)}">${ic("undo")}</button></form>`;
else if (fixed) main = `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(fixed)}</button></form>`;
else main = `<form method="post" action="/income/add" class="ln" style="gap:6px">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required><button class="btn xs o">Add</button></form>`;
return `<div class="rw"><div><div>${esc(x.name)}</div></div><span class="rt">${main}</span></div>`;
};
const homeInc = (s: State) => {
const c = calc(s);
const rows = s.sources.filter((x) => x.active).map((x) => homeRow(s, x)).join("") + s.incomesToday.filter((i) => !i.sourceId).map((i) => incRow(s, i)).join("");
const form = `<form method="post" action="/history/income" class="sf xfm" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="amount" placeholder="Other income today" inputmode="decimal" autocomplete="off" required><button class="btn">Add</button></div></form>`;
return xcard("inc", true, "Income today", `<b class="big2 ea">+${fmt(c.earned)} <small>${cur(s)}</small></b><span class="lb">${c.earnedLine}</span>`, rows || '<div class="lb" style="padding:8px 0">No sources yet.</div>', "", form, "Add other income");
};
const incD = (s: State, title = "Income sources", id = "f-src-d") => addSourceForm(s, true, id) + listCard(true, title, `+${fmt(calc(s).earned)} today`, srcRows(s), id, "Add source");
const cardsM = (s: State) => {
	const c = calc(s);
	const row = (cls: string, big: string) => `<div class="big2 ${cls}" style="white-space:nowrap">${big} <small>${cur(s)}</small></div>`;
	return `<div class="two">${tg("Earned today", row("ea", `+${fmt(c.earned)}`))}${tg("Bought today", row("sp", `−${fmt(c.bought)}`))}</div>`;
};
const buyRows = (s: State) =>
	`<div>${
		s.buys
			.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), `${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`, `−${fmt(b.total)}`))
			.join("") || '<div class="lb" style="padding:8px 0">Nothing bought today.</div>'
	}</div>`;
const spendForm = (s: State, wide: boolean, id: string) =>
	`<form method="post" action="/buy" id="${id}" class="${wide ? "sc" : "cd"} spf" data-sp data-adp hidden>${back(s)}${nameChips(s.names)}<div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required></div><button class="btn full">Add a spend</button></form>`;
const spendFoot = (s: State) => `<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>${back(s)}${nameChips(s.names)}<div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required></div><button class="btn full">Add a spend</button></form>`;
const buysX = (s: State) => xcard("buys", true, "Today's buys", "", buyRows(s), "", spendFoot(s), "Add a spend");
const buysD = (s: State) => spendForm(s, true, "f-buy-d") + listCard(true, "Today's buys", `${s.buys.length}`, buyRows(s), "f-buy-d", "Add a spend");
const hero = (s: State) => {
	const c = calc(s);
	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v ea">+${fmt(c.earned)}</div>${c.earnedLine ? `<div class="lb">${c.earnedLine}</div>` : ""}</div><div><div class="lb">Bought today</div><div class="v sp">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
};
const noteList = (s: State, key: string) => {
	if (key === "dash")
		return `<div data-list="dash">${
			s.notes
				.slice(-2)
				.reverse()
				.map((n) => `<div class="rw"><span>${esc(n.body)}</span><span class="lb">${hhmm(n.at)}</span></div>`)
				.join("") || '<div class="lb" style="padding:8px 0">No notes yet.</div>'
		}</div>`;
	let last = "";
	let out = "";
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at));
		if (label !== last) {
			out += `<div class="day"><span>${esc(label)}</span></div>`;
			last = label;
		}
		out +=
			`<div class="msg" data-id="${n.id}"><div class="bub">${esc(n.body)}</div><div class="meta">${n.edited ? "edited · " : ""}${hhmm(n.at)}</div>` +
			`<div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button>` +
			`<form method="post" action="/notes/delete" style="display:contents" data-confirm="Delete this note?">${back(s)}<input type="hidden" name="id" value="${n.id}"><button class="btn xs dng">Delete</button></form></div></div>`;
	}
	return `<div data-list="${key}">${out}</div>`;
};
const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';
const composer = (s: State, key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes">${back(s)}<input type="hidden" name="id" data-eid><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;
const noteD = (s: State) =>
	sec(
		"Note to yourself",
		`${s.notes.length} saved`,
		`<form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0">${back(s)}<input type="hidden" name="id" data-eid><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></form>${noteList(s, "dash")}`,
	);
const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`;
const incRow = (s: State, i: Income) =>
`<div class="by"><div><div>${esc(i.source)}</div></div><span class="rt"><b class="ea">+${fmt(i.amount)}</b><form method="post" action="/income/delete" style="display:contents" data-confirm="Undo +${fmt(i.amount)} from ${esc(i.source)}?">${back(s)}<input type="hidden" name="id" value="${i.id}"><button class="ub" aria-label="Undo income">${ic("undo")}</button></form></span></div>`;
const dayItems = (s: State, d: DayRow) =>
d.incomes.map((i) => incRow(s, i)).join("") +
d.buys.map((b) => spendRow(s, b.id, esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : "", `−${fmt(b.total)}`)).join("");
const dayForms = (s: State, wide: boolean) => {
const t = today();
const date = `<input class="in" type="date" name="day" value="${t}" max="${t}" required>`;
const body =
`<form method="post" action="/buy">${back(s)}<div class="ln"><input class="in" name="label" placeholder="Item" autocomplete="off" required><input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required></div><div class="ln" style="margin-top:8px">${date}<button class="btn xs">Add buy</button></div></form>` +
`<form method="post" action="/history/income" style="margin-top:14px">${back(s)}<div class="ln"><input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required>${date}<button class="btn xs">Add income</button></div></form>`;
return wide ? sec("Add to any day", "", body) : tg("Add to any day", body);
};
const histM = (s: State) =>
err(s) +
dayForms(s, false) +
s.days
.map((d) =>
tg(
esc(d.label),
`<div class="l1"><span><span class="lb">Earned</span> <b class="ea">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${dayItems(s, d)}`,
),
)
.join("");
const histD = (s: State) => {
const e = s.days.reduce((a, d) => a + d.earned, 0);
const b = s.days.reduce((a, d) => a + d.bought, 0);
return sec(
"Last 30 days",
`+${fmt(e)} earned · −${fmt(b)} bought`,
'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="ea">+${fmt(d.earned)}</b><b class="sp">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b><div>${dayItems(s, d)}</div></div>`).join(""),
);
};
const editFields = (s: State) =>
	fld("Name", esc(s.user.name), { f: true, name: "name" }) +
	fld("Email", esc(s.user.email), { t: "email", name: "email" }) +
	fld("Phone", esc(s.user.phone), { t: "tel", name: "phone", p: "+212 6 00 00 00 00" }) +
	fld("Bio", esc(s.user.bio), { name: "bio", p: "A line about you" });
const profileForm = (s: State, cancel: string) =>
	`<form method="post" action="/profile/edit">${err(s)}${editFields(s)}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="${cancel}">Cancel</a></div></form>`;
const prefsForm = (s: State) =>
	`<form method="post" action="/settings">${fld("Currency", esc(s.user.currency), { name: "currency" })}${fld("Auto income runs at", esc(s.user.run_at), { name: "run_at" })}${fld("Week starts", esc(s.user.week_start), { name: "week" })}<button class="btn" style="margin-top:14px">Save</button></form>`;
const dataButtons = `<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>`;
const balanceCard = (s: State) =>
	tg(
		"Total balance",
		`<div class="ow" style="margin:0"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></div>`,
	);
const plainBal = (s: State) => (s.balance / 100).toFixed(2).replace(/\.00$/, "");
const balanceForm = (s: State) =>
	`<form method="post" action="/profile/balance">${back(s)}<div class="fl"><label>Balance (${cur(s)})</label><input class="in f" name="balance" inputmode="decimal" value="${plainBal(s)}" autocomplete="off" required></div><button class="btn full" style="margin-top:14px">Update balance</button></form>`;
const profileM = (s: State) =>
	err(s) +
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div></div></div>` +
	balanceCard(s) +
	tg("Update balance", balanceForm(s)) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);
const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));
const settingsM = (s: State) =>
	err(s) +
	tg("Money & income", prefsForm(s)) +
	tg("Data", dataButtons) + '<div class="lb" style="text-align:center;margin:18px 0">Moneytracker v1.0 · stable</div>';
const settingsD = (s: State) =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	err(s) +
	`<div class="g3"><div>${sec("Balance", "", balanceForm(s))}${sec("Profile", "", profileForm(s, "/home"))}${sec(
		"Account",
		"",
		`<form method="post" action="/logout"><button class="btn o">Log out</button></form>`,
	)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Money & income", "", prefsForm(s))}${sec(
		"Data",
		"",
		dataButtons,
	)}</div></div>`;
const dashboardD = (s: State) =>
	hero(s) +
	`<div class="g2"><div>${buysD(s)}</div><div>${oweD(s, false, "owe")}${incD(s, "Income today")}${noteD(s)}</div></div>`;
const debtsD = (s: State) => {
	const c = calc(s);
	return (
		`<div class="hd"><h1 class="t">Debts</h1><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span></div>` +
		`<div class="g3"><div>${oweD(s, true, "owe-page")}</div><div>${sec(
			"How it works",
			"",
			'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div>',
		)}</div></div>`
	);
};
const notesD = (s: State) => `<div class="chat" data-x>${chatHead}${noteList(s, "d")}<div style="margin:30px 0 0">${composer(s, "d")}</div></div>`;
const planD = (s: State) => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${goalsX(s, true, "goals-d", true)}</div><div>${incD(s)}</div></div>`;
const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 30 days</span></div>${err(s)}${dayForms(s, true)}${histD(s)}`;
const base = (s: State) => ({
	theme: s.user.theme,
});
const homeBar = () => `<div style="text-align:right"><div style="font-size:14px;font-weight:600;letter-spacing:-.01em">Today</div><div class="lb">${longDay(today())}</div></div>`;
export const homePage = (s: State) =>
	page({
		...base(s),
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobileBar: homeBar(),
		mobile: err(s) + balanceCard(s) + cardsM(s) + homeInc(s) + buysX(s) + goalsX(s, false, "goals", false) + oweM(s, false, "owe"),
		desktop: err(s) + dashboardD(s),
	});
export const debtsPage = (s: State) =>
	page({
		...base(s),
		title: "Debts",
		mobileTab: "home",
		desktopTab: "home",
		mobile: err(s) + hd("Debts", s.debts.map((d) => esc(d.person)).slice(0, 2).join(" + ")) + goalM(s) + oweM(s, true, "owe-page"),
		desktop: err(s) + debtsD(s),
	});
export const notesPage = (s: State) =>
	page({ ...base(s), title: "Notes", mobileTab: "notes", desktopTab: "notes", mobile: chatHead + noteList(s, "m"), dock: composer(s, "m"), desktop: notesD(s) });
export const goalsPage = (s: State) =>
	page({ ...base(s), title: "Goals", mobileTab: "home", desktopTab: "plan", mobile: hd("Goals", "add, edit, remove") + err(s) + goalsX(s, true, "goals-page", true), desktop: err(s) + planD(s) });
export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "income", desktopTab: "income", mobile: err(s) + hd("Income", calc(s).earned ? `+${fmt(calc(s).earned)} today` : "") + incomeX(s), desktop: err(s) + '<div class="hd"><h1 class="t">Income</h1><span></span></div>' + incomeX(s) });
export const padPage = (s: State) => page({ ...base(s), title: "Pad", mobileTab: "pad", desktopTab: "pad", mobile: "", desktop: "" });
export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 30 days") + histM(s), desktop: historyD(s) });
export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });
export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });
export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
