import { clientEntry, type Handle } from "remix/component"
import { entryId } from "../client/entry-url.ts"
import { liveClockNow } from "../lib/time.ts"

// Hydrated in the browser: shows the local time and ticks once a second.
// Dates live in one place only (the card next to the balance), so the header
// carries the clock and nothing else.
export const ClockWidget = clientEntry(entryId("ClockWidget"), function ClockWidget(handle: Handle) {
	let { timeStr } = liveClockNow()
	// Hydration compares against the server's text. If a minute ticked in
	// between, reuse the rendered value for the first paint and let the timer
	// below correct it a second later instead of logging a mismatch.
	if (typeof document !== "undefined") {
		const shown = document.querySelector("[data-clock-time]")?.textContent?.trim()
		if (shown && shown !== timeStr) timeStr = shown
	}
	if (typeof document !== "undefined") {
		const timer = setInterval(() => {
			const next = liveClockNow()
			if (next.timeStr === timeStr) return
			timeStr = next.timeStr
			void handle.update()
		}, 1000)
		handle.signal.addEventListener("abort", () => clearInterval(timer))
	}
	return () => (
		<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local time">
			<div class="clock-time" data-clock-time>
				{timeStr}
			</div>
		</div>
	)
})
