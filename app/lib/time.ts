const TZ = "Africa/Casablanca"

const dayFmt = new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" })
const timeFmt = new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "2-digit", minute: "2-digit" })

export const dayOf = (ms: number) => dayFmt.format(ms)
export const today = () => dayOf(Date.now())
export const hhmm = (ms: number) => timeFmt.format(ms)

export function addDays(day: string, n: number) {
	const d = new Date(`${day}T12:00:00Z`)
	d.setUTCDate(d.getUTCDate() + n)
	return d.toISOString().slice(0, 10)
}

export function dayLabel(day: string) {
	const t = today()
	if (day === t) return "Today"
	if (day === addDays(t, -1)) return "Yesterday"
	return new Date(`${day}T12:00:00Z`).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" }).replace(",", "")
}

export function timeAgo(ms: number) {
	const s = Math.max(0, Math.floor((Date.now() - ms) / 1000))
	if (s < 60) return "just now"
	const m = Math.floor(s / 60)
	if (m < 60) return `${m} min ago`
	const h = Math.floor(m / 60)
	if (h < 24) return `${h}h ago`
	const d = Math.floor(h / 24)
	if (d < 30) return d === 1 ? "1 day ago" : `${d} days ago`
	const mo = Math.floor(d / 30)
	if (mo < 12) return mo === 1 ? "1 month ago" : `${mo} months ago`
	const y = Math.floor(d / 365)
	return y === 1 ? "1 year ago" : `${y} years ago`
}

const part = (locale: string, options: Intl.DateTimeFormatOptions, now: Date) => new Intl.DateTimeFormat(locale, { timeZone: TZ, ...options }).format(now)

export function liveClockNow() {
	const now = new Date()
	return {
		timeStr: part("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false }, now),
		dateStr: part("en-GB", { weekday: "long", day: "numeric", month: "long" }, now),
		numDate: part("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" }, now),
		arabicDay: part("ar-MA", { weekday: "long" }, now),
	}
}
