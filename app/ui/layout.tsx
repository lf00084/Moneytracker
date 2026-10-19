import type { Handle, RemixNode } from "remix/component";

const rawCss = String.raw;

const baseCss = rawCss`
@layer reset, rmx;

@layer reset {
	*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

	:root {
		color-scheme: dark;
		--mono: 'Geist Mono', ui-monospace, SFMono-Regular, Menlo, monospace;
		--bg: #121212;
		--surface: #181818;
		--field: #202020;
		--line: #2c2c2c;
		--line-strong: #3a3a3a;
		--track: #2c2c2c;
		--fg: #f5f5f5;
		--fg2: #8c8c8c;
		--muted: #666666;
		--accent: #f5f5f5;
		--on-accent: #121212;
		--pos: #3ddc84;
		--neg: #ff5a4d;
		--warn: #e6b35a;
	}

	@media (prefers-color-scheme: light) {
		:root {
			color-scheme: light;
			--bg: #ffffff;
			--surface: #fafafa;
			--field: #f1f1f1;
			--line: #e3e3e3;
			--line-strong: #cfcfcf;
			--track: #e3e3e3;
			--fg: #000000;
			--fg2: #6e6e6e;
			--muted: #9a9a9a;
			--accent: #000000;
			--on-accent: #ffffff;
			--pos: #12a150;
			--neg: #e0382b;
			--warn: #a8741a;
		}
	}

	html { -webkit-text-size-adjust: 100%; }

	body {
		min-height: 100dvh;
		background: var(--bg);
		color: var(--fg);
		font-family: Geist, Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
		font-size: 14px;
		line-height: 1.45;
		font-variant-numeric: tabular-nums;
		-webkit-font-smoothing: antialiased;
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
		height: 38px;
		padding: 0;
		font-size: 16px;
		border: 0;
		border-bottom: 1px solid var(--line-strong);
		border-radius: 0;
		background: transparent;
	}
	select { appearance: none; }
	input::placeholder { color: var(--fg2); opacity: 0.6; }
	input[type=checkbox], input[type=radio] { width: auto; height: auto; }

	[data-chip] { position: relative; display: flex; flex: 1; }
	[data-chip] input { position: absolute; opacity: 0; width: 1px; height: 1px; }
}
`;

const stateCss = rawCss`
[data-chip][aria-current=true], [data-chip] input:checked + span {
	background: var(--accent);
	border-color: var(--accent);
	color: var(--on-accent);
}
[data-quick][aria-current=true] {
	background: var(--accent);
	border-color: var(--accent);
	color: var(--on-accent);
}
[data-quick][aria-current=true] small { opacity: 0.7; color: inherit; }
section > div > :first-child { border-top-width: 0; padding-top: 0; }
section > div > details:first-child > summary { border-top-width: 0; padding-top: 0; }
:focus-visible { outline: 2px solid var(--fg); outline-offset: 2px; }
input:focus, select:focus { outline: none; border-bottom: 2px solid var(--fg); }
a:active, button:active, summary:active { opacity: 0.7; }
`;

export function Document(handle: Handle<{ title: string; children?: RemixNode }>) {
	return () => (
		<html lang="en">
			<head>
				<meta charSet="UTF-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="color-scheme" content="dark light" />
				<link
					rel="stylesheet"
					href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap"
				/>
				<title>{handle.props.title}</title>
				<style>{baseCss}</style>
				<style>{stateCss}</style>
			</head>
			<body>{handle.props.children}</body>
		</html>
	);
}
