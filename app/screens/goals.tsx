import type { Goal, GoalItem, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Header } from "../ui/primitives.tsx"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Back, calc, canBuy, covered, cur, Empty, Err, pctOf, plain, XCard } from "./shared.tsx"
import { IncomeSourcesDesktop } from "./income.tsx"
export const GoalRoad = ({ s }: { s: State }) => {
const c = calc(s)
const chips = [
...s.goals.map((g) => `${g.title} ${pctOf(s, g)}%`),
...s.debts.filter((d) => d.kind === "money").map((d) => `${d.person} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%`),
]
return (
<div class="cd jarc"><i class="jar" style={`width:${c.pct}%`}></i><div class="jin"><div class="tg">Road to goals</div><div class="cb"><div class="gl"><span class="big">{c.pct}<small>%</small></span><span class="lb">{fmt(c.toGo)} {cur(s)} to go</span></div>{chips.length ? <div class="chips">{chips.map((t) => <span class="chip">{t}</span>)}</div> : null}</div></div></div>
)
}
const goalLeft = (s: State, g: Goal) => (g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${cur(s)} · ready` : `${fmt(g.target - (covered(s).get(g.id) ?? 0))} to go`)
const ItemRow = ({ s, it, manage }: { s: State; it: GoalItem; manage: boolean }) => {
const ok = s.balance >= it.price
const cls = `gi${it.done ? " gdone" : ""}`
const name = <><span class="gn">{it.name}</span><span class="lb">{fmt(it.price)}</span></>
if (!manage)
return (
<div class={cls}>{name}<span class="wb">{it.done ? null : <form method="post" action="/goals/buy" style="display:contents" data-confirm={`Mark ${it.name} as bought? It will be added as a spend.`}><Back s={s} /><input type="hidden" name="id" value={it.id} /><button class={`btn xs${ok ? "" : " off"}`} disabled={!ok}>Bought</button></form>}</span></div>
)
return (
<div class="dbw"><div class={cls}>{name}<span class="wb">{it.done ? null : <button type="button" class="ub" data-pay aria-label={`Edit ${it.name}`}><Icon name="edit" /></button>}<form method="post" action="/goals/item/delete" style="display:contents" data-confirm={`Remove ${it.name} from this goal?`}><Back s={s} /><input type="hidden" name="id" value={it.id} /><button class="ub" aria-label={`Remove ${it.name}`}><Icon name="trash" /></button></form></span></div>{it.done ? null : <form method="post" action="/goals/item/edit" class="ad" data-payp hidden><Back s={s} /><input type="hidden" name="id" value={it.id} /><label>Edit {it.name}</label><div class="ln"><input class="in f" name="name" value={it.name} autocomplete="off" required /><input class="in pr2" name="price" value={plain(it.price)} placeholder="Price" inputmode="decimal" autocomplete="off" required /><button class="btn xs">Save</button></div></form>}</div>
)
}
const GoalRow = ({ s, g, manage }: { s: State; g: Goal; manage: boolean }) => {
const pct = pctOf(s, g)
const info = <div class="dn"><div class="l1"><b>{g.title}</b><span class="lb">{goalLeft(s, g)}</span></div><div class={`mt s${pct >= 100 ? " full" : ""}`}><i style={`width:${pct}%`}></i></div></div>
const items = g.items.map((it) => <ItemRow s={s} it={it} manage={manage} />)
if (!manage) return <div class="gw"><div class="db">{info}</div>{items}</div>
return (
<div class="gw"><div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label={`Add item to ${g.title}`}><Icon name="plus" /></button>{info}<span class="wb"><button type="button" class="ub" data-pay aria-label={`Rename ${g.title}`}><Icon name="edit" /></button><form method="post" action="/goals/delete" style="display:contents" data-confirm={`Delete ${g.title} and all its items?`}><Back s={s} /><input type="hidden" name="id" value={g.id} /><button class="ub" aria-label={`Delete ${g.title}`}><Icon name="trash" /></button></form></span></div><form method="post" action="/goals/item" class="ad" data-addp hidden><Back s={s} /><input type="hidden" name="goal_id" value={g.id} /><label>Add item to {g.title}</label><div class="ln"><input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required /><input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required /><button class="btn xs">Add</button></div></form><form method="post" action="/goals/edit" class="ad" data-payp hidden><Back s={s} /><input type="hidden" name="id" value={g.id} /><label>Rename goal</label><div class="ln"><input class="in f" name="name" value={g.title} autocomplete="off" required /><button class="btn xs">Save</button></div></form></div>{items}</div>
)
}
const GoalList = ({ s, manage }: { s: State; manage: boolean }) => (s.goals.length ? <>{s.goals.map((g) => <GoalRow s={s} g={g} manage={manage} />)}</> : <Empty>{manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</Empty>)
const GoalForm = ({ s }: { s: State }) => (
<form method="post" action="/goals" class="sf xfm" data-adp hidden><Back s={s} /><input class="in" name="name" placeholder="Goal name" autocomplete="off" required /><button class="btn full">Add goal</button></form>
)
const goalStat = (s: State) => {
const target = s.goals.reduce((a, g) => a + g.target, 0)
const saved = Math.min(Math.max(0, s.balance), target)
const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0
return { target, pct, toGo: Math.max(0, target - saved) }
}
export const GoalsCard = ({ s, open, k, manage }: { s: State; open: boolean; k: string; manage: boolean }) => {
const g = goalStat(s)
const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${cur(s)} to go`
const head = <><b class="big2">{g.pct}<small>%</small></b><span class="lb">{sub}</span></>
if (manage) return <XCard k={k} open={open} title="Goals" head={head} body={<GoalList s={s} manage={true} />} foot={<div class="xl"><span>Pencil edits, bin removes</span></div>} form={<GoalForm s={s} />} label="Add goal" jar={g.pct} />
return <XCard k={k} open={open} title="Goals" head={head} body={<GoalList s={s} manage={false} />} foot={<div class="xl"><span>Left to buy {fmt(g.target)} {cur(s)}</span><a class="lnk" href="/goals">Manage</a></div>} form={null} label="" jar={g.pct} />
}
export const goals = (s: State): PageSpec => ({
title: "Goals",
mobileTab: "home",
desktopTab: "plan",
mobile: <><Header title="Goals" right="add, edit, remove" /><Err s={s} /><GoalsCard s={s} open={true} k="goals-page" manage={true} /></>,
desktop: <><Err s={s} /><PlanDesktop s={s} /></>,
})
const PlanDesktop = ({ s }: { s: State }) => (
<><div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div><GoalsCard s={s} open={true} k="goals-d" manage={true} /></div><div><IncomeSourcesDesktop s={s} /></div></div></>
)
