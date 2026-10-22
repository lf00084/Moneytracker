import { createController } from "remix/router"
import { assets } from "../lib/assets.ts"
import { routes } from "../routes.ts"
import appCss from "../client/app.css?raw"
import appJs from "../client/app.js?raw"
import themeJs from "../client/theme.js?raw"
const hash = (s: string) => {
let h = 5381
for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
return (h >>> 0).toString(36)
}
const file = (body: string, type: string) => {
const etag = `"${hash(body)}"`
return (ctx: { request: Request }) =>
ctx.request.headers.get("if-none-match") === etag
? new Response(null, { status: 304, headers: { ETag: etag } })
: new Response(body, { headers: { "Content-Type": type, "Cache-Control": "no-cache", ETag: etag } })
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
css: file(appCss, "text/css; charset=utf-8"),
js: file(appJs, "application/javascript; charset=utf-8"),
theme: file(themeJs, "application/javascript; charset=utf-8"),
},
})
