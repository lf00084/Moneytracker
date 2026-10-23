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

export function liveClockNow() {
	const now = new Date();
	const timeStr = new Intl.DateTimeFormat("en-GB", {
		timeZone: TZ,
		hour: "2-digit",
		minute: "2-digit",
		hour12: false,
	}).format(now);
	const dateStr = new Intl.DateTimeFormat("en-GB", {
		timeZone: TZ,
		weekday: "long",
		day: "numeric",
		month: "long",
	}).format(now);
	const numDate = new Intl.DateTimeFormat("en-GB", {
		timeZone: TZ,
		day: "2-digit",
		month: "2-digit",
		year: "numeric",
	}).format(now);
	const arabicDay = new Intl.DateTimeFormat("ar-MA", {
		timeZone: TZ,
		weekday: "long",
	}).format(now);
	return { timeStr, dateStr, numDate, arabicDay };
}

export function getTimePeriod(): "morning" | "day" | "evening" | "night" {
	const hour = parseInt(
		new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "numeric", hour12: false }).format(new Date()),
		10
	);
	if (hour >= 5 && hour < 12) return "morning";
	if (hour >= 12 && hour < 18) return "day";
	if (hour >= 18 && hour < 22) return "evening";
	return "night";
}
