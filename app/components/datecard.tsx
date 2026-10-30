import { dateParts } from "../lib/time.ts"
import { view } from "./ui.tsx"

export const DateCard = view(() => {
	const { weekday, day, month } = dateParts()
	return (
		<div class="hm-c hm-date" aria-label="Today">
			<b data-d-day>{day}</b>
			<div class="hm-dm">
				<small data-d-wd>{weekday}</small>
				<small data-d-mo>{month}</small>
			</div>
		</div>
	)
})
