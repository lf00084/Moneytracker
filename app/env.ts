import { env as cfEnv } from "cloudflare:workers";
export type AppEnv = {
TURSO_DATABASE_URL: string;
TURSO_AUTH_TOKEN: string;
SESSION_SECRET: string;
GOOGLE_CLIENT_ID: string;
GOOGLE_CLIENT_SECRET: string;
APP_ORIGIN: string;
};
const raw = (cfEnv as unknown as Record<string, unknown>) ?? {};

const getVal = (key: string, fallback = ""): string => {
	const val = raw[key];
	if (typeof val === "string" && val.trim()) return val.trim();
	if (typeof process !== "undefined" && process.env?.[key]) return process.env[key]!.trim();
	return fallback;
};

const rawDbUrl = getVal("TURSO_DATABASE_URL");
// Turso requires HTTPS/TLS for bearer token authentication
const normalizedDbUrl = rawDbUrl.startsWith("http://")
	? rawDbUrl.replace(/^http:\/\//, "https://")
	: rawDbUrl;

export const env: AppEnv = {
	TURSO_DATABASE_URL: normalizedDbUrl,
	TURSO_AUTH_TOKEN: getVal("TURSO_AUTH_TOKEN"),
	SESSION_SECRET: getVal("SESSION_SECRET", "moneytracker-session-secret-local-dev-key-32-chars-long"),
	GOOGLE_CLIENT_ID: getVal("GOOGLE_CLIENT_ID", ""),
	GOOGLE_CLIENT_SECRET: getVal("GOOGLE_CLIENT_SECRET", ""),
	APP_ORIGIN: getVal("APP_ORIGIN", "http://localhost:3000"),
};

export const missingEnv = () => {
	const missing: string[] = [];
	if (!env.TURSO_DATABASE_URL) missing.push("TURSO_DATABASE_URL");
	if (!env.TURSO_AUTH_TOKEN) missing.push("TURSO_AUTH_TOKEN");
	return missing;
};
