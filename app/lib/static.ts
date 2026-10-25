import css from "../client/app.css?raw"
import js from "../client/app.js?raw"

export const hash = (s: string) => {
	let h = 5381
	for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
	return (h >>> 0).toString(36)
}

export const files = { css, js }

export const V = { css: hash(css), js: hash(js) }
