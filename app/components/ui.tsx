import { unsafeHTML, type Handle, type RemixNode } from "remix/component"
import type { State } from "../lib/data.ts"

export function view<P extends Record<string, any> = {}>(render: (props: P) => RemixNode) {
	return function View(handle: Handle<P>) {
		return () => render(handle.props)
	}
}

const ICONS: Record<string, string> = {
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
	moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
	pad: '<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h7M9 17h5"/>',
	trade: '<path d="M3 17l5-6 4 3 8-9"/><path d="M15 5h5v5"/>',
	coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
	undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	chev: '<path d="M6 9l6 6 6-6"/>',
	check: '<path d="m5 12 5 5 9-9"/>',
	bhome: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
	btrade: '<path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/>',
	bdoc: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h8"/>',
	bsun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
	bchat: '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22z"/>',
	buser: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
	revert: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
	eyeoff: '<path d="M3 3l18 18M10.6 6.1A9.8 9.8 0 0 1 12 6c6 0 10 6 10 6a17 17 0 0 1-3.2 3.9M6.6 7.6A17 17 0 0 0 2 12s4 7 10 7a9.6 9.6 0 0 0 4.2-1M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
	Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
	Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
	Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
	Other: '<path d="M12 5v14M5 12h14"/>',
	Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
	Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
	Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
	Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
	Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
	Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
}

/**
 * Shared submit button. Use it for every button that submits a form.
 * While its form is submitting, the page script marks it data-busy and CSS shows
 * only the rotate icon (label and icons are hidden, size stays the same).
 */
export const Submit = view<Record<string, any>>(({ children, ...rest }) => (
	<button {...rest}>
		<span class="sb-l">{children}</span>
		<span class="sb-i" aria-hidden="true">
			<Icon name="revert" />
		</span>
	</button>
))

export const Icon = view<{ name: string }>(({ name }) => <svg class="ic" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS[name] ?? "")} />)

export const ThemeIcons = view(() => (
	<>
		<svg class="ic t-sun" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.sun!)} />
		<svg class="ic t-moon" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.moon!)} />
	</>
))

const GOOGLE_INNER =
	'<path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/>'

export const GoogleMark = view(() => <svg width="18" height="18" viewBox="0 0 48 48" innerHTML={unsafeHTML(GOOGLE_INNER)} />)

const GOAT_INNER =
	'<rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/>'

const GoatMark = view(() => <svg viewBox="0 0 24 24" innerHTML={unsafeHTML(GOAT_INNER)} />)

export const Logo = view<{ href: string }>(({ href }) => (
	<a class="logo" href={href}>
		<GoatMark />
		<span>moneytracker</span>
	</a>
))

export const Card = view<{ title: RemixNode; children?: RemixNode }>(({ title, children }) => (
	<div class="cd">
		<div class="tg">{title}</div>
		<div class="cb">{children}</div>
	</div>
))

export const Section = view<{ title: RemixNode; right?: RemixNode; children?: RemixNode }>(({ title, right = "", children }) => (
	<div class="sc">
		<div class="sh">
			<span>{title}</span>
			<span class="lb">{right}</span>
		</div>
		{children}
	</div>
))

export const PageHeader = view<{ title: string; right?: RemixNode; back?: string }>(({ title, right = "", back }) => (
	<div class="hd">
		{back ? (
			<a class="back" href={back}>
				<Icon name="back" />
				<h1 class="t">{title}</h1>
			</a>
		) : (
			<h1 class="t">{title}</h1>
		)}
		<span class="lb">{right}</span>
	</div>
))

type FieldProps = { label: string; value?: string; name?: string; type?: string; placeholder?: string; first?: boolean }

export const Field = view<FieldProps>(({ label, value = "", name, type, placeholder = "", first }) => (
	<div class="fl">
		<label>{label}</label>
		<input class={first ? "in f" : "in"} name={name} type={type} value={value} placeholder={value ? undefined : placeholder} autocomplete="off" />
	</div>
))

export const FloatField = view<{ label: string; name: string; type?: string; auto?: string }>(({ label, name, type = "text", auto }) => (
	<div class="of">
		<input name={name} type={type} placeholder=" " autocomplete={auto} />
		<label>{label}</label>
	</div>
))

export const Back = view<{ s: State }>(({ s }) => <input type="hidden" name="back" value={s.back} />)

export const ErrorBanner = view<{ s: State }>(({ s }) =>
	s.error ? (
		<div class="neg" role="alert" style={{ margin: "10px 0", fontSize: "13px" }}>
			{s.error}
		</div>
	) : null,
)

export const Empty = view<{ children?: RemixNode }>(({ children }) => (
	<div class="lb" style={{ padding: "8px 0" }}>
		{children}
	</div>
))

export const Avatar = view<{ avatar: string | null; name: string }>(({ avatar, name }) => {
	const url = avatar ? encodeURI(avatar).replace(/'/g, "%27") : ""
	return (
		<div class="av" style={url ? { background: `url('${url}') center/cover` } : undefined}>
			{url ? "" : (name.trim()[0] ?? "?").toUpperCase()}
		</div>
	)
})

export const ThemeSwitch = view(() => (
	<div class="sg">
		<button type="button" data-set-theme="dark">
			<Icon name="moon" />
			Dark
		</button>
		<button type="button" data-set-theme="light">
			<Icon name="sun" />
			White
		</button>
	</div>
))

export const NameChips = view<{ names: string[] }>(({ names }) =>
	names.length ? (
		<div class="chips nm">
			{names.map((n) => (
				<span key={n} class="chip" data-nm={n}>
					{n}
				</span>
			))}
		</div>
	) : null,
)

export const BigAdd = view<{ label: string; target?: string; right?: boolean }>(({ label, target = "", right = false }) => (
	<button type="button" class={right ? "addb r" : "addb"} data-bigadd data-for={target || undefined} aria-label={label}>
		<Icon name="plus" />
	</button>
))

export const ListCard = view<{ title: RemixNode; right: RemixNode; target: string; label: string; children?: RemixNode }>(({ title, right, target, label, children }) => (
	<div class="sc bgc rgt">
		<div class="ct">
			<div class="sh">
				<span>{title}</span>
				<span class="lb">{right}</span>
			</div>
			{children}
		</div>
		<BigAdd label={label} target={target} right />
	</div>
))

type ExpandProps = {
	storeKey: string
	open: boolean
	title: string
	head?: RemixNode
	foot?: RemixNode
	form?: RemixNode
	label?: string
	jar?: number
	fixed?: boolean
	children?: RemixNode
}

export const ExpandCard = view<ExpandProps>(({ storeKey, open, title, head, foot, form, label = "", jar = -1, fixed = false, children }) => (
	<div class={label ? "xc" : "xc xn"}>
		<details class="xd" data-keep-open={fixed ? undefined : storeKey} data-fixed={fixed ? "1" : undefined} open={open || fixed ? true : undefined}>
			<summary class="xh osum">
				{jar >= 0 ? <i class={jar >= 100 ? "xj full" : "xj"} style={{ width: `${jar}%` }}></i> : null}
				<div>
					<div class="tg0">{title}</div>
					{head ? <div class="ow">{head}</div> : null}
				</div>
				{fixed ? null : (
					<span class="chev">
						<Icon name="chev" />
					</span>
				)}
				{label ? (
					<button type="button" class="xp" data-xplus aria-label={label}>
						<Icon name="plus" />
					</button>
				) : null}
			</summary>
			<div class="xb">{children}</div>
			<div class={foot ? "xf" : "xf xo"}>
				{foot}
				{form}
			</div>
		</details>
	</div>
))
