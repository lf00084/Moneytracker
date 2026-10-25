import { createController } from "remix/router"
import { assets } from "../lib/assets.ts"
import { files, hash } from "../lib/static.ts"
import { routes } from "../routes.ts"

const file = (body: string, type: string) => {
	const etag = `"${hash(body)}"`
	return (ctx: { request: Request }) => {
		const pinned = new URL(ctx.request.url).searchParams.has("v")
		const headers = { "Cache-Control": pinned ? "public, max-age=31536000, immutable" : "no-cache", ETag: etag }
		return ctx.request.headers.get("if-none-match") === etag ? new Response(null, { status: 304, headers }) : new Response(body, { headers: { ...headers, "Content-Type": type } })
	}
}

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
		css: file(files.css, "text/css; charset=utf-8"),
		js: file(files.js, "application/javascript; charset=utf-8"),
	},
})
