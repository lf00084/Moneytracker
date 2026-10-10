import { bindings, defineConfig } from "cf/config";

export default defineConfig({
	worker: {
		name: "remix-starter",
		compatibilityDate: "2026-09-02",
		compatibilityFlags: ["nodejs_compat"],
		entrypoint: "./bootstrap/worker.ts",
		workersDev: true,
		observability: { enabled: true },
		env: {
			/** Turso database URL, like libsql://your-db-your-org.turso.io */
			TURSO_DATABASE_URL: bindings.secret(),
			/** Turso auth token (turso db tokens create <db>) */
			TURSO_AUTH_TOKEN: bindings.secret(),
			/** Google OAuth client from console.cloud.google.com */
			GOOGLE_CLIENT_ID: bindings.secret(),
			GOOGLE_CLIENT_SECRET: bindings.secret(),
			/** Long random string that signs the session cookie */
			SESSION_SECRET: bindings.secret(),
			/** Public origin of the site, no trailing slash. Used for the OAuth callback. */
			APP_URL: bindings.secret(),
		},
	},
});
