import { clientEntry, type Handle } from "remix/component"
import { entryId } from "../client/entry-url.ts"
import { liveClockNow } from "../lib/time.ts"
import { view } from "./ui.tsx"

type Parts = { numDate: string; arabicDay: string }

const SubDate = view<Parts>(({ numDate, arabicDay }) => (
	<>
		<span class="clock-num">{numDate}</span> <span class="clock-dot">·</span> <span class="clock-ar">{arabicDay}</span>
	</>
))

// Hydrated in the browser: ticks once per second without a page reload.
export const ClockWidget = clientEntry(entryId("ClockWidget"), function ClockWidget(handle: Handle) {
	let { timeStr, dateStr, numDate, arabicDay } = liveClockNow()
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
			;({ timeStr, dateStr, numDate, arabicDay } = next)
			void handle.update()
		}, 1000)
		handle.signal.addEventListener("abort", () => clearInterval(timer))
	}
	return () => (
		<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time">
			<div class="clock-time" data-clock-time>
				{timeStr}
			</div>
			<div class="clock-date" data-clock-date>
				{dateStr}
			</div>
			<div class="clock-subdate" data-clock-subdate dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})
