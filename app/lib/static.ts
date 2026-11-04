import appCss from "../client/app.css?raw"
import homeCss from "../client/home.css?raw"
import js from "../client/app.ts?raw"
import authCss from "../client/auth.css?raw"
import pico from "@picocss/pico/css/pico.min.css?raw"

export const hash = (s: string) => {
	let h = 5381
	for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
	return (h >>> 0).toString(36)
}

const css = `${appCss}\n${homeCss}`
const auth = `${pico}\n${authCss}`

export const files = { css, js, auth }

export const V = { css: hash(css), js: hash(js), auth: hash(auth) }
