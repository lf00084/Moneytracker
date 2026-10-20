import { minor, minorOr, num, type SourceType } from "./types.ts"

export const job: SourceType = {
key: "job",
label: "Job",
auto: false,
keyed: true,
fields: [
{ name: "fixed", label: "Fixed pay per day", kind: "money" },
{ name: "rate", label: "Rate per extra hour", kind: "money" },
],
dayFields: [
{ name: "fixed", label: "Fixed pay", kind: "money" },
{ name: "hours", label: "Extra hours", kind: "number" },
],
parseConfig: (f) => {
const fixed = minor(f.get("fixed"))
if (!fixed) return "Enter the fixed pay per day"
const rate = minorOr(f.get("rate"), 0)
if (rate === null) return "Enter a valid rate per extra hour"
return { fixed_minor: fixed, rate_minor: rate }
},
entry: ({ config, form }) => {
const fixed = minorOr(form.get("fixed"), Number(config.fixed_minor) || 0)
if (fixed === null) return "Enter a valid fixed pay"
const raw = String(form.get("hours") ?? "").trim()
const hours = raw ? num(raw) : 0
if (hours === null || hours < 0 || hours > 24) return "Extra hours must be between 0 and 24"
const rate = Number(config.rate_minor) || 0
const amount = fixed + Math.round(hours * rate)
if (amount <= 0) return "Amount must be more than 0"
return { amount, meta: { fixed_minor: fixed, hours, rate_minor: rate } }
},
}
