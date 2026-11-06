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
		// One date only: the day number next to the weekday and month. The Arabic
		// weekday duplicated the same date, so it is gone.
		const { weekday, day, month } = parts
		return (
			<article class="hm-date" aria-label="Today">
				<b data-d-day>{day}</b>
				<div class="hm-dm">
					<small data-d-wd>{weekday}</small>
					<small data-d-mo>{month}</small>
				</div>
			</article>
		)
	}
})
