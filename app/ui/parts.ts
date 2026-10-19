/** Small HTML builders shared by every screen. Everything is static sample markup. */

const P: Record<string, string> = {
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
	moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
	Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
	Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
	Other: '<path d="M12 5v14M5 12h14"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
};

export const ic = (k: string) => `<svg class="ic" viewBox="0 0 24 24">${P[k] ?? ""}</svg>`;

export const GOOGLE =
	'<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>';

const GOAT =
	'<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/></svg>';

export const logo = (href: string) => `<a class="logo" href="${href}">${GOAT}<span>moneytracker</span></a>`;

export const themeBtn = `<button type="button" class="ib" data-theme-toggle aria-label="Theme"><svg class="ic t-sun" viewBox="0 0 24 24">${P.sun}</svg><svg class="ic t-moon" viewBox="0 0 24 24">${P.moon}</svg></button>`;

// ---------- building blocks ----------

export const tg = (t: string, b: string) => `<div class="cd"><div class="tg">${t}</div><div class="cb">${b}</div></div>`;

export const sec = (t: string, r: string, b: string) =>
	`<div class="sc"><div class="sh"><span>${t}</span><span class="lb">${r}</span></div>${b}</div>`;

type FieldOpts = { name?: string; t?: string; p?: string; f?: boolean };
export const fld = (label: string, value: string, o: FieldOpts = {}) =>
	`<div class="fl"><label>${label}</label><input class="in${o.f ? " f" : ""}"${o.name ? ` name="${o.name}"` : ""}${
		o.t ? ` type="${o.t}"` : ""
	} value="${value}"${value ? "" : ` placeholder="${o.p ?? ""}"`} autocomplete="off"></div>`;

export const hd = (t: string, r: string, back?: string) =>
	`<div class="hd">${
		back ? `<a class="back" href="${back}">${ic("back")}<h1 class="t">${t}</h1></a>` : `<h1 class="t">${t}</h1>`
	}<span class="lb">${r}</span></div>`;

export const chips = (a: string[]) => `<div class="chips" style="margin:0">${a.map((i) => `<span class="chip">${i}</span>`).join("")}</div>`;

export const by = (n: string, s: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${s}</div></div><b class="neg">${a}</b></div>`;

/** A person I owe. The "+" button opens the add panel under the row. */
export const dbt = (n: string, l: string, p: number, add?: boolean) =>
	`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${n}">${ic("plus")}</button><div class="dn"><div class="l1"><b>${n}</b><span class="neg">${l}</span></div><div class="mt s n"><i style="width:${p}%"></i></div></div><button type="button" class="btn xs o">Pay</button></div>` +
	`<form method="post" action="/debts" class="ad"${add ? "" : " hidden"}><label>Add to ${n}</label><div class="ln"><input class="in f" name="amount" value="200"><span class="mu">MAD</span><button class="btn xs">Add</button></div><div class="lb">800 → 1,000 MAD · same person, no new row</div></form></div>`;

export const newPerson =
	'<div class="sub">New person</div><form method="post" action="/debts" class="ln3"><input class="in" name="name" placeholder="Name"><input class="in n3" name="cig" placeholder="3"><input class="in n3" name="cur" value="MAD"><button class="btn xs">Add</button></form><div class="lb" style="margin-top:10px">Cleared: Karim (hidden). Type his name to bring him back.</div>';

export const buyRows =
	by("Paid Youssef", "13:40", "−24") + by("Bread", "13:00", "−4") + by("Smoke ×3", "09:30 · 3 × 2", "−6") + by("Coffee", "08:10", "−12");

export const srcRows =
	'<div class="rw"><div><div>Ad revenue</div><div class="lb">auto · every day 06:00</div></div><b class="pos">+64</b></div><div class="rw"><div><div>Tips</div><div class="lb">manual · added today</div></div><button type="button" class="btn xs o" style="opacity:.5">Add 120</button></div><div class="rw"><div><div>Salary</div><div class="lb">monthly · Nov 1</div></div><b class="pos">+8,000</b></div>';

// ---------- notes ----------

const acts = (show: boolean) =>
	`<div class="acts"${show ? "" : " hidden"}><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button><button type="button" class="btn xs dng" data-act="del">Delete</button></div>`;

const bub = (t: string, tm: string, sel = false, ed = false) =>
	`<div class="msg"><div class="bub${sel ? " sel" : ""}">${t}</div><div class="meta">${ed ? "edited · " : ""}${tm}</div>${acts(sel)}</div>`;

export const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';

export const chatBody = (key: string, sel: boolean) =>
	`<div data-list="${key}"><div class="day"><span>Yesterday</span></div>${bub('Laptop: Lenovo 15"\n6,000 MAD — wait for Black Friday', "21:14")}<div class="day"><span>Today</span></div>${bub(
		"Call Youssef about the 800 on Friday",
		"09:02",
		sel,
	)}${bub("Bread 4 · Coffee 12 · Smoke 6", "13:05", false, true)}</div>`;

export const composer = (key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes"><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;

// ---------- history ----------

export type Day = { d: string; earned: string; bought: string; items: string[]; net: string };
export const H: Day[] = [
	{ d: "Today", earned: "+184", bought: "−46", items: ["Coffee 12", "Smoke ×3 6", "Bread 4", "Paid Youssef 24"], net: "+138" },
	{ d: "Yesterday", earned: "+64", bought: "−210", items: ["Groceries 150", "Taxi 28", "Smoke 20", "Coffee 12"], net: "−146" },
	{ d: "Sat 10 Oct", earned: "+64", bought: "−95", items: ["Lunch 60", "Smoke 20", "Coffee 11", "Bread 4"], net: "−31" },
	{ d: "Fri 9 Oct", earned: "+230", bought: "−38", items: ["Coffee 12", "Smoke 20", "Bread 6"], net: "+192" },
	{ d: "Thu 8 Oct", earned: "+64", bought: "−130", items: ["Phone credit 100", "Smoke 20", "Bread 10"], net: "−66" },
];

// ---------- settings ----------

export const editFields = () =>
	fld("Name", "Sami", { f: true, name: "name" }) +
	fld("Email", "sami@email.com", { t: "email", name: "email" }) +
	fld("Phone", "+212 6 00 00 00 00", { t: "tel", name: "phone" }) +
	fld("Bio", "Saving for the laptop", { name: "bio" });

export const themeSwitch = () =>
	`<div class="sg"><button type="button" data-set-theme="dark">${ic("moon")}Dark</button><button type="button" data-set-theme="light">${ic("sun")}White</button></div><div class="lb" style="margin-top:8px">Also the sun/moon button, top right.</div>`;

export const priceFields =
	'<div class="ln3"><div class="fl" style="margin:0;flex:1"><label>Smoke</label><input class="in" name="p_smoke" value="2"></div><div class="fl" style="margin:0;flex:1"><label>Coffee</label><input class="in" name="p_coffee" value="12"></div><div class="fl" style="margin:0;flex:1"><label>Bread</label><input class="in" name="p_bread" value="4"></div></div>';

// ---------- auth form ----------

/** Sign in / sign up. Submitting just goes to the dashboard: no session, no cookie. */
export const auth = (up: boolean, wide: boolean) =>
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">${wide ? "" : '<div style="height:22px"></div>'}<h1 class="t" style="margin-bottom:20px">${
		up ? "Sign up" : "Sign in"
	}</h1><a class="gbtn" href="/home">${GOOGLE}${up ? "Sign up with Google" : "Continue with Google"}</a><div class="or">or</div>${
		up ? fld("Name", "", { name: "name", p: "Your name" }) : ""
	}${fld("Email", "", { t: "email", name: "email", p: "you@email.com" })}${fld("Password", "", {
		t: "password",
		name: "password",
		p: "••••••••",
	})}<button class="btn full">${up ? "Create account" : "Sign in"}</button><div style="display:flex;justify-content:space-between;margin-top:16px"><a class="lnk" href="${
		up ? "/login" : "/signup"
	}">${up ? "I have an account" : "Create account"}</a>${up ? "" : '<a class="lnk" href="/login">Forgot password?</a>'}</div></form>`;
