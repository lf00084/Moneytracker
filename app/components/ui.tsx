/** Small building blocks used by every screen: cards, sections, headers, fields, and so on. */
import type { RemixNode } from "remix/component";
import type { State } from "../lib/data.ts";
import { Icon } from "./Icon.tsx";
import { view } from "./view.ts";

/** Titled card (`.cd`) used on phone screens. */
export const Card = view<{ title: RemixNode; children?: RemixNode }>(({ title, children }) => (
	<div class="cd">
		<div class="tg">{title}</div>
		<div class="cb">{children}</div>
	</div>
));

/** Titled section (`.sc`) used on desktop screens. */
export const Section = view<{ title: RemixNode; right?: RemixNode; children?: RemixNode }>(({ title, right = "", children }) => (
	<div class="sc">
		<div class="sh">
			<span>{title}</span>
			<span class="lb">{right}</span>
		</div>
		{children}
	</div>
));

/** Page title row. Pass `back` to make the title a back link. */
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
));

type FieldProps = { label: string; value?: string; name?: string; type?: string; placeholder?: string; first?: boolean; keep?: string };

/** Label + text input. The placeholder only shows while the value is empty. */
export const Field = view<FieldProps>(({ label, value = "", name, type, placeholder = "", first, keep }) => (
	<div class="fl">
		<label>{label}</label>
		<input class={first ? "in f" : "in"} name={name} data-keep={keep} type={type} value={value} placeholder={value ? undefined : placeholder} autocomplete="off" />
	</div>
));

/** Hidden field that tells the server which page to come back to after a post. */
export const Back = view<{ s: State }>(({ s }) => <input type="hidden" name="back" value={s.back} />);

/** The one-shot error left by a failed post, if there is one. */
export const ErrorBanner = view<{ s: State }>(({ s }) =>
	s.error ? (
		<div class="neg" role="alert" style={{ margin: "10px 0", fontSize: "13px" }}>
			{s.error}
		</div>
	) : null,
);

/** Quiet one-line message inside a list ("Nothing bought today."). */
export const Empty = view<{ children?: RemixNode }>(({ children }) => (
	<div class="lb" style={{ padding: "8px 0" }}>
		{children}
	</div>
));

/** Round avatar: the user's picture, or their first initial. */
export const Avatar = view<{ avatar: string | null; name: string }>(({ avatar, name }) => {
	const url = avatar ? encodeURI(avatar).replace(/'/g, "%27") : "";
	return (
		<div class="av" style={url ? { background: `url('${url}') center/cover` } : undefined}>
			{url ? "" : (name.trim()[0] ?? "?").toUpperCase()}
		</div>
	);
});

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
));

/** Tap-to-fill chips of names the user has typed before. */
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
);

/** The big round "+" that opens the add form of a card. */
export const BigAdd = view<{ label: string; target?: string; right?: boolean }>(({ label, target = "", right = false }) => (
	<button type="button" class={right ? "addb r" : "addb"} data-bigadd data-for={target || undefined} aria-label={label}>
		<Icon name="plus" />
	</button>
));

/** Desktop card with a list inside and a big "+" that reveals the form with id `target`. */
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
));

type ExpandProps = {
	/** Remembers open/closed in the browser. */
	storeKey: string;
	open: boolean;
	title: string;
	head?: RemixNode;
	foot?: RemixNode;
	form?: RemixNode;
	/** Label of the round "+" button; leave empty for a card without one. */
	label?: string;
	/** Progress bar behind the header, 0-100. Leave out for none. */
	jar?: number;
	children?: RemixNode;
};

/** Collapsible phone card: header summary, body, optional footer and add form. */
export const ExpandCard = view<ExpandProps>(({ storeKey, open, title, head, foot, form, label = "", jar = -1, children }) => (
	<div class={label ? "xc" : "xc xn"}>
		<details class="xd" data-keep-open={storeKey} open={open ? true : undefined}>
			<summary class="xh osum">
				{jar >= 0 ? <i class={jar >= 100 ? "xj full" : "xj"} style={{ width: `${jar}%` }}></i> : null}
				<div>
					<div class="tg0">{title}</div>
					{head ? <div class="ow">{head}</div> : null}
				</div>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="xb">{children}</div>
			<div class={foot ? "xf" : "xf xo"}>
				{foot}
				{form}
			</div>
		</details>
		{label ? (
			<button type="button" class="xp" data-xplus aria-label={label}>
				<Icon name="plus" />
			</button>
		) : null}
	</div>
));
