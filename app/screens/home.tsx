import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import type { PageSpec } from "../ui/layout.tsx"
import { Card } from "../ui/primitives.tsx"
import { OweDesktop, OweMobile } from "./debts.tsx"
import { GoalsCard } from "./goals.tsx"
import { HomeIncome, IncomeSourcesDesktop } from "./income.tsx"
import { NoteDash } from "./notes.tsx"
import { BalanceCard } from "./profile.tsx"
import { Back, calc, cur, Empty, Err, ListCard, NameChips, SpendRow, XCard } from "./shared.tsx"
const EarnedBought = ({ s }: { s: State }) => {
const c = calc(s)
return (
<div class="two"><Card title="Earned today"><div class="big2" style="white-space:nowrap">+{fmt(c.earned)} <small>{cur(s)}</small></div></Card><Card title="Bought today"><div class="big2" style="white-space:nowrap">−{fmt(c.bought)} <small>{cur(s)}</small></div></Card></div>
)
}
const BuyRows = ({ s }: { s: State }) => (
<div>{s.buys.length ? s.buys.map((b) => <SpendRow s={s} id={b.id} name={b.qty > 1 ? `${b.name} ×${b.qty}` : b.name} sub={`${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`} amount={`−${fmt(b.total)}`} />) : <Empty>Nothing bought today.</Empty>}</div>
)
const SpendFields = ({ s }: { s: State }) => (
<><Back s={s} /><NameChips names={s.names} /><div class="ln"><input class="in" name="label" data-name placeholder="Item" autocomplete="off" required /><input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required /></div><button class="btn full">Add a spend</button></>
)
const BuysMobile = ({ s }: { s: State }) => (
<XCard k="buys" open={true} title="Today's buys" head="" body={<BuyRows s={s} />} foot={null} form={<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden><SpendFields s={s} /></form>} label="Add a spend" />
)
const BuysDesktop = ({ s }: { s: State }) => (
<><form method="post" action="/buy" id="f-buy-d" class="sc spf" data-sp data-adp hidden><SpendFields s={s} /></form><ListCard wide={true} title="Today's buys" right={`${s.buys.length}`} body={<BuyRows s={s} />} target="f-buy-d" label="Add a spend" /></>
)
const Hero = ({ s }: { s: State }) => {
const c = calc(s)
return (
<div class="hero"><div><div class="lb">Earned today</div><div class="v">+{fmt(c.earned)}</div>{c.earnedLine ? <div class="lb">{c.earnedLine}</div> : null}</div><div><div class="lb">Bought today</div><div class="v">−{fmt(c.bought)}</div><div class="lb">{s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">{c.pct}%</div><div class="mt"><i style={`width:${c.pct}%`}></i></div></div><div><div class="lb">I owe</div><div class="v sp">{fmt(c.oweMoney)}</div><div class="lb">{cur(s)} {c.oweExtra}</div></div></div>
)
}
const Dashboard = ({ s }: { s: State }) => (
<><Hero s={s} /><div class="g2"><div><BuysDesktop s={s} /></div><div><OweDesktop s={s} open={false} k="owe" /><IncomeSourcesDesktop s={s} title="Income today" /><NoteDash s={s} /></div></div></>
)
export const home = (s: State): PageSpec => ({
title: "Home",
mobileTab: "home",
desktopTab: "home",
mobile: <><Err s={s} /><BalanceCard s={s} /><EarnedBought s={s} /><HomeIncome s={s} /><BuysMobile s={s} /><GoalsCard s={s} open={false} k="goals" manage={false} /><OweMobile s={s} open={false} k="owe" /></>,
desktop: <><Err s={s} /><Dashboard s={s} /></>,
})
