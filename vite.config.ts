import { cloudflare } from "@cloudflare/vite-plugin";
import { remix } from "@pitlane/vite-plugin-remix";
import { defineConfig } from "vite-plus";

export default defineConfig({
	server: { port: 3000 },
	resolve: { tsconfigPaths: true },
	environments: { client: { build: { sourcemap: true } } },
	plugins: [
		remix({
			clientEntry: "bootstrap/browser.ts",
			serverEntry: "bootstrap/worker.ts",
			serverHandler: false,
		}),
		cloudflare({ viteEnvironment: { name: "ssr" } }),
	],
	fmt: {
		ignorePatterns: ["build/**", "worker-configuration.d.ts"],
		useTabs: true,
		experimentalSortPackageJson: true,
		experimentalSortImports: {
			groups: [
				["value-builtin"],
				["type-external"],
				["value-external"],
				["type-internal"],
				["value-internal"],
				["type-parent"],
				["value-parent"],
				["type-sibling"],
				["value-sibling"],
				["type-index"],
				["value-index"],
				["side_effect"],
			],
		},
	},
	lint: {
		options: { typeAware: true, typeCheck: true, denyWarnings: true },
		plugins: ["eslint", "import", "oxc", "promise", "typescript", "unicorn"],
		rules: { "no-unused-expressions": "deny" },
		env: { builtin: true },
	},
});
