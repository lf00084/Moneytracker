import { Icon } from "./Icon.tsx";
import { view } from "./view.ts";

export type MobileTab = "home" | "notes" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | "";

const TABS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "income", label: "Income", icon: "gear", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "profile", label: "Profile", icon: "user", href: "/profile" },
] as const;

/** Phone navigation, fixed to the bottom of the screen. */
export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label}>
				<Icon name={t.icon} />
			</a>
		))}
	</nav>
));
