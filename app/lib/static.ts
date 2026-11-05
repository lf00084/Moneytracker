import appCss from "../client/app.css?raw"
import entryJs from "../client/dist/entry.js?raw"
import pico from "@picocss/pico/css/pico.min.css?raw"

export const hash = (s: string) => {
	let h = 5381
	for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
	return (h >>> 0).toString(36)
}

// One stylesheet for the whole app: Pico (the design system) + the small
// chrome layer (shell, sheets, pad). No CDN, no per-page CSS files.
const css = `${pico}\n${appCss}`

export const files = { css, js: entryJs }

export const V = { css: hash(css), js: hash(entryJs) }
