export const row = {
	display: "flex",
	alignItems: "center",
	justifyContent: "space-between",
	gap: "12px",
} as const;

export const formRow = { display: "flex", alignItems: "center", gap: "8px" } as const;
export const grow = { flex: "1", minWidth: "0" } as const;

export const mono = { fontFamily: "var(--mono)" } as const;
export const small = { fontSize: "12px", lineHeight: 1.4, color: "var(--fg2)" } as const;
export const h2 = {
	fontFamily: "var(--mono)",
	fontSize: "12px",
	fontWeight: 500,
	color: "var(--fg2)",
} as const;
export const pos = { color: "var(--pos)", fontWeight: 600 } as const;
export const neg = { color: "var(--neg)" } as const;
export const warn = { color: "var(--warn)" } as const;
export const muted = { color: "var(--muted)" } as const;
export const accentText = {
	fontFamily: "var(--mono)",
	fontSize: "12px",
	color: "var(--fg)",
	textDecoration: "underline",
	textUnderlineOffset: "3px",
} as const;

export const big = { fontSize: "48px", fontWeight: 600, letterSpacing: "-0.06em", lineHeight: 0.95 } as const;
export const big2 = { fontSize: "28px", fontWeight: 600, letterSpacing: "-0.05em", lineHeight: 1 } as const;

export const dueTone = {
	normal: small,
	warn: { ...small, ...warn },
	late: { ...small, ...neg },
} as const;

export const hair = { padding: "12px 0", borderTop: "1px solid var(--line)" } as const;

export const card = {
	background: "var(--surface)",
	border: "1px solid var(--line)",
	borderRadius: "16px",
	padding: "14px",
} as const;

export const btn = {
	display: "inline-flex",
	alignItems: "center",
	justifyContent: "center",
	height: "30px",
	padding: "0 12px",
	fontSize: "13px",
	fontWeight: 600,
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

export const btnLarge = { height: "40px", padding: "0 18px", fontSize: "14px", borderRadius: "10px" } as const;

export const chip = {
	flex: "1",
	display: "flex",
	alignItems: "center",
	justifyContent: "center",
	height: "34px",
	fontFamily: "var(--mono)",
	fontSize: "12px",
	fontWeight: 500,
	borderRadius: "20px",
	border: "1px solid var(--line-strong)",
	color: "var(--fg2)",
} as const;

export const quick = {
	flex: "1",
	display: "flex",
	flexDirection: "column",
	alignItems: "center",
	gap: "6px",
	padding: "13px 0 11px",
	fontSize: "13px",
	fontWeight: 600,
	borderRadius: "14px",
	border: "1px solid var(--line)",
	background: "var(--surface)",
	color: "var(--fg)",
} as const;

export const track = {
	height: "4px",
	borderRadius: "99px",
	background: "var(--track)",
	overflow: "hidden",
} as const;

function enc(svg: string): string {
	return `url(data:image/svg+xml,${encodeURIComponent(svg).replace(/'/g, "%27").replace(/\(/g, "%28").replace(/\)/g, "%29")})`;
}

function icon(inner: string): string {
	return enc(
		`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" ` +
			`stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>`,
	);
}

export const icons = {
	home: icon(`<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>`),
	stats: icon(`<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>`),
	plus: icon(`<path d="M12 5v14M5 12h14"/>`),
	goals: icon(`<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>`),
	settings: icon(
		`<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>`,
	),
	back: icon(`<path d="M15 5l-7 7 7 7"/>`),
	next: icon(`<path d="M9 5l7 7-7 7"/>`),
	Smoke: icon(`<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>`),
	Coffee: icon(`<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>`),
	Bread: icon(`<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>`),
	Other: icon(`<path d="M12 5v14M5 12h14"/>`),
} as const;

export const goat = enc(
	`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/>` +
		`<path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/>` +
		`<path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/></svg>`,
);
