import { loadState, type Part, type State } from "./lib/data.ts"
import type { User } from "./lib/users.ts"
import type { ScreenKey } from "./screens/index.tsx"
export const loaders: Record<ScreenKey, { path: string; parts: Part[] }> = {
home: { path: "/home", parts: ["today", "sources", "names", "debts", "goals", "notes", "balance"] },
debts: { path: "/debts", parts: ["debts", "goals", "balance"] },
notes: { path: "/notes", parts: ["notes"] },
goals: { path: "/goals", parts: ["goals", "debts", "balance"] },
income: { path: "/income", parts: ["sources", "today"] },
plan: { path: "/plan", parts: ["goals", "debts", "sources", "today", "balance"] },
history: { path: "/history", parts: ["history"] },
profile: { path: "/profile", parts: ["avatar", "balance"] },
profileEdit: { path: "/profile/edit", parts: ["avatar"] },
settings: { path: "/settings", parts: [] },
pad: { path: "/pad", parts: [] },
}
export const isScreen = (key: string): key is ScreenKey => Object.hasOwn(loaders, key)
export const loadScreen = (user: User, key: ScreenKey, error = ""): Promise<State> => loadState(user, loaders[key].parts, { back: loaders[key].path, error })
