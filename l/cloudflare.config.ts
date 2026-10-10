import { defineConfig } from "cf/config";

export default defineConfig({
	worker: {
		name: "moneytracker",
		compatibilityDate: "2026-09-02",
		compatibilityFlags: ["nodejs_compat"],
		entrypoint: "./bootstrap/worker.ts",
		workersDev: true,
		observability: { enabled: true },
		env: {},
	},
});
