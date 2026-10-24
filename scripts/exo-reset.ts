import { createClient } from "@libsql/client"

const url = process.env.TURSO_DATABASE_URL
const authToken = process.env.TURSO_AUTH_TOKEN
if (!url) throw new Error("TURSO_DATABASE_URL is not set (put it in .dev.vars)")
const yes = process.argv.includes("--yes")
const client = createClient({ url, authToken })
const fmtDay = new Intl.DateTimeFormat("en-CA", { timeZone: "Africa/Casablanca", year: "numeric", month: "2-digit", day: "2-digit" })
const exoDay = fmtDay.format(Date.now() - 5 * 3600000)
const before = new Date(`${exoDay}T12:00:00Z`)
before.setUTCDate(before.getUTCDate() - 1)
const checked = before.toISOString().slice(0, 10)
const sources = await client.execute("SELECT id, name, config FROM income_sources WHERE type = 'exoclick'")
if (!sources.rows.length) console.log("No ExoClick source found.")
for (const s of sources.rows) {
const rows = await client.execute({ sql: "SELECT day, usd_minor, amount_minor FROM incomes WHERE source_id = ? ORDER BY day", args: [String(s.id)] })
const total = rows.rows.reduce((a, r) => a + Number(r.amount_minor || 0), 0)
console.log(`${s.name}: ${rows.rows.length} rows, ${(total / 100).toFixed(2)} added to your balance`)
for (const r of rows.rows) console.log(`  ${r.day}  $${(Number(r.usd_minor || 0) / 100).toFixed(2)}  ->  ${(Number(r.amount_minor || 0) / 100).toFixed(2)}`)
if (!yes) continue
let cfg: Record<string, unknown> = {}
try {
cfg = JSON.parse(String(s.config || "{}"))
} catch {}
await client.execute({ sql: "DELETE FROM incomes WHERE source_id = ?", args: [String(s.id)] })
await client.execute({ sql: "UPDATE income_sources SET config = ? WHERE id = ?", args: [JSON.stringify({ ...cfg, checked }), String(s.id)] })
console.log(`  removed. ExoClick will start fresh from ${exoDay}.`)
}
if (!yes) console.log("\nNothing changed. Run again with --yes to remove these rows and take the money out of your balance.")
client.close()
