import { env as cfEnv } from "cloudflare:workers";
export type AppEnv = {
TURSO_DATABASE_URL: string;
TURSO_AUTH_TOKEN: string;
SESSION_SECRET: string;
GOOGLE_CLIENT_ID: string;
GOOGLE_CLIENT_SECRET: string;
APP_ORIGIN: string;
};
const keys = ["TURSO_DATABASE_URL", "TURSO_AUTH_TOKEN", "SESSION_SECRET", "GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET", "APP_ORIGIN"] as const;
const raw = cfEnv as unknown as Record<string, unknown>;
export const env = Object.fromEntries(
keys.map((k) => [k, typeof raw[k] === "string" ? (raw[k] as string).trim() : ""]),
) as AppEnv;
export const missingEnv = () => keys.filter((k) => !env[k]);
