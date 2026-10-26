import { PageHeader, view } from "./ui.tsx"

export type PadTab = "projects" | "people" | "books" | "tips"

const TABS: { key: PadTab; label: string; href: string }[] = [
	{ key: "projects", label: "Projects", href: "/pad" },
	{ key: "people", label: "People say", href: "/pad/people" },
	{ key: "books", label: "Books", href: "/pad/books" },
	{ key: "tips", label: "Useful", href: "/pad/tips" },
]

export const PadBody = view<{ tab: PadTab }>(({ tab }) => (
	<>
		<PageHeader title="Pad" right="saved on this device" />
		<div class="chips pdtabs">
			{TABS.map((t) => (
				<a key={t.key} class={t.key === tab ? "chip on" : "chip"} href={t.href}>
					{t.label}
				</a>
			))}
		</div>
		<div class="pdx" data-pad={tab}></div>
	</>
))

export const PadHome = view(() => <div class="sc pdhome" data-pad-home></div>)
