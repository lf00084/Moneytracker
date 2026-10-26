import { COLORS, type Entry, type PadData, type Space } from "../lib/padmeta.ts"
import { timeAgo } from "../lib/time.ts"
import { Icon, Submit, view } from "./ui.tsx"

export type PadTab = "projects" | "said" | "home" | "new" | "edit"

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
			<a key={x.key} href={x.href} class={x.key === tab || ((tab === "new" || tab === "edit") && x.key === "projects") ? "on" : ""}>
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

// Edit uses the same look as the add bar, pre-filled with the current text.
const EditForm = view<{ e: Entry; back: string }>(({ e, back }) => (
	<form method="post" action="/pad/edit" class="nt-edit" data-edit hidden>
		<Hid id={e.id} back={back} />
		<div class="nt-c nt-cin">
			<input name="body" value={e.body} maxlength="2000" aria-label="Edit" autocomplete="off" required />
			<button type="button" class="nt-xc" data-edit-x aria-label="Cancel edit">
				<Icon name="plus" />
			</button>
			<Submit class="nt-sd" aria-label="Save">
				<Icon name="send" />
			</Submit>
		</div>
	</form>
))

// Settings icon with a dropdown: Edit and Delete.
const RowMenu = view<{ e: Entry; back: string }>(({ e, back }) => (
	<div class="nt-mn">
		<button type="button" class="nt-x" data-menu aria-label="Options" aria-haspopup="menu" aria-expanded="false">
			<Icon name="gear" />
		</button>
		<div class="nt-dd" role="menu" hidden>
			<button type="button" role="menuitem" data-menu-edit>
				<Icon name="edit" />
				Edit
			</button>
			<form method="post" action="/pad/delete" class="nt-f" data-confirm="Delete this?">
				<Hid id={e.id} back={back} />
				<Submit role="menuitem" class="dg">
					<Icon name="trash" />
					Delete
				</Submit>
			</form>
		</div>
	</div>
))

const Row = view<{ e: Entry; back: string }>(({ e, back }) => {
	const note = e.kind === "note"
	const done = e.kind === "done"
	return (
		<div class={done ? "nt-it dn" : note ? "nt-it nt" : "nt-it"} data-pad-item>
			{note ? null : (
				<form method="post" action="/pad/toggle" class="nt-f">
					<Hid id={e.id} back={back} />
					<Submit class={done ? "nt-ck d" : "nt-ck"} aria-label={done ? "Mark as open" : "Mark as done"}>
						{done ? <Icon name="check" /> : null}
					</Submit>
				</form>
			)}
			<div class="nt-b" data-copy>
				<p>{e.body}</p>
				{note ? <div class="nt-m">{`note · ${timeAgo(e.at)}`}</div> : null}
			</div>
			<EditForm e={e} back={back} />
			<RowMenu e={e} back={back} />
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
	const all = d.entries.filter((e) => e.space === sp.id && e.kind !== "said").reverse()
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
			<div class="nt-c nt-ph nt-pg">
				{sp.bar && sp.type !== "notes" ? <i class={open + done > 0 && done === open + done ? "nt-pgf full" : "nt-pgf"} style={{ width: `${open + done ? Math.round((done / (open + done)) * 100) : 0}%` }}></i> : null}
				<b>{sp.title}</b>
				<span class="nt-m">{`${open} open · ${done} done`}</span>
				<a class="nt-gs" href={`/pad/project?p=${sp.id}`} aria-label="Project settings">
					<Icon name="gear" />
				</a>
			</div>
			{sp.type === "mix" ? <Filters base={`/pad?p=${sp.id}`} f={f} items={[["All", ""], ["Tasks", "tasks"], ["Notes", "notes"]]} /> : null}
			<div class="nt-c nt-list nt-scr" data-bottom>{list.length ? list.map((e) => <Row key={e.id} e={e} back={back} />) : <Empty>{sp.type === "notes" ? "No notes yet. Write one below." : "Nothing here yet. Add one below."}</Empty>}</div>
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
								<RowMenu e={e} back={back} />
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
	const all = d.entries.filter((e) => !e.space && (e.kind === "task" || e.kind === "done")).reverse()
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

const Sheet = view<{ sp?: Space | null }>(({ sp }) => {
	const nid = sp ? sp.id : crypto.randomUUID()
	const close = sp ? `/pad?p=${sp.id}` : "/pad"
	return (
		<>
			<a class="nt-ov" href={close} aria-label="Close"></a>
			<form class="nt-sht" method="post" action={sp ? "/pad/space/edit" : "/pad/space"}>
				{sp ? <input type="hidden" name="id" value={sp.id} /> : <input type="hidden" name="nid" value={nid} />}
				<input type="hidden" name="back" value={`/pad?p=${nid}`} />
				<span class="nt-gr"></span>
				<div class="nt-shh">
					<b>{sp ? "Edit project" : "New project"}</b>
					<a class="nt-m" href={close}>
						Cancel
					</a>
				</div>
				<label class="nt-fi">
					<span class="nt-m">Name</span>
					<input name="title" value={sp?.title} placeholder="Library website" maxlength="60" autocomplete="off" required />
				</label>
				<div class="nt-cl">
					{COLORS.map((c, i) => (
						<label key={c}>
							<input type="radio" name="color" value={c} checked={(sp ? sp.color === c : i === 0) ? true : undefined} />
							<i style={{ background: c }}></i>
						</label>
					))}
				</div>
				<div class="nt-m">What is it for?</div>
				{TYPE_OPTS.map((o, i) => (
					<label key={o.key} class="nt-op">
						<input type="radio" name="type" value={o.key} checked={(sp ? sp.type === o.key : i === 0) ? true : undefined} />
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
					<input type="checkbox" name="bar" value="1" checked={!sp || sp.bar ? true : undefined} class="nt-tgl" />
				</label>
				<Submit class="nt-go">{sp ? "Save project" : "Create project"}</Submit>
				{sp ? (
					<Submit class="nt-go dg" formaction="/pad/space/delete" formnovalidate data-confirm-btn={`Delete ${sp.title} and everything in it?`}>
						Delete project
					</Submit>
				) : (
					<div class="nt-m" style={{ textAlign: "center" }}>
						You can delete it any time
					</div>
				)}
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
		{tab === "new" ? <Sheet /> : tab === "edit" && d.space ? <Sheet sp={d.space} /> : null}
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
	if ((tab === "projects" || tab === "new" || tab === "edit") && !d.space) return null
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
				<Submit class="nt-sd" aria-label="Add">
					<Icon name="send" />
				</Submit>
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
