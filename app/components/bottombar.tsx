import { Icon, view } from "./ui.tsx"

export type MobileTab = "home" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "bhome", href: "/home" },
	{ key: "trading", label: "Predict", icon: "btrade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "bdoc", href: "/pad" },
	{ key: "income", label: "Income", icon: "bsun", href: "/income" },
	{ key: "profile", label: "Profile", icon: "buser", href: "/profile" },
] as const

export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label} aria-current={active === t.key ? "page" : undefined}>
				<span class="bp">
					<Icon name={t.icon} />
				</span>
				<span class="bl">{t.label}</span>
			</a>
		))}
	</nav>
))
