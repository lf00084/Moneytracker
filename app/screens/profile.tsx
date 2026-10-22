import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon } from "../ui/icons.tsx"
import type { PageSpec } from "../ui/layout.tsx"
import { Card, Field, Header, Section, ThemeSwitch } from "../ui/primitives.tsx"
import { Avatar, Back, cur, Err, LANG, plain } from "./shared.tsx"
const ProfileForm = ({ s, cancel }: { s: State; cancel: string }) => (
<form method="post" action="/profile/edit"><Err s={s} /><Field label="Name" value={s.user.name} f={true} name="name" /><Field label="Email" value={s.user.email} type="email" name="email" /><div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href={cancel}>Cancel</a></div></form>
)
const PrefsForm = ({ s }: { s: State }) => (
<form method="post" action="/settings"><Field label="Currency" value={s.user.currency} name="currency" /><Field label="Auto income runs at" value={s.user.run_at} name="run_at" /><Field label="Week starts" value={s.user.week_start} name="week" /><button class="btn" style="margin-top:14px">Save</button></form>
)
const DataButtons = () => (
<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>
)
const BalanceForm = ({ s }: { s: State }) => (
<form method="post" action="/profile/balance"><Back s={s} /><div class="fl"><label>Balance ({cur(s)})</label><input class="in f" name="balance" inputmode="decimal" value={plain(s.balance)} autocomplete="off" required /></div><button class="btn full" style="margin-top:14px">Update balance</button></form>
)
export const BalanceCard = ({ s, edit = false }: { s: State; edit?: boolean }) => (
<div class="cd"><div class="tg">Total balance</div><div class="cb"><div class="ow" style="margin:0"><span style="display:flex;align-items:center;gap:10px"><b class="big2" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={cur(s)}>••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance"><Icon name="eye" /></button></span>{edit ? <button type="button" class="lnk" data-edit-bal>Edit balance</button> : null}</div>{edit ? <div data-balf hidden><BalanceForm s={s} /></div> : null}</div></div>
)
const ProfileMobile = ({ s }: { s: State }) => (
<><Err s={s} /><div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px"><Avatar s={s} /><div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">{s.user.name}</div><div class="lb">{s.user.email}</div><div class="chips" style="justify-content:center;margin-top:10px"><span class="chip" style="cursor:default">{cur(s)}</span><span class="chip" style="cursor:default">{LANG}</span></div></div></div><BalanceCard s={s} edit={true} /><Card title="Appearance"><ThemeSwitch /></Card><Card title="Account"><a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form></Card></>
)
const EditMobile = ({ s }: { s: State }) => (
<><div style="display:flex;justify-content:center;margin:14px 0 0"><Avatar s={s} /></div><Card title="Profile"><ProfileForm s={s} cancel="/profile" /></Card></>
)
const SettingsMobile = ({ s }: { s: State }) => (
<><Err s={s} /><Card title="Money & income"><PrefsForm s={s} /></Card><Card title="Data"><DataButtons /></Card><div class="lb" style="text-align:center;margin:18px 0">Moneytracker v1.0 · stable</div></>
)
const SettingsDesktop = ({ s }: { s: State }) => (
<><div class="hd"><h1 class="t">Settings</h1><span class="lb">{cur(s)} · {LANG}</span></div><Err s={s} /><div class="g3"><div><BalanceCard s={s} edit={true} /><Section title="Profile"><ProfileForm s={s} cancel="/home" /></Section><Section title="Account"><form method="post" action="/logout"><button class="btn o">Log out</button></form></Section></div><div><Section title="Appearance"><ThemeSwitch /></Section><Section title="Money & income"><PrefsForm s={s} /></Section><Section title="Data"><DataButtons /></Section></div></div></>
)
export const profile = (s: State): PageSpec => ({ title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: <ProfileMobile s={s} />, desktop: <SettingsDesktop s={s} /> })
export const profileEdit = (s: State): PageSpec => ({ title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: <><Header title="Edit profile" back="/profile" /><EditMobile s={s} /></>, desktop: <SettingsDesktop s={s} /> })
export const settings = (s: State): PageSpec => ({ title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: <><Header title="Settings" back="/profile" /><SettingsMobile s={s} /></>, desktop: <SettingsDesktop s={s} /> })
export const pad = (): PageSpec => ({ title: "Pad", mobileTab: "pad", desktopTab: "pad", mobile: "", desktop: "" })
