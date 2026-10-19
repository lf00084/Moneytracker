import {
	auth,
	buyRows,
	by,
	chatBody,
	chatHead,
	chips,
	composer,
	dbt,
	editFields,
	fld,
	H,
	hd,
	ic,
	newPerson,
	quickEditor,
	QUICK_DEF,
	sec,
	srcRows,
	tg,
	themeSwitch,
} from "../ui/parts.ts";
import { page } from "../ui/shell.ts";

// ---------- shared mobile pieces ----------

const goalM = () =>
	tg(
		"Road to goals",
		'<div class="gl"><span class="big">46<small>%</small></span><span class="lb">5,200 MAD to go</span></div><div class="mt"><i style="width:46%"></i></div><div class="chips"><span class="chip">Laptop 40%</span><span class="chip">Phone 67%</span><span class="chip n">Youssef 47%</span><span class="chip n">Mom 50%</span></div>',
	);

const cardsM = () =>
	`<div class="two">${tg("Earned today", '<div class="big2 pos">+184 <small>MAD</small></div><div class="lb" style="margin-top:6px">Ad 64 · Tips 120</div>')}${tg(
		"Bought today",
		'<div class="big2 neg">−<span data-bought>46</span> <small>MAD</small></div><div class="lb" style="margin-top:6px"><span data-nbuys>4</span> buys</div>',
	)}</div>`;

const chev = `<span class="chev">${ic("chev")}</span>`;

/** "I owe" card. Closed by default; the open/closed state is saved in the browser. */
const oweM = (open: boolean, key: string) => {
	let people = dbt("Youssef", "800 MAD", 47, open) + dbt("Mom", "300 MAD", 50) + dbt("Amar", "3 cig", 0) + (open ? newPerson : "");
	return `<details class="cd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">I owe</div><div class="ow"><b class="neg big2">1,100 <small>MAD</small></b><span class="neg sm">+ 3 cig</span></div>${chev}</summary><div class="cb">${people}</div></details>`;
};

const QUICK = [...QUICK_DEF.map((k) => ({ n: k.n, s: `${k.p} each`, p: k.p, i: k.i })), { n: "Other", s: "custom", p: "", i: "Other" }];

const quickM = () =>
	`<div data-qb><div class="qk" data-qgrid>${QUICK.map(
		(k) => `<button type="button" data-q="${k.n}" data-p="${k.p}"${k.n === "Other" ? ' data-o="1"' : ""}>${ic(k.i)}<span>${k.n}</span><small>${k.s}</small></button>`,
	).join("")}</div>` +
	`<form method="post" action="/buy" data-qp hidden>${tg(
		'<span data-qt>Smoke</span> · quantity × price',
		'<input type="hidden" name="category" data-cat value="Smoke"><div class="fl" data-labelwrap hidden style="margin:0 0 12px"><label>What</label><input class="in" name="label" data-label autocomplete="off"></div><div class="pn"><div class="fl" style="margin:0"><label>Quantity</label><div class="stp"><button type="button" data-step="-1">−</button><input class="in f" name="qty" data-qty value="3"><button type="button" data-step="1">+</button></div></div><div class="fl" style="margin:0;flex:1;min-width:90px"><label>Price each</label><input class="in" name="price" data-price value="2"></div></div><div class="tt"><span class="lb">Total</span><b class="neg" data-tot>−6</b><button class="btn">Add</button></div>',
	)}</form></div>`;

const wishCardM = (n: string, l: string, p: number) =>
	tg(n, `<div class="l1"><span class="lb">${l}</span><button type="button" class="btn xs">Save 100</button></div><div class="mt"><i style="width:${p}%"></i></div>`);

const wishesM = () =>
	wishCardM("Laptop", "3,600 left of 6,000", 40) +
	wishCardM("Phone", "500 left of 1,500", 67) +
	tg("New wish", '<form method="post" action="/goals" class="ln"><input class="in" name="name" placeholder="Name"><input class="in n3" name="price" placeholder="Price"><button class="btn xs">Add</button></form>');

const debtsM = () =>
	tg(
		"Debts",
		'<div class="ow"><b class="neg big2">1,100 <small>MAD</small></b><span class="neg sm">+ 3 cig</span></div>' +
			dbt("Youssef", "800 MAD", 47) +
			dbt("Mom", "300 MAD", 50) +
			dbt("Amar", "3 cig", 0),
	);

const incomeM = () =>
	tg(
		"Sources",
		'<div class="rw"><div><div>Ad revenue<span class="tag">auto</span></div><div class="lb">daily · 06:00</div></div><b class="pos">+64</b></div><div class="rw"><div><div>Tips<span class="tag">manual</span></div><div class="lb">ready now</div></div><button type="button" class="btn xs o">Add 120</button></div><div class="rw"><div><div>Salary<span class="tag">monthly</span></div><div class="lb">Nov 1</div></div><b class="pos">+8,000</b></div>',
	) +
	tg(
		"Add a source",
		`<form method="post" action="/income">${fld("Name", "", { name: "name" })}${fld("Amount", "", { t: "number", name: "amount" })}<div class="chips"><span class="chip on">Manual</span><span class="chip">Auto daily</span><span class="chip">Monthly</span></div><button class="btn full">Add source</button></form>`,
	);

const histM = () =>
	H.map((d) =>
		tg(
			d.d,
			`<div class="l1"><span><span class="lb">Earned</span> <b class="pos">${d.earned}</b></span><span><span class="lb">Bought</span> <b class="neg">${d.bought}</b></span><b>${d.net}</b></div>${chips(d.items)}`,
		),
	).join("");

const profileM = () =>
	'<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px"><div class="av" data-bind-init="profile.name">S</div><div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em" data-bind="profile.name">Sami</div><div class="lb" data-bind="profile.email">sami@email.com</div></div></div>' +
	tg(
		"Total balance",
		`<div class="ow" style="margin:0"><b class="big2">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></div>`,
	) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);

const editM = () =>
	'<div style="display:flex;justify-content:center;margin:14px 0 0"><div class="av" data-bind-init="profile.name">S</div></div>' +
	tg(
		"Profile",
		`<form method="post" action="/profile/edit">${editFields()}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="/profile">Cancel</a></div></form>`,
	);

const settingsM = () =>
	tg("Appearance", themeSwitch()) +
	tg("Quick buys", quickEditor()) +
	tg("Money", fld("Currency", "MAD", { name: "currency", keep: "set.currency" })) +
	tg("Income & week", fld("Auto income runs at", "06:00", { name: "run_at", keep: "set.run_at" }) + fld("Week starts", "Monday", { name: "week", keep: "set.week" })) +
	tg(
		"Data",
		'<div style="display:flex;gap:10px"><button type="button" class="btn o" style="flex:1">Export CSV</button><button type="button" class="btn dng" style="flex:1">Delete account</button></div>',
	);

// ---------- shared desktop pieces ----------

const hero =
	'<div class="hero"><div><div class="lb">Earned today</div><div class="v pos">+184</div><div class="lb">Ad 64 · Tips 120</div></div><div><div class="lb">Bought today</div><div class="v neg">−<span data-bought>46</span></div><div class="lb"><span data-nbuys>4</span> buys</div></div><div><div class="lb">Road to goals</div><div class="v">46%</div><div class="mt"><i style="width:46%"></i></div></div><div><div class="lb">I owe</div><div class="v neg">1,100</div><div class="lb">MAD + 3 cig</div></div></div>';

const quickD = () =>
	`<div data-qb><div class="qk4" data-qgrid>${QUICK.map(
		(k, i) =>
			`<button type="button" class="${i === 0 ? "on" : ""}" data-q="${k.n}" data-p="${k.p}"${k.n === "Other" ? ' data-o="1"' : ""}>${ic(k.i)}<span><b>${k.n}</b><small>${k.s}</small></span></button>`,
	).join("")}</div>` +
	'<form method="post" action="/buy" class="qrow" data-qp><input type="hidden" name="category" data-cat value="Smoke"><div data-labelwrap hidden style="width:140px"><div class="lb">What</div><input class="in" name="label" data-label autocomplete="off"></div><div><div class="lb">Quantity</div><div class="stp"><button type="button" data-step="-1">−</button><input class="in f" name="qty" data-qty value="3"><button type="button" data-step="1">+</button></div></div><div style="width:110px"><div class="lb">Price each</div><input class="in" name="price" data-price value="2"></div><div class="eq neg" data-tot data-pre="= ">= −6</div><button class="btn" style="margin-left:auto">Add</button></form></div>';

const oweD = (open: boolean, key: string) =>
	`<details class="sc" data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">1,100 MAD + 3 cig</span>${chev}</span></summary>${
		dbt("Youssef", "800 MAD", 47, open) + dbt("Mom", "300 MAD", 50) + dbt("Amar", "3 cig", 0)
	}</details>`;

const noteD = () =>
	sec(
		"Note to yourself",
		'<span data-nnotes>3</span> saved',
		`<form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></form><div data-list="dash"><div class="rw"><span>Call Youssef about the 800 on Friday</span><span class="lb">09:02</span></div><div class="rw"><span>Bread 4 · Coffee 12 · Smoke 6</span><span class="lb">13:05</span></div></div>`,
	);

const wishD = () =>
	sec(
		"Wish list",
		"2 active",
		[
			["Laptop", "3,600 left of 6,000", 40],
			["Phone", "500 left of 1,500", 67],
		]
			.map(
				([n, l, p]) =>
					`<div class="wr"><div style="flex:1"><div class="l1"><b>${n}</b><span class="lb">${l}</span></div><div class="mt"><i style="width:${p}%"></i></div></div><button type="button" class="btn xs">Save 100</button></div>`,
			)
			.join("") +
			'<form method="post" action="/plan" class="ln" style="margin-top:18px"><input class="in" name="name" placeholder="New wish"><input class="in" name="price" style="width:120px" placeholder="Price"><button class="btn xs">Add</button></form>',
	);

const incD = (title = "Income sources", right = "+184 today") =>
	sec(
		title,
		right,
		srcRows +
			'<form method="post" action="/plan" class="ln" style="margin-top:18px"><input class="in" name="name" placeholder="New source"><input class="in" name="amount" style="width:100px" placeholder="Amount"><button class="btn xs">Add</button></form><div class="chips"><span class="chip on">Manual</span><span class="chip">Auto daily</span><span class="chip">Monthly</span></div>',
	);

const histD = () =>
	sec(
		"Last 7 days",
		"+356 earned · −519 bought",
		'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
			H.map((d) => `<div class="tr"><b>${d.d}</b><b class="pos">${d.earned}</b><b class="neg">${d.bought}</b><b>${d.net}</b>${chips(d.items)}</div>`).join(""),
	);

const dashboardD = () =>
	hero +
	`<div class="g2"><div>${sec("Quick buy", "tap, set quantity and price", quickD())}${sec("Today's buys", '<span data-nbuys>4</span>', buyRows)}</div><div>${oweD(false, "owe")}${incD("Income today")}${noteD()}</div></div>`;

const debtsD = () =>
	'<div class="hd"><h1 class="t">Debts</h1><span class="lb">1,100 MAD + 3 cig</span></div>' +
	`<div class="g3"><div>${oweD(true, "owe-page")}</div><div>${sec("Add", "new person or more to a name", newPerson.replace('<div class="sub">New person</div>', ""))}${sec(
		"How it works",
		"",
		'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings him back</span></div>',
	)}</div></div>`;

const notesD = () =>
	`<div class="chat" data-x>${chatHead}${chatBody("d", true)}<div style="margin:30px 0 0">${composer("d")}</div></div>`;

const planD = () => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${wishD()}</div><div>${incD()}</div></div>`;

const historyD = () => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 7 days</span></div>${histD()}`;

const settingsD = () =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	`<form method="post" action="/settings" class="g3"><div>${sec(
		"Profile",
		"",
		editFields() + '<div style="display:flex;gap:10px;margin-top:20px"><button class="btn">Save</button><a class="btn o" href="/home">Cancel</a></div>',
	)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Quick buys", "", quickEditor())}${sec(
		"Data",
		"",
		'<div style="display:flex;gap:10px;margin-top:6px"><button type="button" class="btn o">Export CSV</button><button type="button" class="btn dng">Delete account</button></div>',
	)}</div></form>`;

const splitD = (up: boolean) =>
	`<div class="split"><div class="sl"><div style="font-weight:600">moneytracker</div><h2>Quiet<br>money.</h2><div class="lb" style="color:inherit;opacity:.6">earned · bought · owed · saved</div></div><div class="sr">${auth(up, true)}</div></div>`;

// ---------- pages ----------

export const loginPage = () => page({ title: "Sign in", user: false, full: true, mobile: auth(false, false), desktop: splitD(false) });
export const signupPage = () => page({ title: "Sign up", user: false, full: true, mobile: auth(true, false), desktop: splitD(true) });

export const homePage = () =>
	page({
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobile: hd("Today", "Tue 13 Oct") + oweM(false, "owe") + cardsM() + tg("Income sources", srcRows) + quickM() + tg('Today\'s buys · <span data-nbuys>4</span>', buyRows),
		desktop: dashboardD(),
	});

export const debtsPage = () =>
	page({ title: "Debts", mobileTab: "home", desktopTab: "home", mobile: hd("Debts", "Youssef + Mom") + goalM() + oweM(true, "owe-page"), desktop: debtsD() });

export const notesPage = () =>
	page({
		title: "Notes",
		mobileTab: "notes",
		desktopTab: "notes",
		mobile: chatHead + chatBody("m", true),
		dock: composer("m"),
		desktop: notesD(),
	});

export const goalsPage = () =>
	page({ title: "Goals", mobileTab: "goals", desktopTab: "plan", mobile: hd("Goals", "wishes + debts") + goalM() + wishesM() + debtsM(), desktop: planD() });

export const incomePage = () =>
	page({ title: "Income", mobileTab: "home", desktopTab: "plan", mobile: hd("Income", "+184 today") + incomeM(), desktop: planD() });

export const historyPage = () =>
	page({ title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 7 days") + histM(), desktop: historyD() });

export const profilePage = () => page({ title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(), desktop: settingsD() });
export const profileEditPage = () => page({ title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(), desktop: settingsD() });
export const settingsPage = () => page({ title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(), desktop: settingsD() });
