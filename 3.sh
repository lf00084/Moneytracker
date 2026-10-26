#!/bin/bash
set -e
cd "$(dirname "$0")"
for f in app/lib/users.ts app/lib/time.ts app/screens.tsx app/client/app.css scripts/migrate.ts; do [ -f "$f" ] || { echo "run this inside the Moneytracker folder (missing $f)"; exit 1; }; done
if ! grep -q "day_start" app/lib/users.ts; then
T=$(mktemp -d)
trap "rm -rf $T" EXIT
mkdir -p "$T/p"
cp -r app scripts database "$T/p/"
cat > "$T/patch.js" << 'PATCH_EOF'
const fs = require("fs")
const rep = (file, from, to, n = 1) => {
	const src = fs.readFileSync(file, "utf8")
	const parts = src.split(from)
	if (parts.length - 1 !== n) {
		console.error(`patch failed in ${file}: expected ${n} match(es) for:\n${from}\nfound ${parts.length - 1}`)
		process.exit(1)
	}
	fs.writeFileSync(file, parts.join(to))
}

rep("app/lib/time.ts", "export const dayOf = (ms: number) => dayFmt.format(ms)", "export const dayOf = (ms: number, h = 0) => dayFmt.format(ms - h * 3600000)")
rep("app/lib/time.ts", "export const today = () => dayOf(Date.now())", "export const today = (h = 0) => dayOf(Date.now(), h)")
rep("app/lib/time.ts", "export const hhmm = (ms: number) => timeFmt.format(ms)", "export const hhmm = (ms: number, h = 0) => timeFmt.format(ms - h * 3600000)")
rep("app/lib/time.ts", "export function dayLabel(day: string) {\n\tconst t = today()\n", "export function dayLabel(day: string, t = today()) {\n")

rep("app/lib/users.ts", 'import { id } from "./util.ts"\n', 'import { today } from "./time.ts"\nimport { id } from "./util.ts"\n')
rep("app/lib/users.ts", "\trun_at: string\n\tweek_start: string\n\tusd_rate_minor: number", "\trun_at: string\n\tday_start: number\n\tweek_start: string\n\tusd_rate_minor: number")
rep("app/lib/users.ts", '\trun_at: r.run_at || "06:00",\n\tweek_start: r.week_start || "Monday",', '\trun_at: r.run_at || "06:00",\n\tday_start: Number.isInteger(r.day_start) && r.day_start >= 0 && r.day_start <= 23 ? r.day_start : 17,\n\tweek_start: r.week_start || "Monday",')
rep("app/lib/users.ts", '\trun_at: "06:00",\n\tweek_start: "Monday",\n\tusdt_rate_minor: 1100,', '\trun_at: "06:00",\n\tday_start: 17,\n\tweek_start: "Monday",\n\tusdt_rate_minor: 1100,')
rep("app/lib/users.ts", "input: { currency: string; run_at: string; week_start: string;", "input: { currency: string; run_at: string; day_start: number; week_start: string;")
rep("app/lib/users.ts", '\t\tweek_start: input.week_start.trim().slice(0, 16) || "Monday",\n', '\t\tweek_start: input.week_start.trim().slice(0, 16) || "Monday",\n\t\t...(Number.isInteger(input.day_start) && input.day_start >= 0 && input.day_start <= 23 ? { day_start: input.day_start } : {}),\n')
fs.appendFileSync("app/lib/users.ts", '\nexport async function todayFor(userId: string) {\n\tconst row = await db.find(users, userId)\n\treturn today(row ? toUser(row).day_start : 17)\n}\n')

rep("app/db/tables.ts", "\t\trun_at: c.varchar(8),\n", "\t\trun_at: c.varchar(8),\n\t\tday_start: c.integer(),\n")
rep("scripts/migrate.ts", '\t"ALTER TABLE users ADD COLUMN week_start TEXT NOT NULL DEFAULT \'Monday\'",\n', '\t"ALTER TABLE users ADD COLUMN week_start TEXT NOT NULL DEFAULT \'Monday\'",\n\t"ALTER TABLE users ADD COLUMN day_start INTEGER NOT NULL DEFAULT 17",\n')
rep("app/commands.ts", 'run_at: field(f, "run_at"), week_start', 'run_at: field(f, "run_at"), day_start: parseInt(field(f, "day_start"), 10), week_start')

rep("app/lib/actions.ts", 'import { today } from "./time.ts"\n', 'import { todayFor } from "./users.ts"\n')
rep("app/lib/actions.ts", 'const pickDay = (f: FormData) => {\n\tconst d = text(f.get("day"), 10) || today()\n\treturn realDay(d) && d <= today() ? d : null\n}', 'const pickDay = (f: FormData, t: string) => {\n\tconst d = text(f.get("day"), 10) || t\n\treturn realDay(d) && d <= t ? d : null\n}')
rep("app/lib/actions.ts", "const day = pickDay(f)\n", "const day = pickDay(f, await todayFor(uid))\n", 2)
rep("app/lib/actions.ts", "\tconst now = Date.now()\n\tif (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: today(),", "\tconst now = Date.now()\n\tconst t = await todayFor(uid)\n\tif (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: t,")
rep("app/lib/actions.ts", 'total_minor: -diff, day: today(), created_at: now })', "total_minor: -diff, day: t, created_at: now })")
rep("app/lib/actions.ts", "\tconst purchaseId = id()\n\tconst now = Date.now()\n", "\tconst purchaseId = id()\n\tconst now = Date.now()\n\tconst t = await todayFor(uid)\n")
rep("app/lib/actions.ts", "total_minor: pay, day: today(), debt_id: d.id", "total_minor: pay, day: t, debt_id: d.id")
rep("app/lib/actions.ts", "\tif (!it || it.done_at) return\n\tconst bal = await balanceOf(uid)\n", "\tif (!it || it.done_at) return\n\tconst t = await todayFor(uid)\n\tconst bal = await balanceOf(uid)\n")
rep("app/lib/actions.ts", "total_minor: it.price_minor, day: today(), created_at: Date.now() })", "total_minor: it.price_minor, day: t, created_at: Date.now() })")
rep("app/lib/actions.ts", "\tconst day = today()\n\tconst key = extKey(s.id, day)", "\tconst day = await todayFor(uid)\n\tconst key = extKey(s.id, day)")

rep("app/lib/income.ts", 'import { today } from "./time.ts"\n', 'import { todayFor } from "./users.ts"\n')
rep("app/lib/income.ts", "ext_key: extKey(s.id, today()) }", "ext_key: extKey(s.id, await todayFor(uid)) }")
rep("app/lib/income.ts", "amount_minor: amount, day: today(), created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: \"\" })\n}", "amount_minor: amount, day: await todayFor(uid), created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: \"\" })\n}")

rep("app/lib/trading.ts", 'import { today } from "./time.ts"\n', 'import { today } from "./time.ts"\nimport { todayFor } from "./users.ts"\n')
rep("app/lib/trading.ts", "\tconst day = today()\n\tconst sessionId = id()", "\tconst day = today(user.day_start)\n\tconst sessionId = id()")
rep("app/lib/trading.ts", '\tconst now = Date.now()\n\tconst incomeId = mad > 0 ? id() : ""\n', '\tconst now = Date.now()\n\tconst t = await todayFor(uid)\n\tconst incomeId = mad > 0 ? id() : ""\n')
rep("app/lib/trading.ts", "\t\t\t\tday: today(),\n\t\t\t\tcreated_at: now,\n\t\t\t\tmeta: JSON.stringify({ trade: 1", "\t\t\t\tday: t,\n\t\t\t\tcreated_at: now,\n\t\t\t\tmeta: JSON.stringify({ trade: 1")

rep("app/lib/data.ts", "\tconst t = today()\n\tconst s: State = {", "\tconst t = today(user.day_start)\n\tconst s: State = {")
rep("app/lib/data.ts", "label: dayLabel(day),", "label: dayLabel(day, t),")
rep("app/components/history.tsx", "\tconst t = today()\n", "\tconst t = today(s.user.day_start)\n")

rep("app/lib/auto.ts", "const lastDayOf = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).getUTCDate()\n", "const lastDayOf = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).getUTCDate()\n\nconst shiftHm = (v: string, h: number) => {\n\tconst m = ((((Number(v.slice(0, 2)) * 60 + Number(v.slice(3, 5)) - h * 60) % 1440) + 1440) % 1440)\n\treturn `${pad(Math.floor(m / 60))}:${pad(m % 60)}`\n}\n")
rep("app/lib/auto.ts", "\tconst runAt = hm(u?.run_at)\n\tconst now = Date.now()\n\tconst t = today()\n\tconst nowHm = hhmm(now)\n", "\tconst h = u && Number.isInteger(u.day_start) && u.day_start >= 0 && u.day_start <= 23 ? u.day_start : 17\n\tconst runAt = shiftHm(hm(u?.run_at), h)\n\tconst now = Date.now()\n\tconst t = today(h)\n\tconst nowHm = hhmm(now, h)\n")
rep("app/lib/auto.ts", "const created = dayOf(s.created_at)\n\t\tconst createdHm = hhmm(s.created_at)\n", "const created = dayOf(s.created_at, h)\n\t\tconst createdHm = hhmm(s.created_at, h)\n")

rep("app/components/profile.tsx", '\t\t<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />\n', '\t\t<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />\n\t\t<div class="fl">\n\t\t\t<label>Day resets at</label>\n\t\t\t<select class="in" name="day_start" style={{ width: "100%" }}>\n\t\t\t\t{Array.from({ length: 24 }, (_, h) => (\n\t\t\t\t\t<option key={h} value={String(h)} selected={h === s.user.day_start ? true : undefined}>\n\t\t\t\t\t\t{String(h).padStart(2, "0")}:00\n\t\t\t\t\t</option>\n\t\t\t\t))}\n\t\t\t</select>\n\t\t</div>\n')

rep("app/routes.ts", '\t\tpad: get("/pad"),\n', '\t\tpad: get("/pad"),\n\t\tpadSaid: get("/pad/said"),\n\t\tpadHome: get("/pad/home"),\n\t\tpadNew: get("/pad/new"),\n')
rep("app/controllers/pages.tsx", '\t\tpad: page("/pad", [], (s) => <PadScreen s={s} />),\n', '\t\tpad: page("/pad", [], (s) => <PadScreen s={s} tab="projects" />),\n\t\tpadSaid: page("/pad/said", [], (s) => <PadScreen s={s} tab="said" />),\n\t\tpadHome: page("/pad/home", [], (s) => <PadScreen s={s} tab="home" />),\n\t\tpadNew: page("/pad/new", [], (s) => <PadScreen s={s} tab="new" />),\n')
rep("app/screens.tsx", 'import { BalanceCard,', 'import { PadBody, PadComposer, type PadTab } from "./components/pad.tsx"\nimport { BalanceCard,')
rep("app/screens.tsx", 'export const PadScreen = view<{ s: State }>(({ s }) => <AppLayout title="Pad" theme={s.user.theme} mobileTab="pad" desktopTab="pad" mobile={null} desktop={null} />)', 'export const PadScreen = view<{ s: State; tab: PadTab }>(({ s, tab }) => (\n\t<AppLayout\n\t\ttitle="Notes"\n\t\ttheme={s.user.theme}\n\t\tmobileTab="pad"\n\t\tdesktopTab="pad"\n\t\ttopLeft={<b class="nt-ttl">Notes</b>}\n\t\tmobile={<PadBody tab={tab} />}\n\t\tdock={<PadComposer tab={tab} />}\n\t\tdesktop={\n\t\t\t<>\n\t\t\t\t<PadBody tab={tab} />\n\t\t\t\t<PadComposer tab={tab} />\n\t\t\t</>\n\t\t}\n\t/>\n))')
rep("app/components/ui.tsx", "\tback: '<path d=\"M15 5l-7 7 7 7\"/>',\n", "\tback: '<path d=\"M15 5l-7 7 7 7\"/>',\n\tcheck: '<path d=\"m5 12 5 5 9-10\"/>',\n")
rep("app/components/layout.tsx", '\t{ key: "home", label: "Home", icon: "home", href: "/home" },\n\t{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },\n\t{ key: "income", label: "Income", icon: "gear", href: "/income" },\n\t{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },\n\t{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },\n\t{ key: "profile", label: "Profile", icon: "user", href: "/profile" },\n', '\t{ key: "home", label: "Home", icon: "nhome", href: "/home" },\n\t{ key: "trading", label: "Trading", icon: "ntrade", href: "/trading" },\n\t{ key: "pad", label: "Notes", icon: "npad", href: "/pad" },\n\t{ key: "income", label: "Sources", icon: "nsun", href: "/income" },\n\t{ key: "notes", label: "Message myself", icon: "nchat", href: "/notes" },\n\t{ key: "profile", label: "Profile", icon: "nuser", href: "/profile" },\n')
rep("app/components/layout.tsx", '{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },\n\t{ key: "plan"', '{ key: "notes", label: "Message myself", icon: "notes", href: "/notes" },\n\t{ key: "plan"')
rep("app/components/layout.tsx", '{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },\n\t{ key: "history"', '{ key: "pad", label: "Notes", icon: "pad", href: "/pad" },\n\t{ key: "history"')

rep("app/client/app.css", ".bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:var(--rc) var(--rc) 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}\n.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}\n.bt svg.ic{position:relative;width:26px;height:26px}\n.bt a.on::before{content:\"\";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}\n.bt .on{color:var(--ac)}\n.bt .on svg.ic{stroke-width:2}\n", ".bt{display:flex;align-items:center;justify-content:space-around;height:64px;padding:0 10px env(safe-area-inset-bottom,0px);border-top:1px solid var(--ln);background:var(--s1);box-shadow:none;border-radius:0;box-sizing:content-box}\n.bt a,.bt button{position:relative;flex:none;width:52px;height:42px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;border-radius:14px;padding:0}\n.bt svg.ic{position:relative;width:20px;height:20px;stroke-width:1.8}\n.bt a.on{width:58px;background:var(--acs);border:1px solid var(--acl)}\n.bt .on{color:var(--ac)}\n")
rep("app/client/app.css", ".dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}\n", ".dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}\n.mm>.cd .big2{font-size:24px}\n.mm .two .big2{font-size:20px}\n.mm .xbare .xb{padding:2px 14px}\n.hr{display:grid;grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;align-items:center;padding:9px 0}\n.hn{min-width:0;font-size:15px}\n.hr .ea{white-space:nowrap;text-align:right;font-size:15px}\n.hr .ub{width:32px;height:32px;border-radius:12px;background:var(--s2)}\n.hspan{grid-column:2/4;justify-self:end}\n.sw .ad{margin:0 0 10px}\n.hx{margin:0 0 8px;border:0;background:var(--s2);border-radius:14px}\n.hx>summary{min-height:38px;padding:5px 6px 5px 12px;justify-content:flex-start;gap:10px}\n.hx>summary>span:nth-child(2){margin-left:0;color:var(--mu)}\n.hx>summary .chev{margin-left:auto;width:28px;height:28px;border-radius:50%;background:var(--s1);align-items:center;justify-content:center}\n")

rep("app/components/ui.tsx", "\tback: ", "\tnhome: '<path d=\"m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z\"/><path d=\"M9 22V12h6v10\"/>',\n\tntrade: '<path d=\"m22 7-8.5 8.5-5-5L2 17\"/><path d=\"M16 7h6v6\"/>',\n\tnpad: '<path d=\"M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z\"/><path d=\"M14 2v6h6M8 13h8M8 17h8\"/>',\n\tnsun: '<circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41\"/>',\n\tnchat: '<path d=\"M7.9 20A9 9 0 1 0 4 16.1L2 22z\"/>',\n\tnuser: '<circle cx=\"12\" cy=\"8\" r=\"4\"/><path d=\"M4 21a8 8 0 0 1 16 0\"/>',\n\tback: ")
PATCH_EOF
(cd "$T/p" && node "$T/patch.js")
cp -r "$T/p/app/." app/
cp -r "$T/p/scripts/." scripts/
fi
cat > app/components/income.tsx << 'EOF'
import type { Income, Source, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { isFixed } from "../lib/util.ts"
import { calc, gotToday, srcAmount } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, view } from "./ui.tsx"

const contents = { display: "contents" }
const rateOf = (x: Source) => Number(x.config.rate_minor) || 0
const tagOf = (x: Source) => (!x.active ? "paused" : x.type === "exoclick" ? "exoclick" : isFixed(x.type) ? "fixed" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "daily") : "manual")
const usdTxt = (n: number) => `$${fmt(n)}`
const exoSub = (s: State, x: Source) => s.exo[x.id] || `${usdTxt(s.exoToday[x.id] ?? 0)} today`

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
))

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`incl. ${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">
				+{fmt(i.amount)} <small>{s.user.currency}</small>
			</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<button class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
))

const HoursPanel = view<{ s: State; x: Source; row: Income }>(({ s, x, row }) => {
	const rate = rateOf(x)
	const h = row.hours
	const cur = s.user.currency
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))} ${cur}` : `${fmt(rate)} ${cur} / hour`}</span>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hxb">
				<div class="hxg">
					{opts.map((n) => (
						<form key={n} method="post" action="/income/hours" style={contents}>
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input type="hidden" name="hours" value={String(n)} />
							<input type="hidden" name="toggle" value="1" />
							<button class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</button>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<button class="btn xs o">Set</button>
					<button type="button" class="btn xs o" data-close>
						Close
					</button>
				</form>
			</div>
		</details>
	)
})

const HomeAct = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const amt = (n: number) => (
		<b class="ea">
			+{fmt(n)} <small>{cur}</small>
		</b>
	)
	if (x.type === "exoclick") {
		return (
			<>
				{amt(sum)}
				<span></span>
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				{amt(x.amount)}
				<span></span>
			</>
		)
	}
	if (got.length) {
		return (
			<>
				{amt(sum)}
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</button>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan" data-tg>
			Add
		</button>
	)
})


const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
))

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const all = gotToday(s, x)
	const got = fixedSrc ? all[0] : undefined
	const cur = s.user.currency
	const exo = x.type === "exoclick"
	const sub = exo ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} ${cur} + ${fmt(rateOf(x))} / hour`) : ""
	const manual = !fixedSrc && !exo && x.mode !== "auto" && !all.length
	return (
		<div class="sw dbw" data-exo={exo ? "1" : undefined}>
			<div class="hr">
				<div class="hn">
					<div>{x.name}</div>
					{sub ? <div class={exo && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
					{exo && s.exo[x.id] ? (
						<a class="lnk" href="/income">
							Fix
						</a>
					) : null}
				</div>
				<HomeAct s={s} x={x} />
			</div>
			{manual ? (
				<form method="post" action="/income/add" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<div class="ln">
						<input class="in" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs">Add</button>
					</div>
				</form>
			) : null}
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	)
})

const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<button class="btn full">Add income</button>
	</>
))

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
	["exoclick", "ExoClick"],
]

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<input class="in" name="name" placeholder="Source name (e.g. Construction)" autocomplete="off" required />
		<input type="hidden" name="kind" value="fixed" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 8px" }}>
			{KINDS.map(([k, l]) => (
				<span key={k} class={k === "fixed" ? "chip on" : "chip"} data-mode={k} style={{ cursor: "pointer" }}>
					{l}
				</span>
			))}
		</div>
		<div class="kf kf-fixed">
			<div class="ln">
				<input class="in" name="fixed" placeholder="Per day" inputmode="decimal" autocomplete="off" />
				<input class="in" name="rate" placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
			</div>
			<div class="lb">Tap it once a day on Home, then pick the extra hours.</div>
		</div>
		<div class="kf kf-manual">
			<div class="lb">You type the amount yourself each day.</div>
		</div>
		<div class="kf kf-daily kf-monthly">
			<input class="in" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
			<div class="lb">Added for you automatically.</div>
		</div>
		<div class="kf kf-exoclick">
			<input class="in" name="api_key" type="password" placeholder="ExoClick API key" autocomplete="off" />
			<div class="lb">Saved encrypted. Counted in USD during the day, converted to {s.user.currency} when the day ends.</div>
		</div>
		<button class="btn full">Add source</button>
	</>
))

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-kind="fixed" data-adp hidden>
		<SourceFields s={s} />
	</form>
))

const TodayRows = view<{ s: State }>(({ s }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return sources.length || others.length ? (
		<>
			{sources.map((x) => (
				<HomeRow key={x.id} s={s} x={x} />
			))}
			{others.map((i) => (
				<IncomeRow key={i.id} s={s} i={i} />
			))}
		</>
	) : (
		<Empty>No sources yet. Add one on the Income page.</Empty>
	)
})

export const IncomeDesktop = view<{ s: State; title?: string; id?: string; bare?: boolean }>(({ s, title = "Income today", id = "f-inc-d", bare = false }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	if (bare) {
		return (
			<div class="sc incbare">
				<TodayRows s={s} />
			</div>
		)
	}
	return (
		<>
			<form method="post" action="/income/named" id={id} class="sc spf" data-adp hidden>
				<NamedFields s={s} />
			</form>
			<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add manual income">
				{sources.length || others.length ? (
					<>
						{sources.map((x) => (
							<HomeRow key={x.id} s={s} x={x} />
						))}
						{others.map((i) => (
							<IncomeRow key={i.id} s={s} i={i} />
						))}
					</>
				) : (
					<Empty>No sources yet. Add one on the Income page.</Empty>
				)}
			</ListCard>
		</>
	)
})

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : ""
	return (
		<div class="dbw" data-exo={x.type === "exoclick" ? "1" : undefined}>
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{tagOf(x)}</span>
					</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">{x.active ? "Pause" : "Resume"}</button>
					</form>
					<button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}>
						<Icon name="edit" />
					</button>
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			<form method="post" action="/income/edit" class="ad" data-addp hidden>
				<Hid s={s} id={x.id} />
				<label>Edit {x.name}</label>
				<input class="in f" name="name" value={x.name} autocomplete="off" required />
				{fixedSrc ? (
					<div class="ln" style={{ marginTop: "8px" }}>
						<input class="in" name="fixed" value={fixed ? plain(fixed) : ""} placeholder="Per day" inputmode="decimal" autocomplete="off" />
						<input class="in" name="rate" value={rateOf(x) ? plain(rateOf(x)) : ""} placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
					</div>
				) : null}
				{x.type === "exoclick" ? <input class="in" style={{ marginTop: "8px" }} name="api_key" type="password" placeholder="New API key (leave empty to keep)" autocomplete="off" /> : null}
				{!fixedSrc && x.type !== "exoclick" && x.mode === "auto" ? <input class="in" style={{ marginTop: "8px" }} name="amount" value={plain(x.amount)} placeholder="Amount" inputmode="decimal" autocomplete="off" /> : null}
				<button class="btn xs" style={{ marginTop: "10px" }}>
					Save
				</button>
			</form>
		</div>
	)
})

export const IncomeExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="income"
		open
		title="Income sources"
		label="Add source"
		head={
			<>
				<b class="big2">{s.sources.length}</b>
				<span class="lb">{`${s.sources.filter((x) => x.active).length} active`}</span>
			</>
		}
		form={<SourceForm s={s} />}
	>
		{s.sources.length ? <>{s.sources.map((x) => <ManageRow key={x.id} s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>}
	</ExpandCard>
))

export const HomeIncome = view<{ s: State }>(({ s }) => (
	<div class="xc xbare">
		<div class="xb">
			<TodayRows s={s} />
		</div>
	</div>
))
EOF
cat > app/components/pad.tsx << 'EOF'
import { Icon, view } from "./ui.tsx"

export type PadTab = "projects" | "said" | "home" | "new"

const SEG = [
	{ key: "projects", label: "Projects", href: "/pad" },
	{ key: "said", label: "Said", href: "/pad/said" },
	{ key: "home", label: "Home", href: "/pad/home" },
]

const Seg = view<{ tab: PadTab }>(({ tab }) => (
	<div class="nt-seg">
		{SEG.map((x) => (
			<a key={x.key} href={x.href} class={x.key === tab || (tab === "new" && x.key === "projects") ? "on" : ""}>
				{x.label}
			</a>
		))}
	</div>
))

const Filters = view<{ items: string[] }>(({ items }) => (
	<div class="nt-fl">
		{items.map((x, i) => (
			<span key={x} class={i === 0 ? "on" : ""}>
				{x}
			</span>
		))}
	</div>
))

const Item = view<{ kind: "task" | "note" | "done"; text: string; meta?: string }>(({ kind, text, meta }) => (
	<div class={kind === "done" ? "nt-it nt-done" : kind === "note" ? "nt-it nt-note" : "nt-it"}>
		{kind === "note" ? null : (
			<span class={kind === "done" ? "nt-ck ok" : "nt-ck"}>{kind === "done" ? <Icon name="check" /> : null}</span>
		)}
		<div>
			<p>{text}</p>
			{meta ? <div class="nt-m">{meta}</div> : null}
		</div>
	</div>
))

const Quote = view<{ text: string; name: string; src: string; tag: string; to: string }>(({ text, name, src, tag, to }) => (
	<div class="nt-q">
		<p>{text}</p>
		<div class="nt-who">
			<span class="nt-av">{name[0]}</span>
			<div>
				<b>{name}</b>
				<span class="nt-m">{src}</span>
			</div>
			<span class="nt-tag hi">{tag}</span>
		</div>
		<div class="nt-m" style={{ marginTop: "8px" }}>
			→ {to}
		</div>
	</div>
))

const Projects = view(() => (
	<>
		<div class="nt-pj">
			<span class="nt-pc on">
				Moneytracker <small>4</small>
			</span>
			<span class="nt-pc">
				Video site <small>7</small>
			</span>
			<span class="nt-pc">
				Library <small>2</small>
			</span>
			<a class="nt-pc" href="/pad/new">
				+ New
			</a>
		</div>
		<div class="nt-c nt-ph">
			<div class="nt-spread">
				<b>Moneytracker</b>
				<span class="nt-m">4 open · 8 done</span>
			</div>
			<div class="nt-bar2">
				<i></i>
			</div>
		</div>
		<Filters items={["All", "Tasks", "Notes"]} />
		<div class="nt-c nt-list">
			<Item kind="task" text="Collapse extra hours with arrow on the right" meta="today" />
			<Item kind="note" text="Balance stays in the normal flow, no floating." meta="note · 2h ago" />
			<Item kind="task" text="Custom source: tap Add to show the input" meta="today" />
			<Item kind="task" text="Deploy to Cloudflare preview" meta="Fri" />
			<Item kind="note" text="Phase 2: real DB after fake data is good." meta="note · yesterday" />
			<Item kind="done" text="Bottom bar without radius" />
			<Item kind="done" text="Revert icon in a fixed right slot" />
		</div>
	</>
))

const Said = view(() => (
	<>
		<Filters items={["All", "Tips", "Info"]} />
		<div class="nt-c nt-list">
			<Quote text="Save a part of every earning before you spend anything." name="Youssef" src="said in person · 2 days ago" tag="Tip" to="Moneytracker" />
			<Quote text="Check the payout threshold before expecting your first payment." name="Reda" src="WhatsApp · last week" tag="Info" to="Moneytracker" />
			<Quote text="Always test on a preview link before the real deploy." name="Imane" src="call · 3 weeks ago" tag="Tip" to="Library" />
			<Quote text="Keep thumbnails small, the grid loads much faster." name="Salma" src="WhatsApp · 1 month ago" tag="Tip" to="Video site" />
		</div>
	</>
))

const HomeTasks = view(() => (
	<>
		<div class="nt-c nt-ph">
			<div class="nt-spread">
				<b>Home</b>
				<span class="nt-m">3 of 7 done</span>
			</div>
			<div class="nt-bar2">
				<i style={{ width: "43%" }}></i>
			</div>
		</div>
		<div class="nt-gl">Today</div>
		<div class="nt-c nt-list">
			<Item kind="done" text="Buy bread and milk" />
			<Item kind="done" text="Wash the dishes" meta="daily" />
			<Item kind="task" text="Call the plumber about the tap" meta="today" />
			<Item kind="task" text="Pay the electricity bill" meta="Fri" />
		</div>
		<div class="nt-gl">This week</div>
		<div class="nt-c nt-list">
			<Item kind="task" text="Clean the room" meta="weekly · Sat" />
			<Item kind="task" text="Laundry" meta="weekly · Sun" />
			<Item kind="task" text="Fix the shelf" />
		</div>
	</>
))

const Opt = view<{ on?: boolean; title: string; sub: string; rows: ("o" | "x")[] }>(({ on, title, sub, rows }) => (
	<div class={on ? "nt-op on" : "nt-op"}>
		<span class="nt-pv">
			{rows.map((r, i) => (
				<div key={i} class="nt-pr2">
					{r === "o" ? <u></u> : null}
					<i></i>
				</div>
			))}
		</span>
		<div>
			<b>{title}</b>
			<span class="nt-ds">{sub}</span>
		</div>
		<span class="nt-rd"></span>
	</div>
))

const Sheet = view(() => (
	<>
		<a class="nt-ov" href="/pad" aria-label="Close"></a>
		<div class="nt-sht">
			<span class="nt-gr"></span>
			<div class="nt-shh">
				<b>New project</b>
				<a class="nt-m" href="/pad">
					Cancel
				</a>
			</div>
			<div class="nt-fi">
				<span class="nt-m">Name</span>
				<b>Library website</b>
			</div>
			<div class="nt-cl">
				<i style={{ background: "#2f6f78" }}></i>
				<i style={{ background: "#6a4fd1" }}></i>
				<i class="on" style={{ background: "#8a5a00" }}></i>
				<i style={{ background: "#b4435a" }}></i>
				<i style={{ background: "#3b6fd1" }}></i>
				<i style={{ background: "#4b5563" }}></i>
			</div>
			<div class="nt-m">What is it for?</div>
			<Opt on title="Mixed" sub="Notes and tasks together in one list" rows={["o", "x"]} />
			<Opt title="Notes only" sub="Just writing, no checkboxes" rows={["x", "x"]} />
			<Opt title="Tasks only" sub="A clean checklist with progress, like Home" rows={["o", "o"]} />
			<div class="nt-tr2">
				<span>Show its tasks in Now</span>
				<span class="nt-tgl"></span>
			</div>
			<div class="nt-tr2">
				<span>Progress bar</span>
				<span class="nt-tgl"></span>
			</div>
			<a class="nt-go" href="/pad">
				Create project
			</a>
			<div class="nt-m" style={{ textAlign: "center" }}>
				You can change the type later
			</div>
		</div>
	</>
))

export const PadBody = view<{ tab: PadTab }>(({ tab }) => (
	<div class="nt-page">
		<Seg tab={tab} />
		{tab === "said" ? <Said /> : tab === "home" ? <HomeTasks /> : <Projects />}
		{tab === "new" ? <Sheet /> : null}
	</div>
))

export const PadComposer = view<{ tab: PadTab }>(({ tab }) => (
	<div class="nt-cmp">
		<div class="nt-c nt-cin">
			<input placeholder={tab === "said" ? "Add what someone said…" : tab === "home" ? "Add a home task…" : "Write a note or task…"} aria-label="Add" />
			{tab === "said" ? <span class="nt-tag">Tip</span> : null}
			{tab === "projects" || tab === "new" ? (
				<div class="nt-tg2">
					<span class="on">Task</span>
					<span>Note</span>
				</div>
			) : null}
			<button type="button" class="nt-sd" aria-label="Add">
				<Icon name="send" />
			</button>
		</div>
	</div>
))
EOF
if ! grep -q "nt-page" app/client/app.css; then
cat >> app/client/app.css << 'EOF'

.app:has(.nt-page) .tsplit .clock-time{display:none}
.nt-ttl{font-size:22px;font-weight:700;letter-spacing:-.02em}
.app:has(.nt-page) .tsplit .clock-num,.app:has(.nt-page) .tsplit .clock-ar,.app:has(.nt-page) .tsplit .clock-dot,.app:has(.nt-page) .tsplit .clock-subdate{font:400 13px var(--mono);color:var(--mu)}
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
.nt-ck.ok{background:var(--ac);border-color:var(--ac)}
.nt-ck svg.ic{width:16px;height:16px;stroke-width:2.4}
.nt-it p{margin:0;font-size:15px;line-height:1.35}
.nt-it.nt-done p{color:var(--mu);text-decoration:line-through}
.nt-it.nt-note{border-left:3px solid var(--ac);background:color-mix(in srgb,var(--acs) 28%,var(--s1))}
.nt-it.nt-note p{font-size:14px}
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
.nt-tag.hi{background:var(--acs);color:var(--ac)}
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
.nt-op.on{border-color:var(--ac);background:color-mix(in srgb,var(--acs) 28%,var(--s1))}
.nt-op b{font-size:15px;display:block}
.nt-ds{font-size:12px;color:var(--mu)}
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
.mm:has(.nt-page){padding-left:12px;padding-right:12px}
EOF
fi
echo "done. now run: bun run db:migrate"
