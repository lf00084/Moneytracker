import { css, type Handle } from "remix/component";

import { dayLabel, fmt, purchases } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Section } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

const kindNote = { quick: "", wish: "Wish list", debt: "Debt payment" } as const;

/** Everything bought this month, newest first, grouped by day. */
export function PurchasesPage(handle: Handle) {
	return () => {
		let dates = [...new Set(purchases.map((p) => p.date))];

		return (
			<Screen
				title="Purchases"
				active="stats"
				heading="Purchases"
				back={{ href: routes.stats.href(), label: "Stats" }}
			>
				{dates.map((date) => {
					let items = purchases.filter((p) => p.date === date);
					let total = items.reduce((sum, p) => sum + p.amount, 0);
					return (
						<Section key={date}>
							<div mix={css({ ...s.row })}>
								<h2 mix={css({ ...s.h2 })}>{dayLabel(date)}</h2>
								<span mix={css({ ...s.small })}>−{fmt(total)}</span>
							</div>
							<div>
								{items.map((item) => (
									<div key={item.id} mix={css({ ...s.row, ...s.hair })}>
										<div>
											<div>{item.label}</div>
											<div mix={css({ ...s.small })}>
												{item.time}
												{kindNote[item.kind] ? ` · ${kindNote[item.kind]}` : ""}
											</div>
										</div>
										<span mix={css({ ...s.neg })}>−{fmt(item.amount)}</span>
									</div>
								))}
							</div>
						</Section>
					);
				})}
			</Screen>
		);
	};
}
