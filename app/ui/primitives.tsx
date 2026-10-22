import { Icon } from "./icons.tsx"
type Kids = { children?: unknown }
export const Google = () => (
<svg width="18" height="18" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>
)
export const Goat = () => (
<svg viewBox="0 0 24 24"><rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/></svg>
)
export const Logo = ({ href }: { href: string }) => (
<a class="logo" href={href}><Goat /><span>moneytracker</span></a>
)
export const ThemeIcons = () => (
<><Icon name="sun" class="ic t-sun" /><Icon name="moon" class="ic t-moon" /></>
)
export const Card = ({ title, children }: Kids & { title: unknown }) => (
<div class="cd"><div class="tg">{title}</div><div class="cb">{children}</div></div>
)
export const Section = ({ title, right = "", children }: Kids & { title: unknown; right?: unknown }) => (
<div class="sc"><div class="sh"><span>{title}</span><span class="lb">{right}</span></div>{children}</div>
)
export const Field = ({ label, value = "", name, type, placeholder, f, keep }: { label: string; value?: string; name?: string; type?: string; placeholder?: string; f?: boolean; keep?: string }) => (
<div class="fl"><label>{label}</label><input class={"in" + (f ? " f" : "")} name={name} data-keep={keep} type={type} value={value} placeholder={value ? undefined : (placeholder ?? "")} autocomplete="off" /></div>
)
export const Header = ({ title, right = "", back }: { title: string; right?: unknown; back?: string }) => (
<div class="hd">{back ? <a class="back" href={back}><Icon name="back" /><h1 class="t">{title}</h1></a> : <h1 class="t">{title}</h1>}<span class="lb">{right}</span></div>
)
export const ThemeSwitch = () => (
<div class="sg"><button type="button" data-set-theme="dark"><Icon name="moon" />Dark</button><button type="button" data-set-theme="light"><Icon name="sun" />White</button></div>
)
