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
