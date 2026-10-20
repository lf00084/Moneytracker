import { env as cfEnv } from "cloudflare:workers";

export type AppEnv = {
	TURSO_DATABASE_URL: string;
	TURSO_AUTH_TOKEN: string;
	SESSION_SECRET: string;
	GOOGLE_CLIENT_ID: string;
	GOOGLE_CLIENT_SECRET: string;
	APP_ORIGIN: string;
};

/** Cloudflare bindings and secrets. Locally they come from `.dev.vars`, in production from `wrangler secret put`. */
export const env = cfEnv as unknown as AppEnv;
