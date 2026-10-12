import { css, type Handle } from "remix/component";

import { CURRENCY, debtLeft, debts, dueText, fmt } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Bar, Empty, Field, Section, SectionHead, SubmitButton } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** Only the debts you owe and will pay. Each one has a Pay form and a progress bar. */
export function DebtsPage(handle: Handle) {
	return () => {
		let owed = debts.reduce((sum, d) => sum + debtLeft(d), 0);

		return (
			<Screen
				title="Debts"
				active="goals"
				heading="Debts I pay"
				back={{ href: routes.goals.href(), label: "Goal" }}
			>
				<Section>
					<SectionHead title="Open" sub={`${fmt(owed)} ${CURRENCY} left`} />
					<div>
						{debts.length === 0 ? (
							<Empty>No debts to pay. Add one below if that changes.</Empty>
						) : (
							debts.map((debt) => {
								let left = debtLeft(debt);
								let due = dueText(debt.due);
								return (
									<div
										key={debt.id}
										mix={css({ ...s.hair, display: "flex", flexDirection: "column", gap: "8px" })}
									>
										<div mix={css({ ...s.row })}>
											<span>{debt.name}</span>
											<span>{fmt(left)} left</span>
										</div>
										<Bar percent={(debt.paid / debt.total) * 100} />
										<div mix={css({ ...s.row })}>
											<span mix={css({ ...s.dueTone[due.tone] })}>{due.text}</span>
											<span mix={css({ ...s.small })}>
												{fmt(debt.paid)} of {fmt(debt.total)} paid
											</span>
										</div>
										<form
											method="post"
											action={routes.payDebt.href({ id: debt.id })}
											mix={css({ ...s.formRow })}
										>
											<input
												name="amount"
												placeholder="Amount to pay"
												aria-label={`Amount to pay ${debt.name}`}
												inputMode="decimal"
												autoComplete="off"
											/>
											<SubmitButton primary large>
												Pay
											</SubmitButton>
										</form>
									</div>
								);
							})
						)}
					</div>
				</Section>

				<Section>
					<SectionHead id="add" title="Add a debt" />
					<form
						method="post"
						action={routes.createDebt.href()}
						mix={css({ display: "flex", flexDirection: "column", gap: "10px" })}
					>
						<Field name="name" label="Who or what" placeholder="Phone store" required />
						<div mix={css({ ...s.formRow })}>
							<Field name="amount" label={`Amount (${CURRENCY})`} placeholder="1500" decimal required />
							<Field name="due" label="Due date" type="date" />
						</div>
						<div>
							<SubmitButton primary large>
								Add debt
							</SubmitButton>
						</div>
					</form>
				</Section>
			</Screen>
		);
	};
}
