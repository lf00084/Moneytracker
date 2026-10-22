import type { DayRow, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import type { PageSpec } from "../ui/layout.tsx"
import { Card, Header, Section } from "../ui/primitives.tsx"
import { Back, Err, IncRow, SpendRow } from "./shared.tsx"
const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`
const DayItems = ({ s, d }: { s: State; d: DayRow }) => (
<>{d.incomes.map((i) => <IncRow s={s} i={i} />)}{d.buys.map((b) => <SpendRow s={s} id={b.id} name={b.qty > 1 ? `${b.name} ×${b.qty}` : b.name} sub={b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : ""} amount={`−${fmt(b.total)}`} />)}</>
)
const DayForms = ({ s, wide }: { s: State; wide: boolean }) => {
const t = today()
const body = (
<><form method="post" action="/buy"><Back s={s} /><div class="ln"><input class="in" name="label" placeholder="Item" autocomplete="off" required /><input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required /></div><div class="ln" style="margin-top:8px"><input class="in" type="date" name="day" value={t} max={t} required /><button class="btn xs">Add buy</button></div></form><form method="post" action="/history/income" style="margin-top:14px"><Back s={s} /><div class="ln"><input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required /><input class="in" type="date" name="day" value={t} max={t} required /><button class="btn xs">Add income</button></div></form></>
)
return wide ? <Section title="Add to any day">{body}</Section> : <Card title="Add to any day">{body}</Card>
}
const HistoryMobile = ({ s }: { s: State }) => (
<><Err s={s} /><DayForms s={s} wide={false} />{s.days.map((d) => <Card title={d.label}><div class="l1"><span><span class="lb">Earned</span> <b class="ea">+{fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−{fmt(d.bought)}</b></span><b>{dayNet(d.earned, d.bought)}</b></div><DayItems s={s} d={d} /></Card>)}</>
)
const HistoryTable = ({ s }: { s: State }) => {
const e = s.days.reduce((a, d) => a + d.earned, 0)
const b = s.days.reduce((a, d) => a + d.bought, 0)
return (
<Section title="Last 30 days" right={`+${fmt(e)} earned · −${fmt(b)} bought`}><div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>{s.days.map((d) => <div class="tr"><b>{d.label}</b><b class="ea">+{fmt(d.earned)}</b><b class="sp">−{fmt(d.bought)}</b><b>{dayNet(d.earned, d.bought)}</b><div><DayItems s={s} d={d} /></div></div>)}</Section>
)
}
export const history = (s: State): PageSpec => ({
title: "History",
mobileTab: "history",
desktopTab: "history",
mobile: <><Header title="History" right="last 30 days" /><HistoryMobile s={s} /></>,
desktop: <><div class="hd"><h1 class="t">History</h1><span class="lb">last 30 days</span></div><Err s={s} /><DayForms s={s} wide={true} /><HistoryTable s={s} /></>,
})
