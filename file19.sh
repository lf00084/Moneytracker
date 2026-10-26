#!/bin/bash
set -e
cd "$(dirname "$0")"
if grep -q "file19:" app/client/app.css 2>/dev/null; then echo "already applied"; exit 0; fi
if ! grep -q "file18:" app/client/app.css 2>/dev/null; then echo "run file18.sh first"; exit 1; fi
for f in app/screens.tsx app/routes.ts app/commands.ts app/controllers/pages.tsx app/db/tables.ts app/lib/actions.ts app/components/layout.tsx app/components/ui.tsx app/components/pad.tsx; do [ -f "$f" ] || { echo "run this inside the Moneytracker folder (missing $f)"; exit 1; }; done
T=$(mktemp -d)
trap "rm -rf $T" EXIT
mkdir -p "$T/p"
cp -r app "$T/p/"
cat > "$T/patch.js" << 'PATCH_EOF'
const fs = require("fs")
const read = (f) => fs.readFileSync(f, "utf8")
const rep = (file, from, to, n = 1) => {
	const src = read(file)
	const parts = src.split(from)
	if (parts.length - 1 !== n) {
		console.error(`patch failed in ${file}: expected ${n} match(es) for:\n${from}\nfound ${parts.length - 1}`)
		process.exit(1)
	}
	fs.writeFileSync(file, parts.join(to))
}
const between = (file, a, b, to) => {
	const src = read(file)
	const i = src.indexOf(a)
	const j = src.indexOf(b, i + 1)
	if (i < 0 || j < 0 || src.indexOf(a, i + 1) >= 0) {
		console.error(`patch failed in ${file}: anchors not found (${a.slice(0, 40)})`)
		process.exit(1)
	}
	fs.writeFileSync(file, src.slice(0, i) + to + src.slice(j))
}

// db tables
fs.appendFileSync(
	"app/db/tables.ts",
	`
export const padSpaces = table({
	name: "pad_spaces",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(16),
		title: c.varchar(120),
		sub: c.varchar(500),
		sort: c.integer(),
		archived_at: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})

export const padEntries = table({
	name: "pad_entries",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		space_id: c.varchar(36),
		kind: c.varchar(16),
		body: c.varchar(2000),
		ref: c.varchar(500),
		on_home: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})
`,
)

// routes
rep("app/routes.ts", `		padPeople: get("/pad/people"),\n		padBooks: get("/pad/books"),\n		padTips: get("/pad/tips"),\n`, `		padSaid: get("/pad/said"),\n		padHome: get("/pad/home"),\n		padNew: get("/pad/new"),\n`)
rep("app/routes.ts", `		setTheme: post("/settings/theme"),\n`, `		setTheme: post("/settings/theme"),\n		padAddSpace: post("/pad/space"),\n		padDelSpace: post("/pad/space/delete"),\n		padAdd: post("/pad/add"),\n		padToggle: post("/pad/toggle"),\n		padDel: post("/pad/delete"),\n`)

// commands
rep("app/commands.ts", `import * as trading from "./lib/trading.ts"\n`, `import * as pad from "./lib/pad.ts"\nimport * as trading from "./lib/trading.ts"\n`)
rep(
	"app/commands.ts",
	`	setTheme: { run: quiet((u, f) => setTheme(u.id, field(f, "theme"))), to: "/settings", empty: true },\n`,
	`	setTheme: { run: quiet((u, f) => setTheme(u.id, field(f, "theme"))), to: "/settings", empty: true },
	padAddSpace: { run: (u, f) => pad.addSpace(u.id, f), to: "/pad", fail: "/pad/new" },
	padDelSpace: { run: quiet((u, f) => pad.deleteSpace(u.id, f)), to: "/pad" },
	padAdd: { run: (u, f) => pad.addEntry(u.id, f), to: "/pad" },
	padToggle: { run: quiet((u, f) => pad.toggleEntry(u.id, f)), to: "/pad" },
	padDel: { run: quiet((u, f) => pad.deleteEntry(u.id, f)), to: "/pad" },
`,
)

// pad pages
rep("app/controllers/pages.tsx", `import { go, takeError, userOf, type Ctx } from "../request.ts"\n`, `import { go, takeError, userOf, type Ctx } from "../request.ts"\nimport { loadPad } from "../lib/pad.ts"\nimport type { PadTab } from "../components/pad.tsx"\n`)
rep(
	"app/controllers/pages.tsx",
	`export default createController(`,
	`const padPage = (tab: PadTab) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	const q = new URL(ctx.request.url).searchParams
	const d = await loadPad(user.id, q.get("p") ?? "")
	return ctx.render(<PadScreen u={user} d={d} tab={tab} f={q.get("f") ?? ""} error={takeError(ctx)} />)
}

export default createController(`,
)
between(
	"app/controllers/pages.tsx",
	`		pad: page("/pad"`,
	`		trading: page(`,
	`		pad: padPage("projects"),
		padSaid: padPage("said"),
		padHome: padPage("home"),
		padNew: padPage("new"),
`,
)

// screens
rep("app/screens.tsx", `import { PadBody, type PadTab } from "./components/pad.tsx"`, `import { PadBody, PadComposer, type PadTab } from "./components/pad.tsx"\nimport type { PadData } from "./lib/padmeta.ts"\nimport type { User } from "./lib/users.ts"`)
between(
	"app/screens.tsx",
	`export const PadScreen = view<`,
	`export const ProfileScreen = view<`,
	`export const PadScreen = view<{ u: User; d: PadData; tab: PadTab; f: string; error: string }>(({ u, d, tab, f, error }) => (
	<AppLayout
		title="Pad"
		theme={u.theme}
		mobileTab="pad"
		desktopTab="pad"
		mobile={<PadBody d={d} tab={tab} f={f} error={error} />}
		dock={<PadComposer d={d} tab={tab} f={f} />}
		desktop={
			<div class="chat">
				<PadBody d={d} tab={tab} f={f} error={error} />
				<PadComposer d={d} tab={tab} f={f} />
			</div>
		}
	/>
))

`,
)
rep("app/screens.tsx", `<div class="hm">`, `<div class="hm hm-f">`)

// icon + layout + account delete
rep("app/components/ui.tsx", `	bhome: `, `	check: '<path d="m5 12 5 5 9-9"/>',\n	bhome: `)
rep("app/components/layout.tsx", `<div class="m mm">{mobile}</div>`, `<div class="m mm hm">{mobile}</div>`)
rep("app/lib/actions.ts", "			sql`delete from notes where user_id = ${uid}`,\n", "			sql`delete from pad_entries where user_id = ${uid}`,\n			sql`delete from pad_spaces where user_id = ${uid}`,\n			sql`delete from notes where user_id = ${uid}`,\n")
PATCH_EOF
cat > "$T/pad.ts" << 'F_EOF'
import { sql } from "remix/data-table"
import { db, padEntries, padSpaces } from "../db/index.ts"
import { id, parseJson, text } from "./util.ts"

import { COLORS, TYPES, type Entry, type PadData, type Space } from "./padmeta.ts"

export type { Entry, PadData, Space }

type Result = Promise<string | void>

export async function loadPad(uid: string, pick: string): Promise<PadData> {
	const [sp, en] = await Promise.all([
		db.findMany(padSpaces, { where: { user_id: uid, kind: "project" }, orderBy: ["sort", "asc"] }),
		db.findMany(padEntries, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 3000 }),
	])
	const spaces = sp
		.filter((x) => !x.archived_at)
		.map((x): Space => {
			const j = parseJson(x.sub)
			return { id: x.id, title: x.title, color: String(j.c || COLORS[0]), type: String(j.t || "mix"), bar: j.b !== 0 }
		})
	const entries = en.map((x): Entry => {
		const j = parseJson(x.ref)
		return { id: x.id, space: x.space_id ?? "", kind: x.kind, body: x.body, who: String(j.n || ""), tag: String(j.t || ""), today: !!x.on_home, at: x.created_at }
	})
	return { spaces, space: spaces.find((x) => x.id === pick) ?? spaces[0] ?? null, entries }
}

const mine = async (uid: string, v: unknown) => {
	const i = text(v, 36)
	return i ? ((await db.findOne(padSpaces, { where: { id: i, user_id: uid } })) ?? null) : null
}

export async function addSpace(uid: string, f: FormData): Result {
	const title = text(f.get("title"), 60)
	if (!title) return "Give the project a name"
	const color = COLORS.includes(text(f.get("color"), 9)) ? text(f.get("color"), 9) : COLORS[0]!
	const type = (TYPES as readonly string[]).includes(text(f.get("type"), 8)) ? text(f.get("type"), 8) : "mix"
	const nid = text(f.get("nid"), 36)
	const now = Date.now()
	try {
		await db.create(padSpaces, {
			id: /^[0-9a-f-]{36}$/.test(nid) ? nid : id(),
			user_id: uid,
			kind: "project",
			title,
			sub: JSON.stringify({ c: color, t: type, b: f.get("bar") ? 1 : 0 }),
			sort: now,
			archived_at: null as never,
			created_at: now,
			updated_at: now,
		})
	} catch {
		return "You already have a project with that name"
	}
}

export async function deleteSpace(uid: string, f: FormData) {
	const s = await mine(uid, f.get("id"))
	if (!s) return
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from pad_entries where space_id = ${s.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from pad_spaces where id = ${s.id} and user_id = ${uid}`)
	})
}

export async function addEntry(uid: string, f: FormData): Result {
	const body = text(f.get("body"), 2000)
	if (!body) return "Write something first"
	const tab = text(f.get("tab"), 8)
	const mode = text(f.get("mode"), 8)
	const now = Date.now()
	let space: string | null = null
	let kind = "task"
	let ref = "{}"
	let home = 0
	if (tab === "said") {
		kind = "said"
		ref = JSON.stringify({ n: text(f.get("who"), 40) || "Someone", t: mode === "info" ? "Info" : "Tip" })
		space = (await mine(uid, f.get("space")))?.id ?? null
	} else if (tab === "home") {
		home = mode === "later" ? 0 : 1
	} else {
		const s = await mine(uid, f.get("space"))
		if (!s) return "Create a project first"
		space = s.id
		const t = parseJson(s.sub).t
		kind = t === "notes" ? "note" : t === "tasks" ? "task" : mode === "note" ? "note" : "task"
	}
	await db.create(padEntries, { id: id(), user_id: uid, space_id: space as never, kind, body, ref, on_home: home, created_at: now, updated_at: now })
}

export async function toggleEntry(uid: string, f: FormData) {
	const e = await db.findOne(padEntries, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (e && (e.kind === "task" || e.kind === "done")) await db.update(padEntries, e.id, { kind: e.kind === "task" ? "done" : "task", updated_at: Date.now() })
}

export async function deleteEntry(uid: string, f: FormData) {
	await db.deleteMany(padEntries, { where: { id: text(f.get("id"), 36), user_id: uid } })
}
F_EOF
cat > "$T/padmeta.ts" << 'F_EOF'
export const COLORS = ["#2f6f78", "#6a4fd1", "#8a5a00", "#b4435a", "#3b6fd1", "#4b5563"]
export const TYPES = ["mix", "notes", "tasks"] as const

export type Space = { id: string; title: string; color: string; type: string; bar: boolean }
export type Entry = { id: string; space: string; kind: string; body: string; who: string; tag: string; today: boolean; at: number }
export type PadData = { spaces: Space[]; space: Space | null; entries: Entry[] }
F_EOF
cat > "$T/pad.tsx" << 'F_EOF'
import { COLORS, type Entry, type PadData } from "../lib/padmeta.ts"
import { timeAgo } from "../lib/time.ts"
import { Icon, view } from "./ui.tsx"

export type PadTab = "projects" | "said" | "home" | "new"

type Props = { d: PadData; tab: PadTab; f: string }

const SEG = [
	{ key: "projects", label: "Projects", href: "/pad" },
	{ key: "said", label: "Said", href: "/pad/said" },
	{ key: "home", label: "Home", href: "/pad/home" },
]

export const padBack = (d: PadData, tab: PadTab, f: string) =>
	tab === "said" ? `/pad/said${f ? `?f=${f}` : ""}` : tab === "home" ? "/pad/home" : d.space ? `/pad?p=${d.space.id}${f ? `&f=${f}` : ""}` : "/pad"

const Seg = view<{ tab: PadTab }>(({ tab }) => (
	<div class="nt-seg">
		{SEG.map((x) => (
			<a key={x.key} href={x.href} class={x.key === tab || (tab === "new" && x.key === "projects") ? "on" : ""}>
				{x.label}
			</a>
		))}
	</div>
))

const Filters = view<{ base: string; f: string; items: [string, string][] }>(({ base, f, items }) => (
	<div class="nt-fl">
		{items.map(([label, key]) => (
			<a key={key} href={key ? `${base}${base.includes("?") ? "&" : "?"}f=${key}` : base} class={f === key ? "on" : ""}>
				{label}
			</a>
		))}
	</div>
))

const Bar = view<{ pct: number }>(({ pct }) => (
	<div class="nt-bar2">
		<i style={{ width: `${pct}%` }}></i>
	</div>
))

const Hid = view<{ id: string; back: string }>(({ id, back }) => (
	<>
		<input type="hidden" name="id" value={id} />
		<input type="hidden" name="back" value={back} />
	</>
))

const Row = view<{ e: Entry; back: string }>(({ e, back }) => {
	const note = e.kind === "note"
	const done = e.kind === "done"
	return (
		<div class={done ? "nt-it dn" : note ? "nt-it nt" : "nt-it"}>
			{note ? null : (
				<form method="post" action="/pad/toggle" class="nt-f">
					<Hid id={e.id} back={back} />
					<button class={done ? "nt-ck d" : "nt-ck"} aria-label={done ? "Mark as open" : "Mark as done"}>
						{done ? <Icon name="check" /> : null}
					</button>
				</form>
			)}
			<div class="nt-b">
				<p>{e.body}</p>
				{note ? <div class="nt-m">{`note · ${timeAgo(e.at)}`}</div> : null}
			</div>
			<form method="post" action="/pad/delete" class="nt-f" data-confirm="Delete this?">
				<Hid id={e.id} back={back} />
				<button class="nt-x" aria-label="Delete">
					<Icon name="plus" />
				</button>
			</form>
		</div>
	)
})

const Empty = view<{ children?: unknown }>(({ children }) => <div class="nt-m nt-em">{children as never}</div>)

const Projects = view<Props>(({ d, f }) => {
	const sp = d.space
	if (!sp) {
		return (
			<div class="nt-c nt-ph">
				<b>No projects yet</b>
				<div class="nt-m" style={{ margin: "4px 0 10px" }}>
					Make one for each thing you work on.
				</div>
				<a class="nt-go" href="/pad/new">
					New project
				</a>
			</div>
		)
	}
	const all = d.entries.filter((e) => e.space === sp.id && e.kind !== "said")
	const open = all.filter((e) => e.kind === "task").length
	const done = all.filter((e) => e.kind === "done").length
	const list = all.filter((e) => (f === "tasks" ? e.kind !== "note" : f === "notes" ? e.kind === "note" : true))
	const back = padBack(d, "projects", f)
	return (
		<>
			<div class="nt-pj">
				{d.spaces.map((x) => (
					<a key={x.id} class={x.id === sp.id ? "nt-pc on" : "nt-pc"} href={`/pad?p=${x.id}`}>
						<i class="nt-dot" style={{ background: x.color }}></i>
						{x.title} <small>{d.entries.filter((e) => e.space === x.id && e.kind === "task").length}</small>
					</a>
				))}
				<a class="nt-pc" href="/pad/new">
					+ New
				</a>
			</div>
			<div class="nt-c nt-ph">
				<div class="nt-spread">
					<b>{sp.title}</b>
					<span class="nt-m">{`${open} open · ${done} done`}</span>
				</div>
				{sp.bar && sp.type !== "notes" ? <Bar pct={open + done ? Math.round((done / (open + done)) * 100) : 0} /> : null}
			</div>
			{sp.type === "mix" ? <Filters base={`/pad?p=${sp.id}`} f={f} items={[["All", ""], ["Tasks", "tasks"], ["Notes", "notes"]]} /> : null}
			<div class="nt-c nt-list">{list.length ? list.map((e) => <Row key={e.id} e={e} back={back} />) : <Empty>{sp.type === "notes" ? "No notes yet. Write one below." : "Nothing here yet. Add one below."}</Empty>}</div>
			<form method="post" action="/pad/space/delete" class="nt-del" data-confirm={`Delete ${sp.title} and everything in it?`}>
				<Hid id={sp.id} back="/pad" />
				<button type="submit">Delete this project</button>
			</form>
		</>
	)
})

const Said = view<Props>(({ d, f }) => {
	const all = d.entries.filter((e) => e.kind === "said")
	const list = all.filter((e) => !f || e.tag.toLowerCase() === f)
	const back = padBack(d, "said", f)
	const title = (id: string) => d.spaces.find((x) => x.id === id)?.title
	return (
		<>
			<Filters base="/pad/said" f={f} items={[["All", ""], ["Tips", "tip"], ["Info", "info"]]} />
			<div class="nt-c nt-list">
				{list.length ? (
					list.map((e) => (
						<div key={e.id} class="nt-q">
							<p>{e.body}</p>
							<div class="nt-who">
								<span class="nt-av">{(e.who[0] ?? "?").toUpperCase()}</span>
								<div>
									<b>{e.who}</b>
									<span class="nt-m">{timeAgo(e.at)}</span>
								</div>
								<span class="nt-tag t">{e.tag}</span>
								<form method="post" action="/pad/delete" class="nt-f" data-confirm="Delete this?">
									<Hid id={e.id} back={back} />
									<button class="nt-x" aria-label="Delete">
										<Icon name="plus" />
									</button>
								</form>
							</div>
							{title(e.space) ? <div class="nt-m" style={{ marginTop: "8px" }}>{`→ ${title(e.space)}`}</div> : null}
						</div>
					))
				) : (
					<Empty>Nothing yet. Write what someone told you below.</Empty>
				)}
			</div>
		</>
	)
})

const HomeTasks = view<Props>(({ d }) => {
	const all = d.entries.filter((e) => !e.space && (e.kind === "task" || e.kind === "done"))
	const done = all.filter((e) => e.kind === "done").length
	const back = padBack(d, "home", "")
	const group = (label: string, rows: Entry[]) =>
		rows.length ? (
			<>
				<div class="nt-gl">{label}</div>
				<div class="nt-c nt-list">{rows.map((e) => <Row key={e.id} e={e} back={back} />)}</div>
			</>
		) : null
	return (
		<>
			<div class="nt-c nt-ph">
				<div class="nt-spread">
					<b>Home</b>
					<span class="nt-m">{`${done} of ${all.length} done`}</span>
				</div>
				<Bar pct={all.length ? Math.round((done / all.length) * 100) : 0} />
			</div>
			{group("Today", all.filter((e) => e.today))}
			{group("Later", all.filter((e) => !e.today))}
			{all.length ? null : <Empty>No home tasks yet. Add one below.</Empty>}
		</>
	)
})

const TYPE_OPTS = [
	{ key: "mix", title: "Mixed", sub: "Notes and tasks together in one list", rows: ["o", "x"] },
	{ key: "notes", title: "Notes only", sub: "Just writing, no checkboxes", rows: ["x", "x"] },
	{ key: "tasks", title: "Tasks only", sub: "A clean checklist with progress, like Home", rows: ["o", "o"] },
]

const Sheet = view(() => {
	const nid = crypto.randomUUID()
	return (
		<>
			<a class="nt-ov" href="/pad" aria-label="Close"></a>
			<form class="nt-sht" method="post" action="/pad/space">
				<input type="hidden" name="nid" value={nid} />
				<input type="hidden" name="back" value={`/pad?p=${nid}`} />
				<span class="nt-gr"></span>
				<div class="nt-shh">
					<b>New project</b>
					<a class="nt-m" href="/pad">
						Cancel
					</a>
				</div>
				<label class="nt-fi">
					<span class="nt-m">Name</span>
					<input name="title" placeholder="Library website" maxlength="60" autocomplete="off" required />
				</label>
				<div class="nt-cl">
					{COLORS.map((c, i) => (
						<label key={c}>
							<input type="radio" name="color" value={c} checked={i === 0 ? true : undefined} />
							<i style={{ background: c }}></i>
						</label>
					))}
				</div>
				<div class="nt-m">What is it for?</div>
				{TYPE_OPTS.map((o, i) => (
					<label key={o.key} class="nt-op">
						<input type="radio" name="type" value={o.key} checked={i === 0 ? true : undefined} />
						<span class="nt-pv">
							{o.rows.map((r, j) => (
								<div key={j} class="nt-pr2">
									{r === "o" ? <u></u> : null}
									<i></i>
								</div>
							))}
						</span>
						<div>
							<b>{o.title}</b>
							<span class="d">{o.sub}</span>
						</div>
						<span class="nt-rd"></span>
					</label>
				))}
				<label class="nt-tr2">
					<span>Progress bar</span>
					<input type="checkbox" name="bar" value="1" checked class="nt-tgl" />
				</label>
				<button class="nt-go">Create project</button>
				<div class="nt-m" style={{ textAlign: "center" }}>
					You can delete it any time
				</div>
			</form>
		</>
	)
})

export const PadBody = view<Props & { error?: string }>(({ d, tab, f, error }) => (
	<div class="nt-page">
		<Seg tab={tab} />
		{error ? (
			<div class="neg" role="alert" style={{ fontSize: "13px" }}>
				{error}
			</div>
		) : null}
		{tab === "said" ? <Said d={d} tab={tab} f={f} /> : tab === "home" ? <HomeTasks d={d} tab={tab} f={f} /> : <Projects d={d} tab={tab} f={f} />}
		{tab === "new" ? <Sheet /> : null}
	</div>
))

const Mode = view<{ opts: [string, string][] }>(({ opts }) => (
	<div class="nt-tg2">
		{opts.map(([k, label], i) => (
			<label key={k}>
				<input type="radio" name="mode" value={k} checked={i === 0 ? true : undefined} />
				<span>{label}</span>
			</label>
		))}
	</div>
))

export const PadComposer = view<Props>(({ d, tab, f }) => {
	if ((tab === "projects" || tab === "new") && !d.space) return null
	const said = tab === "said"
	const home = tab === "home"
	const type = d.space?.type
	return (
		<form class="nt-cmp" method="post" action="/pad/add">
			<input type="hidden" name="tab" value={said ? "said" : home ? "home" : "projects"} />
			<input type="hidden" name="back" value={padBack(d, tab, f)} />
			{said || home ? null : <input type="hidden" name="space" value={d.space!.id} />}
			<div class="nt-c nt-cin">
				{said ? <input class="nt-who-i" name="who" placeholder="Who" maxlength="40" autocomplete="off" /> : null}
				<input name="body" placeholder={said ? "What did they say…" : home ? "Add a home task…" : type === "notes" ? "Write a note…" : "Write a note or task…"} aria-label="Add" autocomplete="off" required />
				{said ? <Mode opts={[["tip", "Tip"], ["info", "Info"]]} /> : home ? <Mode opts={[["today", "Today"], ["later", "Later"]]} /> : type === "mix" ? <Mode opts={[["task", "Task"], ["note", "Note"]]} /> : null}
				<button class="nt-sd" aria-label="Add">
					<Icon name="send" />
				</button>
			</div>
			{said && d.spaces.length ? (
				<select name="space" class="nt-sel" aria-label="Project">
					<option value="">No project</option>
					{d.spaces.map((x) => (
						<option key={x.id} value={x.id}>
							{x.title}
						</option>
					))}
				</select>
			) : null}
		</form>
	)
})
F_EOF
cat > "$T/file19.css" << 'CSS_EOF'

/* file19: pad + other pages */
.hm{display:block;gap:0;padding-top:0}
.hm-f{display:flex;flex-direction:column;gap:6px;padding-top:8px}
.mm.hm{padding-top:8px}
.hm .cd,.hm .sc,.hm .hero{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none}
.hm .cd{margin-top:8px}
.hm .tg{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .lb,.hm .mu.sm{font-family:var(--h-mono)}
.hm .rw,.hm .by,.hm .db{border-color:var(--h-ln)}
.hm .big{font-size:34px;font-weight:700;letter-spacing:0}
.hm .big2{font-weight:700;letter-spacing:0}
.hm .hd{margin:10px 4px 2px}
.hm .hd h1.t{font-size:18px;font-weight:700;letter-spacing:0}
.hm .btn{background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none;font-family:var(--h-sans)}
.hm .btn.o{background:var(--h-card);border-color:var(--h-acl);color:var(--h-ac)}
.hm .btn.full{border-radius:24px;min-height:48px;font-size:16px}
.hm .btn.off,.hm .btn:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .in,.hm .of input{background:var(--h-card);border:1px solid var(--h-ln2);border-radius:14px;color:var(--h-ink)}
.hm .chip{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .chip.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .av{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .sg{background:var(--h-chip);border-color:var(--h-ln)}
.hm .li:hover{background:var(--h-chip)}
.hm .mt{background:var(--h-bar)}
.hm .mt i{background:var(--h-mu)}
.hm .mt.n i{background:var(--h-pur)}
.hm .pos{color:var(--pos)!important}
.hm .nt-page{padding-top:0}

/* pad */
.nt-c{background:var(--h-card);border-color:var(--h-ln)}
.nt-m{font-family:var(--h-mono);color:var(--h-mu)}
.nt-f{display:contents}
.nt-b{flex:1;min-width:0}
.nt-it{align-items:flex-start}
button.nt-ck{background:none;padding:0;cursor:pointer;color:var(--h-on);flex:none}
button.nt-ck.d{background:var(--h-ac);border-color:var(--h-ac)}
.nt-x{flex:none;width:26px;height:26px;border-radius:50%;border:0;background:none;color:var(--h-mu);padding:0;display:flex;align-items:center;justify-content:center;opacity:.75}
.nt-x svg.ic{width:16px;height:16px;transform:rotate(45deg)}
.nt-em{padding:16px 14px}
.nt-pj{overflow-x:auto;scrollbar-width:none}
.nt-pj::-webkit-scrollbar{display:none}
.nt-pc{text-decoration:none;white-space:nowrap}
.nt-dot{width:8px;height:8px;border-radius:50%;flex:none}
.nt-pc.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.nt-fl a{font:12px var(--h-mono);padding:5px 11px;border-radius:12px;background:var(--h-chip);color:var(--h-mu)}
.nt-fl a.on{background:var(--h-ink);color:var(--h-card)}
.nt-bar2{background:var(--h-bar)}
.nt-bar2 i{background:var(--h-ac)}
.nt-del{text-align:center;margin:2px 0 6px}
.nt-del button{background:none;border:0;padding:6px;color:var(--h-mu);font-size:12px;text-decoration:underline;width:auto}
.nt-who .nt-tag{margin-left:auto}
.nt-cin .nt-who-i{flex:0 0 76px;width:76px;border-right:1px solid var(--h-ln);padding-right:8px;border-radius:0}
.nt-cin input{background:none;border:0;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-tg2{position:relative;background:var(--h-chip)}
.nt-tg2 label{display:flex;margin:0}
.nt-tg2 input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-tg2 input:checked+span{background:var(--h-card);color:var(--h-ac)}
.nt-tg2 span{cursor:pointer}
.nt-sd{background:var(--h-fill);color:var(--h-on)}
.nt-sel{width:100%;margin:6px 0 0;padding:6px 12px;height:34px;border-radius:14px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);font-size:13px}
.nt-cmp{background:var(--bg)}
.nt-sht{max-height:92dvh;overflow:auto;background:var(--h-card)}
.nt-fi{display:block;background:var(--h-bg);margin:0}
.nt-fi input{display:block;width:100%;height:auto;border:0;background:none;padding:0;margin:0;font-size:16px;font-weight:600;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-cl label{position:relative;display:block;margin:0;cursor:pointer}
.nt-cl input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-cl input:checked+i{outline:2px solid var(--h-ink);outline-offset:2px}
.nt-op{position:relative;cursor:pointer;margin:0}
.nt-op input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-op:has(input:checked){border-color:var(--h-ac);background:var(--h-acs)}
.nt-op:has(input:checked) .nt-rd{border:6px solid var(--h-ac)}
.nt-tr2{margin:0;cursor:pointer}
input.nt-tgl[type=checkbox],input.nt-tgl[type=checkbox]:checked{-webkit-appearance:none;appearance:none;background-image:none;width:40px;height:24px;border-radius:12px;border:0;padding:0;margin:0;position:relative;background-color:var(--h-chip);flex:none}
input.nt-tgl[type=checkbox]:checked{background-color:var(--h-ac)}
input.nt-tgl[type=checkbox]::after{content:"";position:absolute;left:3px;right:auto;top:3px;width:18px;height:18px;border-radius:50%;background:var(--h-card);transition:left .15s}
input.nt-tgl[type=checkbox]:checked::after{left:19px}
.nt-go{border:0;width:100%;background:var(--h-fill);color:var(--h-on);text-decoration:none}

/* balance reveal + goals manage row */
.hm-bal{height:auto;min-height:48px;padding:6px 6px 6px 14px}
.hm-dots:has(small){font-size:18px;line-height:1.15;letter-spacing:0}
.hm-two .hm-c{flex:1 1 0}
.hm .gw .db{gap:10px}
CSS_EOF
(cd "$T/p" && node "$T/patch.js" && cp "$T/pad.tsx" app/components/pad.tsx && cp "$T/pad.ts" app/lib/pad.ts && cp "$T/padmeta.ts" app/lib/padmeta.ts && cat "$T/file19.css" >> app/client/app.css)
cp -r "$T/p/app/." app/
echo "done (file19). now run: bun run db:migrate   (creates the pad tables if missing), then bun run dev"
