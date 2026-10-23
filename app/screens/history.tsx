import { HistoryDesktop, HistoryMobile } from "../components/history.tsx";
import { AppLayout } from "../components/Layout.tsx";
import { PageHeader } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";

export const HistoryScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="History"
		theme={s.user.theme}
		mobileTab="history"
		desktopTab="history"
		mobile={
			<>
				<PageHeader title="History" right="last 30 days" />
				<HistoryMobile s={s} />
			</>
		}
		desktop={<HistoryDesktop s={s} />}
	/>
));
