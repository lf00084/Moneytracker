#!/bin/bash
set -e
cd "$(dirname "$0")"
if grep -q "file20:" app/client/app.css 2>/dev/null; then echo "already applied"; exit 0; fi
if ! grep -q "file19:" app/client/app.css 2>/dev/null; then echo "run file18.sh and file19.sh first"; exit 1; fi
for f in app/screens.tsx app/routes.ts app/commands.ts app/controllers/pages.tsx app/lib/data.ts app/lib/exoclick.ts app/components/ui.tsx app/components/buys.tsx app/components/profile.tsx app/components/income.tsx app/client/app.js; do [ -f "$f" ] || { echo "run this inside the Moneytracker folder (missing $f)"; exit 1; }; done
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

// + button lives inside the summary so it centers with the arrow
const btn = `		{label ? (
			<button type="button" class="xp" data-xplus aria-label={label}>
				<Icon name="plus" />
			</button>
		) : null}
`
rep("app/components/ui.tsx", btn, "")
rep(
	"app/components/ui.tsx",
	"			</summary>",
	`				{label ? (
					<button type="button" class="xp" data-xplus aria-label={label}>
						<Icon name="plus" />
					</button>
				) : null}
			</summary>`,
)
rep("app/client/app.js", `if (t.closest && t.closest("details[data-fixed] > summary")) {`, `if (t.closest && !t.closest("[data-xplus]") && t.closest("details[data-fixed] > summary")) {`)
rep("app/client/app.js", `		if ((q = t.closest("[data-xplus]"))) {\n`, `		if ((q = t.closest("[data-xplus]"))) {\n			e.preventDefault()\n`)
fs.appendFileSync("app/client/app.js", read(process.argv[2] + "/client.js"))

// today's buys: empty text inside the header row
rep("app/components/buys.tsx", `		title="Today's buys"\n		label="Add a spend"\n`, `		title="Today's buys"\n		label="Add a spend"\n		head={s.buys.length ? undefined : <span class="em">Nothing bought today.</span>}\n`)
rep("app/components/buys.tsx", `		<BuyRows s={s} />\n	</ExpandCard>`, `		{s.buys.length ? <BuyRows s={s} /> : null}\n	</ExpandCard>`)

// profile balance card = same compact card as home
between(
	"app/components/profile.tsx",
	"export const BalanceCard",
	"const ProfileForm",
	`export const BalanceCard = view<{ s: State; edit?: boolean }>(({ s, edit = false }) => (
	<div class="cd hm-balc">
		<div class="hm-bal">
			<b class="hm-dots" data-bal={\`\${s.balance < 0 ? "−" : ""}\${fmt(Math.abs(s.balance))}\`} data-cur={s.user.currency}>
				••••••
			</b>
			<button type="button" class="ib" data-eye aria-label="Show balance">
				<Icon name="eye" />
			</button>
			{edit ? (
				<button type="button" class="lnk" data-edit-bal>
					Edit balance
				</button>
			) : null}
			<div class="hm-m">Total balance</div>
		</div>
		{edit ? (
			<div class="hm-bedit" data-balf hidden>
				<BalanceForm s={s} />
			</div>
		) : null}
	</div>
))

`,
)

// exoclick invoice
fs.appendFileSync("app/lib/exoclick.ts", read(process.argv[2] + "/exo.ts"))
rep("app/lib/data.ts", `import { exoStatus, liveExo, settleExo } from "./exoclick.ts"`, `import { exoStatus, latestInvoice, liveExo, settleExo, type Invoice } from "./exoclick.ts"`)
rep("app/lib/data.ts", `"avatar" | "names"`, `"avatar" | "invoice" | "names"`)
rep("app/lib/data.ts", `	balance: number\n}`, `	balance: number\n	invoice: Invoice | null\n}`)
rep("app/lib/data.ts", `		balance: 0,\n`, `		balance: 0,\n		invoice: null,\n`)
rep("app/lib/data.ts", `	if (need.has("avatar")) jobs.push(`, `	if (need.has("invoice")) jobs.push(latestInvoice(uid).then((v) => void (s.invoice = v)))\n	if (need.has("avatar")) jobs.push(`)
rep("app/controllers/pages.tsx", `income: page("/income", ["sources", "today"]`, `income: page("/income", ["sources", "today", "invoice"]`)
rep(
	"app/components/income.tsx",
	"export const IncomeExpand = view<",
	`export const InvoiceCard = view<{ s: State }>(({ s }) => {
	const v = s.invoice
	if (!v) return null
	const label = v.status === "paid" ? "Paid" : v.status === "processing" ? "Processing" : "Pending"
	const sub = v.status === "paid" ? (v.paid ? \`paid \${v.paid}\` : "paid") : v.due ? \`due \${v.due}\` : v.date ? \`issued \${v.date}\` : ""
	return (
		<div class="hm-c inv" data-inv={\`\${v.id}:\${v.status}\`}>
			<div>
				<div class="hm-m">{\`ExoClick invoice\${v.period ? \` · \${v.period}\` : ""}\`}</div>
				<div class="inv-a">{\`$\${v.usd.toFixed(2)}\`}</div>
				{sub ? <div class="hm-m">{sub}</div> : null}
			</div>
			<span class={\`inv-st \${v.status}\`}>{label}</span>
			<button type="button" class="ub" data-inv-x aria-label="Close">
				<Icon name="plus" />
			</button>
		</div>
	)
})

export const IncomeExpand = view<`,
)
rep("app/screens.tsx", `import { HomeIncome, IncomeDesktop, IncomeExpand } from`, `import { HomeIncome, IncomeDesktop, IncomeExpand, InvoiceCard } from`)
rep("app/screens.tsx", `<IncomeExpand s={s} />`, `<InvoiceCard s={s} />\n<IncomeExpand s={s} />`, 2)

// pad edit
rep("app/routes.ts", `		padDel: post("/pad/delete"),\n`, `		padDel: post("/pad/delete"),\n		padEdit: post("/pad/edit"),\n`)
rep("app/commands.ts", `	padDel: {`, `	padEdit: { run: (u, f) => pad.editEntry(u.id, f), to: "/pad" },\n	padDel: {`)
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

export async function editEntry(uid: string, f: FormData): Result {
	const body = text(f.get("body"), 2000)
	if (!body) return "Write something first"
	await db.updateMany(padEntries, { body, updated_at: Date.now() }, { where: { id: text(f.get("id"), 36), user_id: uid } })
}
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

const EditForm = view<{ e: Entry; back: string }>(({ e, back }) => (
	<form method="post" action="/pad/edit" class="nt-edit" data-edit hidden>
		<Hid id={e.id} back={back} />
		<textarea name="body" rows="2" maxlength="2000" aria-label="Edit">
			{e.body}
		</textarea>
		<div class="nt-eb">
			<button type="button" class="btn xs o" data-edit-x>
				Cancel
			</button>
			<button class="btn xs">Save</button>
		</div>
	</form>
))

const Row = view<{ e: Entry; back: string }>(({ e, back }) => {
	const note = e.kind === "note"
	const done = e.kind === "done"
	return (
		<div class={done ? "nt-it dn" : note ? "nt-it nt" : "nt-it"} data-pad-item>
			{note ? null : (
				<form method="post" action="/pad/toggle" class="nt-f">
					<Hid id={e.id} back={back} />
					<button class={done ? "nt-ck d" : "nt-ck"} aria-label={done ? "Mark as open" : "Mark as done"}>
						{done ? <Icon name="check" /> : null}
					</button>
				</form>
			)}
			<div class="nt-b" data-copy>
				<p>{e.body}</p>
				{note ? <div class="nt-m">{`note · ${timeAgo(e.at)}`}</div> : null}
			</div>
			<EditForm e={e} back={back} />
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
						<div key={e.id} class="nt-q" data-pad-item>
							<div class="nt-b" data-copy>
								<p>{e.body}</p>
							</div>
							<EditForm e={e} back={back} />
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
cat > "$T/exo.ts" << 'F_EOF'

export type Invoice = { id: string; status: "pending" | "processing" | "paid"; usd: number; period: string; date: string; due: string; paid: string }
const invCache = new Map<string, { at: number; v: Invoice | null }>()
const INVOICE_PATHS = ["/payments", "/publisher/payments", "/payments/p", "/invoices"]
const ymd = (v: unknown) => {
	const d = String(v ?? "")
	return /^\d{4}-\d{2}-\d{2}/.test(d) ? d.slice(0, 10) : ""
}
const toInvoice = (r: any): Invoice | null => {
	if (!r || typeof r !== "object") return null
	const raw = String(r.status ?? r.state ?? r.payment_status ?? "").toLowerCase()
	const paid = ymd(r.payment_date ?? r.paid_at ?? r.date_paid ?? r.paid_date)
	const status = (raw.includes("paid") && !raw.includes("unpaid")) || (!raw && paid) ? "paid" : raw.includes("process") ? "processing" : "pending"
	const usd = Number(r.total ?? r.amount ?? r.revenue ?? r.sum ?? 0) || 0
	const date = ymd(r.date ?? r.invoice_date ?? r.created_at ?? r.created ?? r.generated)
	const from = ymd(r.period_from ?? r.date_from ?? r.from ?? r.period_start)
	const to = ymd(r.period_to ?? r.date_to ?? r.to ?? r.period_end)
	const period = typeof r.period === "string" ? r.period : from && to ? `${from} to ${to}` : ""
	return { id: String(r.id ?? r.invoice_id ?? r.invoice_number ?? `${date}${usd}`), status, usd, period, date, due: ymd(r.due_date ?? r.due), paid }
}

export async function latestInvoice(uid: string): Promise<Invoice | null> {
	try {
		const all = await db.findMany(incomeSources, { where: { user_id: uid, type: "exoclick" } })
		const src = all.find((s) => s.active !== 0 && String(parseJson(s.config).key_enc ?? ""))
		if (!src) return null
		const hit = invCache.get(src.id)
		if (hit && Date.now() - hit.at < 15 * 60000) return hit.v
		const apiKey = await decryptSecret(String(parseJson(src.config).key_enc))
		const token = apiKey ? await login(apiKey) : null
		if (!token) return null
		let v: Invoice | null = null
		for (const p of INVOICE_PATHS) {
			const r = await jf(`${BASE}${p}`, { headers: { Authorization: `Bearer ${token}`, Accept: "application/json" } }).catch(() => null)
			if (!r || !r.ok) continue
			const rows = listOf(await r.json().catch(() => null))
				.map(toInvoice)
				.filter((x): x is Invoice => !!x)
				.sort((a, b) => b.date.localeCompare(a.date))
			if (rows.length) {
				v = rows[0]!
				break
			}
		}
		invCache.set(src.id, { at: Date.now(), v })
		return v
	} catch {
		return null
	}
}
F_EOF
cat > "$T/client.js" << 'F_EOF'

/* file20 */
;(function () {
	var d = document
	var hold = 0
	var fired = false
	var sx = 0
	var sy = 0
	var toast = function (t) {
		var x = d.createElement("div")
		x.className = "nt-toast"
		x.textContent = t
		d.body.appendChild(x)
		setTimeout(function () {
			x.remove()
		}, 1100)
	}
	var copy = function (t) {
		try {
			if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(t)
		} catch (e) {}
		var a = d.createElement("textarea")
		a.value = t
		a.style.cssText = "position:fixed;opacity:0"
		d.body.appendChild(a)
		a.select()
		try {
			d.execCommand("copy")
		} catch (e) {}
		a.remove()
		return Promise.resolve()
	}
	var edit = function (it) {
		var f = it && it.querySelector("[data-edit]")
		var b = it && it.querySelector("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		var ta = f.querySelector("textarea")
		ta.focus()
		ta.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "center", behavior: "smooth" })
	}
	d.addEventListener("pointerdown", function (e) {
		var b = e.target.closest && e.target.closest("[data-copy]")
		if (!b) return
		fired = false
		sx = e.clientX
		sy = e.clientY
		clearTimeout(hold)
		hold = setTimeout(function () {
			fired = true
			if (navigator.vibrate) navigator.vibrate(15)
			edit(b.closest("[data-pad-item]"))
		}, 450)
	})
	d.addEventListener("pointermove", function (e) {
		if (hold && (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8)) clearTimeout(hold)
	})
	;["pointerup", "pointercancel", "pointerleave"].forEach(function (n) {
		d.addEventListener(n, function () {
			clearTimeout(hold)
		}, true)
	})
	d.addEventListener("contextmenu", function (e) {
		if (e.target.closest && e.target.closest("[data-copy]")) e.preventDefault()
	})
	d.addEventListener("click", function (e) {
		var t = e.target
		var b = t.closest && t.closest("[data-copy]")
		if (b) {
			if (fired) {
				fired = false
				return
			}
			var p = b.querySelector("p")
			copy((p || b).textContent.trim()).then(function () {
				toast("Copied")
			})
			return
		}
		var x = t.closest && t.closest("[data-edit-x]")
		if (x) {
			var it = x.closest("[data-pad-item]")
			it.querySelector("[data-edit]").hidden = true
			it.querySelector("[data-copy]").hidden = false
			return
		}
		var a = t.closest && t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")
		if (a) {
			setTimeout(function () {
				var box = a.closest(".xc,.dbw,.sc,.cd") || d
				var f = [].slice.call(box.querySelectorAll("[data-adp],[data-addp],[data-payp]")).filter(function (n) {
					return !n.hidden && n.offsetParent
				})[0]
				if (!f) return
				var i = f.querySelector("input:not([type=hidden]),textarea")
				if (i) i.focus({ preventScroll: true })
				f.scrollIntoView({ block: "center", behavior: "smooth" })
			}, 60)
		}
	})

	var dis = {}
	try {
		dis = JSON.parse(localStorage.getItem("mt:inv") || "{}")
	} catch (e) {}
	;[].slice.call(d.querySelectorAll("[data-inv]")).forEach(function (n) {
		if (dis[n.getAttribute("data-inv")]) n.hidden = true
	})
	d.addEventListener("click", function (e) {
		var x = e.target.closest && e.target.closest("[data-inv-x]")
		if (!x) return
		var n = x.closest("[data-inv]")
		dis[n.getAttribute("data-inv")] = 1
		try {
			localStorage.setItem("mt:inv", JSON.stringify(dis))
		} catch (err) {}
		n.hidden = true
	})
})()
F_EOF
cat > "$T/file20.css" << 'CSS_EOF'

/* file20: spacing, shadow, centered icons, invoice, pad edit */
.hm-f{gap:12px}
.hm-two{gap:10px}
.hm .cd{margin-top:12px}
.nt-page{gap:12px}
.hm-c,.hm .xc,.hm .cd,.hm .sc,.hm .hero,.nt-c{box-shadow:var(--sh1)}
.bt{box-shadow:var(--sh1)}

/* header icons centered inside the summary */
.hm .xp{top:50%;margin-top:-19px;right:14px}
.hm .xc:has(details[data-fixed]) .xp{top:50%}
.hm .xc .chev{top:50%;margin-top:-11px}
.hm .xc:has(.xp.on) .chev{display:none}
.hm details[data-fixed]>.xh{padding:9px 70px 9px 16px}
.hm .xb:empty{display:none}
.hm .osum .ow .em{font:400 14px/1.4 var(--h-sans);color:var(--h-mu)}

/* balance card (home + profile) */
.hm-bal{column-gap:0;grid-template-columns:1fr auto auto;grid-template-areas:"l e b" "v e b"}
.hm-bal .ib{margin-left:10px}
.hm-bal .lnk{grid-area:e;align-self:center;margin-left:10px}
.hm-balc{padding:0;overflow:hidden}
.hm-bedit{padding:0 14px 14px}

/* exoclick invoice */
.inv{display:flex;align-items:center;gap:10px;padding:8px 8px 8px 14px;margin-bottom:12px}
.inv>div:first-child{flex:1;min-width:0}
.inv-a{font-size:20px;font-weight:700;line-height:1.2}
.inv-st{font:600 12px/1 var(--h-mono);padding:5px 10px;border-radius:12px;background:var(--h-chip);color:var(--h-mu);flex:none}
.inv-st.pending{background:rgba(166,106,0,.14);color:var(--h-earn)}
.inv-st.processing{background:rgba(109,79,214,.14);color:var(--h-pur)}
.inv-st.paid{background:rgba(18,161,80,.14);color:var(--pos)}
.inv .ub svg.ic{transform:rotate(45deg)}

/* pad: tap copies, long press edits */
.nt-b{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;cursor:pointer}
.nt-it,.nt-q{flex-wrap:wrap}
.nt-q .nt-b p{margin:0 0 10px}
.nt-edit{flex:1 1 0;min-width:0;display:flex;flex-direction:column;gap:8px;margin:0}
.nt-edit textarea{width:100%;margin:0;padding:8px 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font:15px/1.35 var(--h-sans);resize:none}
.nt-eb{display:flex;gap:8px;justify-content:flex-end}
.nt-toast{position:fixed;left:50%;bottom:96px;transform:translateX(-50%);background:var(--h-ink);color:var(--h-card);padding:8px 16px;border-radius:18px;font-size:13px;z-index:60}
CSS_EOF
(cd "$T/p" && node "$T/patch.js" "$T" && cp "$T/pad.tsx" app/components/pad.tsx && cp "$T/pad.ts" app/lib/pad.ts && cat "$T/file20.css" >> app/client/app.css)
cp -r "$T/p/app/." app/
echo "done (file20). restart: bun run dev"
