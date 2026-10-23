import { liveClockNow } from "../lib/time.ts";
import { view } from "./view.ts";

type Parts = { numDate: string; arabicDay: string };

/** "13/10/2026 · الثلاثاء". The browser keeps it ticking (see `updateLiveClock` in app.js). */
export const SubDate = view<Parts>(({ numDate, arabicDay }) => (
	<>
		<span class="clock-num">{numDate}</span> <span class="clock-dot">·</span> <span class="clock-ar">{arabicDay}</span>
	</>
));

/** The Casablanca clock, drawn on the server with the right time and then updated live. */
export const ClockWidget = view(() => {
	const { timeStr, dateStr, numDate, arabicDay } = liveClockNow();
	return (
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
	);
});

/** Top strip: on desktop just the clock, on mobile the clock plus the numeric date on the right. */
export const TopBar = view<{ split?: boolean }>(({ split }) => {
	if (!split) {
		return (
			<div class="top-status-bar">
				<ClockWidget />
			</div>
		);
	}
	const { numDate, arabicDay } = liveClockNow();
	return (
		<div class="top-status-bar tsplit">
			<ClockWidget />
			<div class="clock-subdate" dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	);
});
