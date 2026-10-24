import type { Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { calc, gotToday, plain, sourceTag, srcAmount, srcRate } from "../lib/view.ts";
import { Icon } from "./Icon.tsx";
import { Back, Empty, ExpandCard, ListCard, NameChips } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };

const HOUR_CHOICES = [1, 2, 3, 4];

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
));

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`+${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">+{fmt(i.amount)}</b>
			{i.locked ? null : (
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}>
					<Back s={s} />
					<input type="hidden" name="id" value={i.id} />
					<button class="ub" aria-label="Undo income">
						<Icon name="undo" />
					</button>
				</form>
			)}
		</span>
	</div>
));

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

const HoursPanel = view<{ s: State; x: Source; got: Income }>(({ s, x, got }) => {
	const rate = srcRate(x);
	const now = got.hours;
	const summary = now ? `${now}h · +${fmt(Math.round(now * rate))}` : rate ? `${fmt(rate)} per hour` : "no hour price yet";
	return (
		<details class="hrs" data-keep-open={`hrs-${x.id}-${got.day}`} open={true}>
			<summary class="hrs-h">
				<span>Extra hours</span>
				<span class="lb">{summary}</span>
				<span class="hv">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hrs-b">
				{rate ? (
					<>
						<form method="post" action="/income/hours" class="chips hrc">
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							{HOUR_CHOICES.map((h) => (
								<button key={h} class={now === h ? "chip on" : "chip"} name="hours" value={String(h)}>
									{h}h
								</button>
							))}
							{now ? (
								<button class="chip n" name="hours" value="0">
									Clear
								</button>
							) : null}
						</form>
						<form method="post" action="/income/hours" class="ln hrx">
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input class="in" name="hours" placeholder="Other number of hours" inputmode="decimal" autocomplete="off" required />
							<button class="btn xs o">Add</button>
						</form>
					</>
				) : (
					<div class="lb">Tap the pencil on the Income page and type the price for one extra hour.</div>
				)}
			</div>
		</details>
	);
});

const noteOf = (x: Source, got: Income[]) => (x.type === "job" && got[0] ? (got[0].hours ? `${fmt(got[0].amount)} · ${got[0].hours}h extra` : `${fmt(got[0].amount)} · no extra hours`) : "");

const SourceRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x);
	const note = noteOf(x, got);
	return (
		<div class="srw">
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{sourceTag(x)}</span>
					</div>
					{note ? <div class="lb">{note}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle />
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			{x.type === "job" && x.active && got[0] ? <HoursPanel s={s} x={x} got={got[0]} /> : null}
		</div>
	);
});

const QuickIncome = view<{ s: State }>(({ s }) => (
	<form method="post" action="/history/income" class="qi">
		<Back s={s} />
		<NameChips names={s.incomeNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Other income name" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs">Add</button>
		</div>
	</form>
));

const SourceList = view<{ s: State }>(({ s }) => {
	const others = s.incomesToday.filter((i) => !i.sourceId);
	return s.sources.length || others.length ? (
		<>
			{s.sources.map((x) => (
				<SourceRow key={x.id} s={s} x={x} />
			))}
			{others.map((i) => (
				<IncomeRow key={i.id} s={s} i={i} />
			))}
		</>
	) : (
		<Empty>No sources yet. Add one below.</Empty>
	);
});

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x);
	const note = noteOf(x, got);
	return (
		<div class="srw">
			<div class="rw">
				<div>
					<div>{x.name}</div>
					{note ? <div class="lb">{note}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle={false} />
				</span>
			</div>
			{x.type === "job" && got[0] ? <HoursPanel s={s} x={x} got={got[0]} /> : null}
		</div>
	);
});

const MODES = [
	{ key: "manual", label: "Manual" },
	{ key: "job", label: "Fixed + hours" },
	{ key: "daily", label: "Auto daily" },
	{ key: "monthly", label: "Monthly" },
];

const ModeChips = view(() => (
	<>
		<input type="hidden" name="mode" value="manual" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 4px" }}>
			{MODES.map((m) => (
				<span key={m.key} class={m.key === "manual" ? "chip on" : "chip"} data-mode={m.key} style={{ cursor: "pointer" }}>
					{m.label}
				</span>
			))}
		</div>
		<div class="lb mh mh-manual" style={{ marginBottom: "2px" }}>
			Manual: you tap it once a day. Leave the amount empty if the number is different each day.
		</div>
		<div class="lb mh mh-job" style={{ marginBottom: "2px" }}>
			Fixed + hours: the same pay each day, plus a price for every extra hour. After you tap it on Home you pick the extra hours.
		</div>
		<div class="lb mh mh-daily" style={{ marginBottom: "2px" }}>
			Auto daily: the money is added for you every day.
		</div>
		<div class="lb mh mh-monthly" style={{ marginBottom: "2px" }}>
			Monthly: the money is added for you once a month.
		</div>
	</>
));

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<div class="ln">
			<input class="in" name="name" placeholder="Source name (like Construction)" autocomplete="off" required />
			<input class="in pr src-amt" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
		</div>
		<div class="ln src-job">
			<input class="in" name="fixed" placeholder="Fixed per day" inputmode="decimal" autocomplete="off" />
			<input class="in" name="rate" placeholder="Price per hour" inputmode="decimal" autocomplete="off" />
		</div>
		<ModeChips />
		<button class="btn full">Add source</button>
	</>
));

const AddSourceForm = view<{ s: State; id: string }>(({ s, id }) => (
	<form method="post" action="/income" id={id} class="sc spf" data-adp data-m="manual" hidden>
		<SourceFields s={s} />
	</form>
));

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-adp data-m="manual" hidden>
		<SourceFields s={s} />
	</form>
));

export const IncomeDesktop = view<{ s: State; title?: string; id?: string }>(({ s, title = "Income sources", id = "f-src-d" }) => (
	<>
		<AddSourceForm s={s} id={id} />
		<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add source">
			<SourceList s={s} />
			<QuickIncome s={s} />
		</ListCard>
	</>
));

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixed = srcAmount(x);
	const rate = srcRate(x);
	const job = x.type === "job";
	return (
		<div class="dbw">
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{sourceTag(x)}</span>
					</div>
					{fixed ? <div class="lb">{`${fmt(fixed)} ${s.user.currency}${job ? ` + ${rate ? fmt(rate) : "?"} per hour` : ""}`}</div> : null}
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
				{job ? (
					<>
						<div class="ln">
							<input class="in f" name="name" value={x.name} autocomplete="off" required />
						</div>
						<div class="ln" style={{ marginTop: "8px" }}>
							<input class="in" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Fixed per day" inputmode="decimal" autocomplete="off" />
							<input class="in" name="rate" value={rate ? plain(rate) : ""} placeholder="Price per hour" inputmode="decimal" autocomplete="off" />
							<button class="btn xs">Save</button>
						</div>
					</>
				) : (
					<div class="ln">
						<input class="in f" name="name" value={x.name} autocomplete="off" required />
						<input class="in pr2" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Amount" inputmode="decimal" autocomplete="off" />
						<button class="btn xs">Save</button>
					</div>
				)}
			</form>
		</div>
	);
});

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
					<NameChips names={s.incomeNames} />
					<div class="ln">
						<input class="in" name="label" data-name placeholder="Name (like Fiverr)" autocomplete="off" />
						<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
					</div>
					<button class="btn full">Add income</button>
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
