/**
 * Applies database/schema.sql to the Turso database named in your env.
 *   npm run db:migrate
 * Same database for local dev and Cloudflare, so run it once. Safe to run again.
 */
import { createClient } from "@libsql/client";
import { readFileSync } from "node:fs";

const url = process.env.TURSO_DATABASE_URL;
const authToken = process.env.TURSO_AUTH_TOKEN;
if (!url) throw new Error("TURSO_DATABASE_URL is not set (put it in .dev.vars)");

const client = createClient({ url, authToken });
const schema = readFileSync(new URL("../database/schema.sql", import.meta.url), "utf8");

await client.executeMultiple(schema);

// Columns added after the first version. A database created earlier gets them here.
const addColumns = [
"ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ''",
"ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT ''",
"ALTER TABLE users ADD COLUMN run_at TEXT NOT NULL DEFAULT '06:00'",
"ALTER TABLE users ADD COLUMN week_start TEXT NOT NULL DEFAULT 'Monday'",
"ALTER TABLE quick_buys ADD COLUMN price_minor INTEGER NOT NULL DEFAULT 0",
"ALTER TABLE users ADD COLUMN bg_mode TEXT NOT NULL DEFAULT 'auto'",
"ALTER TABLE users ADD COLUMN bg_url TEXT NOT NULL DEFAULT ''",
"ALTER TABLE income_sources ADD COLUMN type TEXT NOT NULL DEFAULT 'manual'",
"ALTER TABLE income_sources ADD COLUMN config TEXT NOT NULL DEFAULT '{}'",
"ALTER TABLE income_sources ADD COLUMN currency TEXT NOT NULL DEFAULT 'MAD'",
"ALTER TABLE income_sources ADD COLUMN active INTEGER NOT NULL DEFAULT 1",
"ALTER TABLE income_sources ADD COLUMN sort INTEGER NOT NULL DEFAULT 0",
"ALTER TABLE incomes ADD COLUMN meta TEXT NOT NULL DEFAULT '{}'",
"ALTER TABLE incomes ADD COLUMN ext_key TEXT NOT NULL DEFAULT ''",
];
for (const statement of addColumns) {
try {
await client.execute(statement);
console.log("added:", statement);
} catch (err) {
if (!/duplicate column/i.test(String(err))) throw err;
}
}

await client.execute("CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_key_idx ON incomes(ext_key) WHERE ext_key <> ''");
await client.execute("INSERT INTO goal_items (id, user_id, goal_id, name, price_minor, done_at, created_at) SELECT lower(hex(randomblob(16))), user_id, id, title, target_minor, NULL, created_at FROM goals g WHERE target_minor > 0 AND NOT EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = g.id)");
await client.execute("UPDATE goals SET target_minor = 0 WHERE target_minor > 0 AND EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = goals.id)");

const { rows } = await client.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
console.log("tables:", rows.map((r) => r.name).join(", "));
client.close();
