import { css, type Handle } from "remix/component";

import {
	balance,
	CURRENCY,
	debtLeft,
	debts,
	dueText,
	earnedOn,
	fmt,
	goal,
	hoursOn,
	sources,
	TODAY,
	todayLong,
	wishes,
	type Category,
} from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Bar, QuickBuy, Section, SectionHead, SubmitButton, TodayAmount } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

export function HomePage(handle: Handle<{ buy: Category | null }>) {
	return () => {
		let { buy } = handle.props;
		let g = goal();
		let openWishes = wishes.filter((w) => !w.boughtOn);

		return (
			<Screen title="Home" active="home">
				<details mix={css({ ...s.card })}>
					<summary mix={css({ ...s.row })}>
						<div>
							<div mix={css({ ...s.small })}>Total balance</div>
							<div mix={css({ ...s.big, marginTop: "8px" })}>
								{fmt(balance)} <span mix={css({ ...s.small, fontFamily: "var(--mono)", letterSpacing: "0" })}>{CURRENCY}</span>
							</div>
						</div>
						<span mix={css({ ...s.btn })}>Edit</span>
					</summary>
					<form
						method="post"
						action={routes.saveBalance.href()}
						mix={css({ ...s.formRow, marginTop: "12px" })}
					>
						<input
							name="balance"
							value={balance}
							inputMode="decimal"
							autoComplete="off"
							aria-label="Total balance"
						/>
						<SubmitButton primary large>
							Save
						</SubmitButton>
					</form>
				</details>

				<Section>
					<h2 mix={css({ ...s.h2 })}>I bought</h2>
					<QuickBuy path={routes.home.href()} selected={buy} />
				</Section>

				<Section>
					<div mix={css({ ...s.row })}>
						<h2 mix={css({ ...s.h2 })}>Goal</h2>
						<a href={routes.goals.href()} mix={css({ fontWeight: 600 })}>
							{fmt(g.left)} <span mix={css({ ...s.small, fontWeight: 400 })}>left</span>
						</a>
					</div>
					<Bar percent={g.percent} />
					<div mix={css({ ...s.small })}>
						{g.percent}% done · Wish list {fmt(g.wishLeft)} + Debts {fmt(g.debtOwed)}
					</div>
				</Section>

				<Section>
					<SectionHead
						title="Income sources"
						sub={`Today · ${todayLong()}`}
						href={`${routes.sources.href()}#new`}
						action="+ Add"
					/>
					<div>
						{sources.map((source) => {
							let amount = earnedOn(source, TODAY);
							let hours = hoursOn(source, TODAY);
							let sub = source.rate
								? `${fmt(hours)} h today · ${fmt(source.rate)} ${CURRENCY}/h`
								: source.note;

							return (
								<details key={source.id}>
									<summary mix={css({ ...s.row, ...s.hair })}>
										<div>
											<div>{source.name}</div>
											<div mix={css({ ...s.small })}>{sub}</div>
										</div>
										<TodayAmount amount={amount} />
									</summary>
									<div
										mix={css({ display: "flex", flexDirection: "column", gap: "10px", paddingBottom: "12px" })}
									>
										<form
											method="post"
											action={routes.createEntry.href({ id: source.id })}
											mix={css({ ...s.formRow })}
										>
											<input
												name={source.rate ? "hours" : "amount"}
												placeholder={source.rate ? "Hours worked" : "Amount earned"}
												aria-label={source.rate ? "Hours worked" : "Amount earned"}
												inputMode="decimal"
												autoComplete="off"
											/>
											<SubmitButton primary large>
												Add
											</SubmitButton>
										</form>
										<a href={routes.source.href({ id: source.id })} mix={css({ ...s.accentText })}>
											History and details
										</a>
									</div>
								</details>
							);
						})}
					</div>
				</Section>

				<Section>
					<SectionHead title="Wish list" href={`${routes.wishes.href()}#add`} action="+ Add" />
					<div>
						{openWishes.length === 0 ? (
							<div mix={css({ ...s.hair, ...s.small })}>Nothing to buy right now.</div>
						) : (
							openWishes.map((wish) => (
								<div key={wish.id} mix={css({ ...s.row, ...s.hair })}>
									<span>{wish.name}</span>
									<form
										method="post"
										action={routes.buyWish.href({ id: wish.id })}
										mix={css({ ...s.formRow, gap: "10px" })}
									>
										<span>{fmt(wish.price)}</span>
										<SubmitButton>Bought</SubmitButton>
									</form>
								</div>
							))
						)}
					</div>
				</Section>

				<Section>
					<SectionHead
						title="Debts I pay"
						sub={`${fmt(g.debtOwed)} left`}
						href={`${routes.debts.href()}#add`}
						action="+ Add"
					/>
					<div>
						{debts.map((debt) => {
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
									<details>
										<summary mix={css({ ...s.row })}>
											<span mix={css({ ...s.dueTone[due.tone] })}>{due.text}</span>
											<span mix={css({ ...s.btn })}>Pay</span>
										</summary>
										<form
											method="post"
											action={routes.payDebt.href({ id: debt.id })}
											mix={css({ ...s.formRow, marginTop: "10px" })}
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
									</details>
								</div>
							);
						})}
					</div>
				</Section>
			</Screen>
		);
	};
}
