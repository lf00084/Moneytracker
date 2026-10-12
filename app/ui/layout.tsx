import type { Handle, RemixNode } from "remix/component";

const rawCss = String.raw;

/**
 * Global base styles: the reset, the color variables and the look of bare form controls.
 * Everything sits in the lowest cascade layer so the `css()` mixins on elements win. The
 * theme follows the system: dark by default, light when the system asks for it.
 */
const baseCss = rawCss`
@layer reset, rmx;

@layer reset {
	*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

	:root {
		color-scheme: dark;
		--bg: #0f1113;
		--surface: #15181b;
		--field: #1b1f23;
		--line: #262b30;
		--line-strong: #353c43;
		--track: #2a3036;
		--fg: #e8ecef;
		--fg2: #9aa4ad;
		--muted: #6b7680;
		--accent: #6db3ff;
		--on-accent: #08121c;
		--pos: #46c38a;
		--neg: #f0837a;
		--warn: #e6b35a;
	}

	@media (prefers-color-scheme: light) {
		:root {
			color-scheme: light;
			--bg: #f6f7f9;
			--surface: #ffffff;
			--field: #ffffff;
			--line: #e3e7eb;
			--line-strong: #cfd6dc;
			--track: #dde3e8;
			--fg: #14181c;
			--fg2: #5b6670;
			--muted: #8a949d;
			--accent: #1f6fd1;
			--on-accent: #ffffff;
			--pos: #188a55;
			--neg: #c9453b;
			--warn: #a8741a;
		}
	}

	html { -webkit-text-size-adjust: 100%; }

	body {
		min-height: 100dvh;
		background: var(--bg);
		color: var(--fg);
		font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
		font-size: 14px;
		line-height: 1.45;
		font-variant-numeric: tabular-nums;
	}

	a { color: inherit; text-decoration: none; }
	ul { list-style: none; }
	button, input, select { font: inherit; color: inherit; }
	button { cursor: pointer; }
	summary { list-style: none; cursor: pointer; }
	summary::-webkit-details-marker { display: none; }

	input, select {
		width: 100%;
		min-width: 0;
		height: 36px;
		padding: 0 10px;
		border-radius: 9px;
		border: 1px solid var(--line-strong);
		background: var(--field);
	}
	input::placeholder { color: var(--muted); }
	input[type=checkbox], input[type=radio] { width: auto; height: auto; }

	[data-chip] { position: relative; display: flex; flex: 1; }
	[data-chip] input { position: absolute; opacity: 0; width: 1px; height: 1px; }
}
`;

/** State styles. Left outside any layer on purpose so they beat the layered `css()` rules. */
const stateCss = rawCss`
[data-chip][aria-current=true], [data-chip] input:checked + span {
	border-color: var(--accent);
	color: var(--accent);
}
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
input:focus, select:focus { outline: none; border-color: var(--accent); }
a:active, button:active, summary:active { opacity: 0.7; }
`;

export function Document(handle: Handle<{ title: string; children?: RemixNode }>) {
	return () => (
		<html lang="en">
			<head>
				<meta charSet="UTF-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="color-scheme" content="dark light" />
				<title>{handle.props.title}</title>
				<style>{baseCss}</style>
				<style>{stateCss}</style>
			</head>
			<body>{handle.props.children}</body>
		</html>
	);
}
