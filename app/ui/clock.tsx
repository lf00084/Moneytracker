import { TZ } from "../lib/time.ts"
const at = (loc: string, o: Intl.DateTimeFormatOptions) => new Intl.DateTimeFormat(loc, { timeZone: TZ, ...o }).format(new Date())
export const SubDate = () => (
<><span class="clock-num">{at("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })}</span>{" "}<span class="clock-dot">·</span>{" "}<span class="clock-ar">{at("ar-MA", { weekday: "long" })}</span></>
)
export const ClockWidget = () => (
<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time"><div class="clock-time" data-clock-time>{at("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })}</div><div class="clock-date" data-clock-date>{at("en-GB", { weekday: "long", day: "numeric", month: "long" })}</div><div class="clock-subdate" data-clock-subdate dir="ltr"><SubDate /></div></div>
)
