import { cloudflare } from "@cloudflare/vite-plugin"
import { defineConfig } from "vite"

export default defineConfig({
	server: { host: "0.0.0.0", port: 3000, allowedHosts: true },
	oxc: { jsx: { runtime: "automatic", importSource: "remix/component" } },
	plugins: [cloudflare()],
})
