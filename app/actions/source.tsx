import { css, type Handle } from "remix/component";

import {
	CURRENCY,
	dayLabel,
	earnedOn,
	fmt,
	hoursOn,
	lastSevenDays,
	TODAY,
	type Source,
} from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Field, Section, SectionHead, SubmitButton, TodayAmount } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** One source: today's amount, a form to add more, the rate, and the last seven days. */
export function SourcePage(handle: Handle<{ source: Source }>) {
	return () => {
		let { source } = handle.props;
		let hourly = source.rate !== undefined;
		let todays = source.entries.filter((e) => e.date === TODAY);

		return (
			<Screen
				title={source.name}
				active="home"
				heading={source.name}
				back={{ href: routes.sources.href(), label: "Income sources" }}
			>
				<Section>
					<div mix={css({ ...s.row })}>
						<div>
							<div mix={css({ ...s.small })}>
								{hourly ? `${fmt(hoursOn(source, TODAY))} h today · ${fmt(source.rate ?? 0)} ${CURRENCY}/h` : source.note}
							</div>
						</div>
						<TodayAmount amount={earnedOn(source, TODAY)} />
					</div>
				</Section>

				<Section>
					<SectionHead title={hourly ? "Add hours" : "Add earnings"} />
					<form
						method="post"
						action={routes.createEntry.href({ id: source.id })}
						mix={css({ ...s.formRow, alignItems: "flex-end" })}
					>
						<Field
							name={hourly ? "hours" : "amount"}
							label={hourly ? "Hours worked" : `Amount (${CURRENCY})`}
							placeholder={hourly ? "8" : "120"}
							decimal
							required
						/>
						<SubmitButton primary large>
							Add
						</SubmitButton>
					</form>
					{hourly ? (
						<div mix={css({ ...s.small })}>Hours are multiplied by your rate to get the amount.</div>
					) : null}
				</Section>

				{hourly ? (
					<Section>
						<SectionHead title="Rate" />
						<form
							method="post"
							action={routes.saveRate.href({ id: source.id })}
							mix={css({ ...s.formRow, alignItems: "flex-end" })}
						>
							<Field name="rate" label={`${CURRENCY} per hour`} value={source.rate} decimal required />
							<SubmitButton large>Save</SubmitButton>
						</form>
					</Section>
				) : null}

				{todays.length > 0 ? (
					<Section>
						<SectionHead title="Added today" />
						<div>
							{todays.map((item) => (
								<div key={item.id} mix={css({ ...s.row, ...s.hair })}>
									<div>
										<div mix={css({ ...s.pos })}>+{fmt(item.amount)}</div>
										<div mix={css({ ...s.small })}>
											{item.time}
											{item.hours ? ` · ${fmt(item.hours)} h` : ""}
										</div>
									</div>
									<form method="post" action={routes.deleteEntry.href({ id: source.id, entryId: item.id })}>
										<SubmitButton label={`Remove ${fmt(item.amount)}`}>Remove</SubmitButton>
									</form>
								</div>
							))}
						</div>
					</Section>
				) : null}

				<Section>
					<SectionHead title="Last 7 days" />
					<div>
						{[...lastSevenDays].reverse().map((date) => {
							let amount = earnedOn(source, date);
							let hours = hoursOn(source, date);
							return (
								<div key={date} mix={css({ ...s.row, ...s.hair })}>
									<span>{dayLabel(date)}</span>
									<span mix={css({ ...(amount > 0 ? s.pos : s.muted) })}>
										{hours > 0 ? (
											<span mix={css({ ...s.small, fontWeight: 400 })}>{fmt(hours)} h · </span>
										) : null}
										{amount > 0 ? `+${fmt(amount)}` : "—"}
									</span>
								</div>
							);
						})}
					</div>
				</Section>
			</Screen>
		);
	};
}
