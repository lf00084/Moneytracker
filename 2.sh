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
rep("app/components/layout.tsx", '\t{ key: "home", label: "Home", icon: "home", href: "/home" },\n\t{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },\n\t{ key: "income", label: "Income", icon: "gear", href: "/income" },\n\t{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },\n\t{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },\n\t{ key: "profile", label: "Profile", icon: "user", href: "/profile" },\n', '\t{ key: "home", label: "Home", icon: "home", href: "/home" },\n\t{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },\n\t{ key: "pad", label: "Notes", icon: "pad", href: "/pad" },\n\t{ key: "income", label: "Sources", icon: "gear", href: "/income" },\n\t{ key: "notes", label: "Message myself", icon: "notes", href: "/notes" },\n\t{ key: "profile", label: "Profile", icon: "user", href: "/profile" },\n')
rep("app/components/layout.tsx", '{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },\n\t{ key: "plan"', '{ key: "notes", label: "Message myself", icon: "notes", href: "/notes" },\n\t{ key: "plan"')
rep("app/components/layout.tsx", '{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },\n\t{ key: "history"', '{ key: "pad", label: "Notes", icon: "pad", href: "/pad" },\n\t{ key: "history"')
PATCH_EOF
(cd "$T/p" && node "$T/patch.js")
cp -r "$T/p/app/." app/
cp -r "$T/p/scripts/." scripts/
fi
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
	<div class={kind === "done" ? "nt-it dn" : kind === "note" ? "nt-it nt" : "nt-it"}>
		{kind === "note" ? null : (
			<span class={kind === "done" ? "nt-ck d" : "nt-ck"}>{kind === "done" ? <Icon name="check" /> : null}</span>
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
			<span class="nt-tag t">{tag}</span>
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
			<span class="d">{sub}</span>
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
.nt-ttl{font-size:18px;font-weight:700;letter-spacing:-.02em}
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
.nt-ck.d{background:var(--ac);border-color:var(--ac)}
.nt-ck svg.ic{width:16px;height:16px;stroke-width:2.4}
.nt-it p{margin:0;font-size:15px;line-height:1.35}
.nt-it.dn p{color:var(--mu);text-decoration:line-through}
.nt-it.nt{border-left:3px solid var(--ac);background:var(--acs)}
.nt-it.nt p{font-size:14px}
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
.nt-tag.t{background:var(--acs);color:var(--ac)}
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
.nt-op.on{border-color:var(--ac);background:var(--acs)}
.nt-op b{font-size:15px;display:block}
.nt-op span.d{font-size:12px;color:var(--mu)}
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
EOF
fi
echo "done. now run: bun run db:migrate"
