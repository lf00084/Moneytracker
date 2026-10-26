#!/bin/bash
set -e
cd "$(dirname "$0")"
if grep -q "day_start" app/lib/users.ts 2>/dev/null; then echo "already applied"; exit 0; fi
for f in app/lib/users.ts app/lib/time.ts app/screens.tsx app/client/app.js app/client/app.css database/schema.sql scripts/migrate.ts; do [ -f "$f" ] || { echo "run this inside the Moneytracker folder (missing $f)"; exit 1; }; done
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

rep("app/routes.ts", '\t\tpad: get("/pad"),\n', '\t\tpad: get("/pad"),\n\t\tpadPeople: get("/pad/people"),\n\t\tpadBooks: get("/pad/books"),\n\t\tpadTips: get("/pad/tips"),\n')
rep("app/controllers/pages.tsx", '\t\tpad: page("/pad", [], (s) => <PadScreen s={s} />),\n', '\t\tpad: page("/pad", [], (s) => <PadScreen s={s} tab="projects" />),\n\t\tpadPeople: page("/pad/people", [], (s) => <PadScreen s={s} tab="people" />),\n\t\tpadBooks: page("/pad/books", [], (s) => <PadScreen s={s} tab="books" />),\n\t\tpadTips: page("/pad/tips", [], (s) => <PadScreen s={s} tab="tips" />),\n')

rep("app/screens.tsx", 'import { BalanceCard,', 'import { PadBody, PadHome, type PadTab } from "./components/pad.tsx"\nimport { BalanceCard,')
rep("app/screens.tsx", '<OweMobile s={s} open={false} storeKey="owe" />\n\t\t\t</>', '<OweMobile s={s} open={false} storeKey="owe" />\n\t\t\t\t<PadHome />\n\t\t\t</>')
rep("app/screens.tsx", "\t\t\t\t\t\t<NoteCard s={s} />\n", "\t\t\t\t\t\t<NoteCard s={s} />\n\t\t\t\t\t\t<PadHome />\n")
rep("app/screens.tsx", 'export const PadScreen = view<{ s: State }>(({ s }) => <AppLayout title="Pad" theme={s.user.theme} mobileTab="pad" desktopTab="pad" mobile={null} desktop={null} />)', 'export const PadScreen = view<{ s: State; tab: PadTab }>(({ s, tab }) => (\n\t<AppLayout title="Pad" theme={s.user.theme} mobileTab="pad" desktopTab="pad" mobile={<PadBody tab={tab} />} desktop={<PadBody tab={tab} />} />\n))')
PATCH_EOF
(cd "$T/p" && node "$T/patch.js")
cp -r "$T/p/app/." app/
cp -r "$T/p/scripts/." scripts/
cat > app/components/pad.tsx << 'EOF'
import { PageHeader, view } from "./ui.tsx"

export type PadTab = "projects" | "people" | "books" | "tips"

const TABS: { key: PadTab; label: string; href: string }[] = [
	{ key: "projects", label: "Projects", href: "/pad" },
	{ key: "people", label: "People say", href: "/pad/people" },
	{ key: "books", label: "Books", href: "/pad/books" },
	{ key: "tips", label: "Useful", href: "/pad/tips" },
]

export const PadBody = view<{ tab: PadTab }>(({ tab }) => (
	<>
		<PageHeader title="Pad" right="saved on this device" />
		<div class="chips pdtabs">
			{TABS.map((t) => (
				<a key={t.key} class={t.key === tab ? "chip on" : "chip"} href={t.href}>
					{t.label}
				</a>
			))}
		</div>
		<div class="pdx" data-pad={tab}></div>
	</>
))

export const PadHome = view(() => <div class="sc pdhome" data-pad-home></div>)
EOF
cat >> app/client/app.js << 'EOF'

;(function () {
	var d = document
	var K = "mt:pad:v1"
	var TABS = {
		projects: { space: "project", entry: "note", head: "Projects", add: "New project", ph: "Write a note", empty: "No projects yet. Add your first one above.", noun: "notes" },
		people: { space: "person", entry: "quote", head: "People", add: "Add a person", ph: "What did they say?", empty: "No one yet. Add a person, then what they said.", noun: "things said" },
		books: { space: "book", entry: "lesson", head: "Books", add: "Book name", sub: "Author (optional)", ref: "Chapter or page (optional)", ph: "What did you learn?", empty: "No books yet. Add a book, then what you learned from it.", noun: "lessons" },
		tips: { entry: "tip", flat: true, ph: "Something useful to remember", ref: "Where from (optional)", empty: "Nothing saved yet." },
	}
	var data = { spaces: [], entries: [] }
	var load = function () {
		try {
			var v = JSON.parse(localStorage.getItem(K) || "null")
			if (v && v.spaces && v.entries) data = v
		} catch (e) {}
	}
	var save = function () {
		try {
			localStorage.setItem(K, JSON.stringify(data))
		} catch (e) {}
	}
	var uid = function () {
		return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
	}
	var esc = function (s) {
		return String(s).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
		})
	}
	var when = function (t) {
		return new Date(t).toLocaleDateString("en-GB", { day: "numeric", month: "short" })
	}
	var spaceOf = function (id) {
		return data.spaces.filter(function (s) {
			return s.id === id
		})[0]
	}
	var entriesOf = function (fn) {
		return data.entries
			.filter(fn)
			.sort(function (a, b) {
				return b.at - a.at
			})
	}
	var entryHtml = function (e, label) {
		return (
			'<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + "</div>" +
			'<div class="pdm"><span class="lb">' + (label ? esc(label) + " · " : "") + (e.ref ? esc(e.ref) + " · " : "") + when(e.at) + "</span>" +
			'<span class="pda"><button type="button" class="chip' + (e.home ? " on" : "") + '" data-pd="home">Home</button>' +
			'<button type="button" class="chip" data-pd="edit">Edit</button>' +
			'<button type="button" class="chip" data-pd="del">Delete</button></span></div></div>'
		)
	}
	var composer = function (c, spaceId) {
		return (
			'<form class="pdf" data-pd="entry" data-space="' + (spaceId || "") + '">' +
			'<textarea class="pdi" name="body" rows="3" placeholder="' + esc(c.ph) + '" required></textarea>' +
			(c.ref ? '<input class="pdi" name="ref" placeholder="' + esc(c.ref) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>'
		)
	}
	var tabHtml = function (key) {
		var c = TABS[key]
		var id = decodeURIComponent(location.hash.slice(1))
		if (c.flat) return composer(c, "") + (entriesOf(function (e) { return e.kind === c.entry }).map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">' + c.empty + "</div>")
		var sp = id && spaceOf(id)
		if (sp && sp.kind === c.space) {
			var list = entriesOf(function (e) { return e.space === sp.id })
			return (
				'<div class="pdhd"><a class="chip" href="#" data-pd="back">‹ ' + c.head + "</a>" +
				'<button type="button" class="chip" data-pd="delspace" data-id="' + sp.id + '">Delete</button></div>' +
				'<h2 class="pdtt">' + esc(sp.title) + "</h2>" + (sp.sub ? '<div class="lb">' + esc(sp.sub) + "</div>" : "") +
				composer(c, sp.id) +
				(list.map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">Nothing here yet.</div>')
			)
		}
		var spaces = data.spaces
			.filter(function (s) { return s.kind === c.space })
			.sort(function (a, b) { return b.at - a.at })
		return (
			'<form class="pdf" data-pd="space"><input class="pdi" name="title" placeholder="' + esc(c.add) + '" autocomplete="off" required>' +
			(c.sub ? '<input class="pdi" name="sub" placeholder="' + esc(c.sub) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>' +
			(spaces.map(function (s) {
				var n = data.entries.filter(function (e) { return e.space === s.id }).length
				return '<a class="pdc" href="#' + encodeURIComponent(s.id) + '"><span><b>' + esc(s.title) + '</b><span class="lb">' + (s.sub ? esc(s.sub) + " · " : "") + n + " " + c.noun + '</span></span><span class="mu">›</span></a>'
			}).join("") || '<div class="lb pde">' + c.empty + "</div>")
		)
	}
	var homeHtml = function () {
		var list = entriesOf(function (e) { return e.home }).slice(0, 6)
		return (
			'<div class="sh"><span>Pinned notes</span><span class="lb">' + list.length + "</span></div>" +
			'<form class="pdf" data-pd="entry" data-space="" data-home="1"><input class="pdi" name="body" placeholder="Add a note to home" autocomplete="off" required><button class="btn xs">Add</button></form>' +
			(list.map(function (e) {
				var s = e.space && spaceOf(e.space)
				return '<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + '</div><div class="pdm"><span class="lb">' + (s ? esc(s.title) + " · " : "") + when(e.at) + '</span><span class="pda"><button type="button" class="chip" data-pd="home">Unpin</button></span></div></div>'
			}).join("") || '<div class="lb pde">Pin any note with the Home button.</div>')
		)
	}
	var paint = function () {
		[].slice.call(d.querySelectorAll("[data-pad]")).forEach(function (r) {
			var a = d.activeElement
			if (a && r.contains(a) && a.value) return
			r.innerHTML = tabHtml(r.getAttribute("data-pad"))
		})
		var h = d.activeElement
		;[].slice.call(d.querySelectorAll("[data-pad-home]")).forEach(function (r) {
			if (h && r.contains(h) && h.value) return
			r.innerHTML = homeHtml()
		})
	}
	var repaint = function () {
		save()
		;[].slice.call(d.querySelectorAll("[data-pad],[data-pad-home]")).forEach(function (r) {
			r.innerHTML = r.hasAttribute("data-pad") ? tabHtml(r.getAttribute("data-pad")) : homeHtml()
		})
	}
	d.addEventListener("submit", function (e) {
		var f = e.target
		var kind = f.getAttribute && f.getAttribute("data-pd")
		if (kind !== "space" && kind !== "entry") return
		e.preventDefault()
		var root = f.closest("[data-pad]")
		var tab = root && root.getAttribute("data-pad")
		var c = tab && TABS[tab]
		var v = function (n) {
			var i = f.elements[n]
			return i ? i.value.trim() : ""
		}
		var now = Date.now()
		if (kind === "space" && c) {
			if (!v("title")) return
			data.spaces.push({ id: uid(), kind: c.space, title: v("title").slice(0, 120), sub: v("sub").slice(0, 120), at: now })
		} else if (kind === "entry") {
			if (!v("body")) return
			var home = f.getAttribute("data-home") === "1"
			data.entries.push({ id: uid(), space: f.getAttribute("data-space") || null, kind: c ? c.entry : "note", body: v("body").slice(0, 4000), ref: v("ref").slice(0, 120), home: home, at: now })
		}
		repaint()
	})
	d.addEventListener("click", function (e) {
		var b = e.target.closest && e.target.closest("[data-pd]")
		if (!b || b.tagName === "FORM") return
		var act = b.getAttribute("data-pd")
		var row = b.closest("[data-id]")
		var id = row ? row.getAttribute("data-id") : b.getAttribute("data-id")
		var en = id && data.entries.filter(function (x) { return x.id === id })[0]
		if (act === "back") {
			e.preventDefault()
			history.pushState("", "", location.pathname)
			return repaint()
		}
		if (act === "home" && en) en.home = !en.home
		else if (act === "edit" && en) {
			var t = prompt("Edit", en.body)
			if (t === null || !t.trim()) return
			en.body = t.trim().slice(0, 4000)
		} else if (act === "del" && en) {
			if (!confirm("Delete this?")) return
			data.entries = data.entries.filter(function (x) { return x.id !== id })
		} else if (act === "delspace" && id) {
			if (!confirm("Delete this and everything inside it?")) return
			data.spaces = data.spaces.filter(function (x) { return x.id !== id })
			data.entries = data.entries.filter(function (x) { return x.space !== id })
			history.pushState("", "", location.pathname)
		} else return
		repaint()
	})
	addEventListener("hashchange", paint)
	addEventListener("storage", function (e) {
		if (e.key !== K) return
		load()
		paint()
	})
	load()
	paint()
})()
EOF
cat >> app/client/app.css << 'EOF'

.pdtabs{margin:8px 0 4px;flex-wrap:nowrap;overflow-x:auto;scrollbar-width:none}
.pdtabs::-webkit-scrollbar{display:none}
.pdtabs .chip{flex:none;white-space:nowrap}
.pdx{margin-top:12px}
.pdf{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 14px}
.pdi{flex:1 1 140px;min-width:0;width:100%;font-size:15px;font-family:inherit;background:var(--s1);color:var(--ink);border:1px solid var(--ln);border-radius:14px;padding:10px 14px;margin:0;resize:none;outline:0}
.pdi:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
textarea.pdi{flex-basis:100%}
.pdf .btn.xs{margin-left:auto}
.pdc{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:14px 16px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdc>span:first-child{display:flex;flex-direction:column;gap:2px;min-width:0}
.pdc b{font-weight:600;letter-spacing:-.01em;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.pdn{padding:12px 14px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdt{white-space:pre-wrap;word-break:break-word}
.pdm{display:flex;justify-content:space-between;align-items:center;gap:8px;margin-top:8px;flex-wrap:wrap}
.pda{display:flex;gap:6px}
.pda .chip{padding:3px 10px;font-size:11px}
.pdhd{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}
.pdtt{font-size:20px;font-weight:700;letter-spacing:-.03em;margin:4px 0 2px}
.pde{padding:14px 2px}
.pdhome .pdf{margin:12px 0}
.pdhome .pdn{background:var(--s2);box-shadow:none}
EOF
cat >> database/schema.sql << 'EOF'

CREATE TABLE IF NOT EXISTS pad_spaces (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL,
  title         TEXT NOT NULL,
  sub           TEXT NOT NULL DEFAULT '',
  sort          INTEGER NOT NULL DEFAULT 0,
  archived_at   INTEGER,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS pad_spaces_list_idx ON pad_spaces(user_id, kind, archived_at, sort);
CREATE UNIQUE INDEX IF NOT EXISTS pad_spaces_title_uq ON pad_spaces(user_id, kind, lower(title));

CREATE TABLE IF NOT EXISTS pad_entries (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  space_id      TEXT REFERENCES pad_spaces(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL,
  body          TEXT NOT NULL,
  ref           TEXT NOT NULL DEFAULT '',
  on_home       INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS pad_entries_space_idx ON pad_entries(space_id, created_at DESC);
CREATE INDEX IF NOT EXISTS pad_entries_kind_idx ON pad_entries(user_id, kind, created_at DESC);
CREATE INDEX IF NOT EXISTS pad_entries_home_idx ON pad_entries(user_id, created_at DESC) WHERE on_home = 1;
EOF
echo "done. now run: bun run db:migrate once"
