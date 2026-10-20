import { esc } from "../lib/html.ts";
import type { DebtView, Goal, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { by, chips, fld, hd, ic, ICON_KEYS, sec, tg, themeSwitch } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";

// ---------- numbers every page needs ----------

function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);

	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${esc(n)} ${fmt(a)}`).join(" · ") || "nothing yet";

	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";

	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = s.goals.reduce((a, g) => a + Math.min(g.saved, g.target || g.saved), 0);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;

	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}

const cur = (s: State) => esc(s.user.currency);
const back = (s: State) => `<input type="hidden" name="back" value="${esc(s.back)}">`;
const err = (s: State) => (s.error ? `<div class="neg" role="alert" style="margin:10px 0;font-size:13px">${esc(s.error)}</div>` : "");
const pctOf = (g: Goal) => (g.target ? Math.min(100, Math.round((g.saved / g.target) * 100)) : 0);

const avatar = (s: State) => {
	const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : "";
	return `<div class="av"${url ? ` style="background:url('${esc(url)}') center/cover"` : ""}>${url ? "" : esc((s.user.name.trim()[0] ?? "?").toUpperCase())}</div>`;
};

// ---------- debts ----------

const debtRow = (s: State, d: DebtView) => {
	const unit = d.kind === "money" ? cur(s) : esc(d.item);
	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
	const panel = (flag: string, action: string, title: string, btn: string) =>
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}</label><div class="ln"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off"><span class="mu">${unit}</span><button class="btn xs">${btn}</button></div></form>`;
	return (
		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="neg">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
		panel("data-addp", "/debts", "Add to", "Add") +
		panel("data-payp", "/debts/pay", "Pay", "Pay") +
		`</div>`
	);
};

const debtList = (s: State) => s.debts.map((d) => debtRow(s, d)).join("") || '<div class="lb" style="padding:8px 0">Nobody to pay. All clear.</div>';

const newPerson = (s: State) =>
	`<div class="sub">New person</div><form method="post" action="/debts" class="ln3">${back(s)}<input class="in" name="name" placeholder="Name" autocomplete="off"><input class="in n3" name="cig" placeholder="cig" inputmode="numeric"><input class="in n3" name="amount" placeholder="${cur(s)}" inputmode="decimal"><button class="btn xs">Add</button></form><div class="lb" style="margin-top:10px">Cleared people are hidden. Type their name again to bring them back.</div>`;

const owePair = (s: State) => {
	const c = calc(s);
	return `<div class="ow"><b class="neg big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="neg sm">${c.oweExtra}</span></div>`;
};

const chev = `<span class="chev">${ic("chev")}</span>`;

const oweM = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<details class="cd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">I owe</div><div class="ow"><b class="neg big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="neg sm">${c.oweExtra}</span></div>${chev}</summary><div class="cb">${debtList(s)}${open ? newPerson(s) : ""}</div></details>`;
};

const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<details class="sc" data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>`;
};

// ---------- goals ----------

const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = [
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
	return tg(
		"Road to goals",
		`<div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div><div class="mt"><i style="width:${c.pct}%"></i></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}`,
	);
};

const saveBtn = (s: State, g: Goal) =>
	g.done
		? '<span class="chip">done</span>'
		: `<form method="post" action="/goals/save" style="display:contents">${back(s)}<input type="hidden" name="id" value="${g.id}"><input type="hidden" name="amount" value="100"><button class="btn xs">Save 100</button></form>`;

const goalLeft = (s: State, g: Goal) =>
	g.target ? `${fmt(Math.max(0, g.target - g.saved))} left of ${fmt(g.target)}` : `${fmt(g.saved)} ${cur(s)} saved`;

const newWish = (s: State, wide: boolean) =>
	`<form method="post" action="/goals" class="ln"${wide ? ' style="margin-top:18px"' : ""}>${back(s)}<input class="in" name="name" placeholder="${wide ? "New wish" : "Name"}" autocomplete="off"><input class="in${wide ? "" : " n3"}" name="price"${wide ? ' style="width:120px"' : ""} placeholder="Price" inputmode="decimal"><button class="btn xs">Add</button></form>`;

const wishesM = (s: State) =>
	s.goals
		.map((g) => tg(esc(g.title), `<div class="l1"><span class="lb">${goalLeft(s, g)}</span>${saveBtn(s, g)}</div><div class="mt"><i style="width:${pctOf(g)}%"></i></div>`))
		.join("") + tg("New wish", newWish(s, false));

const wishD = (s: State) =>
	sec(
		"Wish list",
		`${s.goals.filter((g) => !g.done).length} active`,
		s.goals
			.map(
				(g) =>
					`<div class="wr"><div style="flex:1"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt"><i style="width:${pctOf(g)}%"></i></div></div>${saveBtn(s, g)}</div>`,
			)
			.join("") + newWish(s, true),
	);

const debtsM = (s: State) => tg("Debts", owePair(s) + debtList(s));

// ---------- income ----------

const srcLabel = (x: Source) => (x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto · every day") : "manual");

const srcRows = (s: State) =>
	s.sources
		.map((x) => {
			const right =
				x.mode === "auto"
					? `<b class="pos">+${fmt(x.amount)}</b>`
					: `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(x.amount)}</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto") : "manual"}</span></div><div class="lb">${srcLabel(x)}</div></div>${right}</div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';

const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div>`;

const addSourceForm = (s: State, wide: boolean) =>
	wide
		? `<form method="post" action="/income" class="ln" style="margin-top:18px">${back(s)}<input class="in" name="name" placeholder="New source" autocomplete="off"><input class="in" name="amount" style="width:100px" placeholder="Amount" inputmode="decimal"><button class="btn xs">Add</button>${modeChips}</form>`
		: `<form method="post" action="/income">${back(s)}${fld("Name", "", { name: "name" })}${fld("Amount", "", { t: "number", name: "amount" })}${modeChips}<button class="btn full" style="margin-top:14px">Add source</button></form>`;

const incomeM = (s: State) => tg("Sources", srcRows(s)) + tg("Add a source", addSourceForm(s, false));

const incD = (s: State, title = "Income sources") => sec(title, `+${fmt(calc(s).earned)} today`, srcRows(s) + addSourceForm(s, true));

// ---------- home ----------

const cardsM = (s: State) => {
	const c = calc(s);
	return `<div class="two">${tg("Earned today", `<div class="big2 pos">+${fmt(c.earned)} <small>${cur(s)}</small></div><div class="lb" style="margin-top:6px">${c.earnedLine}</div>`)}${tg(
		"Bought today",
		`<div class="big2 neg">−${fmt(c.bought)} <small>${cur(s)}</small></div><div class="lb" style="margin-top:6px">${s.buys.length} buys</div>`,
	)}</div>`;
};

const buyRows = (s: State) =>
	`<div>${
		s.buys
			.map((b) => by(esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), `${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`, `−${fmt(b.total)}`))
			.join("") || '<div class="lb" style="padding:8px 0">Nothing bought today.</div>'
	}</div>`;

const quickBtns = (s: State, desk: boolean) => {
	const items = [...s.quick.map((k) => ({ n: k.name, p: k.price ? fmt(k.price).replace(/,/g, "") : "", i: k.icon, sub: `${fmt(k.price)} each`, o: false })), { n: "Other", p: "", i: "Other", sub: "custom", o: true }];
	return items
		.map((k) => {
			const a = ` data-q="${esc(k.n)}" data-p="${esc(k.p)}"${k.o ? ' data-o="1"' : ""}`;
			return desk
				? `<button type="button"${a}>${ic(k.i)}<span><b>${esc(k.n)}</b><small>${k.sub}</small></span></button>`
				: `<button type="button"${a}>${ic(k.i)}<span>${esc(k.n)}</span><small>${k.sub}</small></button>`;
		})
		.join("");
};

const quickM = (s: State) =>
	`<div data-qb><div class="qk" data-qgrid>${quickBtns(s, false)}</div><form method="post" action="/buy" data-qp hidden>${back(s)}${tg(
		"<span data-qt>Smoke</span> · quantity × price",
		'<input type="hidden" name="category" data-cat value="Smoke"><div class="fl" data-labelwrap hidden style="margin:0 0 12px"><label>What</label><input class="in" name="label" data-label autocomplete="off"></div><div class="pn"><div class="fl" style="margin:0"><label>Quantity</label><div class="stp"><button type="button" data-step="-1">−</button><input class="in f" name="qty" data-qty value="1" inputmode="numeric"><button type="button" data-step="1">+</button></div></div><div class="fl" style="margin:0;flex:1;min-width:90px"><label>Price each</label><input class="in" name="price" data-price value="" inputmode="decimal"></div></div><div class="tt"><span class="lb">Total</span><b class="neg" data-tot>0</b><button class="btn">Add</button></div>',
	)}</form></div>`;

const quickD = (s: State) =>
	`<div data-qb><div class="qk4" data-qgrid>${quickBtns(s, true)}</div><form method="post" action="/buy" class="qrow" data-qp>${back(s)}<input type="hidden" name="category" data-cat value="Smoke"><div data-labelwrap hidden style="width:140px"><div class="lb">What</div><input class="in" name="label" data-label autocomplete="off"></div><div><div class="lb">Quantity</div><div class="stp"><button type="button" data-step="-1">−</button><input class="in f" name="qty" data-qty value="1" inputmode="numeric"><button type="button" data-step="1">+</button></div></div><div style="width:110px"><div class="lb">Price each</div><input class="in" name="price" data-price value="" inputmode="decimal"></div><div class="eq neg" data-tot data-pre="= ">= 0</div><button class="btn" style="margin-left:auto">Add</button></form></div>`;

const hero = (s: State) => {
	const c = calc(s);
	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v pos">+${fmt(c.earned)}</div><div class="lb">${c.earnedLine}</div></div><div><div class="lb">Bought today</div><div class="v neg">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v neg">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
};

// ---------- notes ----------

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

// ---------- history ----------

const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`;

const histM = (s: State) =>
	s.days
		.map((d) =>
			tg(
				esc(d.label),
				`<div class="l1"><span><span class="lb">Earned</span> <b class="pos">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="neg">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${chips(d.items.map(esc))}`,
			),
		)
		.join("");

const histD = (s: State) => {
	const e = s.days.reduce((a, d) => a + d.earned, 0);
	const b = s.days.reduce((a, d) => a + d.bought, 0);
	return sec(
		"Last 7 days",
		`+${fmt(e)} earned · −${fmt(b)} bought`,
		'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
			s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="pos">+${fmt(d.earned)}</b><b class="neg">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b>${chips(d.items.map(esc))}</div>`).join(""),
	);
};

// ---------- profile + settings ----------

const editFields = (s: State) =>
	fld("Name", esc(s.user.name), { f: true, name: "name" }) +
	fld("Email", esc(s.user.email), { t: "email", name: "email" }) +
	fld("Phone", esc(s.user.phone), { t: "tel", name: "phone", p: "+212 6 00 00 00 00" }) +
	fld("Bio", esc(s.user.bio), { name: "bio", p: "A line about you" });

const profileForm = (s: State, cancel: string) =>
	`<form method="post" action="/profile/edit">${err(s)}${editFields(s)}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="${cancel}">Cancel</a></div></form>`;

const quickEditor = (s: State) => {
	const opts = (sel: string) => ICON_KEYS.map((k) => `<option value="${k}"${k === sel ? " selected" : ""}>${k}</option>`).join("");
	const rows =
		s.quick
			.map(
				(k) =>
					`<form class="qe" method="post" action="/settings/quick"><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="${k.id}"><select class="in sel" name="icon" aria-label="Icon">${opts(k.icon)}</select><input class="in" name="name" value="${esc(k.name)}" aria-label="Name" autocomplete="off"><input class="in n3" name="price" value="${k.price ? fmt(k.price).replace(/,/g, "") : ""}" inputmode="decimal" aria-label="Price" autocomplete="off"><button class="btn xs">Save</button><button class="ib sm" name="op" value="delete" aria-label="Remove" data-confirm="Remove ${esc(k.name)}?">×</button></form>`,
			)
			.join("") || '<div class="lb" style="padding:8px 0">No quick buys yet. Add one below.</div>';
	return `<div class="lb" style="margin-bottom:6px">These are the buttons under Quick buy.</div>${rows}<form class="qadd" method="post" action="/settings/quick"><input type="hidden" name="op" value="add"><select class="in sel" name="icon" aria-label="Icon">${opts("Tag")}</select><input class="in" name="name" placeholder="Name" autocomplete="off"><input class="in n3" name="price" placeholder="Price" inputmode="decimal" autocomplete="off"><button class="btn xs">Add</button></form>`;
};

const prefsForm = (s: State) =>
	`<form method="post" action="/settings">${fld("Currency", esc(s.user.currency), { name: "currency" })}${fld("Auto income runs at", esc(s.user.run_at), { name: "run_at" })}${fld("Week starts", esc(s.user.week_start), { name: "week" })}<button class="btn" style="margin-top:14px">Save</button></form>`;

const dataButtons = `<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>`;

const balanceCard = (s: State) =>
	tg(
		"Total balance",
		`<div class="ow" style="margin:0"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></div>`,
	);

const profileM = (s: State) =>
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div></div></div>` +
	balanceCard(s) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);

const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));

const settingsM = (s: State) => tg("Quick buys", quickEditor(s)) + tg("Money & income", prefsForm(s)) + tg("Data", dataButtons);

const settingsD = (s: State) =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	`<div class="g3"><div>${sec("Profile", "", profileForm(s, "/home"))}${sec("Account", "", `<form method="post" action="/logout"><button class="btn o">Log out</button></form>`)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Quick buys", "", quickEditor(s))}${sec("Money & income", "", prefsForm(s))}${sec("Data", "", dataButtons)}</div></div>`;

// ---------- desktop pages ----------

const dashboardD = (s: State) =>
	hero(s) +
	`<div class="g2"><div>${sec("Quick buy", "tap, set quantity and price", quickD(s))}${sec("Today's buys", `${s.buys.length}`, buyRows(s))}</div><div>${oweD(s, false, "owe")}${incD(s, "Income today")}${noteD(s)}</div></div>`;

const debtsD = (s: State) => {
	const c = calc(s);
	return (
		`<div class="hd"><h1 class="t">Debts</h1><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span></div>` +
		`<div class="g3"><div>${oweD(s, true, "owe-page")}</div><div>${sec("Add", "new person or more to a name", newPerson(s).replace('<div class="sub">New person</div>', ""))}${sec(
			"How it works",
			"",
			'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div>',
		)}</div></div>`
	);
};

const notesD = (s: State) => `<div class="chat" data-x>${chatHead}${noteList(s, "d")}<div style="margin:30px 0 0">${composer(s, "d")}</div></div>`;

const planD = (s: State) => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${wishD(s)}</div><div>${incD(s)}</div></div>`;

const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 7 days</span></div>${histD(s)}`;

// ---------- pages ----------

const base = (s: State) => ({ theme: s.user.theme });

export const homePage = (s: State) =>
	page({
		...base(s),
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobile: hd("Today", longDay(today())) + oweM(s, false, "owe") + cardsM(s) + tg("Income sources", srcRows(s)) + quickM(s) + tg(`Today's buys · ${s.buys.length}`, buyRows(s)),
		desktop: dashboardD(s),
	});

export const debtsPage = (s: State) =>
	page({
		...base(s),
		title: "Debts",
		mobileTab: "home",
		desktopTab: "home",
		mobile: hd("Debts", s.debts.map((d) => esc(d.person)).slice(0, 2).join(" + ")) + goalM(s) + oweM(s, true, "owe-page"),
		desktop: debtsD(s),
	});

export const notesPage = (s: State) =>
	page({ ...base(s), title: "Notes", mobileTab: "notes", desktopTab: "notes", mobile: chatHead + noteList(s, "m"), dock: composer(s, "m"), desktop: notesD(s) });

export const goalsPage = (s: State) =>
	page({ ...base(s), title: "Goals", mobileTab: "goals", desktopTab: "plan", mobile: hd("Goals", "wishes + debts") + goalM(s) + wishesM(s) + debtsM(s), desktop: planD(s) });

export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "home", desktopTab: "plan", mobile: hd("Income", `+${fmt(calc(s).earned)} today`) + incomeM(s), desktop: planD(s) });

export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 7 days") + histM(s), desktop: historyD(s) });

export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });

export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });

export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
