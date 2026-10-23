import type { RemixNode } from "remix/component";
import { env } from "../env.ts";
import { SITE } from "../lib/assets.ts";
import { V } from "../lib/versions.ts";
import { view } from "./view.ts";

export type DocumentProps = {
	title: string;
	/** Signed-in pages are private (noindex); guest pages (login, signup) are indexable. */
	user?: boolean;
	theme?: string;
	desc?: string;
	/** Canonical path, only used on guest pages. */
	path?: string;
	children?: RemixNode;
};

const THEME_BOOT = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;
const REGISTER_SW = `if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))`;
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap";

/** The whole HTML page: head, meta tags, stylesheet, scripts. Pages put their content inside it. */
export const Document = view<DocumentProps>(({ title, user = true, theme, desc, path, children }) => {
	const description = desc ?? SITE.desc;
	const origin = env.APP_ORIGIN.replace(/\/$/, "");
	const fullTitle = `${title} · ${SITE.name}`;
	const ld = JSON.stringify({
		"@context": "https://schema.org",
		"@type": "WebApplication",
		name: SITE.name,
		url: origin,
		description: SITE.desc,
		applicationCategory: "FinanceApplication",
		operatingSystem: "Any",
	}).replace(/</g, "\\u003c");

	return (
		<html lang="en" data-theme={theme === "light" ? "light" : "dark"} data-rmx-preserve-attrs="data-theme">
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="theme-color" content={SITE.color} />
				<title>{fullTitle}</title>
				<meta name="description" content={description} />
				<meta name="robots" content={user ? "noindex,nofollow" : "index,follow"} />
				<meta name="application-name" content={SITE.name} />
				<meta name="apple-mobile-web-app-title" content={SITE.name} />
				<meta name="mobile-web-app-capable" content="yes" />
				<meta name="apple-mobile-web-app-capable" content="yes" />
				<meta name="apple-mobile-web-app-status-bar-style" content="black" />
				<meta name="format-detection" content="telephone=no" />
				<link rel="manifest" href="/manifest.webmanifest" />
				<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
				<link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png" />
				<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
				<meta property="og:type" content="website" />
				<meta property="og:site_name" content={SITE.name} />
				<meta property="og:title" content={fullTitle} />
				<meta property="og:description" content={description} />
				<meta property="og:image" content={`${origin}/icon-512.png`} />
				<meta name="twitter:card" content="summary" />
				<meta name="twitter:title" content={fullTitle} />
				<meta name="twitter:description" content={description} />
				{path && !user ? <link rel="canonical" href={`${origin}${path}`} /> : null}
				{path && !user ? <meta property="og:url" content={`${origin}${path}`} /> : null}
				{user ? null : <script type="application/ld+json">{ld}</script>}
				<link rel="preconnect" href="https://fonts.googleapis.com" />
				<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
				<link rel="stylesheet" href={FONTS} />
				<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />
				{theme ? null : <script>{THEME_BOOT}</script>}
				{import.meta.env.DEV ? <script type="module" src="/@vite/client"></script> : null}
			</head>
			<body>
				<div class="nb" aria-hidden="true" data-rmx-preserve-dom></div>
				{children}
				<script src={`/assets/app.js?v=${V.js}`} defer></script>
				{user ? <script type="module" src={`/assets/entry.js?v=${V.entry}`}></script> : null}
				<script>{REGISTER_SW}</script>
			</body>
		</html>
	);
});
