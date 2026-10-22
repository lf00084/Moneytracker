import { createController } from "remix/router"
import * as act from "../lib/actions.ts"
import { loadScreen } from "../loaders.ts"
import { routes } from "../routes.ts"
import { Screen, type ScreenKey } from "../screens/index.tsx"
import { render } from "../utils/render.ts"
import { go, takeError, userOf, type Ctx } from "../utils/request.ts"
const screen = (key: ScreenKey) => async (ctx: Ctx) => {
const user = userOf(ctx)
if (!user) return go("/login")
const s = await loadScreen(user, key, takeError(ctx))
return render(<Screen name={key} s={s} />)
}
export default createController(routes.pages, {
actions: {
root: (ctx: Ctx) => go(userOf(ctx) ? "/home" : "/login"),
home: screen("home"),
debts: screen("debts"),
notes: screen("notes"),
goals: screen("goals"),
pad: screen("pad"),
income: screen("income"),
plan: screen("plan"),
history: screen("history"),
profile: screen("profile"),
profileEdit: screen("profileEdit"),
settings: screen("settings"),
async exportCsv(ctx: Ctx) {
const user = userOf(ctx)
if (!user) return go("/login")
return new Response(await act.exportCsv(user.id), {
headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": 'attachment; filename="moneytracker.csv"' },
})
},
},
})
