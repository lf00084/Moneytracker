# moneytracker (UI only)

Pages match the `Gaga.html` design, mobile and desktop from one codebase (`min-width: 900px` switches layout).

- `/login`, `/signup`: any input works, submitting redirects to `/home`. No session, no cookie.
- `/home` `/debts` `/notes` `/goals` `/income` `/plan` `/history` `/profile` `/profile/edit` `/settings`
- `POST /logout` redirects to `/login`.
- No top bar. Phone: icon-only bottom bar (logo = Home, Notes, Goals, History, Profile, theme). Desktop: left sidebar.
- Saved in the browser (`localStorage`, keys `mt:*`): theme, quick buys (edit them in Settings), notes, today's buys, profile fields, and whether "I owe" is open.

Layout: `app/ui` (css, shared parts, shell, tiny script), `app/pages/screens.ts` (every screen), `app/actions/controller.tsx` (routes).
