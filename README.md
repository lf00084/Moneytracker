# moneytracker (UI only)

Pages match the `Gaga.html` design, mobile and desktop from one codebase (`min-width: 900px` switches layout).

- `/login`, `/signup`: any input works, submitting redirects to `/home`. No session, no cookie.
- `/home` `/debts` `/notes` `/goals` `/income` `/plan` `/history` `/profile` `/profile/edit` `/settings`
- `POST /logout` redirects to `/login`.
- Theme (dark / white) is the only thing stored, in `localStorage`.

Layout: `app/ui` (css, shared parts, shell, tiny script), `app/pages/screens.ts` (every screen), `app/actions/controller.tsx` (routes).
