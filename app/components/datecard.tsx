import { clientEntry, type Handle } from "remix/component"
import { entryId } from "../client/entry-url.ts"
import { dateParts } from "../lib/time.ts"

// Hydrated in the browser: refreshes the date at midnight without a reload.
export const DateCard = clientEntry(entryId("DateCard"), function DateCard(handle: Handle) {
	let parts = dateParts()
	if (typeof document !== "undefined") {
		const timer = setInterval(() => {
			const next = dateParts()
			if (next.day !== parts.day || next.month !== parts.month) {
				parts = next
				void handle.update()
			}
		}, 60000)
		handle.signal.addEventListener("abort", () => clearInterval(timer))
	}
	return () => {
		const { weekday, day, month, arabic } = parts
		return (
			<div class="hm-c hm-date" aria-label="Today">
				<span class="hm-ar" lang="ar" dir="rtl" data-d-ar>
					{arabic}
				</span>
				<b data-d-day>{day}</b>
				<div class="hm-dm">
					<small data-d-wd>{weekday}</small>
					<small data-d-mo>{month}</small>
				</div>
			</div>
		)
	}
})
