import { OweDesktop, OweMobile, RoadCard } from "../components/debts.tsx";
import { AppLayout } from "../components/Layout.tsx";
import { ErrorBanner, PageHeader, Section } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { calc } from "../lib/view.ts";

export const DebtsScreen = view<{ s: State }>(({ s }) => {
	const c = calc(s);
	return (
		<AppLayout
			title="Debts"
			theme={s.user.theme}
			mobileTab="home"
			desktopTab="home"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={s.debts.map((d) => d.person).slice(0, 2).join(" + ")} />
					<RoadCard s={s} />
					<OweMobile s={s} open storeKey="owe-page" />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`} />
					<div class="g3">
						<div>
							<OweDesktop s={s} open storeKey="owe-page" />
						</div>
						<div>
							<Section title="How it works">
								<div class="rw">
									<span>+ left of a name</span>
									<span class="mu">adds to that person</span>
								</div>
								<div class="rw">
									<span>Pay</span>
									<span class="mu">counts as a buy today</span>
								</div>
								<div class="rw">
									<span>Paid to 0</span>
									<span class="mu">hidden, kept in history</span>
								</div>
								<div class="rw">
									<span>Type old name</span>
									<span class="mu">brings them back</span>
								</div>
							</Section>
						</div>
					</div>
				</>
			}
		/>
	);
});
