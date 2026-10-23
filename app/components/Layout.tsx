import type { RemixNode } from "remix/component";
import { BottomBar, type MobileTab } from "./BottomBar.tsx";
import { ClockWidget, TopBar } from "./Clock.tsx";
import { Document } from "./Document.tsx";
import { ThemeIcons } from "./Icon.tsx";
import { Sidebar, type DesktopTab } from "./Sidebar.tsx";
import { view } from "./view.ts";

type AppLayoutProps = {
	title: string;
	theme?: string;
	/** The phone layout and the desktop layout are two views of the same screen. */
	mobile: RemixNode;
	desktop: RemixNode;
	mobileTab?: MobileTab;
	desktopTab?: DesktopTab;
	/** Pinned above the bottom bar on phones (the notes composer). */
	dock?: RemixNode;
	/** Desktop content spans the whole width instead of the centred column. */
	full?: boolean;
};

/** The signed-in shell: sidebar on desktop, top strip, content, and the bottom bar on phones. */
export const AppLayout = view<AppLayoutProps>(({ title, theme, mobile, desktop, mobileTab = "", desktopTab = "", dock, full }) => (
	<Document title={title} theme={theme}>
		<div class="app">
			<Sidebar active={desktopTab} />
			<main>
				<div class="m">
					<TopBar split />
				</div>
				<div class="m mm">{mobile}</div>
				<div class="d">
					<TopBar />
				</div>
				<div class={full ? "d pg full" : "d pg"}>{desktop}</div>
			</main>
			<div class="dock m">
				{dock}
				<BottomBar active={mobileTab} />
			</div>
		</div>
	</Document>
));

type AuthLayoutProps = { title: string; path: string; desc: string; children?: RemixNode };

/** The signed-out shell used by login and signup: a clock, a theme button, and one centred card. */
export const AuthLayout = view<AuthLayoutProps>(({ title, path, desc, children }) => (
	<Document title={title} path={path} desc={desc} user={false}>
		<div class="app">
			<div class="tf-clock">
				<ClockWidget />
				<button type="button" class="ib" data-theme-toggle aria-label="Theme">
					<ThemeIcons />
				</button>
			</div>
			<main class="auth-viewport">{children}</main>
		</div>
	</Document>
));
