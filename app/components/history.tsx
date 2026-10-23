import type { DayRow, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { today } from "../lib/time.ts";
import { dayNet } from "../lib/view.ts";
import { buyName, SpendRow } from "./buys.tsx";
import { IncomeRow } from "./income.tsx";
import { Back, Card, ErrorBanner, PageHeader, Section } from "./ui.tsx";
import { view } from "./view.ts";

/** Everything that happened on one day: incomes first, then buys. */
const DayItems = view<{ s: State; d: DayRow }>(({ s, d }) => (
	<>
		{d.incomes.map((i) => (
			<IncomeRow key={i.id} s={s} i={i} />
		))}
		{d.buys.map((b) => (
			<SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : ""} amount={`−${fmt(b.total)}`} />
		))}
	</>
));

/** Forms that add a buy or an income to any past day. */
const DayForms = view<{ s: State; wide: boolean }>(({ s, wide }) => {
	const t = today();
	const body = (
		<>
			<form method="post" action="/buy">
				<Back s={s} />
				<div class="ln">
					<input class="in" name="label" placeholder="Item" autocomplete="off" required />
					<input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required />
				</div>
				<div class="ln" style={{ marginTop: "8px" }}>
					<input class="in" type="date" name="day" value={t} max={t} required />
					<button class="btn xs">Add buy</button>
				</div>
			</form>
			<form method="post" action="/history/income" style={{ marginTop: "14px" }}>
				<Back s={s} />
				<div class="ln">
					<input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required />
					<input class="in" type="date" name="day" value={t} max={t} required />
					<button class="btn xs">Add income</button>
				</div>
			</form>
		</>
	);
	return wide ? <Section title="Add to any day">{body}</Section> : <Card title="Add to any day">{body}</Card>;
});

/** Phone history: one card per day. */
export const HistoryMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<DayForms s={s} wide={false} />
		{s.days.map((d) => (
			<Card key={d.day} title={d.label}>
				<div class="l1">
					<span>
						<span class="lb">Earned</span> <b class="ea">+{fmt(d.earned)}</b>
					</span>
					<span>
						<span class="lb">Bought</span> <b class="sp">−{fmt(d.bought)}</b>
					</span>
					<b>{dayNet(d.earned, d.bought)}</b>
				</div>
				<DayItems s={s} d={d} />
			</Card>
		))}
	</>
));

/** Desktop history: a table of the last 30 days. */
export const HistoryDesktop = view<{ s: State }>(({ s }) => {
	const earned = s.days.reduce((a, d) => a + d.earned, 0);
	const bought = s.days.reduce((a, d) => a + d.bought, 0);
	return (
		<>
			<PageHeader title="History" right="last 30 days" />
			<ErrorBanner s={s} />
			<DayForms s={s} wide />
			<Section title="Last 30 days" right={`+${fmt(earned)} earned · −${fmt(bought)} bought`}>
				<div class="th">
					<span>Day</span>
					<span>Earned</span>
					<span>Bought</span>
					<span>Net</span>
					<span>What</span>
				</div>
				{s.days.map((d) => (
					<div key={d.day} class="tr">
						<b>{d.label}</b>
						<b class="ea">+{fmt(d.earned)}</b>
						<b class="sp">−{fmt(d.bought)}</b>
						<b>{dayNet(d.earned, d.bought)}</b>
						<div>
							<DayItems s={s} d={d} />
						</div>
					</div>
				))}
			</Section>
		</>
	);
});
