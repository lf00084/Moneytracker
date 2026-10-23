import { createController } from "remix/router";
import appCss from "../client/app.css?raw";
import appJs from "../client/app.js?raw";
import themeJs from "../client/theme.js?raw";
import entryJs from "../client/dist/entry.js?raw";
import { assets } from "../lib/assets.ts";
import { hash } from "../lib/versions.ts";
import { routes } from "../routes.ts";

/** Serves a text file from memory. Links carrying ?v=<hash> are saved on the user's device for a year; plain links are re-checked with an ETag. */
const file = (body: string, type: string) => {
	const etag = `"${hash(body)}"`;
	return (ctx: { request: Request }) => {
		const pinned = new URL(ctx.request.url).searchParams.has("v");
		const headers = { "Cache-Control": pinned ? "public, max-age=31536000, immutable" : "no-cache", ETag: etag };
		return ctx.request.headers.get("if-none-match") === etag ? new Response(null, { status: 304, headers }) : new Response(body, { headers: { ...headers, "Content-Type": type } });
	};
};

export default createController(routes.assets, {
	actions: {
		manifest: () => assets.manifest(),
		favicon: () => assets.favicon(),
		faviconIco: () => assets.icon192(),
		icon192: () => assets.icon192(),
		icon512: () => assets.icon512(),
		iconMaskable: () => assets.iconMaskable(),
		appleIcon: () => assets.appleIcon(),
		sw: () => assets.sw(),
		robots: () => assets.robots(),
		sitemap: () => assets.sitemap(),
		css: file(appCss, "text/css; charset=utf-8"),
		js: file(appJs, "application/javascript; charset=utf-8"),
		theme: file(themeJs, "application/javascript; charset=utf-8"),
		entry: file(entryJs, "application/javascript; charset=utf-8"),
	},
});
