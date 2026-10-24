import { AppLayout } from "../components/Layout.tsx";
import { TradingBody } from "../components/trading.tsx";
import { ErrorBanner, PageHeader } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";

export const TradingScreen = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.user.usdt_rate)} ${s.user.currency}`;
	return (
		<AppLayout
			title="Trading"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
		/>
	);
});
