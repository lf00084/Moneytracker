/**
 * Shared style objects for Remix's `css()` mixin. Spread one into `css({ ...s.row, gap: "8px" })`
 * and add whatever the element needs on top. Colors and sizes come from the CSS variables
 * declared in `layout.tsx`, so dark and light mode need nothing here.
 */

export const row = {
	display: "flex",
	alignItems: "center",
	justifyContent: "space-between",
	gap: "12px",
} as const;

export const formRow = { display: "flex", alignItems: "center", gap: "8px" } as const;
export const grow = { flex: "1", minWidth: "0" } as const;

export const small = { fontSize: "12px", lineHeight: 1.4, color: "var(--fg2)" } as const;
export const h2 = { fontSize: "14px", fontWeight: 500, color: "var(--fg)" } as const;
export const pos = { color: "var(--pos)", fontWeight: 500 } as const;
export const neg = { color: "var(--neg)" } as const;
export const warn = { color: "var(--warn)" } as const;
export const muted = { color: "var(--muted)" } as const;
export const accentText = { fontSize: "12px", color: "var(--accent)" } as const;

/** Colors for the "Due Nov 20 · in 39 days" line. */
export const dueTone = {
	normal: small,
	warn: { ...small, ...warn },
	late: { ...small, ...neg },
} as const;

/** A list row with a hairline above it. */
export const hair = { padding: "11px 0", borderTop: "0.5px solid var(--line)" } as const;

export const card = {
	background: "var(--surface)",
	border: "0.5px solid var(--line)",
	borderRadius: "12px",
	padding: "14px",
} as const;

export const btn = {
	display: "inline-flex",
	alignItems: "center",
	justifyContent: "center",
	height: "28px",
	padding: "0 11px",
	fontSize: "12px",
	fontWeight: 500,
	borderRadius: "8px",
	border: "1px solid var(--line-strong)",
	background: "transparent",
	color: "var(--fg)",
	whiteSpace: "nowrap",
} as const;

export const btnPrimary = {
	...btn,
	background: "var(--accent)",
	borderColor: "var(--accent)",
	color: "var(--on-accent)",
} as const;

export const btnLarge = { height: "36px", padding: "0 14px", fontSize: "13px", borderRadius: "9px" } as const;

export const chip = {
	flex: "1",
	display: "flex",
	alignItems: "center",
	justifyContent: "center",
	height: "34px",
	fontSize: "13px",
	fontWeight: 500,
	borderRadius: "10px",
	border: "1px solid var(--line-strong)",
	color: "var(--fg)",
} as const;

export const track = {
	height: "5px",
	borderRadius: "99px",
	background: "var(--track)",
	overflow: "hidden",
} as const;

// ---------------------------------------------------------------------------------------------
// Icons. Drawn as CSS masks, so they take the text color and need no SVG attributes in JSX.

function icon(inner: string): string {
	let svg =
		`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" ` +
		`stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>`;
	let encoded = encodeURIComponent(svg).replace(/'/g, "%27").replace(/\(/g, "%28").replace(/\)/g, "%29");
	return `url(data:image/svg+xml,${encoded})`;
}

export const icons = {
	home: icon(
		`<path d="M5 12H3l9-9l9 9h-2"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>` +
			`<path d="M9 21v-6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v6"/>`,
	),
	stats: icon(`<path d="M5 20v-7"/><path d="M12 20V5"/><path d="M19 20V10"/>`),
	plus: icon(`<path d="M12 5v14"/><path d="M5 12h14"/>`),
	goals: icon(`<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>`),
	settings: icon(
		`<path d="M4 6h8"/><path d="M18 6h2"/><circle cx="15" cy="6" r="2"/>` +
			`<path d="M4 12h2"/><path d="M12 12h8"/><circle cx="9" cy="12" r="2"/>` +
			`<path d="M4 18h10"/><path d="M20 18h0"/><circle cx="17" cy="18" r="2"/>`,
	),
	back: icon(`<path d="M15 6l-6 6l6 6"/>`),
	next: icon(`<path d="M9 6l6 6l-6 6"/>`),
} as const;
