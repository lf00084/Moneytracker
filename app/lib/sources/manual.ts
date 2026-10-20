import { minorOr, type SourceType } from "./types.ts"

export const manual: SourceType = {
key: "manual",
label: "Manual",
auto: false,
keyed: true,
fields: [],
dayFields: [{ name: "amount", label: "Amount", kind: "money" }],
parseConfig: () => ({}),
entry: ({ form, fallback }) => {
const amount = minorOr(form.get("amount"), fallback)
if (amount === null) return "Enter a valid amount"
if (amount <= 0) return "Amount must be more than 0"
return { amount, meta: {} }
},
}
