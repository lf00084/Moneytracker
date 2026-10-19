import { css, type Handle } from "remix/component";

import { debtLeft, debts, dueText, fmt, goal, wishes } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Bar, Icon, Section, SectionHead } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** The goal in one place: what is left, what it is made of, and what is due next. */
export function GoalsPage(handle: Handle) {
	return () => {
		let g = goal();
		let openWishes = wishes.filter((w) => !w.boughtOn);
		let next = debts
			.filter((d) => debtLeft(d) > 0)
			.sort((a, b) => a.due.localeCompare(b.due))[0];
		let nextDue = next ? dueText(next.due) : null;

		return (
			<Screen title="Goal" active="goals" heading="Goal">
				<Section>
					<div mix={css({ ...s.row })}>
						<h2 mix={css({ ...s.h2 })}>Left to reach it</h2>
						<span mix={css({ fontWeight: 500 })}>
							{fmt(g.left)} <span mix={css({ ...s.small, fontWeight: 400 })}>left</span>
						</span>
					</div>
					<Bar percent={g.percent} />
					<div mix={css({ ...s.small })}>
						{g.percent}% done · {fmt(g.debtPaid)} of debt paid so far
					</div>
				</Section>

				<Section>
					<SectionHead title="What it is made of" />
					<div>
						<a href={routes.wishes.href()} mix={css({ ...s.row, ...s.hair })}>
							<div>
								<div>Wish list</div>
								<div mix={css({ ...s.small })}>
									{openWishes.length} item{openWishes.length === 1 ? "" : "s"} not bought yet
								</div>
							</div>
							<div mix={css({ ...s.formRow, gap: "6px" })}>
								<span>{fmt(g.wishLeft)}</span>
								<span mix={css({ color: "var(--fg2)" })}>
									<Icon name="next" size="16px" />
								</span>
							</div>
						</a>
						<a href={routes.debts.href()} mix={css({ ...s.row, ...s.hair })}>
							<div>
								<div>Debts I pay</div>
								<div mix={css({ ...s.small })}>
									{debts.length} debt{debts.length === 1 ? "" : "s"}
								</div>
							</div>
							<div mix={css({ ...s.formRow, gap: "6px" })}>
								<span>{fmt(g.debtOwed)}</span>
								<span mix={css({ color: "var(--fg2)" })}>
									<Icon name="next" size="16px" />
								</span>
							</div>
						</a>
					</div>
				</Section>

				{next && nextDue ? (
					<Section>
						<SectionHead title="Due next" />
						<div mix={css({ ...s.row, ...s.hair })}>
							<div>
								<div>{next.name}</div>
								<div mix={css({ ...s.dueTone[nextDue.tone] })}>{nextDue.text}</div>
							</div>
							<span>{fmt(debtLeft(next))} left</span>
						</div>
					</Section>
				) : null}
			</Screen>
		);
	};
}
