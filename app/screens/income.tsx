import type { Source, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Header } from "../ui/primitives.tsx"
import { Back, calc, cur, Empty, Err, IncRow, ListCard, plain, XCard } from "./shared.tsx"
const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount)
const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id)
const tagOf = (x: Source) => (!x.active ? "paused" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto") : "manual")
const Hid = ({ s, id }: { s: State; id: string }) => <><Back s={s} /><input type="hidden" name="id" value={id} /></>
const ToggleForm = ({ s, x, label }: { s: State; x: Source; label: string }) => (
<form method="post" action="/income/toggle" style="display:contents"><Hid s={s} id={x.id} /><button class="btn xs o">{label}</button></form>
)
const DeleteSource = ({ s, x }: { s: State; x: Source }) => (
<form method="post" action="/income/source/delete" style="display:contents" data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}><Hid s={s} id={x.id} /><button class="ub" aria-label={`Delete ${x.name}`}><Icon name="trash" /></button></form>
)
const AddedUndo = ({ s, x, got }: { s: State; x: Source; got: State["incomesToday"] }) => (
<><button class="btn xs" disabled>Added</button><form method="post" action="/income/delete" style="display:contents" data-confirm={`Undo +${fmt(got.reduce((a, i) => a + i.amount, 0))} from ${x.name}?`}><Hid s={s} id={got[0]!.id} /><button class="ub" aria-label={`Undo ${x.name}`}><Icon name="undo" /></button></form></>
)
const AddFixed = ({ s, x, fixed }: { s: State; x: Source; fixed: number }) => (
<form method="post" action="/income/add" style="display:contents"><Back s={s} /><input type="hidden" name="source_id" value={x.id} /><button class="btn xs o">Add {fmt(fixed)}</button></form>
)
const AddAmount = ({ s, x }: { s: State; x: Source }) => (
<form method="post" action="/income/add" class="ln" style="gap:6px"><Back s={s} /><input type="hidden" name="source_id" value={x.id} /><input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required /><button class="btn xs o">Add</button></form>
)
const SourceRow = ({ s, x }: { s: State; x: Source }) => {
const got = gotToday(s, x)
const fixed = srcAmount(x)
const main = !x.active ? <ToggleForm s={s} x={x} label="Resume" /> : x.mode === "auto" ? <><b class="ea">+{fmt(x.amount)}</b><ToggleForm s={s} x={x} label="Pause" /></> : got.length ? <AddedUndo s={s} x={x} got={got} /> : fixed ? <AddFixed s={s} x={x} fixed={fixed} /> : <AddAmount s={s} x={x} />
return <div class="rw"><div><div>{x.name}<span class="tag">{tagOf(x)}</span></div></div><span class="rt">{main}<DeleteSource s={s} x={x} /></span></div>
}
const SourceRows = ({ s }: { s: State }) => (s.sources.length ? <>{s.sources.map((x) => <SourceRow s={s} x={x} />)}</> : <Empty>No sources yet. Add one below.</Empty>)
const ModeChips = () => (
<><input type="hidden" name="mode" value="manual" data-mode-input /><div class="chips" style="margin:10px 0 4px"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div><div class="lb" style="margin-bottom:2px">Manual: you tap it, once a day. Auto: added for you.</div></>
)
const SourceFields = () => (
<div class="ln"><input class="in" name="name" placeholder="New source" autocomplete="off" required /><input class="in pr" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" /></div>
)
const AddSourceForm = ({ s, id }: { s: State; id: string }) => (
<form method="post" action="/income" id={id} class="sc spf" data-adp hidden><Back s={s} /><SourceFields /><ModeChips /><button class="btn full">Add source</button></form>
)
const SourceForm = ({ s }: { s: State }) => (
<form method="post" action="/income" class="sf xfm" data-adp hidden><Back s={s} /><SourceFields /><ModeChips /><button class="btn full">Add source</button></form>
)
const ManageRow = ({ s, x }: { s: State; x: Source }) => {
const fixed = srcAmount(x)
return (
<div class="dbw"><div class="rw"><div><div>{x.name}<span class="tag">{tagOf(x)}</span></div>{fixed ? <div class="lb">{fmt(fixed)} {cur(s)}</div> : null}</div><span class="rt"><ToggleForm s={s} x={x} label={x.active ? "Pause" : "Resume"} /><button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}><Icon name="edit" /></button><DeleteSource s={s} x={x} /></span></div><form method="post" action="/income/edit" class="ad" data-addp hidden><Hid s={s} id={x.id} /><label>Edit {x.name}</label><div class="ln"><input class="in f" name="name" value={x.name} autocomplete="off" required /><input class="in pr2" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Amount" inputmode="decimal" autocomplete="off" /><button class="btn xs">Save</button></div></form></div>
)
}
const IncomeCard = ({ s }: { s: State }) => (
<XCard k="income" open={true} title="Income sources" head={<><b class="big2">{s.sources.length}</b><span class="lb">{s.sources.filter((x) => x.active).length} active</span></>} body={s.sources.length ? <>{s.sources.map((x) => <ManageRow s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>} foot={null} form={<SourceForm s={s} />} label="Add source" />
)
const HomeRow = ({ s, x }: { s: State; x: Source }) => {
const got = gotToday(s, x)
const fixed = srcAmount(x)
const main = x.mode === "auto" ? <b class="ea">+{fmt(x.amount)}</b> : got.length ? <AddedUndo s={s} x={x} got={got} /> : fixed ? <AddFixed s={s} x={x} fixed={fixed} /> : <AddAmount s={s} x={x} />
return <div class="rw"><div><div>{x.name}</div></div><span class="rt">{main}</span></div>
}
export const HomeIncome = ({ s }: { s: State }) => {
const c = calc(s)
const active = s.sources.filter((x) => x.active)
const other = s.incomesToday.filter((i) => !i.sourceId)
const form = <form method="post" action="/history/income" class="sf xfm" data-adp hidden><Back s={s} /><div class="ln"><input class="in" name="amount" placeholder="Other income today" inputmode="decimal" autocomplete="off" required /><button class="btn">Add</button></div></form>
return <XCard k="inc" open={true} title="Income today" head={<><b class="big2">+{fmt(c.earned)} <small>{cur(s)}</small></b><span class="lb">{c.earnedLine}</span></>} body={active.length || other.length ? <>{active.map((x) => <HomeRow s={s} x={x} />)}{other.map((i) => <IncRow s={s} i={i} />)}</> : <Empty>No sources yet.</Empty>} foot={null} form={form} label="Add other income" />
}
export const IncomeSourcesDesktop = ({ s, title = "Income sources", id = "f-src-d" }: { s: State; title?: string; id?: string }) => (
<><AddSourceForm s={s} id={id} /><ListCard wide={true} title={title} right={`+${fmt(calc(s).earned)} today`} body={<SourceRows s={s} />} target={id} label="Add source" /></>
)
export const income = (s: State): PageSpec => ({
title: "Income",
mobileTab: "income",
desktopTab: "income",
mobile: <><Err s={s} /><Header title="Income" right={calc(s).earned ? `+${fmt(calc(s).earned)} today` : ""} /><IncomeCard s={s} /></>,
desktop: <><Err s={s} /><div class="hd"><h1 class="t">Income</h1><span></span></div><IncomeCard s={s} /></>,
})
