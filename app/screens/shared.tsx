import type { Goal, Income, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon } from "../ui/icons.tsx"
type Kids = { children?: unknown }
export const LANG = "English"
export const cur = (s: State) => s.user.currency
export const plain = (n: number) => (n / 100).toFixed(2).replace(/\.00$/, "")
export function calc(s: State) {
const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0)
const bought = s.buys.reduce((a, b) => a + b.total, 0)
const bySource = new Map<string, number>()
for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount)
const earnedLine = [...bySource].map(([n, a]) => `${n} ${fmt(a)}`).join(" · ") || ""
const money = s.debts.filter((d) => d.kind === "money")
const oweMoney = money.reduce((a, d) => a + d.owed, 0)
const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0)
const oweExtra = oweItems ? `+ ${oweItems} cig` : ""
const wishTarget = s.goals.reduce((a, g) => a + g.target, 0)
const wishSaved = Math.min(Math.max(0, s.balance), wishTarget)
const debtPaid = money.reduce((a, d) => a + d.paid, 0)
const total = wishTarget + oweMoney + debtPaid
const done = wishSaved + debtPaid
const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0
return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) }
}
export const covered = (s: State) => new Map(s.goals.map((g) => [g.id, Math.min(Math.max(0, s.balance), g.target)] as const))
export const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round(((covered(s).get(g.id) ?? 0) / g.target) * 100)) : 0)
export const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target
export const Back = ({ s }: { s: State }) => <input type="hidden" name="back" value={s.back} />
export const Err = ({ s }: { s: State }) => (s.error ? <div class="neg" role="alert" style="margin:10px 0;font-size:13px">{s.error}</div> : null)
export const Empty = ({ children }: Kids) => <div class="lb" style="padding:8px 0">{children}</div>
export function Avatar({ s }: { s: State }) {
const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : ""
return <div class="av" style={url ? `background:url('${url}') center/cover` : undefined}>{url ? null : (s.user.name.trim()[0] ?? "?").toUpperCase()}</div>
}
export const BigAdd = ({ label, target = "", right = false }: { label: string; target?: string; right?: boolean }) => (
<button type="button" class={`addb${right ? " r" : ""}`} data-bigadd data-for={target || undefined} aria-label={label}><Icon name="plus" /></button>
)
export const NameChips = ({ names }: { names: string[] }) => (names.length ? <div class="chips nm">{names.map((n) => <span class="chip" data-nm={n}>{n}</span>)}</div> : null)
export const ListCard = ({ wide, title, right, body, target, label }: { wide: boolean; title: unknown; right: unknown; body: unknown; target: string; label: string }) =>
wide ? (
<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>{title}</span><span class="lb">{right}</span></div>{body}</div><BigAdd label={label} target={target} right={true} /></div>
) : (
<div class="cd bgc rgt"><div class="ct"><div class="tg">{title}</div><div class="cb">{body}</div></div><BigAdd label={label} target={target} right={true} /></div>
)
export const XCard = ({ k, open, title, head, body, foot, form, label, jar = -1 }: { k: string; open: boolean; title: unknown; head: unknown; body: unknown; foot: unknown; form: unknown; label: string; jar?: number }) => (
<div class={`xc${label ? "" : " xn"}`}><details class="xd" data-keep-open={k} open={open}><summary class="xh osum">{jar >= 0 ? <i class={`xj${jar >= 100 ? " full" : ""}`} style={`width:${jar}%`}></i> : null}<div><div class="tg0">{title}</div>{head ? <div class="ow">{head}</div> : null}</div><span class="chev"><Icon name="chev" /></span></summary><div class="xb">{body}</div><div class={`xf${foot ? "" : " xo"}`}>{foot}{form}</div></details>{label ? <button type="button" class="xp" data-xplus aria-label={label}><Icon name="plus" /></button> : null}</div>
)
export const SpendRow = ({ s, id, name, sub, amount }: { s: State; id: string; name: string; sub: string; amount: string }) => (
<div class="by"><div><div>{name}</div><div class="lb">{sub}</div></div><span class="rt"><b class="sp">{amount}</b><form method="post" action="/buy/delete" style="display:contents" data-confirm="Undo this buy? The money comes back."><Back s={s} /><input type="hidden" name="id" value={id} /><button class="ub" aria-label="Undo buy"><Icon name="undo" /></button></form></span></div>
)
export const IncRow = ({ s, i }: { s: State; i: Income }) => (
<div class="by"><div><div>{i.source}</div></div><span class="rt"><b class="ea">+{fmt(i.amount)}</b><form method="post" action="/income/delete" style="display:contents" data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}><Back s={s} /><input type="hidden" name="id" value={i.id} /><button class="ub" aria-label="Undo income"><Icon name="undo" /></button></form></span></div>
)
