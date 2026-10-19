import { css, type Handle } from "remix/component";

import {
	CURRENCY,
	earnedOn,
	fmt,
	lastSevenDays,
	month,
	shortWeekday,
	sources,
	TODAY,
} from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Bar, Section, SectionHead } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** Month totals, the last seven days of earnings, and where money came from and went. */
export function StatsPage(handle: Handle) {
	return () => {
		let days = lastSevenDays.map((date) => ({
			date,
			amount: sources.reduce((total, source) => total + earnedOn(source, date), 0),
		}));
		let best = Math.max(...days.map((d) => d.amount), 1);
		let net = month.income - month.spent;
		let topIncome = Math.max(...month.incomeBySource.map((x) => x.amount), 1);
		let topSpend = Math.max(...month.spentByCategory.map((x) => x.amount), 1);

		return (
			<Screen title="Stats" active="stats" heading="Stats">
				<Section>
					<SectionHead title={month.label} sub="Totals for this month" />
					<div>
						<div mix={css({ ...s.row, ...s.hair })}>
							<span>Income</span>
							<span mix={css({ ...s.pos })}>+{fmt(month.income)}</span>
						</div>
						<div mix={css({ ...s.row, ...s.hair })}>
							<span>Spent</span>
							<span mix={css({ ...s.neg })}>−{fmt(month.spent)}</span>
						</div>
						<div mix={css({ ...s.row, ...s.hair })}>
							<span>Left over</span>
							<span mix={css({ fontWeight: 500 })}>
								{net >= 0 ? "+" : "−"}
								{fmt(Math.abs(net))} {CURRENCY}
							</span>
						</div>
					</div>
				</Section>

				<Section>
					<SectionHead title="Earned, last 7 days" />
					<div mix={css({ display: "flex", alignItems: "flex-end", gap: "8px", height: "120px" })}>
						{days.map((day) => (
							<div
								key={day.date}
								mix={css({
									flex: "1",
									minWidth: "0",
									height: "100%",
									display: "flex",
									flexDirection: "column",
									justifyContent: "flex-end",
									alignItems: "center",
									gap: "4px",
								})}
							>
								<span mix={css({ ...s.small, ...(day.amount > 0 ? {} : s.muted) })}>{day.amount > 0 ? fmt(day.amount) : "0"}</span>
								<div
									mix={css({
										width: "100%",
										borderRadius: "5px",
										background: day.date === TODAY ? "var(--accent)" : "var(--track)",
										height: `${Math.max(4, Math.round((day.amount / best) * 72))}px`,
									})}
								/>
								<span mix={css({ ...s.small, color: day.date === TODAY ? "var(--fg)" : "var(--muted)" })}>
									{shortWeekday(day.date)}
								</span>
							</div>
						))}
					</div>
				</Section>

				<Section>
					<SectionHead title="Income by source" />
					<div>
						{month.incomeBySource.map((item) => (
							<div
								key={item.name}
								mix={css({ ...s.hair, display: "flex", flexDirection: "column", gap: "8px" })}
							>
								<div mix={css({ ...s.row })}>
									<span>{item.name}</span>
									<span mix={css({ ...s.pos })}>+{fmt(item.amount)}</span>
								</div>
								<Bar percent={(item.amount / topIncome) * 100} />
							</div>
						))}
					</div>
				</Section>

				<Section>
					<SectionHead title="Spent by category" href={routes.purchases.href()} action="All purchases" />
					<div>
						{month.spentByCategory.map((item) => (
							<div
								key={item.name}
								mix={css({ ...s.hair, display: "flex", flexDirection: "column", gap: "8px" })}
							>
								<div mix={css({ ...s.row })}>
									<span>{item.name}</span>
									<span>{fmt(item.amount)}</span>
								</div>
								<Bar percent={(item.amount / topSpend) * 100} />
							</div>
						))}
					</div>
				</Section>
			</Screen>
		);
	};
}
