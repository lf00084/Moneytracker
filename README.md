# moneytracker

Remix v3 on Cloudflare Workers, Turso (libSQL) through `data-table`, email + Google login.

## Setup
1. `bunx jsr add @kuboon/remix-data-table-sqlite-turso` then `bun install`
2. Copy `.dev.vars.example` to `.dev.vars` and fill it in (same Turso database for local and Cloudflare)
3. `bun run db:migrate` (safe to run again; adds new columns to an older database)
4. `bun run cf:typegen`, then `bun run dev`
5. Production: `bunx wrangler secret put` for each secret in `wrangler.jsonc`, set `APP_ORIGIN`, `bun run deploy`

## Layout
- `database/schema.sql`: every table. Money is integer minor units (MAD x 100).
- `app/db`: Turso client, typed tables, DB-backed session storage.
- `app/lib`: `users.ts` (accounts), `data.ts` (page data), `actions.ts` (every write), `auth.ts`, `password.ts`.
- `app/pages`, `app/ui`: server-rendered screens and the small browser script.
- `app/actions/controller.tsx`: routes. Every page needs a signed-in user.

Days use the zone in `app/lib/time.ts` (`Africa/Casablanca`).
