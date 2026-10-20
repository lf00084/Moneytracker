/** Days are YYYY-MM-DD in this zone. Change it if you live somewhere else. */
export const TZ = "Africa/Casablanca";

const dayFmt = new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" });
const timeFmt = new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "2-digit", minute: "2-digit" });

export const dayOf = (ms: number) => dayFmt.format(ms);
export const today = () => dayOf(Date.now());
export const hhmm = (ms: number) => timeFmt.format(ms);

export function addDays(day: string, n: number) {
	const d = new Date(`${day}T12:00:00Z`);
	d.setUTCDate(d.getUTCDate() + n);
	return d.toISOString().slice(0, 10);
}

const nice = (day: string, withYear = false) =>
	new Date(`${day}T12:00:00Z`)
		.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC", ...(withYear ? { year: "numeric" } : {}) })
		.replace(",", "");

/** "Today", "Yesterday", or "Sat 10 Oct". */
export function dayLabel(day: string) {
	const t = today();
	if (day === t) return "Today";
	if (day === addDays(t, -1)) return "Yesterday";
	return nice(day);
}

/** "Tue 13 Oct" for the page header. */
export const longDay = (day: string) => nice(day);
