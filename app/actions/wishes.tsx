import { css, type Handle } from "remix/component";

import { CURRENCY, fmt, shortDate, wishes } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Empty, Field, Section, SectionHead, SubmitButton } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** Everything you want to buy. Marking one bought takes its price off the balance. */
export function WishesPage(handle: Handle) {
	return () => {
		let open = wishes.filter((w) => !w.boughtOn);
		let bought = wishes.filter((w) => w.boughtOn);
		let left = open.reduce((sum, w) => sum + w.price, 0);

		return (
			<Screen
				title="Wish list"
				active="goals"
				heading="Wish list"
				back={{ href: routes.goals.href(), label: "Goal" }}
			>
				<Section>
					<SectionHead title="To buy" sub={`${fmt(left)} ${CURRENCY} left`} />
					<div>
						{open.length === 0 ? (
							<Empty>Nothing to buy right now. Add something you want below.</Empty>
						) : (
							open.map((wish) => (
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
					<SectionHead id="add" title="Add a wish" />
					<form
						method="post"
						action={routes.createWish.href()}
						mix={css({ ...s.formRow, alignItems: "flex-end" })}
					>
						<Field name="name" label="What" placeholder="Headphones" required />
						<Field name="price" label={`Price (${CURRENCY})`} placeholder="450" decimal required />
						<SubmitButton primary large>
							Add
						</SubmitButton>
					</form>
				</Section>

				{bought.length > 0 ? (
					<Section>
						<SectionHead title="Bought" />
						<div>
							{bought.map((wish) => (
								<div key={wish.id} mix={css({ ...s.row, ...s.hair, ...s.muted })}>
									<div>
										<div mix={css({ textDecoration: "line-through" })}>{wish.name}</div>
										<div mix={css({ ...s.small })}>{wish.boughtOn ? shortDate(wish.boughtOn) : ""}</div>
									</div>
									<span>{fmt(wish.price)}</span>
								</div>
							))}
						</div>
					</Section>
				) : null}
			</Screen>
		);
	};
}
