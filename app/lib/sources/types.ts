export type Field = { name: string; label: string; kind: "text" | "money" | "number"; placeholder?: string }
export type Json = Record<string, number | string>
export type Entry = { amount: number; meta: Json }
export type Ctx = { config: Json; form: FormData; fallback: number; last: Json | null }
export type SourceType = {
key: string
label: string
auto: boolean
keyed: boolean
fields: Field[]
dayFields: Field[]
parseConfig: (f: FormData) => Json | string
entry: (c: Ctx) => Entry | string
}

export const num = (v: unknown) => {
const raw = String(v ?? "").trim().replace(",", ".")
if (!raw) return null
const n = Number(raw)
return Number.isFinite(n) ? n : null
}

export const minor = (v: unknown) => {
const n = num(v)
return n === null || n < 0 ? null : Math.round(n * 100)
}

export const minorOr = (v: unknown, fallback: number) => (String(v ?? "").trim() ? minor(v) : fallback)
