import { css, type Handle } from "remix/component";

import { CURRENCY, sources, type Category } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Field, Icon, QuickBuy, Section, SubmitButton } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** One place to log a purchase or income, with links to add a wish, a debt or a source. */
export function AddPage(handle: Handle<{ buy: Category | null }>) {
	return () => {
		let { buy } = handle.props;
		let links = [
			{ label: "New wish", note: "Something you want to buy", href: `${routes.wishes.href()}#add` },
			{ label: "New debt", note: "Money you will pay back", href: `${routes.debts.href()}#add` },
			{ label: "New income source", note: "Another place money comes from", href: `${routes.sources.href()}#new` },
		];

		return (
			<Screen title="Add" active="add" heading="Add">
				<Section>
					<h2 mix={css({ ...s.h2 })}>I bought</h2>
					<QuickBuy path={routes.add.href()} selected={buy} />
				</Section>

				<Section>
					<h2 mix={css({ ...s.h2 })}>I earned</h2>
					<form
						method="post"
						action={routes.createEntry.href({ id: "company" })}
						mix={css({ display: "flex", flexDirection: "column", gap: "10px" })}
					>
						<label mix={css({ display: "flex", flexDirection: "column", gap: "4px" })}>
							<span mix={css({ ...s.small })}>Source</span>
							<select name="source">
								{sources.map((source) => (
									<option key={source.id} value={source.id}>
										{source.name}
									</option>
								))}
							</select>
						</label>
						<div mix={css({ ...s.formRow, alignItems: "flex-end" })}>
							<Field name="hours" label="Hours (Company)" placeholder="8" decimal />
							<Field name="amount" label={`Amount (${CURRENCY})`} placeholder="120" decimal />
						</div>
						<div mix={css({ ...s.small })}>Use hours for the Company. Other sources take an amount.</div>
						<div>
							<SubmitButton primary large>
								Add income
							</SubmitButton>
						</div>
					</form>
				</Section>

				<Section>
					<h2 mix={css({ ...s.h2 })}>More</h2>
					<div>
						{links.map((link) => (
							<a key={link.label} href={link.href} mix={css({ ...s.row, ...s.hair })}>
								<div>
									<div>{link.label}</div>
									<div mix={css({ ...s.small })}>{link.note}</div>
								</div>
								<span mix={css({ color: "var(--fg2)" })}>
									<Icon name="next" size="16px" />
								</span>
							</a>
						))}
					</div>
				</Section>
			</Screen>
		);
	};
}
