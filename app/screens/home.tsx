import { Frame } from "remix/component";
import { BuysDesktop, BuysExpand, Hero, TodayCards } from "../components/buys.tsx";
import { GoalsExpand } from "../components/goals.tsx";
import { HomeIncome, IncomeDesktop } from "../components/income.tsx";
import { AppLayout } from "../components/Layout.tsx";
import { BalanceCard } from "../components/profile.tsx";
import { OweDesktop, OweMobile } from "../components/debts.tsx";
import { ErrorBanner } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";
import { routes } from "../routes.ts";

/** Dashboard: today at a glance. */
export const HomeScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Home"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="home"
		mobile={
			<>
				<ErrorBanner s={s} />
				<BalanceCard s={s} />
				<TodayCards s={s} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<Hero s={s} />
				<div class="g2">
					<div>
						<BuysDesktop s={s} />
					</div>
					<div>
						<OweDesktop s={s} open={false} storeKey="owe" />
						<IncomeDesktop s={s} title="Income today" />
						<Frame
							src={routes.pages.frameNotes.href()}
							fallback={
								<div class="sc">
									<div class="sk"></div>
									<div class="sk"></div>
									<div class="sk"></div>
								</div>
							}
						/>
					</div>
				</div>
			</>
		}
	/>
));
