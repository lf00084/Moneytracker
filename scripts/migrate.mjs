import { createClient } from "@libsql/client";

let url = process.env.TURSO_DATABASE_URL;
let authToken = process.env.TURSO_AUTH_TOKEN;

if (!url) {
  console.error("TURSO_DATABASE_URL is missing. Fill it in .dev.vars first.");
  process.exit(1);
}

let db = createClient({ url, authToken });

await db.executeMultiple(`
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  google_id TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  picture TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS settings (
  user_id TEXT PRIMARY KEY,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  day_start_hour INTEGER NOT NULL DEFAULT 0,
  goal_mode TEXT NOT NULL DEFAULT 'kept',
  filled_display TEXT NOT NULL DEFAULT 'done'
);
CREATE TABLE IF NOT EXISTS goals (
  user_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  target_cents INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS sources (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'manual',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, name)
);
CREATE TABLE IF NOT EXISTS daily_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  source_id TEXT NOT NULL,
  date TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  origin TEXT NOT NULL DEFAULT 'manual',
  UNIQUE (user_id, source_id, date)
);
CREATE INDEX IF NOT EXISTS daily_entries_user_date ON daily_entries (user_id, date);
`);

console.log("Schema applied.");
db.close();
