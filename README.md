# Remix starter

Single-app Remix 3 + Vite + Cloudflare Workers, trimmed from `sergiodxa/monorepo/apps/demo`.

```bash
bun install          # or npm / pnpm
bun run cf:typegen   # generates .cloudflare/types (Cloudflare.Env)
bun run dev          # http://localhost:3000
bun run build
bun run cf:deploy
```

## Layout

| Path                        | Purpose                                        |
| --------------------------- | ---------------------------------------------- |
| `bootstrap/worker.ts`       | Worker entry, forwards requests to the router  |
| `bootstrap/app.tsx`         | Router + HTML renderer                         |
| `bootstrap/browser.ts`      | Client entry (only loaded by pages that hydrate) |
| `routes/web.ts`             | Route table                                    |
| `app/http/controllers/`     | One controller per route                       |
| `resources/layouts/`        | HTML document shell                            |
| `cloudflare.config.ts`      | Worker name, flags, bindings                   |

Add a page: add a pattern in `routes/web.ts`, create a controller with `createAction`, then `router.map(...)` it in `bootstrap/app.tsx`.
