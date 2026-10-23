import type { Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { calc, gotToday, plain, sourceTag, srcAmount } from "../lib/view.ts";
import { Icon } from "./Icon.tsx";
import { Back, Empty, ExpandCard, ListCard } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };

/** The hidden fields every income form carries: where to come back to, and which row. */
const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
));

/** An income that is not tied to a source ("Other income today") or one already added today. */
export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
		</div>
		<span class="rt">
			<b class="ea">+{fmt(i.amount)}</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<button class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
));

/** What you can do with a source right now: add today's money, undo it, or pause/resume. */
const SourceMain = view<{ s: State; x: Source; toggle: boolean }>(({ s, x, toggle }) => {
	const got = gotToday(s, x);
	const sum = got.reduce((a, i) => a + i.amount, 0);
	const fixed = srcAmount(x);
	const auto = x.mode === "auto";

	if (toggle && !x.active) {
		return (
			<form method="post" action="/income/toggle" style={contents}>
				<Hid s={s} id={x.id} />
				<button class="btn xs o">Resume</button>
			</form>
		);
	}
	if (auto) {
		return (
			<>
				<b class="ea">+{fmt(x.amount)}</b>
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		);
	}
	if (got.length) {
		return (
			<>
				<button class="btn xs" disabled>
					Added
				</button>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		);
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o">Add {fmt(fixed)}</button>
			</form>
		);
	}
	return (
		<form method="post" action="/income/add" class="ln" style={{ gap: "6px" }}>
			<Back s={s} />
			<input type="hidden" name="source_id" value={x.id} />
			<input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs o">Add</button>
		</form>
	);
});

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
));

/** Row on the desktop income card. */
const SourceRow = view<{ s: State; x: Source }>(({ s, x }) => (
	<div class="rw">
		<div>
			<div>
				{x.name}
				<span class="tag">{sourceTag(x)}</span>
			</div>
		</div>
		<span class="rt">
			<SourceMain s={s} x={x} toggle />
			<DeleteSource s={s} x={x} />
		</span>
	</div>
));

const SourceList = view<{ s: State }>(({ s }) => (s.sources.length ? <>{s.sources.map((x) => <SourceRow key={x.id} s={s} x={x} />)}</> : <Empty>No sources yet. Add one below.</Empty>));

/** Row on the phone home screen: only active sources. */
const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => (
	<div class="rw">
		<div>
			<div>{x.name}</div>
		</div>
		<span class="rt">
			<SourceMain s={s} x={x} toggle={false} />
		</span>
	</div>
));

/** Manual / daily / monthly picker for a new source. */
const ModeChips = view(() => (
	<>
		<input type="hidden" name="mode" value="manual" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 4px" }}>
			<span class="chip on" data-mode="manual" style={{ cursor: "pointer" }}>
				Manual
			</span>
			<span class="chip" data-mode="daily" style={{ cursor: "pointer" }}>
				Auto daily
			</span>
			<span class="chip" data-mode="monthly" style={{ cursor: "pointer" }}>
				Monthly
			</span>
		</div>
		<div class="lb" style={{ marginBottom: "2px" }}>
			Manual: you tap it, once a day. Auto: added for you.
		</div>
	</>
));

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<div class="ln">
			<input class="in" name="name" placeholder="New source" autocomplete="off" required />
			<input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
		</div>
		<ModeChips />
		<button class="btn full">Add source</button>
	</>
));

/** Desktop: add-source form that the card's big "+" reveals. */
const AddSourceForm = view<{ s: State; id: string }>(({ s, id }) => (
	<form method="post" action="/income" id={id} class="sc spf" data-adp hidden>
		<SourceFields s={s} />
	</form>
));

/** Phone: add-source form inside the card footer. */
const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-adp hidden>
		<SourceFields s={s} />
	</form>
));

/** Desktop income card with its add form. */
export const IncomeDesktop = view<{ s: State; title?: string; id?: string }>(({ s, title = "Income sources", id = "f-src-d" }) => (
	<>
		<AddSourceForm s={s} id={id} />
		<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add source">
			<SourceList s={s} />
		</ListCard>
	</>
));

/** One source in manage mode: pause/resume, edit, delete. */
const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixed = srcAmount(x);
	return (
		<div class="dbw">
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{sourceTag(x)}</span>
					</div>
					{fixed ? <div class="lb">{`${fmt(fixed)} ${s.user.currency}`}</div> : null}
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
				<div class="ln">
					<input class="in f" name="name" value={x.name} autocomplete="off" required />
					<input class="in pr2" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Amount" inputmode="decimal" autocomplete="off" />
					<button class="btn xs">Save</button>
				</div>
			</form>
		</div>
	);
});

/** Phone "Income sources" card on the income page. */
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
));

/** Phone "Income today" card on the home screen. */
export const HomeIncome = view<{ s: State }>(({ s }) => {
	const c = calc(s);
	const sources = s.sources.filter((x) => x.active);
	const others = s.incomesToday.filter((i) => !i.sourceId);
	return (
		<ExpandCard
			storeKey="inc"
			open
			title="Income today"
			label="Add other income"
			head={
				<>
					<b class="big2">
						+{fmt(c.earned)} <small>{s.user.currency}</small>
					</b>
					<span class="lb">{c.earnedLine}</span>
				</>
			}
			form={
				<form method="post" action="/history/income" class="sf xfm" data-adp hidden>
					<Back s={s} />
					<div class="ln">
						<input class="in" name="amount" placeholder="Other income today" inputmode="decimal" autocomplete="off" required />
						<button class="btn">Add</button>
					</div>
				</form>
			}
		>
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
				<Empty>No sources yet.</Empty>
			)}
		</ExpandCard>
	);
});
