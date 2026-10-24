import { Icon, Logo, ThemeIcons } from "./Icon.tsx";
import { view } from "./view.ts";

export type DesktopTab = "home" | "notes" | "plan" | "income" | "trading" | "pad" | "history" | "settings" | "";

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "history", label: "History", icon: "hist", href: "/history" },
	{ key: "settings", label: "Settings", icon: "gear", href: "/settings" },
] as const;

/** Desktop navigation, shown on the left. */
export const Sidebar = view<{ active: DesktopTab }>(({ active }) => (
	<aside class="sb d">
		<Logo href="/home" />
		{LINKS.map((l) => (
			<a key={l.key} class={active === l.key ? "sbl on" : "sbl"} href={l.href}>
				<Icon name={l.icon} />
				{l.label}
			</a>
		))}
		<div class="sp"></div>
		<button type="button" class="sbl" data-theme-toggle>
			<ThemeIcons />
			<span>Theme</span>
		</button>
		<form method="post" action="/logout" data-rmx-document>
			<button class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</button>
		</form>
	</aside>
));
