import { Icon, Link, view } from "./ui.tsx"

export type MobileTab = "home" | "income" | "trading" | "pad" | "profile" | "history" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "bhome", href: "/home" },
	{ key: "income", label: "On hold", icon: "bsun", href: "/income" },
	{ key: "trading", label: "P2P & Predict", icon: "btrade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "bdoc", href: "/pad" },
	{ key: "profile", label: "Profile", icon: "buser", href: "/profile" },
] as const

export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="pb-nav" aria-label="Main">
		{TABS.map((t) => (
			<Link key={t.key} href={t.href} class={active === t.key ? "pb-a on" : "pb-a"} aria-label={t.label} aria-current={active === t.key ? "page" : undefined}>
				<Icon name={t.icon} />
				<span>{t.label}</span>
			</Link>
		))}
	</nav>
))
