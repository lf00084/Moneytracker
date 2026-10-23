import { IncomeExpand } from "../components/income.tsx";
import { AppLayout } from "../components/Layout.tsx";
import { ErrorBanner, PageHeader } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { calc } from "../lib/view.ts";

export const IncomeScreen = view<{ s: State }>(({ s }) => {
	const earned = calc(s).earned;
	return (
		<AppLayout
			title="Income"
			theme={s.user.theme}
			mobileTab="income"
			desktopTab="income"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Income" right={earned ? `+${fmt(earned)} today` : ""} />
					<IncomeExpand s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<div class="hd">
						<h1 class="t">Income</h1>
						<span></span>
					</div>
					<IncomeExpand s={s} />
				</>
			}
		/>
	);
});
