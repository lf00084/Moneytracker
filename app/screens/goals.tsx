import { GoalsExpand } from "../components/goals.tsx";
import { IncomeDesktop } from "../components/income.tsx";
import { AppLayout } from "../components/Layout.tsx";
import { ErrorBanner, PageHeader } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";

/** Goals on phones, and the "Plan" page (goals + income) on desktop. Serves /goals and /plan. */
export const GoalsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Goals"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="plan"
		mobile={
			<>
				<PageHeader title="Goals" right="add, edit, remove" />
				<ErrorBanner s={s} />
				<GoalsExpand s={s} open storeKey="goals-page" manage />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<PageHeader title="Plan" right="goals + income" />
				<div class="g3">
					<div>
						<GoalsExpand s={s} open storeKey="goals-d" manage />
					</div>
					<div>
						<IncomeDesktop s={s} />
					</div>
				</div>
			</>
		}
	/>
));
