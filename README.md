# Money goal (Remix v3 + Turso) - Phase 1

Google sign-in, one goal per user, manual income sources, daily entries, mobile-first home.

## Setup

1. Turso: `turso db create myapp`, then `turso db show myapp --url` and `turso db tokens create myapp`.
2. Google Cloud console: OAuth client (Web). Add redirect URI `<APP_URL>/auth/google/callback`
   for localhost, your Codespaces URL and your domain.
3. `cp .dev.vars.example .dev.vars` and fill all six values. `APP_URL` is the exact URL you open.
4. `bun install`, `bun run cf:typegen`, `bun run db:migrate`, `bun run dev`.

## Files

| File | Why it exists |
| --- | --- |
| `bootstrap/app.tsx` | The whole app: routes, auth, data layer, pages, CSS |
| `bootstrap/worker.ts` | Worker entry the Cloudflare plugin requires; passes secrets to the app |
| `bootstrap/browser.ts` | Client entry the Remix Vite plugin requires; no page loads it yet |
| `vite.config.ts`, `cloudflare.config.ts`, `tsconfig.json`, `package.json` | Tooling config |
| `scripts/migrate.mjs` | Creates the tables in Turso |

## Phase 1 behavior

- A day is the user's local day: timezone plus a day-start hour (Settings).
- Left to goal = target - kept, kept = earned - spent. Setting can count earned only.
- Manual source: one number per source per day, input only while not filled today.
- Filled display: done list (default), locked in place, or hidden. Small Edit button for fixes.
- Money is stored as integer cents. Every query is filtered by `user_id` inside `store()`.
- `GET /api/home` returns the same numbers as JSON, same auth and same data layer.
