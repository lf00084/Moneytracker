import { env as cfEnv } from "cloudflare:workers"

const raw = (cfEnv as unknown as Record<string, unknown>) ?? {}

const getVal = (key: string, fallback = "") => {
	const val = raw[key]
	if (typeof val === "string" && val.trim()) return val.trim()
	if (typeof process !== "undefined" && process.env?.[key]) return process.env[key]!.trim()
	return fallback
}

const dbUrl = getVal("TURSO_DATABASE_URL")

export const env = {
	TURSO_DATABASE_URL: dbUrl.startsWith("http://") ? dbUrl.replace(/^http:\/\//, "https://") : dbUrl,
	TURSO_AUTH_TOKEN: getVal("TURSO_AUTH_TOKEN"),
	SESSION_SECRET: getVal("SESSION_SECRET", import.meta.env.DEV ? "moneytracker-dev-session-secret-not-for-production" : ""),
	GOOGLE_CLIENT_ID: getVal("GOOGLE_CLIENT_ID"),
	GOOGLE_CLIENT_SECRET: getVal("GOOGLE_CLIENT_SECRET"),
	APP_ORIGIN: getVal("APP_ORIGIN", "http://localhost:3000"),
}

export const missingEnv = () => (["TURSO_DATABASE_URL", "TURSO_AUTH_TOKEN", "SESSION_SECRET"] as const).filter((k) => !env[k])
