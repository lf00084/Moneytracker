/**
 * Vite configuration. The Cloudflare plugin builds and runs the worker declared in
 * `wrangler.jsonc`. The app renders on the server only, so there is no client entry. JSX is
 * compiled against Remix's own runtime.
 */

import { cloudflare } from "@cloudflare/vite-plugin";
import { defineConfig } from "vite";

export default defineConfig({
	server: {
		host: "0.0.0.0",
		port: 3000,
		allowedHosts: true,
	},

	resolve: { tsconfigPaths: true },

	oxc: { jsx: { runtime: "automatic", importSource: "remix/component" } },

	plugins: [cloudflare()],
});
