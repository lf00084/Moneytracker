import { AppPage, type PageSpec } from "../ui/layout.tsx"
import type { State } from "../lib/data.ts"
import { debts } from "./debts.tsx"
import { goals } from "./goals.tsx"
import { history } from "./history.tsx"
import { home } from "./home.tsx"
import { income } from "./income.tsx"
import { notes } from "./notes.tsx"
import { pad, profile, profileEdit, settings } from "./profile.tsx"
export { LoginScreen, SignupScreen } from "./auth.tsx"
export const specs = { home, debts, notes, goals, income, plan: goals, history, profile, profileEdit, settings, pad: (_s: State) => pad() } satisfies Record<string, (s: State) => PageSpec>
export type ScreenKey = keyof typeof specs
export const Screen = ({ name, s }: { name: ScreenKey; s: State }) => <AppPage {...specs[name](s)} theme={s.user.theme} />
