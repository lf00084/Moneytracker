import { css, type Handle } from "remix/component";

import { CURRENCY, earnedOn, fmt, hoursOn, sources, TODAY, todayLong } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Field, Icon, Section, SectionHead, SubmitButton, TodayAmount } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** Every income source with what it made today, plus a form to add another. */
export function SourcesPage(handle: Handle) {
	return () => (
		<Screen
			title="Income sources"
			active="home"
			heading="Income sources"
			back={{ href: routes.home.href(), label: "Home" }}
		>
			<Section>
				<SectionHead title="Sources" sub={`Today · ${todayLong()}`} />
				<div>
					{sources.map((source) => {
						let hours = hoursOn(source, TODAY);
						let sub = source.rate
							? `${fmt(hours)} h today · ${fmt(source.rate)} ${CURRENCY}/h`
							: source.note;
						return (
							<a
								key={source.id}
								href={routes.source.href({ id: source.id })}
								mix={css({ ...s.row, ...s.hair })}
							>
								<div>
									<div>{source.name}</div>
									<div mix={css({ ...s.small })}>{sub}</div>
								</div>
								<div mix={css({ ...s.formRow, gap: "8px" })}>
									<TodayAmount amount={earnedOn(source, TODAY)} />
									<span mix={css({ color: "var(--fg2)" })}>
										<Icon name="next" size="16px" />
									</span>
								</div>
							</a>
						);
					})}
				</div>
			</Section>

			<Section>
				<SectionHead id="new" title="Add a source" />
				<form
					method="post"
					action={routes.createSource.href()}
					mix={css({ display: "flex", flexDirection: "column", gap: "10px" })}
				>
					<Field name="name" label="Name" placeholder="Freelance" required />
					<Field
						name="rate"
						label={`Hourly rate in ${CURRENCY} (leave empty if it is not paid by the hour)`}
						placeholder="45"
						decimal
					/>
					<div>
						<SubmitButton primary large>
							Add source
						</SubmitButton>
					</div>
				</form>
			</Section>
		</Screen>
	);
}
