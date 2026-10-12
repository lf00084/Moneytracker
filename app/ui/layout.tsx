import type { Handle, RemixNode } from "remix/component";

import { css } from "remix/component";
import { ImportMap } from "remix/component/server";

import { getAssetEntry } from "../middleware/asset-entry.ts";

const rawCss = String.raw;

export function Layout(handle: Handle<{ children?: RemixNode }>) {
	return () => {
		let { scriptEntry } = getAssetEntry();
		let { href, importMap, preloads } = scriptEntry;

		return (
			<html lang="en">
				<head>
					<meta charSet="UTF-8" />
					<meta name="viewport" content="width=device-width, initial-scale=1.0" />
					<title>Moneytracker</title>
					<ImportMap value={importMap} />
					{preloads.map((preloadHref) => (
						<link key={preloadHref} rel="modulepreload" href={preloadHref} />
					))}
					<script type="module" src={href} />
					<style>
						{rawCss`
@layer reset{*{box-sizing:border-box;margin:0;padding:0}}
h1{margin-bottom:1rem}
p{margin-bottom:.75rem}
form{display:grid;gap:1rem;margin-bottom:1rem}
label{display:grid;gap:.25rem;font-weight:600}
input{padding:.6rem;border:1px solid #ccc;border-radius:6px;font:inherit}
button{padding:.7rem;border:0;border-radius:6px;background:#111;color:#fff;font:inherit;cursor:pointer}
p[role=alert]{padding:.75rem;border-radius:6px;background:#ffebee;color:#c62828}
a{color:#0b5fff}
`}
					</style>
				</head>
				<body
					mix={css({
						fontFamily: "system-ui, -apple-system, sans-serif",
						lineHeight: 1.5,
						padding: "2rem 1rem",
						maxWidth: "420px",
						margin: "0 auto",
					})}
				>
					{handle.props.children}
				</body>
			</html>
		);
	};
}
