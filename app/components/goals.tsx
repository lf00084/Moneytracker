import type { Goal, GoalItem, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { canAfford, goalLeft, goalStat, pctOf } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const ItemRow = view<{ s: State; it: GoalItem; manage: boolean }>(({ s, it, manage }) => {
	const ok = canAfford(s, it)
	const cls = it.done ? "gi gdone" : "gi"
	const hid = () => (
		<>
			<Back s={s} />
			<input type="hidden" name="id" value={it.id} />
		</>
	)
	const name = (
		<>
			<span class="gn">{it.name}</span>
			<span class="lb">{fmt(it.price)}</span>
		</>
	)

	if (!manage) {
		return (
			<div class={cls}>
				{name}
				<span class="wb">
					{it.done ? null : (
						<form method="post" action="/goals/buy" style={contents} data-confirm={`Mark ${it.name} as bought? It will be added as a spend.`}>
							{hid()}
							<Submit class={ok ? "btn xs" : "btn xs off"} disabled={ok ? undefined : true}>
								Bought
							</Submit>
						</form>
					)}
				</span>
			</div>
		)
	}

	return (
		<div class="dbw">
			<div class={cls}>
				{name}
				<span class="wb">
					{it.done ? null : (
						<button type="button" class="ub" data-pay aria-label={`Edit ${it.name}`}>
							<Icon name="edit" />
						</button>
					)}
					<form method="post" action="/goals/item/delete" style={contents} data-confirm={`Remove ${it.name} from this goal?`}>
						{hid()}
						<Submit class="ub" aria-label={`Remove ${it.name}`}>
							<Icon name="trash" />
						</Submit>
					</form>
				</span>
			</div>
			{it.done ? null : (
				<form method="post" action="/goals/item/edit" class="ad" data-payp hidden>
					{hid()}
					<label>Edit {it.name}</label>
					<div class="ln">
						<input class="in f" name="name" value={it.name} autocomplete="off" required />
						<input class="in pr2" name="price" value={plain(it.price)} placeholder="Price" inputmode="decimal" autocomplete="off" required />
						<Submit class="btn xs">Save</Submit>
					</div>
				</form>
			)}
		</div>
	)
})

const GoalRow = view<{ s: State; g: Goal; manage: boolean }>(({ s, g, manage }) => {
	const pct = pctOf(s, g)
	const info = (
		<div class="dn">
			<div class="l1">
				<b>{g.title}</b>
				<span class="lb">{goalLeft(s, g)}</span>
			</div>
			<div class={pct >= 100 ? "mt s full" : "mt s"}>
				<i style={{ width: `${pct}%` }}></i>
			</div>
		</div>
	)
	const items = g.items.map((it) => <ItemRow key={it.id} s={s} it={it} manage={manage} />)

	if (!manage) {
		return (
			<div class="gw">
				<div class="db">{info}</div>
				{items}
			</div>
		)
	}

	return (
		<div class="gw">
			<div class="dbw">
				<div class="db">
					<button type="button" class="ib sm hi" data-tg aria-label={`Add item to ${g.title}`}>
						<Icon name="plus" />
					</button>
					{info}
					<span class="wb">
						<button type="button" class="ub" data-pay aria-label={`Rename ${g.title}`}>
							<Icon name="edit" />
						</button>
						<form method="post" action="/goals/delete" style={contents} data-confirm={`Delete ${g.title} and all its items?`}>
							<Back s={s} />
							<input type="hidden" name="id" value={g.id} />
							<Submit class="ub" aria-label={`Delete ${g.title}`}>
								<Icon name="trash" />
							</Submit>
						</form>
					</span>
				</div>
				<form method="post" action="/goals/item" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="goal_id" value={g.id} />
					<label>Add item to {g.title}</label>
					<div class="ln">
						<input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required />
						<input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required />
						<Submit class="btn xs">Add</Submit>
					</div>
				</form>
				<form method="post" action="/goals/edit" class="ad" data-payp hidden>
					<Back s={s} />
					<input type="hidden" name="id" value={g.id} />
					<label>Rename goal</label>
					<div class="ln">
						<input class="in f" name="name" value={g.title} autocomplete="off" required />
						<Submit class="btn xs">Save</Submit>
					</div>
				</form>
			</div>
			{items}
		</div>
	)
})

const GoalList = view<{ s: State; manage: boolean }>(({ s, manage }) =>
	s.goals.length ? (
		<>{s.goals.map((g) => <GoalRow key={g.id} s={s} g={g} manage={manage} />)}</>
	) : (
		<Empty>{manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</Empty>
	),
)

const GoalForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/goals" class="sf xfm" data-adp hidden>
		<Back s={s} />
		<input class="in" name="name" placeholder="Goal name" autocomplete="off" required />
		<Submit class="btn full">Add goal</Submit>
	</form>
))

export const GoalsExpand = view<{ s: State; open: boolean; storeKey: string; manage: boolean }>(({ s, open, storeKey, manage }) => {
	const g = goalStat(s)
	const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${s.user.currency} to go`
	const head = (
		<>
			<b class="big2">
				{g.pct}
				<small>%</small>
			</b>
			<span class="lb">{sub}</span>
		</>
	)
	if (manage) {
		return (
			<ExpandCard
				storeKey={storeKey}
				open={open}
				title="Goals"
				head={head}
				jar={g.pct}
				label="Add goal"
				foot={
					<div class="xl">
						<span>Pencil edits, bin removes</span>
					</div>
				}
				form={<GoalForm s={s} />}
			>
				<GoalList s={s} manage />
			</ExpandCard>
		)
	}
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="Goals"
			head={head}
			jar={g.pct}
			foot={
				<div class="xl">
					<span>{`Left to buy ${fmt(g.target)} ${s.user.currency}`}</span>
					<a class="lnk" href="/goals">
						Manage
					</a>
				</div>
			}
		>
			<GoalList s={s} manage={false} />
		</ExpandCard>
	)
})
