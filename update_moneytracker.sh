#!/bin/bash
set -e
[ -d app/ui ] && [ -d app/pages ] && [ -f app/routes.ts ] || { echo "Run this inside the Moneytracker-main folder"; exit 1; }
trap 'rm -rf .mt_patch' EXIT
rm -rf .mt_patch && mkdir .mt_patch

cat > .mt_patch/people.txt << 'MT_EOF'
const nameChips = (names: string[]) =>
	names.length ? `<div class="chips nm">${names.map((n) => `<span class="chip" data-nm="${esc(n)}">${esc(n)}</span>`).join("")}</div>` : "";

const bigAdd = (label: string) => `<button type="button" class="addb" data-bigadd aria-label="${label}">${ic("plus")}</button>`;

const addDebtPanel = (s: State) =>
	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

MT_EOF

cat > .mt_patch/owe.txt << 'MT_EOF'
const oweM = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="cd bgc">${bigAdd("Add debt")}<div class="ct"><details class="dd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">I owe</div><div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>${chev}</summary><div class="cb">${debtList(s)}</div></details>${addDebtPanel(s)}</div></div>`;
};

const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<div class="sc bgc">${bigAdd("Add debt")}<div class="ct"><details data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>${addDebtPanel(s)}</div></div>`;
};

MT_EOF

cat > .mt_patch/wish.txt << 'MT_EOF'
const addWishPanel = (s: State) =>
	`<form method="post" action="/goals" class="sf adp" data-adp hidden>${back(s)}<input class="in" name="name" data-name placeholder="What do you want?" autocomplete="off" required><input class="in" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

const boughtBtn = (s: State, g: Goal) =>
	`<form method="post" action="/goals/buy" style="display:contents" data-confirm="Mark ${esc(g.title)} as bought? It will be added as a spend.">${back(s)}<input type="hidden" name="id" value="${g.id}"><button class="btn xs o">Bought</button></form>`;

const wishesM = (s: State) =>
	`<div class="cd bgc">${bigAdd("Add wish")}<div class="ct"><div class="tg">Wish list</div><div class="cb">${
		s.goals
			.map(
				(g) =>
					`<div class="wi"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt"><i style="width:${pctOf(g)}%"></i></div><div class="wa">${saveBtn(s, g)}${boughtBtn(s, g)}</div></div>`,
			)
			.join("") || '<div class="lb" style="padding:8px 0">Nothing on the list.</div>'
	}</div>${addWishPanel(s)}</div></div>`;

const wishD = (s: State) =>
	`<div class="sc bgc">${bigAdd("Add wish")}<div class="ct"><div class="sh"><span>Wish list</span><span class="lb">${s.goals.filter((g) => !g.done).length} active</span></div>${
		s.goals
			.map(
				(g) =>
					`<div class="wr"><div style="flex:1"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt"><i style="width:${pctOf(g)}%"></i></div></div>${saveBtn(s, g)}${boughtBtn(s, g)}</div>`,
			)
			.join("") || '<div class="lb" style="padding:14px 0">Nothing on the list.</div>'
	}${addWishPanel(s)}</div></div>`;

MT_EOF

cat > .mt_patch/spend.txt << 'MT_EOF'
const spendForm = (s: State) =>
	`<form method="post" action="/buy" class="sf" data-sp>${back(s)}${nameChips(s.names)}<input class="in" name="label" data-name placeholder="What did you buy?" autocomplete="off" required><input class="in" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;

const quickM = (s: State) => tg("Add a spend", spendForm(s));

MT_EOF

cat > .mt_patch/css.txt << 'MT_EOF'
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
details.dd>summary{padding:14px 16px;display:block;position:relative}
details.dd[open]>summary{padding-bottom:4px}
details.dd>.cb{padding-top:6px}
details.dd .chev{position:absolute;right:16px;top:14px}
.sc.bgc summary.sh{cursor:pointer}
.wi{padding:12px 0;border-top:1px solid var(--ln)}
.wi:first-child{border-top:0;padding-top:0}
.wa{display:flex;gap:8px;justify-content:flex-end;align-items:center;margin-top:10px}
MT_EOF

cat > .mt_patch/script.txt << 'MT_EOF'
  if((q=t.closest('[data-nm]'))){
    var nf=q.closest('form'),nin=nf.querySelector('[data-name]'),pin=nf.querySelector('[data-price]');
    nin.value=q.getAttribute('data-nm');
    if(pin)pin.focus();
    return
  }
  if((q=t.closest('[data-bigadd]'))){
    var ap=q.closest('.bgc').querySelector('[data-adp]');
    ap.hidden=!ap.hidden;
    q.classList.toggle('on',!ap.hidden);
    if(!ap.hidden){var ai=ap.querySelector('[data-name]');if(ai)ai.focus()}
    return
  }
MT_EOF

cat > .mt_patch/names.txt << 'MT_EOF'
if (need.has("names"))
jobs.push(
db
.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null group by lower(name) order by c desc, max(created_at) desc`)
.then((r) => void (s.names = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
);

MT_EOF

cat > .mt_patch/balance.txt << 'MT_EOF'
export async function balanceOf(uid: string): Promise<number> {
const [i, p] = await Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]);
return scalar(i) - scalar(p);
}

MT_EOF

cat > .mt_patch/addbuy.txt << 'MT_EOF'
export async function addBuy(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("label"), 120) || text(f.get("category"), 60) || "Other";
const qty = count(f.get("qty")) || 1;
const unit = toMinor(f.get("price"));
if (!unit) return;
const total = unit * qty;
const bal = await balanceOf(uid);
if (total > bal) return `Not enough balance. You have ${fmt(bal)}`;
await db.create(purchases, { id: id(), user_id: uid, name, qty, unit_minor: unit, total_minor: total, day: today(), created_at: Date.now() });
}

MT_EOF

cat > .mt_patch/buywish.txt << 'MT_EOF'
export async function buyWish(uid: string, f: FormData): Promise<string | void> {
const g = await db.findOne(goals, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!g) return;
const price = g.target_minor || g.saved_minor;
if (price > 0) {
const bal = await balanceOf(uid);
if (price > bal) return `Not enough balance for ${g.title}. You have ${fmt(bal)}`;
}
await db.transaction(async (tx) => {
if (price > 0) await tx.create(purchases, { id: id(), user_id: uid, name: g.title, qty: 1, unit_minor: price, total_minor: price, day: today(), created_at: Date.now() });
await tx.exec(sql`delete from goals where id = ${g.id} and user_id = ${uid}`);
});
}

MT_EOF

cat > .mt_patch/attempt.txt << 'MT_EOF'
const attempt =
	(fallback: string, run: (user: User, f: FormData) => Promise<string | void>) =>
	async (ctx: Ctx) => {
		const user = userOf(ctx);
		if (!user) return go("/login");
		const f = formOf(ctx);
		const to = backTo(f, fallback);
		const error = await run(user, f);
		return error ? fail(ctx, to, error) : go(to);
	};

MT_EOF

cat > .mt_patch/run.cjs << 'MT_EOF'
const fs = require("fs");
const path = require("path");
const root = process.cwd();
const dir = path.join(root, ".mt_patch");
const files = {};
const orig = {};
const get = (f) => {
	if (!(f in files)) {
		orig[f] = fs.readFileSync(path.join(root, f), "utf8");
		files[f] = orig[f];
	}
	return files[f];
};
const pl = (n) => fs.readFileSync(path.join(dir, n), "utf8");
const once = (s, a, f) => {
	const i = s.indexOf(a);
	if (i < 0 || s.indexOf(a, i + 1) >= 0) throw new Error(f + ": no unique match for: " + a.slice(0, 70));
	return i;
};
const rep = (f, a, b) => {
	const s = get(f);
	const i = once(s, a, f);
	files[f] = s.slice(0, i) + b + s.slice(i + a.length);
};
const cut = (f, a, z, b) => {
	const s = get(f);
	const i = once(s, a, f);
	const j = s.indexOf(z, i + a.length);
	if (j < 0) throw new Error(f + ": end marker not found: " + z);
	files[f] = s.slice(0, i) + b + s.slice(j);
};

const SC = "app/pages/screens.ts";
const CT = "app/actions/controller.tsx";
const AC = "app/lib/actions.ts";
const DT = "app/lib/data.ts";
const JS = "app/ui/script.ts";
const CS = "app/ui/css.ts";
const RT = "app/routes.ts";

try {
	if (get(CS).includes(".addb{")) throw new Error("Already applied");

	rep(RT, 'saveGoal: post("/goals/save"),', 'saveGoal: post("/goals/save"),\n\tbuyWish: post("/goals/buy"),');

	rep(DT, '"balance" | "avatar";', '"balance" | "avatar" | "names";');
	rep(DT, "quick: Quick[];", "quick: Quick[];\nnames: string[];");
	rep(DT, "quick: [],", "quick: [],\nnames: [],");
	rep(DT, 'if (need.has("debts")) jobs.push(', pl("names.txt") + 'if (need.has("debts")) jobs.push(');
	rep(DT, "/** Loads only the parts a page needs, in parallel. */", pl("balance.txt") + "/** Loads only the parts a page needs, in parallel. */");

	rep(AC, 'import { fmt, toMinor } from "./money.ts";', 'import { balanceOf } from "./data.ts";\nimport { fmt, toMinor } from "./money.ts";');
	cut(AC, "export async function addBuy(", "// ---------- debts ----------", pl("addbuy.txt"));
	rep(AC, "// ---------- income ----------", pl("buywish.txt") + "// ---------- income ----------");

	rep(CT, "function fail(", pl("attempt.txt") + "function fail(");
	rep(CT, '["today", "sources", "quick", "debts", "goals", "notes"]', '["today", "sources", "names", "debts", "goals", "notes"]');
	rep(CT, '["avatar", "balance", "quick"]', '["avatar", "balance"]');
	rep(CT, '["avatar", "quick"], profileEditPage', '["avatar"], profileEditPage');
	rep(CT, 'view("/settings", ["quick"], settingsPage)', 'view("/settings", [], settingsPage)');
	rep(CT, 'buy: mutate("/home", (u, f) => act.addBuy(u.id, f)),', 'buy: attempt("/home", (u, f) => act.addBuy(u.id, f)),');
	rep(CT, 'saveGoal: mutate("/goals", (u, f) => act.saveToGoal(u.id, f)),', 'saveGoal: mutate("/goals", (u, f) => act.saveToGoal(u.id, f)),\n\t\tbuyWish: attempt("/goals", (u, f) => act.buyWish(u.id, f)),');

	rep(SC, 'import { chips, fld, hd, ic, ICON_KEYS, sec, tg, themeSwitch } from "../ui/parts.ts";', 'import { chips, fld, hd, ic, sec, tg, themeSwitch } from "../ui/parts.ts";');
	cut(SC, "const newPerson = ", "const owePair = ", pl("people.txt"));
	cut(SC, "const oweM = ", "const goalM = ", pl("owe.txt"));
	cut(SC, "const newWish = ", "const debtsM = ", pl("wish.txt"));
	cut(SC, "const quickBtns = ", "const hero = ", pl("spend.txt"));
	cut(SC, "const quickEditor = ", "const prefsForm = ", "");
	rep(SC, 'tg("Quick buys", quickEditor(s)) +\n\t', "");
	rep(SC, '${sec("Quick buys", "", quickEditor(s))}', "");
	rep(SC, '${sec("Quick buy", "tap, set quantity and price", quickD(s))}', '${sec("Add a spend", "", spendForm(s))}');
	rep(SC, `\${sec("Add", "new person or more to a name", newPerson(s).replace('<div class="sub">New person</div>', ""))}`, "");
	rep(SC, "mobile: cardsM(s) + tgp(", "mobile: err(s) + cardsM(s) + tgp(");
	rep(SC, "desktop: dashboardD(s),", "desktop: err(s) + dashboardD(s),");
	rep(SC, 'mobile: hd("Debts",', 'mobile: err(s) + hd("Debts",');
	rep(SC, "desktop: debtsD(s),", "desktop: err(s) + debtsD(s),");
	rep(SC, 'mobile: hd("Goals", "wishes + debts") + goalM(s)', 'mobile: hd("Goals", "wishes + debts") + err(s) + goalM(s)');
	rep(SC, "wishesM(s) + debtsM(s), desktop: planD(s) });", "wishesM(s) + debtsM(s), desktop: err(s) + planD(s) });");

	rep(JS, "var qf=d.querySelector('.mm [data-qp]');", "var qf=d.querySelector('.mm [data-sp]');");
	rep(JS, "var pi=qf.querySelector('[data-price]');if(pi)pi.focus();", "var pi=qf.querySelector('[data-name]');if(pi)pi.focus();");
	rep(JS, "  if((q=t.closest('[data-q]'))){pick(q,false);return}", pl("script.txt") + "  if((q=t.closest('[data-q]'))){pick(q,false);return}");

	rep(CS, ".qadd .in{font-size:14px;padding:8px 12px}\n", ".qadd .in{font-size:14px;padding:8px 12px}\n" + pl("css.txt"));

	const bk = path.join(root, ".mt_backup");
	for (const f of Object.keys(files)) {
		const b = path.join(bk, f);
		fs.mkdirSync(path.dirname(b), { recursive: true });
		fs.writeFileSync(b, orig[f]);
	}
	for (const f of Object.keys(files)) fs.writeFileSync(path.join(root, f), files[f]);
	console.log("Done. Changed " + Object.keys(files).length + " files. Originals saved in .mt_backup/");
} catch (e) {
	console.error("Nothing was changed: " + e.message);
	process.exit(1);
}
MT_EOF

node .mt_patch/run.cjs
