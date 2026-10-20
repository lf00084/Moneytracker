import { minor, minorOr, type SourceType } from "./types.ts"

export const balance: SourceType = {
key: "balance",
label: "Balance",
auto: false,
keyed: false,
fields: [],
dayFields: [
{ name: "balance", label: "New balance", kind: "money" },
{ name: "withdrawn", label: "Withdrawn since last time", kind: "money" },
{ name: "deposited", label: "Deposited since last time", kind: "money" },
],
parseConfig: () => ({}),
entry: ({ form, last }) => {
const now = minor(form.get("balance"))
if (now === null) return "Enter your new balance"
const withdrawn = minorOr(form.get("withdrawn"), 0)
const deposited = minorOr(form.get("deposited"), 0)
if (withdrawn === null || deposited === null) return "Enter valid withdrawn and deposited amounts"
const before = last && last.balance_minor !== undefined ? Number(last.balance_minor) : null
const amount = before === null ? 0 : now - before + withdrawn - deposited
return { amount, meta: { balance_minor: now, previous_minor: before ?? now, withdrawn_minor: withdrawn, deposited_minor: deposited } }
},
}
