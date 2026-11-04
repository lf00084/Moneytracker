import { defineConfig } from "vite"

// Builds the browser runtime entry (Remix run() + hydrated client entries)
// into a single module served at /assets/entry.js in production.
export default defineConfig({
	oxc: { jsx: { runtime: "automatic", importSource: "remix/component" } },
	build: {
		outDir: "app/client/dist",
		emptyOutDir: true,
		target: "es2022",
		minify: "esbuild",
		rollupOptions: {
			input: "app/client/entry.ts",
			output: { entryFileNames: "entry.js", format: "es" },
		},
	},
})
