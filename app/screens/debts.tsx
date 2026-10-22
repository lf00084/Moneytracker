import type { DebtView, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Header, Section } from "../ui/primitives.tsx"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Back, BigAdd, calc, cur, Empty, Err, NameChips, pctOf, plain, XCard } from "./shared.tsx"
import { GoalRoad } from "./goals.tsx"
const DebtPanel = ({ s, d, flag, action, title, btn }: { s: State; d: DebtView; flag: string; action: string; title: string; btn: string }) => {
const unit = d.kind === "money" ? cur(s) : d.item
const all = d.kind === "money" ? plain(d.owed) : String(d.owed)
const attrs = { [flag]: true } as Record<string, boolean>
return (
<form method="post" action={action} class="ad" {...attrs} hidden><input type="hidden" name="debt_id" value={d.id} /><Back s={s} /><label>{title} {d.person}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off" />{flag === "data-payp" ? <button type="button" class="all" data-all={all} aria-label="Fill the full amount">All</button> : null}<span class="mu">{unit}</span></div><button class="btn xs">{btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn={`Remove ${d.person} from the list without marking it paid?`} aria-label="Remove without paying"><Icon name="trash" /></button></div></form>
)
}
const DebtRow = ({ s, d }: { s: State; d: DebtView }) => {
const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${d.item}`
const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0
return (
<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label={`Add debt to ${d.person}`}><Icon name="plus" /></button><div class="dn"><div class="l1"><b>{d.person}</b><span>{label}</span></div><div class="mt s n"><i style={`width:${pct}%`}></i></div></div><button type="button" class="btn xs o" data-pay>Pay</button></div><DebtPanel s={s} d={d} flag="data-addp" action="/debts" title="Add to" btn="Add" /><DebtPanel s={s} d={d} flag="data-payp" action="/debts/pay" title="Pay" btn="Pay" /></div>
)
}
const DebtList = ({ s }: { s: State }) => (s.debts.length ? <>{s.debts.map((d) => <DebtRow s={s} d={d} />)}</> : <Empty>Nobody to pay. All clear.</Empty>)
const AddDebtPanel = ({ s }: { s: State }) => (
<form method="post" action="/debts" class="sf adp" data-adp hidden><Back s={s} /><NameChips names={[...new Set(s.debts.map((d) => d.person))]} /><input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required /><div class="iw"><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required /><span class="mu">{cur(s)}</span></div><button class="btn full">Add</button></form>
)
const peopleCount = (s: State) => new Set(s.debts.map((d) => d.person)).size
export const OweMobile = ({ s, open, k }: { s: State; open: boolean; k: string }) => {
const c = calc(s)
return <XCard k={k} open={open} title="I owe" head={<><b class="big2 sp">{fmt(c.oweMoney)} <small>{cur(s)}</small></b><span class="sp sm">{c.oweExtra}</span></>} body={<DebtList s={s} />} foot={<div class="xl"><span>{peopleCount(s) === 1 ? "1 person" : `${peopleCount(s)} people`}</span></div>} form={<AddDebtPanel s={s} />} label="Add debt" />
}
export const OweDesktop = ({ s, open, k }: { s: State; open: boolean; k: string }) => {
const c = calc(s)
return (
<div class="sc bgc"><BigAdd label="Add debt" /><div class="ct"><details data-keep-open={k} open={open}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">{fmt(c.oweMoney)} {cur(s)} {c.oweExtra}</span><span class="chev"><Icon name="chev" /></span></span></summary><DebtList s={s} /></details><AddDebtPanel s={s} /></div></div>
)
}
const DebtsDesktop = ({ s }: { s: State }) => {
const c = calc(s)
return (
<><div class="hd"><h1 class="t">Debts</h1><span class="lb">{fmt(c.oweMoney)} {cur(s)} {c.oweExtra}</span></div><div class="g3"><div><OweDesktop s={s} open={true} k="owe-page" /></div><div><Section title="How it works"><div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div></Section></div></div></>
)
}
export const debts = (s: State): PageSpec => ({
title: "Debts",
mobileTab: "home",
desktopTab: "home",
mobile: <><Err s={s} /><Header title="Debts" right={s.debts.map((d) => d.person).slice(0, 2).join(" + ")} /><GoalRoad s={s} /><OweMobile s={s} open={true} k="owe-page" /></>,
desktop: <><Err s={s} /><DebtsDesktop s={s} /></>,
})
